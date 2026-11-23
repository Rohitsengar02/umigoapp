#!/usr/bin/env bash
# Test on your own computer + phones on the same Wi-Fi (no domain needed).
# Needs Docker. Phones use the APK (browsers need HTTPS for the camera).
set -e
cd "$(dirname "$0")"
IP="${1:-$(hostname -I 2>/dev/null | awk '{print $1}')}"
docker run -d --name umigo-livekit --rm -p 7880:7880 -p 7881:7881 -p 7882:7882/udp \
  livekit/livekit-server:latest --dev --bind 0.0.0.0 --node-ip "$IP"
(cd token-server && npm install && LIVEKIT_PUBLIC_URL="ws://$IP:7880" node index.js)
# In the app: Me > Live server > http://<this computer's IP>:3001
