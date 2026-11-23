# Umi Guard: free real-time chat + video moderator bot for Umigo lives.
# Debian (glibc) base because @tensorflow/tfjs-node ships glibc binaries.
FROM node:22-bookworm-slim
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev && npm cache clean --force
COPY index.js filter.js wordlist.json ./
ENV DATA_DIR=/data
VOLUME /data
CMD ["node", "index.js"]
