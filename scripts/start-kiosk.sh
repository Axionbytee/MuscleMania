#!/bin/bash
# MuscleMania Kiosk Startup Script
# Place on Raspberry Pi. Starts the Node backend then opens Chromium fullscreen.

# --- Config ---
APP_DIR="$HOME/MuscleMania/backend"
PORT=3000
URL="http://localhost:$PORT/admin"
LOG="$HOME/musclemania-kiosk.log"

# --- Disable screen blanking / screensaver ---
xset s off
xset s noblank
xset -dpms

# --- Start the Node.js backend ---
echo "[$(date)] Starting MuscleMania backend..." >> "$LOG"
cd "$APP_DIR" && npm start >> "$LOG" 2>&1 &

# --- Wait for the server to be ready ---
echo "[$(date)] Waiting for server on port $PORT..." >> "$LOG"
for i in $(seq 1 30); do
    if curl -s "http://localhost:$PORT" > /dev/null 2>&1; then
        echo "[$(date)] Server is up." >> "$LOG"
        break
    fi
    sleep 2
done

# --- Launch Chromium in kiosk mode ---
echo "[$(date)] Launching Chromium kiosk -> $URL" >> "$LOG"
chromium-browser \
    --kiosk \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --no-first-run \
    --incognito \
    "$URL" >> "$LOG" 2>&1
