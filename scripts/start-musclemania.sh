#!/bin/bash
# MuscleMania Startup Script
# Starts MongoDB, backend + scanner via PM2, then opens kiosk browser on main display.
# Deploy: cp scripts/musclemania.desktop ~/.config/autostart/
# Runs automatically on LXDE desktop login.

# Source NVM to ensure Node.js is available in this shell context
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Wait for desktop to be fully ready before doing anything
sleep 5

# Detect project root dynamically (works on Pi, dev machine, or any path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Navigate to project root (required — ecosystem.config.js uses relative paths)
cd "$PROJECT_ROOT" || {
    echo "ERROR: Could not navigate to project root at $PROJECT_ROOT. Aborting."
    exit 1
}

# Try to start MongoDB (skip if not available — ok for dev machines)
if command -v systemctl &> /dev/null; then
    sudo systemctl start mongod 2>/dev/null || echo "[INFO] MongoDB service not available (normal on dev machines)"
else
    echo "[INFO] systemctl not found — skipping MongoDB startup"
fi

# Start all PM2 apps (backend + scanner.py).
# If already running, restart them cleanly.
pm2 start ecosystem.config.js 2>/dev/null || pm2 restart all

# Persist PM2 process list so it survives reboots
pm2 save

# Wait for backend to be ready on port 3000 before launching browser
echo "Waiting for backend to be ready on port 3000..."
MAX_WAIT=60
WAITED=0
until curl -s http://localhost:3000 > /dev/null 2>&1; do
    if [ "$WAITED" -ge "$MAX_WAIT" ]; then
        echo "WARNING: Backend did not respond after ${MAX_WAIT}s. Launching browser anyway."
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
done

echo "Launching MuscleMania kiosk browser..."

# Open Chromium in kiosk mode, full-screen, no chrome, pointing to gate display
DISPLAY=:0 chromium-browser \
    --kiosk \
    --noerrdialogs \
    --disable-infobars \
    --no-first-run \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --disable-features=TranslateUI \
    http://localhost:3000/gate &

echo "MuscleMania started successfully."
