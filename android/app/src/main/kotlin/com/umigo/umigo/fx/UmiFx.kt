package com.umigo.umigo.fx

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.os.SystemClock
import android.util.Log
import com.cloudwebrtc.webrtc.video.LocalVideoTrack
import com.pixpark.gpupixel.FaceDetector
import com.pixpark.gpupixel.GPUPixel
import com.pixpark.gpupixel.GPUPixelFilter
import com.pixpark.gpupixel.GPUPixelSinkRawData
import com.pixpark.gpupixel.GPUPixelSourceRawData
import io.flutter.FlutterInjector
import org.webrtc.JavaI420Buffer
import org.webrtc.VideoFrame
import org.webrtc.YuvHelper
import java.nio.ByteBuffer
import kotlin.math.atan2
import kotlin.math.hypot
import kotlin.math.sin

/** What the creator picked in the filter sheet. All strengths are 0..1. */
data class FxSettings(
    val smooth: Float = 0f,
    val whiten: Float = 0f,
    val slim: Float = 0f,
    val eyes: Float = 0f,
    val lips: Float = 0f,
    val blush: Float = 0f,
    val look: String = "none",
    val sticker: String = "none",
) {
    val beauty get() = smooth > 0f || whiten > 0f
    val reshape get() = slim > 0f || eyes > 0f
    val any get() = beauty || reshape || lips > 0f || blush > 0f || look != "none" || sticker != "none"
    val needsFace get() = reshape || lips > 0f || blush > 0f || sticker != "none"

    companion object {
        fun from(m: Map<*, *>): FxSettings {
            fun f(k: String) = ((m[k] as? Number)?.toFloat() ?: 0f).coerceIn(0f, 1f)
            return FxSettings(
                f("smooth"), f("whiten"), f("slim"), f("eyes"), f("lips"), f("blush"),
                (m["look"] as? String) ?: "none", (m["sticker"] as? String) ?: "none",
            )
        }
    }
}

/**
 * Runs on WebRTC's camera thread for every frame of the host's camera, before it is shown
 * or sent: I420 -> upright RGBA -> face points -> GPUPixel beauty/makeup/look chain ->
 * AR sticker drawn on top -> I420 frame that LiveKit sends to viewers.
 * Any error turns the filters off for the rest of the session instead of breaking the camera.
 */
class UmiFx(private val ctx: Context) : LocalVideoTrack.ExternalVideoFrameProcessing {
    @Volatile var settings = FxSettings()
    @Volatile var ready = false
    @Volatile var failed = false
    @Volatile var lastError: String? = null

    private var source: GPUPixelSourceRawData? = null
    private var sink: GPUPixelSinkRawData? = null
    private var beauty: GPUPixelFilter? = null
    private var reshape: GPUPixelFilter? = null
    private var lipstick: GPUPixelFilter? = null
    private var blusher: GPUPixelFilter? = null
    private val look = ArrayList<GPUPixelFilter>()
    private var builtKey = ""
    private var detector: FaceDetector? = null

