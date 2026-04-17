#!/bin/bash

#############################################################################
# MuscleMania Diagnostic Script
# Checks if services are running and troubleshoots common issues
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

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}MuscleMania Diagnostic Report${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

#############################################################################
# 1. Check PM2 Status
#############################################################################
echo -e "${BLUE}[1] PM2 Status${NC}"
echo "────────────────────────────────────────────────────────────"

if command -v pm2 &> /dev/null; then
    log_success "PM2 is installed"
    echo ""
    pm2 list
    echo ""
else
    log_error "PM2 is NOT installed"
fi

#############################################################################
# 2. Check Backend on Port 3000
#############################################################################
echo ""
echo -e "${BLUE}[2] Backend Port 3000${NC}"
echo "────────────────────────────────────────────────────────────"

if netstat -tlnp 2>/dev/null | grep -q ':3000'; then
    log_success "Port 3000 is listening"
    netstat -tlnp 2>/dev/null | grep ':3000'
elif lsof -i :3000 2>/dev/null | grep -q LISTEN; then
    log_success "Port 3000 is listening"
    lsof -i :3000 2>/dev/null
else
    log_error "Port 3000 is NOT listening"
    log_warning "Backend may not be running. Check PM2 logs:"
    echo -e "  ${BLUE}pm2 logs musclemania-backend${NC}"
fi

#############################################################################
# 3. Check Desktop Autostart File
#############################################################################
echo ""
echo -e "${BLUE}[3] Desktop Autostart Configuration${NC}"
echo "────────────────────────────────────────────────────────────"

DESKTOP_FILE="$HOME/.config/autostart/musclemania-kiosk.desktop"

if [ -f "$DESKTOP_FILE" ]; then
    log_success "Desktop file exists at: $DESKTOP_FILE"
    echo ""
    cat "$DESKTOP_FILE"
    echo ""
else
    log_error "Desktop file NOT found at: $DESKTOP_FILE"
    log_warning "Run: ./scripts/kiosk-setup.sh"
fi

#############################################################################
# 4. Check Chromium Installation
#############################################################################
echo ""
echo -e "${BLUE}[4] Chromium Installation${NC}"
echo "────────────────────────────────────────────────────────────"

if command -v chromium-browser &> /dev/null; then
    log_success "chromium-browser found"
    chromium-browser --version
elif command -v chromium &> /dev/null; then
    log_success "chromium found"
    chromium --version
else
    log_error "Chromium is NOT installed"
    log_warning "Install with: sudo apt-get install chromium-browser"
fi

#############################################################################
# 5. Check Display Variable
#############################################################################
echo ""
echo -e "${BLUE}[5] Display Configuration${NC}"
echo "────────────────────────────────────────────────────────────"

if [ -z "$DISPLAY" ]; then
    log_warning "DISPLAY variable is not set"
    log_info "Available displays:"
    ls -la /tmp/.X11-unix/ 2>/dev/null || echo "  (No X11 sockets found)"
    log_warning "If running without auto-login, DISPLAY won't be set"
else
    log_success "DISPLAY is set to: $DISPLAY"
fi

#############################################################################
# 6. Check PM2 Startup Hook
#############################################################################
echo ""
echo -e "${BLUE}[6] PM2 Startup Hook${NC}"
echo "────────────────────────────────────────────────────────────"

if sudo systemctl is-enabled pm2-$USER &>/dev/null 2>&1; then
    log_success "PM2 systemd service is enabled"
    sudo systemctl status pm2-$USER --no-pager 2>/dev/null | head -5
else
    log_warning "PM2 systemd service may not be enabled"
    log_info "Run: pm2 startup systemd -u \$USER --hp /home/\$USER"
fi

#############################################################################
# 7. Check Kiosk Script
#############################################################################
echo ""
echo -e "${BLUE}[7] Kiosk Script${NC}"
echo "────────────────────────────────────────────────────────────"

KIOSK_SCRIPT="$HOME/MuscleMania/scripts/start-kiosk.sh"

if [ -f "$KIOSK_SCRIPT" ]; then
    log_success "Kiosk script exists: $KIOSK_SCRIPT"
    if [ -x "$KIOSK_SCRIPT" ]; then
        log_success "Kiosk script is executable"
    else
        log_error "Kiosk script is NOT executable"
        log_info "Fix with: chmod +x $KIOSK_SCRIPT"
    fi
else
    log_error "Kiosk script NOT found: $KIOSK_SCRIPT"
fi

#############################################################################
# 8. Summary & Recommendations
#############################################################################
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Troubleshooting Guide${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}If Chromium is NOT showing:${NC}"
echo "1. Check if backend is running:"
echo -e "   ${BLUE}pm2 logs musclemania-backend${NC}"
echo ""
echo "2. Test the kiosk script manually:"
echo -e "   ${BLUE}bash $KIOSK_SCRIPT${NC}"
echo ""
echo "3. Verify desktop autostart file:"
echo -e "   ${BLUE}cat $DESKTOP_FILE${NC}"
echo ""
echo "4. If using SSH or no auto-login, set DISPLAY manually:"
echo -e "   ${BLUE}export DISPLAY=:0${NC}"
echo -e "   ${BLUE}bash $KIOSK_SCRIPT${NC}"
echo ""

echo -e "${YELLOW}If backend is NOT running:${NC}"
echo "1. Check PM2 error logs:"
echo -e "   ${BLUE}pm2 logs musclemania-backend --err${NC}"
echo ""
echo "2. Verify backend dependencies:"
echo -e "   ${BLUE}cd ~/MuscleMania/backend && npm install${NC}"
echo ""
echo "3. Check .env file exists:"
echo -e "   ${BLUE}ls -la ~/MuscleMania/backend/.env${NC}"
echo ""

echo -e "${YELLOW}Common Fixes:${NC}"
echo "• Make scripts executable:"
echo -e "  ${BLUE}chmod +x ~/MuscleMania/scripts/*.sh${NC}"
echo ""
echo "• Restart PM2:"
echo -e "  ${BLUE}pm2 kill && pm2 start ecosystem.config.js${NC}"
echo ""
echo "• View all logs:"
echo -e "  ${BLUE}pm2 logs${NC}"
echo ""
echo "• Check system boot logs:"
echo -e "  ${BLUE}journalctl -u pm2-$USER -n 50${NC}"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
