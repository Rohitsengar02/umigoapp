#!/usr/bin/env bash
# One-command Umigo live server setup for a fresh Ubuntu VPS (Hostinger KVM etc).
#   1. Point a DNS A record (e.g. live.yourdomain.com) to this VPS's IP.
#   2. Copy this "server" folder to the VPS and run:  sudo bash install.sh live.yourdomain.com
# Result: wss://live.yourdomain.com (LiveKit) and https://live.yourdomain.com/api (token server).
set -euo pipefail
DOMAIN="${1:?usage: sudo bash install.sh live.yourdomain.com}"
cd "$(dirname "$0")"

if ! command -v docker >/dev/null; then
  echo "Installing Docker…"
  curl -fsSL https://get.docker.com | sh
fi

# Your own API key + secret (generated once, kept in .env). Nothing is sent to LiveKit Cloud.
if [ ! -f .env ]; then
  KEY="umigo_$(openssl rand -hex 6)"
  SECRET="$(openssl rand -base64 36 | tr -d '/+=\n')"
  cat > .env <<ENV
LIVEKIT_API_KEY=$KEY
LIVEKIT_API_SECRET=$SECRET
LIVEKIT_PUBLIC_URL=wss://$DOMAIN
ENV
fi
set -a; . ./.env; set +a

cat > livekit.yaml <<YAML
port: 7880
log_level: info
rtc:
  tcp_port: 7881
  port_range_start: 50000
  port_range_end: 60000
  use_external_ip: true
keys:
  $LIVEKIT_API_KEY: $LIVEKIT_API_SECRET
room:
  empty_timeout: 60
YAML

cat > Caddyfile <<CADDY
$DOMAIN {
  handle /api/* {
    reverse_proxy 127.0.0.1:3001
  }
  handle {
    reverse_proxy 127.0.0.1:7880
  }
}
CADDY

if command -v ufw >/dev/null; then
  ufw allow 22/tcp || true
  ufw allow 80/tcp; ufw allow 443/tcp
  ufw allow 7881/tcp; ufw allow 50000:60000/udp
fi

mkdir -p data/mod && [ -f data/mod/bans.json ] || echo '{}' > data/mod/bans.json
docker compose up -d --build
echo
echo "Done. In the Umigo app go to Me > Live server and paste:  https://$DOMAIN/api"
echo "Health check: curl https://$DOMAIN/api/health"
echo "If your VPS panel has its own firewall, open TCP 80, 443, 7881 and UDP 50000-60000 there too."
