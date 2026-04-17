#!/bin/bash

#############################################################################
# MuscleMania Full Setup Script
# Installs Python, Node.js, and Raspberry Pi configuration in one go
#############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

log_info "MuscleMania Setup Starting..."
log_info "Project Root: $PROJECT_ROOT"

#############################################################################
# 1. Update System Packages
#############################################################################
log_info "Step 1: Updating system packages..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
log_success "System packages updated"

#############################################################################
# 2. Install Node.js and npm
#############################################################################
log_info "Step 2: Installing Node.js and npm..."

if ! command -v node &> /dev/null; then
    log_warning "Node.js not found, installing..."
    
    # Install Node.js from NodeSource repository (recommended for Raspberry Pi)
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    log_success "Node.js $(node -v) installed"
    log_success "npm $(npm -v) installed"
else
    log_success "Node.js $(node -v) already installed"
    log_success "npm $(npm -v) already installed"
fi

#############################################################################
# 3. Install Python and pip
#############################################################################
log_info "Step 3: Installing Python and pip..."

if ! command -v python3 &> /dev/null; then
    log_warning "Python3 not found, installing..."
    sudo apt-get install -y python3 python3-pip
    log_success "Python $(python3 --version) installed"
else
    log_success "Python $(python3 --version) already installed"
fi

if ! command -v pip &> /dev/null && ! command -v pip3 &> /dev/null; then
    log_warning "pip not found, installing..."
    sudo apt-get install -y python3-pip
fi
log_success "pip $(pip3 --version) already available"

#############################################################################
# 4. Install Python Dependencies
#############################################################################
log_info "Step 4: Installing Python dependencies..."
log_info "Installing: mfrc522, RPi.GPIO, requests"

sudo pip3 install -q mfrc522 RPi.GPIO requests
log_success "Python dependencies installed"

#############################################################################
# 5. Install Node Dependencies (Backend)
#############################################################################
log_info "Step 5: Installing Node.js backend dependencies..."

if [ -d "$PROJECT_ROOT/backend" ]; then
    cd "$PROJECT_ROOT/backend"
    log_info "Installing npm packages from backend/..."
    npm install --quiet
    log_success "Backend dependencies installed"
else
    log_warning "Backend directory not found, skipping npm install"
fi

#############################################################################
# 6. Raspberry Pi Specific Configuration
#############################################################################

# Check if running on Raspberry Pi
if [ -f "/sys/firmware/devicetree/base/model" ]; then
    log_info "Step 6: Configuring Raspberry Pi settings..."
    
    # 6a. Enable SPI0 in /boot/config.txt
    log_info "Checking SPI0 configuration in /boot/config.txt..."
    if ! grep -q "dtoverlay=spi0-3cs" /boot/config.txt; then
        log_warning "SPI0 overlay not found, adding..."
        echo "" | sudo tee -a /boot/config.txt > /dev/null
        echo "# MuscleMania RFID Reader - SPI0 Overlay" | sudo tee -a /boot/config.txt > /dev/null
        echo "dtoverlay=spi0-3cs" | sudo tee -a /boot/config.txt > /dev/null
        log_success "SPI0 overlay added to /boot/config.txt"
        log_warning "⚠️  REBOOT REQUIRED: Please run 'sudo reboot' to enable SPI0"
    else
        log_success "SPI0 overlay already configured"
    fi
    
    # 6b. Install and configure PM2 for process management
    log_info "Installing PM2 for process management..."
    sudo npm install -g pm2 --quiet
    log_success "PM2 installed globally"
    
    # 6c. Install PM2 startup hook
    log_info "Configuring PM2 startup..."
    pm2 startup systemd -u $USER --hp /home/$USER
    log_success "PM2 startup configured"
    
    # 6d. Create PM2 ecosystem config if it doesn't exist
    if [ ! -f "$PROJECT_ROOT/ecosystem.config.js" ]; then
        log_info "Creating ecosystem.config.js..."
        cat > "$PROJECT_ROOT/ecosystem.config.js" << 'EOF'
