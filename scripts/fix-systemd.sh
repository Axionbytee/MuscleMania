#!/bin/bash

#############################################################################
# MuscleMania Fix Systemd Service
# Removes broken PM2 startup hook and installs proper systemd service
# Run this if musclemania.service doesn't exist after reboot
#############################################################################

set -e

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

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

PROJECT_ROOT="$HOME/MuscleMania"
CURRENT_USER="$USER"

log_info "MuscleMania Systemd Service Fix"
log_info "Current user: $CURRENT_USER"

#############################################################################
# 1. Remove broken PM2 startup hook
#############################################################################
log_info "Step 1: Removing old PM2 startup hook..."

# Disable the old pm2-charles service
if sudo systemctl is-enabled pm2-$CURRENT_USER &>/dev/null 2>&1; then
    log_warning "Disabling old pm2-$CURRENT_USER service..."
    sudo systemctl disable pm2-$CURRENT_USER
    sudo systemctl stop pm2-$CURRENT_USER
fi

# Remove the service file
if [ -f "/etc/systemd/system/pm2-$CURRENT_USER.service" ]; then
    log_warning "Removing /etc/systemd/system/pm2-$CURRENT_USER.service..."
    sudo rm "/etc/systemd/system/pm2-$CURRENT_USER.service"
fi

# Run pm2 unstartup to clean up
pm2 unstartup systemd 2>/dev/null || true

log_success "Old PM2 startup hook removed"

#############################################################################
# 2. Install proper musclemania systemd service
#############################################################################
log_info "Step 2: Installing musclemania systemd service..."

# Create service file directly
sudo tee /etc/systemd/system/musclemania.service > /dev/null << EOF
[Unit]
Description=MuscleMania Backend and Scanner (PM2)
Documentation=https://pm2.keymetrics.io
After=network.target

[Service]
Type=forking
User=$CURRENT_USER
WorkingDirectory=/home/$CURRENT_USER/MuscleMania
ExecStart=/usr/local/bin/pm2 start ecosystem.config.js
ExecReload=/usr/local/bin/pm2 reload ecosystem.config.js
ExecStop=/usr/local/bin/pm2 stop ecosystem.config.js
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=musclemania
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

log_success "Service file created: /etc/systemd/system/musclemania.service"

#############################################################################
# 3. Enable and start the service
#############################################################################
log_info "Step 3: Enabling and starting service..."

sudo systemctl daemon-reload
sudo systemctl enable musclemania.service

sleep 1

# Stop any running PM2 apps first
pm2 delete all 2>/dev/null || true
sleep 2

# Start via systemd
sudo systemctl start musclemania.service

sleep 3

# Verify
if sudo systemctl is-active --quiet musclemania.service; then
    log_success "Service is active and running"
else
    log_warning "Service may not be active. Checking status..."
    sudo systemctl status musclemania.service --no-pager
fi

#############################################################################
# 4. Verify PM2 apps are running
#############################################################################
log_info "Step 4: Verifying PM2 applications..."

if pm2 list | grep -q "musclemania-backend"; then
    log_success "Backend is running"
else
    log_error "Backend is NOT running. Check logs:"
    pm2 logs musclemania-backend --lines 20
fi

pm2 list

#############################################################################
# 5. Test connectivity
#############################################################################
log_info "Step 5: Testing backend connectivity..."

if curl -s http://localhost:3000 > /dev/null 2>&1; then
    log_success "Port 3000 is responding"
else
    log_warning "Port 3000 not responding yet. Apps may still be starting."
fi

#############################################################################
# 6. Summary
#############################################################################
log_success "Systemd service fix complete!"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}MuscleMania Systemd Service Status${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Service Status:${NC}"
sudo systemctl status musclemania.service --no-pager | head -6
echo ""
echo -e "${GREEN}PM2 Applications:${NC}"
pm2 list
echo ""
echo -e "${YELLOW}Manual Control:${NC}"
echo -e "  Status: ${BLUE}sudo systemctl status musclemania.service${NC}"
echo -e "  Start: ${BLUE}sudo systemctl start musclemania.service${NC}"
echo -e "  Stop: ${BLUE}sudo systemctl stop musclemania.service${NC}"
echo -e "  Restart: ${BLUE}sudo systemctl restart musclemania.service${NC}"
echo -e "  Logs: ${BLUE}sudo journalctl -u musclemania.service -f${NC}"
echo ""
echo -e "${YELLOW}Next:${NC}"
echo -e "  Reboot to test autostart: ${BLUE}sudo reboot${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
