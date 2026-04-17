#!/bin/bash

# Fix systemd service to run as charles user with nvm environment
# This resolves: "command not found" (exit code 127) when systemd tries to run PM2

echo "[INFO] Updating systemd service to run as charles user with nvm environment..."

# Create service file that:
# 1. Runs as the charles user (has access to nvm)
# 2. Sets HOME to charles's home directory
# 3. Sets PATH to include nvm's node_modules/.bin
# 4. Changes to project directory
# 5. Sources .bashrc for nvm environment

sudo tee /etc/systemd/system/musclemania.service > /dev/null << 'EOF'
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

# Start PM2 to manage backend and scanner
ExecStart=/home/charles/.nvm/versions/node/v24.15.0/bin/pm2 start ecosystem.config.js --no-daemon
ExecReload=/home/charles/.nvm/versions/node/v24.15.0/bin/pm2 reload ecosystem.config.js
ExecStop=/home/charles/.nvm/versions/node/v24.15.0/bin/pm2 stop ecosystem.config.js

Restart=on-failure
RestartSec=10

# Process management
StandardOutput=journal
StandardError=journal
SyslogIdentifier=musclemania

[Install]
WantedBy=multi-user.target
EOF

echo "[✓] Service file updated successfully"

# Reload systemd daemon
echo "[INFO] Reloading systemd daemon..."
sudo systemctl daemon-reload

# Start the service
echo "[INFO] Starting musclemania service..."
sudo systemctl start musclemania.service

# Wait a moment for startup
sleep 2

# Check status
echo ""
echo "[INFO] Checking service status..."
sudo systemctl status musclemania.service

echo ""
echo "[INFO] Checking PM2 apps..."
pm2 list

echo ""
echo "✅ Service updated and started!"
echo "Verify with:"
echo "  sudo systemctl status musclemania.service"
echo "  pm2 list"
echo "  curl http://localhost:3000"
