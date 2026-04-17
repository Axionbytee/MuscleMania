# MuscleMania Systemd Autostart Setup Guide

**You're right** — systemd is more reliable than PM2's startup hook. Here's the fixed setup:

## ⚠️ IMPORTANT - Service Not Found After Reboot?

If you see `Unit musclemania.service could not be found`, run this to fix it:

```bash
cd ~/MuscleMania
chmod +x scripts/fix-systemd.sh
./scripts/fix-systemd.sh
sudo reboot
```

This script:
- ✅ Removes the broken `pm2-charles` service (old hook)
- ✅ Installs the proper `musclemania` systemd service
- ✅ Enables autostart on boot
- ✅ Tests that everything works

---

## Quick Setup (Manual - if fix-systemd.sh doesn't work)

If you need to do it manually on your Pi:

```bash
# 1. Remove the broken PM2 hook
pm2 unstartup systemd
sudo systemctl disable pm2-charles
sudo rm /etc/systemd/system/pm2-charles.service
sudo systemctl daemon-reload

# 2. Create the proper service file
sudo tee /etc/systemd/system/musclemania.service > /dev/null << 'EOF'
[Unit]
Description=MuscleMania Backend and Scanner (PM2)
After=network.target

[Service]
Type=forking
User=charles
WorkingDirectory=/home/charles/MuscleMania
ExecStart=/usr/local/bin/pm2 start ecosystem.config.js
ExecReload=/usr/local/bin/pm2 reload ecosystem.config.js
ExecStop=/usr/local/bin/pm2 stop ecosystem.config.js
Restart=on-failure
RestartSec=5s
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

# 3. Enable and start
sudo systemctl daemon-reload
sudo systemctl enable musclemania.service
sudo systemctl start musclemania.service

# 4. Verify
sudo systemctl status musclemania.service
pm2 list

# 5. Test
sudo reboot
```

---

## What Changed

### Old Way (Unreliable) ❌
```
Boot → PM2 startup hook → (often fails) → Nothing starts
```

### New Way (Reliable) ✅
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
- Direct systemd service (not relying on PM2's hook)
- Starts PM2 on boot
- Auto-restarts if service crashes
- Logs to journalctl (system logs)

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

- **Username auto-detected in scripts**: Scripts replace `pi` with your actual username
- **DISPLAY auto-added**: Scripts add `export DISPLAY=:0` to start-kiosk.sh
- **PM2 still used**: Systemd just starts PM2, which manages the apps
- **No need for PM2 hook**: We bypass PM2's unreliable startup hook entirely
- **If service still missing**: Run `./scripts/fix-systemd.sh` to install manually
