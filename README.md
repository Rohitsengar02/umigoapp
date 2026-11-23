# Umigo · live streaming app (Flutter, Android + iOS)

Rose Plum design, all screens with demo data, and real live streaming on the free,
open-source **LiveKit server you host yourself** (no LiveKit Cloud, no paid API).

## What's inside

| Path | What it is |
| --- | --- |
| `lib/screens/` | Splash, login, 5-step register with Umi the mascot, home feed, live viewer, gift sheet, go live, host live (+ PK bar), leaderboard, wallet, buy coins, transactions, withdraw, profile, inbox, live server settings |
| `lib/live/live_session.dart` | Host/viewer room logic. Video + audio over WebRTC; chat, likes and gifts as LiveKit data messages (topic `umigo`). Falls back to demo mode when no server is set. |
| `lib/live/token_api.dart` | Calls the token server (`/token`, `/rooms`, `/health`). |
| `lib/data/demo_data.dart` | Demo hosts, gifts, coin packs, transactions, ranks. |
| `server/token-server/` | ~150-line Node service: signs LiveKit tokens with your key/secret and lists live rooms. |
| `server/install.sh` | One command VPS setup: Docker, LiveKit, token server, Caddy HTTPS, firewall. |
| `server/run-local.sh` | Same stack on your own computer for Wi-Fi testing. |

## Run it

```bash
flutter pub get
flutter run                      # phone plugged in via USB, or an emulator
flutter run -d chrome            # quick look in the browser
```

### Build the Android APK

```bash
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk  (copy to phone and install)
```

Optional: bake the server in so testers don't type it:
`flutter build apk --release --dart-define=TOKEN_URL=https://live.yourdomain.com/api`

### iOS
Open on a Mac: `cd ios && pod install`, set `platform :ios, '13.0'` in the Podfile,
then `flutter run` / build in Xcode. Camera and mic permission texts are already in Info.plist.

## Go live for real (free, self-hosted)

1. Point a DNS A record, e.g. `live.yourdomain.com`, at your Hostinger VPS IP.
2. Copy the `server/` folder to the VPS and run `sudo bash install.sh live.yourdomain.com`.
3. In the app on two phones: **Me › Live server** → `https://live.yourdomain.com/api` → Save & test.
4. Phone A taps the camera button › **Go Live**. Phone B sees it on Home under
   **Live on your server**, taps Watch, chats, likes and sends gifts. Phone A sees every
   message and gift animation and earns diamonds (50% of the coin value).

Open these ports on the VPS (and in Hostinger's panel firewall): TCP 80, 443, 7881 and UDP 50000-60000.

Without a server the app runs in **demo mode**: your camera is shown locally and viewers,
chat and gifts are simulated, so every screen can still be tried.

## Tested
A real host + viewer session was run against a self-built LiveKit server v1.13.11:
the host's camera reached the viewer, the viewer's chat message and a Rocket gift reached
the host, and the host's diamonds went up by 499.

## Next (backend plan)
Move the token server logic into NestJS, store users/wallet/gifts in PostgreSQL, use Valkey
for live counters and leaderboards, Cloudflare R2 for media and Firebase for push.
Today coins/diamonds are stored on the device only (demo).
