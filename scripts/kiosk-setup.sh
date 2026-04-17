#!/bin/bash

#############################################################################
# MuscleMania Kiosk Setup Script
# Configures PM2 autostart and Chromium desktop autostart
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

log_info "MuscleMania Kiosk Setup Starting..."

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
# 2. Start apps with PM2
#############################################################################
log_info "Step 2: Starting applications with PM2..."

cd "$PROJECT_ROOT"

# Stop any existing PM2 apps
pm2 delete all 2>/dev/null || true

# Start from ecosystem.config.js
pm2 start ecosystem.config.js

log_success "PM2 apps started"
pm2 list

#############################################################################
# 3. Save PM2 configuration
#############################################################################
log_info "Step 3: Saving PM2 configuration..."

pm2 save

log_success "PM2 configuration saved"

#############################################################################
# 4. Install PM2 startup hook
#############################################################################
log_info "Step 4: Installing PM2 startup hook for systemd..."

pm2 startup systemd -u $USER --hp /home/$USER

log_success "PM2 startup hook installed"

#############################################################################
# 5. Configure Chromium autostart
#############################################################################
log_info "Step 5: Configuring Chromium autostart..."

AUTOSTART_DIR="$HOME/.config/autostart"
DESKTOP_FILE="$AUTOSTART_DIR/musclemania-kiosk.desktop"

# Create autostart directory if it doesn't exist
mkdir -p "$AUTOSTART_DIR"

# Copy the desktop file from project
cp "$PROJECT_ROOT/scripts/musclemania-kiosk.desktop" "$DESKTOP_FILE"

# Replace placeholder username with actual user
sed -i "s|/home/pi/|/home/$USER/|g" "$DESKTOP_FILE"

log_success "Desktop autostart file created at: $DESKTOP_FILE"

#############################################################################
# 6. Make scripts executable
#############################################################################
log_info "Step 6: Making scripts executable..."

chmod +x "$PROJECT_ROOT/scripts/start-kiosk.sh"
chmod +x "$PROJECT_ROOT/scripts/setup.sh"

log_success "Scripts made executable"

#############################################################################
# 7. Disable screen blanking
#############################################################################
log_info "Step 7: Disabling screen blanking permanently..."

# Add screen blanking disable to lightdm config
if [ -f "/etc/lightdm/lightdm.conf" ]; then
    if ! grep -q "xserver-command=X -s 0 -dpms" /etc/lightdm/lightdm.conf; then
        sudo sed -i '/^xserver-command=/d' /etc/lightdm/lightdm.conf
        echo "xserver-command=X -s 0 -dpms" | sudo tee -a /etc/lightdm/lightdm.conf > /dev/null
        log_success "Screen blanking disabled in lightdm.conf"
    fi
fi

#############################################################################
# 8. Summary and Next Steps
#############################################################################
log_success "Kiosk autostart setup complete!"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}MuscleMania Kiosk Setup Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓ PM2 apps started${NC}"
pm2 list
echo ""
echo -e "${GREEN}✓ PM2 startup hook installed${NC}"
echo -e "  Will auto-start on reboot"
echo ""
echo -e "${GREEN}✓ Chromium autostart configured${NC}"
echo -e "  Desktop file: $DESKTOP_FILE"
echo -e "  User: $USER"
echo ""
echo -e "${GREEN}✓ Screen blanking disabled${NC}"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo -e "  1. Reboot to test full autostart:"
echo -e "     ${BLUE}sudo reboot${NC}"
echo ""
echo -e "  2. After reboot, verify with:"
echo -e "     ${BLUE}pm2 list${NC}"
echo -e "     ${BLUE}pm2 logs${NC}"
echo ""
echo -e "  3. Manual controls:"
echo -e "     Stop kiosk: ${BLUE}pm2 stop all${NC}"
echo -e "     Start kiosk: ${BLUE}pm2 start all${NC}"
echo -e "     View logs: ${BLUE}pm2 logs musclemania-backend${NC}"
echo -e "     View logs: ${BLUE}pm2 logs musclemania-scanner${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
