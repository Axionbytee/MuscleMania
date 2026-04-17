#!/bin/bash

#############################################################################
# MuscleMania Kiosk Setup Script (Systemd Version)
# Configures systemd service for PM2 and Chromium desktop autostart
# Run on Raspberry Pi after setup.sh completes
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

log_info "MuscleMania Kiosk Setup Starting..."
log_info "Current user: $CURRENT_USER"
log_info "Project root: $PROJECT_ROOT"

#############################################################################
# 1. Verify PM2 is installed
#############################################################################
log_info "Step 1: Verifying PM2 installation..."

if ! command -v pm2 &> /dev/null; then
    log_error "PM2 not found. Run setup.sh first with: ./scripts/setup.sh"
    exit 1
fi

log_success "PM2 $(pm2 -v) is installed"

#############################################################################
# 2. Verify ecosystem.config.js exists
#############################################################################
log_info "Step 2: Verifying ecosystem configuration..."

if [ ! -f "$PROJECT_ROOT/ecosystem.config.js" ]; then
    log_error "ecosystem.config.js not found at $PROJECT_ROOT"
    exit 1
fi

log_success "ecosystem.config.js found"

#############################################################################
# 3. Kill existing PM2 processes
#############################################################################
log_info "Step 3: Stopping existing PM2 processes..."

pm2 delete all 2>/dev/null || true
sleep 2

log_success "PM2 processes cleared"

#############################################################################
# 4. Test ecosystem.config.js starts correctly
#############################################################################
log_info "Step 4: Testing ecosystem configuration..."

cd "$PROJECT_ROOT"
pm2 start ecosystem.config.js

sleep 3

if pm2 list | grep -q "musclemania-backend"; then
    log_success "Backend started successfully"
else
    log_error "Backend failed to start. Check:"
    pm2 logs musclemania-backend --lines 20
    exit 1
fi

log_success "Applications running correctly"
pm2 list

#############################################################################
# 5. Save PM2 state
#############################################################################
log_info "Step 5: Saving PM2 state..."

pm2 save

log_success "PM2 state saved"

#############################################################################
# 6. Install systemd service (MOST IMPORTANT)
#############################################################################
log_info "Step 6: Installing systemd service for autoboot..."

SERVICE_FILE="/etc/systemd/system/musclemania.service"
SOURCE_SERVICE="$PROJECT_ROOT/scripts/musclemania.service"

# Check if source service file exists
if [ ! -f "$SOURCE_SERVICE" ]; then
    log_error "Source service file not found: $SOURCE_SERVICE"
    exit 1
fi

# Copy and update service file with correct user
TMP_SERVICE="/tmp/musclemania.service"
cp "$SOURCE_SERVICE" "$TMP_SERVICE"

# Replace 'pi' with actual username
sed -i "s|User=pi|User=$CURRENT_USER|g" "$TMP_SERVICE"
sed -i "s|/home/pi/|/home/$CURRENT_USER/|g" "$TMP_SERVICE"

# Install service file
sudo cp "$TMP_SERVICE" "$SERVICE_FILE"
sudo chmod 644 "$SERVICE_FILE"

log_success "Systemd service installed at: $SERVICE_FILE"

#############################################################################
# 7. Enable and start the service
#############################################################################
log_info "Step 7: Enabling systemd service..."

sudo systemctl daemon-reload
sudo systemctl enable musclemania.service
sudo systemctl start musclemania.service

sleep 2

if sudo systemctl is-active --quiet musclemania.service; then
    log_success "Systemd service is active and running"
else
    log_error "Systemd service failed to start"
    log_warning "Check with: sudo journalctl -u musclemania.service -n 20"
    exit 1
fi

log_success "Service will auto-start on reboot"

#############################################################################
# 8. Configure Chromium autostart
#############################################################################
log_info "Step 8: Configuring Chromium autostart..."

AUTOSTART_DIR="$HOME/.config/autostart"
DESKTOP_FILE="$AUTOSTART_DIR/musclemania-kiosk.desktop"

mkdir -p "$AUTOSTART_DIR"

