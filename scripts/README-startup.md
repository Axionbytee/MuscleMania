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

```bash
bash ~/MuscleMania/scripts/start-musclemania.sh
```

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
- **Scanner not starting**: Run `pm2 logs musclemania-scanner` to check Python/SPI errors.
- **MongoDB not starting**: Run `sudo systemctl status mongod` to check status.
