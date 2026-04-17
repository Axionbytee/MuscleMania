# MuscleMania Kiosk Troubleshooting Guide

## Quick Diagnosis

Run this on your Raspberry Pi to check everything:
```bash
chmod +x ~/MuscleMania/scripts/diagnose.sh
./scripts/diagnose.sh
```

This will check:
- ✓ PM2 service status
- ✓ Backend port 3000 listening
- ✓ Desktop autostart file
- ✓ Chromium installation
- ✓ Display variable
- ✓ PM2 startup hook
- ✓ Kiosk script permissions

---

## Common Issues & Fixes

### Issue: Chromium doesn't spawn after reboot

**Symptoms:**
- PM2 shows apps running
- Port 3000 responds to `curl http://localhost:3000`
- But Chromium doesn't appear on monitor

**Root Causes & Solutions:**

#### 1. **DISPLAY not set (Most Common)**
```bash
# Check
echo $DISPLAY

# Fix: Add to start-kiosk.sh before chromium line
export DISPLAY=:0

# Or if display is :1
export DISPLAY=:1
```

#### 2. **Desktop autostart file has wrong path**
```bash
# Check
cat ~/.config/autostart/musclemania-kiosk.desktop

# Fix if path shows /home/pi/ but your user is different
sed -i "s|/home/pi/|/home/$USER/|g" ~/.config/autostart/musclemania-kiosk.desktop
```

#### 3. **Chromium not installed**
```bash
sudo apt-get install chromium-browser
```

#### 4. **Kiosk script not executable**
```bash
chmod +x ~/MuscleMania/scripts/start-kiosk.sh
```

#### 5. **Screen blanking interfering**
Manually test:
```bash
# Set display and run directly
export DISPLAY=:0
/home/$USER/MuscleMania/scripts/start-kiosk.sh
```

---

### Issue: Backend not starting

**Symptoms:**
- `pm2 list` shows `musclemania-backend` with status "errored" or "stopped"
- Port 3000 is not listening

**Fixes:**

```bash
# 1. Check what went wrong
pm2 logs musclemania-backend

# 2. Verify .env file exists
ls -la ~/MuscleMania/backend/.env

# 3. Reinstall dependencies
cd ~/MuscleMania/backend
npm install

# 4. Test backend manually
npm start

# 5. If still failing, check MongoDB connection
# Verify MONGO_URL in .env is correct
cat ~/MuscleMania/backend/.env | grep MONGO
```

---

### Issue: PM2 apps don't auto-start on reboot

**Symptoms:**
- After reboot, `pm2 list` shows no apps
- But manual `pm2 start ecosystem.config.js` works

**Fixes:**

```bash
# 1. Reinstall PM2 startup hook
pm2 startup systemd -u $USER --hp /home/$USER

# 2. Save current PM2 state
pm2 save

# 3. Check if service is enabled
sudo systemctl status pm2-$USER

# 4. If still not working, start manually after reboot
pm2 start ecosystem.config.js
pm2 save
```

---

### Issue: Scanner (RFID) not working

**Symptoms:**
- Backend running
- But RFID reader not responding

**Fixes:**

```bash
# 1. Check scanner logs
pm2 logs musclemania-scanner

# 2. Verify SPI0 is enabled
ls -la /dev/spidev0.0

# 3. If missing, add to /boot/config.txt
echo "dtoverlay=spi0-3cs" | sudo tee -a /boot/config.txt
sudo reboot

# 4. Check GPIO pin
# If RC522 RST is wired to different pin, update scanner.py PIN_RST variable

# 5. Test manually
python3 ~/MuscleMania/reader/scanner.py
```

---

## Manual Control Commands

```bash
# View all running apps
pm2 list

# View live logs (all apps)
pm2 logs

# View specific app logs
pm2 logs musclemania-backend
pm2 logs musclemania-scanner

# Stop all
pm2 stop all

# Start all
pm2 start all

# Restart all
pm2 restart all

# Reload (graceful restart for clustering)
pm2 reload all

# Kill PM2 daemon completely
pm2 kill

# View system startup logs
journalctl -u pm2-$USER -n 50

# Check X11 display
ps aux | grep -i x11
```

---

## Testing Checklist

Before considering setup complete, test:

- [ ] Reboot the Pi: `sudo reboot`
- [ ] After reboot, check PM2: `pm2 list`
- [ ] Check backend: `curl http://localhost:3000`
- [ ] Check Chromium appears on monitor
- [ ] Try scanning a card (RFID reader)
- [ ] Check admin panel loads at: `http://localhost:3000/admin`
- [ ] View logs without errors: `pm2 logs`

---

## Quick Reset (if everything breaks)

```bash
# 1. Stop PM2
pm2 kill

# 2. Remove autostart file
rm ~/.config/autostart/musclemania-kiosk.desktop

# 3. Re-run setup
./scripts/setup.sh
sudo reboot

# 4. After reboot, run kiosk setup
./scripts/kiosk-setup.sh
```

---

## Support Info to Gather

If you need help, run and share output:
```bash
./scripts/diagnose.sh
pm2 logs --lines 50
cat ~/.config/autostart/musclemania-kiosk.desktop 2>/dev/null || echo "Desktop file missing"
```
