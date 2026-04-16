# MuscleMania Pi Startup Setup

## Overview

On boot, the Pi will automatically:
1. Start MongoDB
2. Start the backend Express server + RFID scanner via PM2
3. Wait for the backend to be ready
4. Open Chromium in kiosk mode at `http://localhost:3000/gate`

---

## One-Time Setup Steps

### 1. Make startup script executable

```bash
chmod +x ~/MuscleMania/scripts/start-musclemania.sh
```

### 2. Install autostart desktop entry

```bash
mkdir -p ~/.config/autostart
cp ~/MuscleMania/scripts/musclemania.desktop ~/.config/autostart/
```

### 3. Enable PM2 on boot

```bash
pm2 startup
```

Run the command it outputs (copy/paste and run it), then save the process list:

```bash
pm2 save
```

### 4. Allow mongod to start without a password prompt (sudoers)

```bash
sudo visudo
```

Add this line at the end:

```
pi ALL=(ALL) NOPASSWD: /bin/systemctl start mongod
```

### 5. Reboot to test

```bash
sudo reboot
```

After reboot, the Pi should automatically open Chromium in kiosk mode on the gate display.

---

## Manual Start (Without Reboot)

This works on both Pi and dev machines:

```bash
bash ~/MuscleMania/scripts/start-musclemania.sh
```

**On a dev machine (Windows/Mac/Linux):**
- Ensure MongoDB is running (via Docker, local install, or cloud Atlas)
- The script will skip MongoDB systemctl startup automatically
- Make sure Node.js and PM2 are installed: `npm install -g pm2`
- Run the script from the project folder or anywhere with a valid path

**On Pi (Raspberry OS):**
- Follow the one-time setup steps above first
- Run after reboot, or use this command anytime to restart

---

## PM2 Commands

| Command | Purpose |
|---|---|
| `pm2 status` | View running apps |
| `pm2 logs` | View live logs |
| `pm2 restart all` | Restart backend + scanner |
| `pm2 stop all` | Stop everything |

---

## Troubleshooting

- **Browser doesn't open**: Check `DISPLAY=:0` is available. Run `echo $DISPLAY` in a terminal on the Pi.
- **Backend not starting**: Run `pm2 logs musclemania-backend` to check for errors.
- **Scanner not starting**: Run `pm2 logs musclemania-scanner` to check Python/SPI errors (Pi only).
- **MongoDB not starting**: On Pi, run `sudo systemctl status mongod`. On dev machines, ensure MongoDB is running via Docker, local install, or Atlas.
- **NVM packages lost after reboot**: The startup script now sources NVM automatically. If Node.js is still not found, verify NVM is installed at `~/.nvm` or switch to system Node.js: `sudo apt install nodejs npm`.
- **"Could not navigate to project root" error**: The script uses dynamic path detection. Ensure it's run from the MuscleMania project folder or that the script is in `scripts/` subdirectory.
