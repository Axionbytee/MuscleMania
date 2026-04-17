#!/bin/bash

# Complete systemd service installation for MuscleMania kiosk
# Installs and configures:
# 1. musclemania.service - Backend + PM2 + Python scanner
# 2. kiosk.service - Chromium display

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  MuscleMania Systemd Service Installation                  ║"
echo "║  Backend + Scanner + Kiosk Display                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Find correct PM2 path
echo "[1/5] Finding correct PM2 path..."
if [ -f "/home/charles/.nvm/versions/node/v24.15.0/lib/node_modules/pm2/bin/pm2" ]; then
    PM2_PATH="/home/charles/.nvm/versions/node/v24.15.0/lib/node_modules/pm2/bin/pm2"
    echo "[✓] Found PM2 at: $PM2_PATH"
elif command -v pm2 &> /dev/null; then
    PM2_PATH=$(which pm2)
    echo "[✓] Found PM2 at: $PM2_PATH"
else
    echo "[ERROR] PM2 not found. Run setup.sh first."
    exit 1
fi

# Install musclemania.service (backend + scanner)
echo ""
echo "[2/5] Installing musclemania.service (backend + scanner)..."
sudo tee /etc/systemd/system/musclemania.service > /dev/null << EOF
[Unit]
Description=MuscleMania Backend and Scanner (PM2)
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=charles
Group=charles
WorkingDirectory=/home/charles/MuscleMania
Environment="PATH=/home/charles/.nvm/versions/node/v24.15.0/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="HOME=/home/charles"
Environment="NVM_DIR=/home/charles/.nvm"

ExecStart=$PM2_PATH start ecosystem.config.js --no-daemon
ExecReload=$PM2_PATH reload ecosystem.config.js
ExecStop=$PM2_PATH stop ecosystem.config.js

Restart=on-failure
RestartSec=10

StandardOutput=journal
StandardError=journal
SyslogIdentifier=musclemania

[Install]
WantedBy=multi-user.target
EOF
echo "[✓] musclemania.service installed"

# Install kiosk.service (Chromium)
echo ""
echo "[3/5] Installing kiosk.service (Chromium display)..."
sudo tee /etc/systemd/system/kiosk.service > /dev/null << 'EOF'
[Unit]
Description=MuscleMania Chromium Kiosk Display
After=musclemania.service
Wants=musclemania.service

[Service]
Type=simple
User=charles
Group=charles
WorkingDirectory=/home/charles/MuscleMania
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/home/charles/.Xauthority"
Environment="PATH=/home/charles/.nvm/versions/node/v24.15.0/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="HOME=/home/charles"

# Wait for backend to be ready
ExecStartPre=/bin/bash -c 'for i in {1..30}; do curl -s http://localhost:3000 > /dev/null && echo "[✓] Backend ready" && exit 0; sleep 1; done; echo "[ERROR] Backend not responding"; exit 1'

# Start Chromium in fullscreen kiosk mode
ExecStart=/bin/bash -c 'exec /usr/bin/chromium-browser \
  --kiosk \
  --no-first-run \
  --noerrdialogs \
  --disable-translate \
  --disable-background-networking \
  --disable-default-apps \
  --disable-extensions \
  --disable-sync \
  --disable-plugins \
  --disable-plugin-power-saver \
  --disable-preconnect \
  http://localhost:3000'

Restart=always
RestartSec=5

StandardOutput=journal
StandardError=journal
SyslogIdentifier=musclemania-kiosk

[Install]
WantedBy=multi-user.target
EOF
echo "[✓] kiosk.service installed"

# Reload systemd
echo ""
echo "[4/5] Reloading systemd daemon..."
sudo systemctl daemon-reload
echo "[✓] Systemd reloaded"

# Enable both services on boot
echo ""
echo "[5/5] Enabling services on boot..."
sudo systemctl enable musclemania.service
sudo systemctl enable kiosk.service
echo "[✓] Both services enabled"

# Start both services
echo ""
echo "[INFO] Starting services..."
sudo systemctl start musclemania.service
sleep 2
sudo systemctl start kiosk.service

# Wait for services to stabilize
sleep 3

# Check status
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Service Status                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "Backend & Scanner Service:"
sudo systemctl status musclemania.service

echo ""
echo "Kiosk Display Service:"
sudo systemctl status kiosk.service

echo ""
echo "PM2 Apps Status:"
pm2 list

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ Installation Complete!                                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Services will start automatically on boot."
echo ""
echo "Verify everything is working:"
echo "  curl http://localhost:3000"
echo "  pm2 list"
echo "  sudo systemctl status musclemania.service"
echo "  sudo systemctl status kiosk.service"
echo ""
echo "View logs:"
echo "  sudo journalctl -u musclemania.service -f"
echo "  sudo journalctl -u kiosk.service -f"
echo "  pm2 logs"
echo ""
echo "Test reboot:"
echo "  sudo reboot"
echo "  # After reboot, Chromium should appear on the display"