# Create desktop file
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Exec=/home/$CURRENT_USER/MuscleMania/scripts/start-kiosk.sh
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=MuscleMania Kiosk
Comment=Auto-start MuscleMania Chromium kiosk display
Categories=Utility;
EOF

log_success "Desktop autostart file created: $DESKTOP_FILE"

#############################################################################
# 9. Update start-kiosk.sh with DISPLAY variable
#############################################################################
log_info "Step 9: Updating kiosk startup script..."

KIOSK_SCRIPT="$PROJECT_ROOT/scripts/start-kiosk.sh"

if [ -f "$KIOSK_SCRIPT" ]; then
    # Check if DISPLAY is already set
    if ! grep -q "export DISPLAY" "$KIOSK_SCRIPT"; then
        # Add DISPLAY export after shebang
        sed -i '2a export DISPLAY=:0' "$KIOSK_SCRIPT"
        log_success "Added DISPLAY=:0 to kiosk script"
    else
        log_success "DISPLAY already configured in kiosk script"
    fi
    
    chmod +x "$KIOSK_SCRIPT"
else
    log_warning "Kiosk script not found: $KIOSK_SCRIPT"
fi

#############################################################################
# 10. Disable screen blanking permanently
#############################################################################
log_info "Step 10: Disabling screen blanking..."

if [ -f "/etc/lightdm/lightdm.conf" ]; then
    sudo sed -i '/^xserver-command=/d' /etc/lightdm/lightdm.conf
    echo "xserver-command=X -s 0 -dpms" | sudo tee -a /etc/lightdm/lightdm.conf > /dev/null
    log_success "Screen blanking disabled in lightdm.conf"
fi

#############################################################################
# 11. Make scripts executable
#############################################################################
log_info "Step 11: Making scripts executable..."

chmod +x "$PROJECT_ROOT/scripts/start-kiosk.sh"
chmod +x "$PROJECT_ROOT/scripts/setup.sh"
chmod +x "$PROJECT_ROOT/scripts/diagnose.sh"

log_success "Scripts made executable"

#############################################################################
# 12. Summary and Next Steps
#############################################################################
log_success "Kiosk autostart setup complete!"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}MuscleMania Systemd Setup Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓ PM2 applications running${NC}"
pm2 list
echo ""
echo -e "${GREEN}✓ Systemd service installed and enabled${NC}"
sudo systemctl status musclemania.service --no-pager
echo ""
echo -e "${GREEN}✓ Chromium autostart configured${NC}"
echo -e "  Desktop file: $DESKTOP_FILE"
echo -e "  User: $CURRENT_USER"
echo ""
echo -e "${YELLOW}IMPORTANT - BOOT AUTOSTART FLOW:${NC}"
echo -e "  1. System boots → systemd starts musclemania service"
echo -e "  2. Service runs: pm2 start ecosystem.config.js"
echo -e "  3. Backend + Scanner come online"
echo -e "  4. User logs in → desktop loads"
echo -e "  5. Desktop autostart launches: start-kiosk.sh"
echo -e "  6. Chromium opens fullscreen on http://localhost:3000/admin"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo -e "  1. Reboot to test full autostart:"
echo -e "     ${BLUE}sudo reboot${NC}"
echo ""
echo -e "  2. After reboot, verify with:"
echo -e "     ${BLUE}pm2 list${NC}"
echo -e "     ${BLUE}sudo systemctl status musclemania.service${NC}"
echo ""
echo -e "${YELLOW}Manual Control Commands:${NC}"
echo -e "  Stop service: ${BLUE}sudo systemctl stop musclemania.service${NC}"
echo -e "  Start service: ${BLUE}sudo systemctl start musclemania.service${NC}"
echo -e "  Restart: ${BLUE}sudo systemctl restart musclemania.service${NC}"
echo -e "  View logs: ${BLUE}sudo journalctl -u musclemania.service -f${NC}"
echo -e "  PM2 logs: ${BLUE}pm2 logs${NC}"
echo ""
echo -e "${YELLOW}If Chromium still doesn't spawn:${NC}"
echo -e "  Run diagnostic: ${BLUE}./scripts/diagnose.sh${NC}"
echo -e "  Manual test: ${BLUE}export DISPLAY=:0 && bash $KIOSK_SCRIPT${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
