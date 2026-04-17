#!/bin/bash

#############################################################################
# MuscleMania Fix PM2 Path in Systemd Service
# Finds the correct PM2 path and updates the systemd service
#############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "Finding correct PM2 path..."

# Try to find PM2 in various locations
PM2_PATH=""

# Check nvm first (most common on Pi)
if [ -d "$HOME/.nvm" ]; then
    PM2_PATH=$(find "$HOME/.nvm/versions/node" -name "pm2" -type f 2>/dev/null | head -1)
fi

# Check global npm
if [ -z "$PM2_PATH" ]; then
    PM2_PATH=$(which pm2 2>/dev/null || echo "")
fi

# Check usr/local
if [ -z "$PM2_PATH" ]; then
    PM2_PATH="/usr/local/bin/pm2"
fi

if [ ! -f "$PM2_PATH" ]; then
    log_error "PM2 not found in: $PM2_PATH"
    log_info "Trying alternative detection..."
    PM2_PATH=$(npm list -g pm2 2>/dev/null | grep pm2 | head -1 | grep -oE '/[^ ]+pm2' | head -c-4)bin/pm2
    log_info "Detected PM2 at: $PM2_PATH"
fi

if [ ! -f "$PM2_PATH" ]; then
    log_error "Could not find PM2. Try running:"
    echo "  npm install -g pm2"
    exit 1
fi

log_success "Found PM2 at: $PM2_PATH"

# Stop the service
log_info "Stopping musclemania service..."
sudo systemctl stop musclemania.service 2>/dev/null || true
sleep 1

# Update the systemd service with correct PM2 path
log_info "Updating /etc/systemd/system/musclemania.service..."

sudo tee /etc/systemd/system/musclemania.service > /dev/null << EOF
[Unit]
Description=MuscleMania Backend and Scanner (PM2)
Documentation=https://pm2.keymetrics.io
After=network.target

[Service]
Type=forking
User=$USER
WorkingDirectory=$HOME/MuscleMania
ExecStart=$PM2_PATH start ecosystem.config.js
ExecReload=$PM2_PATH reload ecosystem.config.js
ExecStop=$PM2_PATH stop ecosystem.config.js
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=musclemania
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

log_success "Service file updated with correct PM2 path"

# Reload and start
log_info "Reloading systemd daemon..."
sudo systemctl daemon-reload

log_info "Starting musclemania service..."
sudo systemctl start musclemania.service

sleep 3

# Check status
if sudo systemctl is-active --quiet musclemania.service; then
    log_success "Service started successfully!"
    echo ""
    echo -e "${GREEN}Status:${NC}"
    sudo systemctl status musclemania.service --no-pager | head -8
    echo ""
    echo -e "${GREEN}PM2 Apps:${NC}"
    pm2 list
else
    log_error "Service failed to start"
    echo ""
    echo -e "${RED}Status:${NC}"
    sudo systemctl status musclemania.service --no-pager
    echo ""
    echo -e "${RED}Logs:${NC}"
    journalctl -xeu musclemania.service --no-pager | tail -20
    exit 1
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Next Steps${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Service is now running with correct PM2 path:"
echo -e "  ${YELLOW}$PM2_PATH${NC}"
echo ""
echo -e "Test connectivity:"
echo -e "  ${BLUE}curl http://localhost:3000${NC}"
echo ""
echo -e "View logs:"
echo -e "  ${BLUE}sudo journalctl -u musclemania.service -f${NC}"
echo ""
echo -e "Reboot to test autostart:"
echo -e "  ${BLUE}sudo reboot${NC}"
echo ""