    private var rgba = ByteArray(0)
    private var direct: ByteBuffer? = null
    private var canvasBitmap: Bitmap? = null
    private val stickerCache = HashMap<String, Bitmap?>()
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)

    private var lastFace: FloatArray? = null
    private var missed = 0
    // smoothed sticker pose, so stickers don't jitter
    private var sx = 0f; private var sy = 0f; private var sEye = 0f; private var sAngle = 0f
    private var sUx = 0f; private var sUy = -1f; private var sFaceW = 0f; private var hasPose = false

    /** Loads the native libraries and copies GPUPixel's models. Call off the main thread. */
    fun init() {
        try {
            GPUPixel.Init(ctx.applicationContext)
            ready = true
        } catch (t: Throwable) {
            failed = true
            lastError = t.toString()
            Log.e(TAG, "GPUPixel init failed", t)
        }
    }

    override fun onFrame(frame: VideoFrame): VideoFrame {
        val s = settings
        if (!ready || failed || !s.any) return frame
        return try {
            process(frame, s)
        } catch (t: Throwable) {
            failed = true
            lastError = t.toString()
            Log.e(TAG, "filter failed, turning filters off", t)
            frame
        }
    }

    private fun process(frame: VideoFrame, s: FxSettings): VideoFrame {
        val src = frame.buffer.toI420() ?: return frame
        try {
            val rot = ((frame.rotation % 360) + 360) % 360
            val w0 = src.width
            val h0 = src.height
            val w = if (rot % 180 != 0) h0 else w0
            val h = if (rot % 180 != 0) w0 else h0

            // 1. upright I420, then RGBA
            var upright: VideoFrame.I420Buffer = src
            if (rot != 0) {
                val r = JavaI420Buffer.allocate(w, h)
                YuvHelper.I420Rotate(
                    src.dataY, src.strideY, src.dataU, src.strideU, src.dataV, src.strideV,
                    r.dataY, r.strideY, r.dataU, r.strideU, r.dataV, r.strideV, w0, h0, rot,
                )
                upright = r
            }
            if (rgba.size != w * h * 4) rgba = ByteArray(w * h * 4)
            try {
                GPUPixel.i420ToRgba(
                    upright.dataY, upright.strideY, upright.dataU, upright.strideU,
                    upright.dataV, upright.strideV, w, h, rgba,
                )
            } finally {
                if (upright !== src) upright.release()
            }

            // 2. face points (106, normalised 0..1)
            var face: FloatArray? = null
            if (s.needsFace) {
                val d = detector ?: FaceDetector.Create().also { detector = it }
                val r = d.detect(rgba, w, h, w * 4, FaceDetector.GPUPIXEL_MODE_FMT_VIDEO, FaceDetector.GPUPIXEL_FRAME_TYPE_RGBA)
                if (r != null && r.size >= 212) {
                    face = r; lastFace = r; missed = 0
                } else if (++missed <= 5) {
                    face = lastFace // brief misses keep the last face so stickers don't blink
                } else {
                    lastFace = null; hasPose = false
                }
            }

            // 3. GPUPixel chain
            build(s)
            beauty?.apply {
                SetProperty("skin_smoothing", s.smooth)
                SetProperty("whiteness", s.whiten * 0.6f)
            }
            if (face != null) {
                reshape?.apply {
                    SetProperty("face_landmark", face)
                    SetProperty("thin_face", s.slim * 0.0625f)
                    SetProperty("big_eye", s.eyes * 0.25f)
                }
                lipstick?.apply { SetProperty("face_landmark", face); SetProperty("blend_level", s.lips * 0.8f) }
                blusher?.apply { SetProperty("face_landmark", face); SetProperty("blend_level", s.blush * 0.8f) }
            } else {
                // no face: make the face tools do nothing rather than warp the wrong place
                reshape?.apply { SetProperty("thin_face", 0f); SetProperty("big_eye", 0f) }
                lipstick?.SetProperty("blend_level", 0f)
                blusher?.SetProperty("blend_level", 0f)
            }
            val sinkNow = sink ?: return frame
            source!!.ProcessData(rgba, w, h, w * 4, GPUPixelSourceRawData.FRAME_TYPE_RGBA)
            val out = sinkNow.GetRgbaBuffer() ?: return frame
            val ow = sinkNow.GetWidth()
            val oh = sinkNow.GetHeight()
            if (ow <= 0 || oh <= 0 || out.size < ow * oh * 4) return frame

            var buf = direct
            if (buf == null || buf.capacity() != ow * oh * 4) {
                buf = ByteBuffer.allocateDirect(ow * oh * 4)
                direct = buf
            }
            buf!!.clear()
            buf.put(out, 0, ow * oh * 4)
            buf.rewind()

            // 4. AR sticker
            if (s.sticker != "none" && face != null) drawSticker(buf, ow, oh, face, s.sticker)

            // 5. back to I420 for the encoder
            val i420 = JavaI420Buffer.allocate(ow, oh)
            buf.rewind()
            YuvHelper.ABGRToI420(buf, ow * 4, i420.dataY, i420.strideY, i420.dataU, i420.strideU, i420.dataV, i420.strideV, ow, oh)
            return VideoFrame(i420, 0, frame.timestampNs)
        } finally {
            src.release()
        }
    }

    private fun build(s: FxSettings) {
        val key = "${s.beauty}|${s.reshape}|${s.lips > 0f}|${s.blush > 0f}|${s.look}"
        if (key == builtKey && source != null) return
        val src = source ?: GPUPixelSourceRawData.Create().also { source = it }
        val out = sink ?: GPUPixelSinkRawData.Create().also { sink = it }
        src.RemoveAllSinks()
        listOfNotNull(beauty, reshape, lipstick, blusher).forEach { it.RemoveAllSinks() }
        look.forEach { it.RemoveAllSinks(); it.Destroy() }
        look.clear()

        val chain = ArrayList<GPUPixelFilter>()
        if (s.lips > 0f) chain += (lipstick ?: GPUPixelFilter.Create(GPUPixelFilter.LIPSTICK_FILTER).also { lipstick = it })
        if (s.blush > 0f) chain += (blusher ?: GPUPixelFilter.Create(GPUPixelFilter.BLUSHER_FILTER).also { blusher = it })
        if (s.beauty) chain += (beauty ?: GPUPixelFilter.Create(GPUPixelFilter.BEAUTY_FACE_FILTER).also { beauty = it })
        if (s.reshape) chain += (reshape ?: GPUPixelFilter.Create(GPUPixelFilter.FACE_RESHAPE_FILTER).also { reshape = it })
        look += lookFilters(s.look)
        chain += look

        var prev: com.pixpark.gpupixel.GPUPixelSource = src
        for (f in chain) {
            prev.AddSink(f)
            prev = f
        }
        prev.AddSink(out)
        builtKey = key
    }

    private fun lookFilters(name: String): List<GPUPixelFilter> {
        fun f(type: String, vararg props: Pair<String, Float>) =
            GPUPixelFilter.Create(type).also { g -> props.forEach { (k, v) -> g.SetProperty(k, v) } }
        return when (name) {
            "warm" -> listOf(f("WhiteBalanceFilter", "temperature" to 6300f), f("SaturationFilter", "saturation" to 1.12f))
            "cool" -> listOf(f("WhiteBalanceFilter", "temperature" to 4200f), f("ContrastFilter", "contrast" to 1.05f))
            "vintage" -> listOf(
                f("SaturationFilter", "saturation" to 0.62f),
                f("WhiteBalanceFilter", "temperature" to 6000f),
                f("ContrastFilter", "contrast" to 0.9f),
            )
            "vivid" -> listOf(f("SaturationFilter", "saturation" to 1.45f), f("ContrastFilter", "contrast" to 1.12f))
            "mono" -> listOf(f("GrayscaleFilter"), f("ContrastFilter", "contrast" to 1.1f))
            "sketch" -> listOf(f("SketchFilter"))
            "toon" -> listOf(f("SmoothToonFilter"))
            else -> emptyList()
        }
    }

    // ---------------- AR stickers ----------------
    private class Part(val asset: String, val widthOfFace: Float, val upEyes: Float, val anchor: Int = -1, val bob: Boolean = false)

    private fun partsFor(sticker: String): List<Part> = when (sticker) {
        "glasses" -> listOf(Part("glasses", 0.95f, 0.05f))
        "crown" -> listOf(Part("crown", 0.78f, 2.15f))
        "cat" -> listOf(Part("cat_ears", 1.25f, 1.95f), Part("cat_nose", 0.62f, 0f, anchor = 46))
        "bunny" -> listOf(Part("bunny_ears", 1.0f, 2.7f))
        "hearts" -> listOf(Part("hearts", 1.45f, 2.0f, bob = true))
        "star" -> listOf(Part("star_glasses", 1.0f, 0.05f))
        else -> emptyList()
    }

    private fun sticker(name: String): Bitmap? = stickerCache.getOrPut(name) {
        try {
            val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/fx/$name.png")
            ctx.assets.open(key).use { BitmapFactory.decodeStream(it) }
        } catch (t: Throwable) {
            Log.w(TAG, "sticker $name missing", t)
            null
        }
    }

    private fun drawSticker(buf: ByteBuffer, w: Int, h: Int, lm: FloatArray, name: String) {
        fun px(i: Int) = lm[2 * i] * w
        fun py(i: Int) = lm[2 * i + 1] * h
        var ax = px(74); var ay = py(74); var bx = px(77); var by = py(77)
        if (ax > bx) { val tx = ax; ax = bx; bx = tx; val ty = ay; ay = by; by = ty }
        val ex = bx - ax; val ey = by - ay
        val eye = hypot(ex, ey)
        if (eye < 6f) return
        val mx = (ax + bx) / 2f; val my = (ay + by) / 2f
        var ux = ey / eye; var uy = -ex / eye // perpendicular to the eye line
        if (ux * (px(16) - mx) + uy * (py(16) - my) > 0) { ux = -ux; uy = -uy } // point away from the chin
        val angle = Math.toDegrees(atan2(ey, ex).toDouble()).toFloat()
        val faceW = hypot(px(32) - px(0), py(32) - py(0)).coerceAtLeast(eye * 1.8f)

        val k = if (hasPose) 0.45f else 1f
        sx += (mx - sx) * k; sy += (my - sy) * k; sEye += (eye - sEye) * k
        sAngle += (angle - sAngle) * k; sFaceW += (faceW - sFaceW) * k
        sUx += (ux - sUx) * k; sUy += (uy - sUy) * k
        hasPose = true

        var bmp = canvasBitmap
        if (bmp == null || bmp.width != w || bmp.height != h) {
            bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            canvasBitmap = bmp
        }
        buf.rewind()
        bmp!!.copyPixelsFromBuffer(buf)
        val c = Canvas(bmp)
        val t = SystemClock.uptimeMillis() / 1000.0
        for (p in partsFor(name)) {
            val img = sticker(p.asset) ?: continue
            val dw = sFaceW * p.widthOfFace
            val dh = dw * img.height / img.width
            var cx: Float; var cy: Float
            if (p.anchor >= 0) {
                cx = px(p.anchor); cy = py(p.anchor)
            } else {
                val up = sEye * p.upEyes + if (p.bob) (sin(t * 3.0) * sEye * 0.08).toFloat() else 0f
                cx = sx + sUx * up; cy = sy + sUy * up
            }
            c.save()
            c.translate(cx, cy)
            c.rotate(sAngle)
            c.drawBitmap(img, null, RectF(-dw / 2, -dh / 2, dw / 2, dh / 2), paint)
            c.restore()
        }
        buf.rewind()
        bmp.copyPixelsToBuffer(buf)
        buf.rewind()
    }

    companion object {
        const val TAG = "UmiFx"
    }
}