module.exports = {
  apps: [
    {
      name: 'musclemania-backend',
      script: './backend/server.js',
      cwd: __dirname,
      instances: 1,
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/err.log',
      out_file: './logs/out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true
    }
  ]
};
EOF
        log_success "ecosystem.config.js created"
    fi
    
    # 6e. Enable I2C and GPIO if needed
    log_info "Checking I2C and GPIO settings..."
    if ! grep -q "dtparam=i2c_arm=on" /boot/config.txt; then
        echo "dtparam=i2c_arm=on" | sudo tee -a /boot/config.txt > /dev/null
        log_success "I2C enabled"
    fi
    
else
    log_warning "Not running on Raspberry Pi - skipping Pi-specific configuration"
    log_info "Note: For Raspberry Pi deployment, manually enable SPI0 and configure startup"
fi

#############################################################################
# 7. Make Scripts Executable
#############################################################################
log_info "Step 7: Making scripts executable..."

if [ -d "$PROJECT_ROOT/scripts" ]; then
    chmod +x "$PROJECT_ROOT/scripts"/*.sh 2>/dev/null || true
    log_success "Scripts made executable"
fi

#############################################################################
# 8. Create Required Directories
#############################################################################
log_info "Step 8: Creating required directories..."

mkdir -p "$PROJECT_ROOT/logs"
mkdir -p "$PROJECT_ROOT/backend/uploads"

log_success "Directories created"

#############################################################################
# 9. Summary and Next Steps
#############################################################################
log_success "Setup complete!"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}MuscleMania Setup Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓ Python${NC} (v$(python3 --version | cut -d' ' -f2))"
echo -e "  Dependencies: mfrc522, RPi.GPIO, requests"
echo ""
echo -e "${GREEN}✓ Node.js${NC} (v$(node -v | cut -c2-))"
echo -e "  npm $(npm -v)"
echo -e "  Backend dependencies installed"
echo ""

if [ -f "/sys/firmware/devicetree/base/model" ]; then
    echo -e "${GREEN}✓ Raspberry Pi Configuration${NC}"
    echo -e "  SPI0 overlay configured"
    echo -e "  PM2 installed for process management"
    echo ""
    echo -e "${YELLOW}IMPORTANT - NEXT STEPS:${NC}"
    echo -e "  1. Reboot to enable SPI0: ${BLUE}sudo reboot${NC}"
    echo -e "  2. After reboot, start the backend with:"
    echo -e "     ${BLUE}cd $PROJECT_ROOT${NC}"
    echo -e "     ${BLUE}npm --prefix backend start${NC}"
    echo -e "  3. (Optional) Run Python RFID scanner:"
    echo -e "     ${BLUE}python3 $PROJECT_ROOT/reader/scanner.py${NC}"
    echo ""
    echo -e "${YELLOW}For PM2 autostart (kiosk mode):${NC}"
    echo -e "  1. Test: ${BLUE}pm2 start ecosystem.config.js${NC}"
    echo -e "  2. Save: ${BLUE}pm2 save${NC}"
    echo -e "  3. Install startup: ${BLUE}pm2 startup${NC}"
    echo -e "  4. Reboot: ${BLUE}sudo reboot${NC}"
else
    echo -e "${GREEN}✓ Development Environment${NC}"
    echo ""
    echo -e "${YELLOW}NEXT STEPS:${NC}"
    echo -e "  Start the backend:"
    echo -e "  ${BLUE}cd $PROJECT_ROOT/backend${NC}"
    echo -e "  ${BLUE}npm run dev${NC}"
    echo ""
    echo -e "  Run Python RFID scanner (on Raspberry Pi only):"
    echo -e "  ${BLUE}python3 $PROJECT_ROOT/reader/scanner.py${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
