# MuscleMania Systemd Autostart Setup Guide

**You're right** — systemd is more reliable than PM2's startup hook. Here's the fixed setup:

## Quick Setup (Run These Steps)

### On your Raspberry Pi:

```bash
cd ~/MuscleMania

# 1. Stop existing PM2 processes
pm2 delete all

# 2. Run the updated kiosk setup (now uses systemd)
chmod +x scripts/kiosk-setup.sh
./scripts/kiosk-setup.sh

# 3. Reboot to test
sudo reboot
```

That's it. The script now:
- ✅ Installs systemd service file
- ✅ Enables systemd autostart (NOT PM2's hook)
- ✅ Configures desktop Chromium launch
- ✅ Sets DISPLAY variable automatically
- ✅ Disables screen blanking

---

## What Changed

### Old Way (Unreliable)
```
Boot → PM2 startup hook → (often fails) → Nothing starts
```

### New Way (Reliable - Systemd)
```
Boot → systemd starts musclemania.service
      → Service runs: pm2 start ecosystem.config.js
      → Backend + Scanner online
      → User logs in
      → Desktop launches: start-kiosk.sh
      → Chromium opens fullscreen
```

---

## What Gets Installed

### `/etc/systemd/system/musclemania.service`
- Systemd service that starts PM2 on boot
- Uses your actual username (auto-detected)
- Restarts automatically if service crashes
- Logs to journalctl (system logs)

### Files Created
```
~/MuscleMania/scripts/musclemania.service    ← Systemd service template
~/.config/autostart/musclemania-kiosk.desktop ← Desktop launch entry
```

---

## Verify It Works

After reboot:

```bash
# Check if service is running
sudo systemctl status musclemania.service

# Check if apps started via PM2
pm2 list

# Check if port 3000 is listening
curl http://localhost:3000

# View systemd logs
sudo journalctl -u musclemania.service -n 20

# View PM2 logs
pm2 logs
```

---

## Manual Control

```bash
# Stop the service
sudo systemctl stop musclemania.service

# Start the service
sudo systemctl start musclemania.service

# Restart
sudo systemctl restart musclemania.service

# View live logs
sudo journalctl -u musclemania.service -f

# Check if enabled on boot
sudo systemctl is-enabled musclemania.service
# Should output: enabled
```

---

## If Chromium Still Doesn't Spawn

After reboot, manually test:

```bash
# Check what's running
pm2 list
sudo systemctl status musclemania.service

# Test desktop launch manually
export DISPLAY=:0
bash ~/MuscleMania/scripts/start-kiosk.sh

# Or run diagnostic
./scripts/diagnose.sh
```

---

## Disable Systemd Autostart (if needed)

```bash
# Disable boot autostart
sudo systemctl disable musclemania.service

# Remove service file
sudo rm /etc/systemd/system/musclemania.service
sudo systemctl daemon-reload

# You can still start manually with:
pm2 start ecosystem.config.js
```

---

## Important Notes

- **Username auto-detected**: Script replaces `pi` with your actual username
- **DISPLAY auto-added**: Script adds `export DISPLAY=:0` to start-kiosk.sh
- **PM2 still used**: Systemd just starts PM2, which manages the apps
- **No need for PM2 hook**: We bypass PM2's unreliable startup hook entirely
