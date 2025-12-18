#!/bin/bash
# ============================================
# 🚀 Auto Installer: Ubuntu + RDP + Cloudflare
# ============================================

set -e

echo "=== 🔧 Checking root access ==="
if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo bash rdp.sh"
  exit 1
fi

echo
echo "=== 📦 Installing Docker ==="
apt update -y
apt install -y docker.io docker-compose wget curl

systemctl enable docker
systemctl start docker

echo
echo "=== 📂 Creating workspace ==="
mkdir -p /root/dockercom
cd /root/dockercom

echo
echo "=== 🧾 Creating ubuntu-rdp.yml ==="
cat > ubuntu-rdp.yml <<'EOF'
version: "3.9"
services:
  ubuntu-rdp:
    image: dorowu/ubuntu-desktop-lxde-vnc
    container_name: ubuntu-rdp
    environment:
      USER: admin
      PASSWORD: admin123
    ports:
      - "3389:3389"
      - "6080:80"
    restart: always
EOF

echo
echo "=== 🚀 Starting Ubuntu RDP container ==="
docker-compose -f ubuntu-rdp.yml up -d

echo
echo "=== ☁️ Installing Cloudflare Tunnel ==="
if [ ! -f "/usr/local/bin/cloudflared" ]; then
  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
  chmod +x /usr/local/bin/cloudflared
fi

echo
echo "=== 🌍 Creating Cloudflare tunnels ==="
nohup cloudflared tunnel --url tcp://localhost:3389 > /var/log/cloudflared_rdp.log 2>&1 &
nohup cloudflared tunnel --url http://localhost:6080 > /var/log/cloudflared_web.log 2>&1 &
sleep 6

CF_RDP=$(grep -o "tcp://[a-zA-Z0-9.-]*\.trycloudflare\.com:[0-9]*" /var/log/cloudflared_rdp.log | head -n 1)
CF_WEB=$(grep -o "https://[a-zA-Z0-9.-]*\.trycloudflare\.com" /var/log/cloudflared_web.log | head -n 1)

echo
echo "=============================================="
echo "🎉 Ubuntu Desktop is Ready!"
echo
echo "🖥️ RDP Access (Use Any RDP Client):"
echo "   ${CF_RDP}"
echo
echo "🌍 Web Desktop (Browser):"
echo "   ${CF_WEB}"
echo
echo "👤 Username: admin"
echo "🔑 Password: admin123"
echo
echo "=============================================="
