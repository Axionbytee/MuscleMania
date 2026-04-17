# MuscleMania Systemd Autostart Setup Guide

## ⚠️ ERROR #1 - Service Failed: `/usr/local/bin/pm2 could not be executed`

If you see this error after starting the service, PM2 isn't in `/usr/local/bin`. It's installed in your user's npm directory. Fix it:

```bash
cd ~/MuscleMania
chmod +x scripts/fix-pm2-path.sh
./scripts/fix-pm2-path.sh
```

---

## ⚠️ ERROR #2 - Service Still Fails With Exit Code 127: `command not found`

If the PM2 path is correct but the service still fails with exit code 127, the issue is **systemd runs as root and can't access nvm's PM2**. Fix:

```bash
cd ~/MuscleMania
chmod +x scripts/fix-systemd-user.sh
./scripts/fix-systemd-user.sh
```

This script updates the service to:
- ✅ Run as the `charles` user (not root) — has access to nvm
- ✅ Set `PATH` to include nvm's node_modules bin directory
- ✅ Set `HOME` and `NVM_DIR` environment variables
- ✅ Use the correct PM2 path with proper environment

Then test:
```bash
curl http://localhost:3000
pm2 list
sudo reboot
```

---

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

## Quick Setup (Manual - if scripts don't work)

If you need to do it manually on your Pi:

```bash
# 1. Find the correct PM2 path
which pm2
# Output should be something like: /home/charles/.nvm/versions/node/v24.15.0/bin/pm2
# Note this path, use it below instead of /usr/local/bin/pm2

# 2. Create the service file with CORRECT PM2 path
sudo tee /etc/systemd/system/musclemania.service > /dev/null << 'EOF'
[Unit]
Description=MuscleMania Backend and Scanner (PM2)
After=network.target

[Service]
Type=forking
User=charles
WorkingDirectory=/home/charles/MuscleMania
ExecStart=/home/charles/.nvm/versions/node/v24.15.0/bin/pm2 start ecosystem.config.js
ExecReload=/home/charles/.nvm/versions/node/v24.15.0/bin/pm2 reload ecosystem.config.js
ExecStop=/home/charles/.nvm/versions/node/v24.15.0/bin/pm2 stop ecosystem.config.js
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

**IMPORTANT:** Replace `/home/charles/.nvm/versions/node/v24.15.0/bin/pm2` with the actual output from `which pm2`

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
- Starts PM2 on boot with correct path
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

## Troubleshooting Checklist

- [ ] PM2 path is correct (use `which pm2`)
- [ ] Service file has correct username (not hardcoded `pi`)
- [ ] Service file has correct working directory
- [ ] Service is enabled: `sudo systemctl is-enabled musclemania.service`
- [ ] Service starts: `sudo systemctl start musclemania.service`
- [ ] Port 3000 responds: `curl http://localhost:3000`
- [ ] PM2 apps running: `pm2 list`
- [ ] No errors in logs: `sudo journalctl -u musclemania.service -n 20`

---

## Important Notes

- **Find correct PM2 path**: `which pm2` — use this in the service file
- **Username matters**: Service must run as your user (e.g., `charles`), not `pi` or `root`
- **PM2 still used**: Systemd just starts PM2, which manages the apps
- **No PM2 hook**: We bypass PM2's unreliable startup hook entirely
- **Logs available**: Check `sudo journalctl -u musclemania.service -f` for real-time logs
