# RC522 RFID Reader Setup Guide

## Quick Diagnostics

If `scanner.py` fails with GPIO errors, run:

```bash
cd ~/MuscleMania/reader
python3 diagnose_rc522.py
```

This checks:
- ✅ SPI0/SPI1 enabled in `/boot/firmware/config.txt`
- ✅ SPI devices available (`/dev/spidev0.0`, etc.)
- ✅ GPIO pins available (especially GPIO 25 for RST)
- ✅ Python libraries installed
- ✅ RC522 module accessible via SPI

---

## Default Wiring (RC522 → Raspberry Pi GPIO)

```
┌─────────────────────────────────────────┐
│ RC522 RFID Module Pinout                │
├─────────────────────────────────────────┤
│ Pin Name  │ GPIO  │ Board Pin │ Purpose │
├───────────┼───────┼───────────┼─────────┤
│ SDA (CS)  │ GPIO8 │ Pin 24    │ Chip Select (SPI0)
│ SCK (CLK) │ GPIO11│ Pin 23    │ SPI Clock
│ MOSI (DIN)│ GPIO10│ Pin 19    │ SPI Data Out
│ MISO(DOUT)│ GPIO9 │ Pin 21    │ SPI Data In
│ RST       │ GPIO25│ Pin 22    │ Reset (configurable)
│ GND       │ GND   │ Pin 6,9   │ Ground
│ 3.3V      │ 3.3V  │ Pin 1,17  │ Power (3.3V only!)
└─────────────────────────────────────────┘
```

---

## Common Errors & Fixes

### Error: `GPIO pin 25 initialization failed`

**Cause:** GPIO 25 is already in use or not available

**Fix 1: Use a different RST pin**
Edit `scanner.py`:
```python
PIN_RST = 24  # Try 24, 23, 27, or another available pin
```

**Fix 2: Kill process using GPIO 25**
```bash
ps aux | grep python
# Kill any hanging Python/PM2 processes
sudo pkill -f python
pm2 stop all
```

---

### Error: `The channel sent is invalid on a Raspberry Pi`

**Cause:** SPI0 not enabled in `/boot/firmware/config.txt`

**Fix:**
```bash
sudo nano /boot/firmware/config.txt
```

Add or uncomment:
```
dtparam=spi=on
```

Save (Ctrl+X, Y, Enter), then reboot:
```bash
sudo reboot
```

Verify SPI enabled:
```bash
ls -la /dev/spidev*
# Should see: /dev/spidev0.0, /dev/spidev0.1
```

---

### Error: `No module named 'mfrc522'`

**Fix:**
```bash
pip3 install mfrc522 RPi.GPIO spidev
```

---

### RC522 Not Responding (SPI reads fail)

**Check 1: Wiring**
- Verify all pins match the diagram above
- Check 3.3V power (NOT 5V - will destroy RC522)
- Verify ground connections

**Check 2: SPI Bus**
If using SPI1 instead of SPI0, update `scanner.py`:
```python
reader = MFRC522(bus=1, device=0, pin_rst=PIN_RST)
```

And ensure `/boot/firmware/config.txt` has:
```
dtoverlay=spi1-3cs
```

---

## Verify Setup

After fixing, test:

```bash
cd ~/MuscleMania/reader

# 1. Run diagnostics again
python3 diagnose_rc522.py

# 2. Start scanner
python3 scanner.py

# 3. Tap an RFID card - should log: [INFO] Card UID: <card_id>
```

---

## Integration with Systemd

Once scanner works manually, it will auto-start via systemd:

```bash
# Check PM2 is running both backend and scanner
pm2 list

# Check logs
pm2 logs musclemania-scanner

# If scanner crashes, restart via PM2
pm2 restart musclemania-scanner
```

---

## Troubleshooting Checklist

- [ ] `diagnose_rc522.py` shows ✓ for all checks
- [ ] `/dev/spidev0.0` exists
- [ ] GPIO 25 (or custom RST pin) is available
- [ ] 3.3V power (not 5V) connected to RC522
- [ ] GND connected to both RC522 and Pi
- [ ] All SPI pins wired correctly
- [ ] `python3 scanner.py` starts without GPIO errors
- [ ] Tapping RFID card shows `[INFO] Card UID: <id>` in logs
- [ ] `pm2 list` shows musclemania-scanner running

---

## Reference

- **RC522 Datasheet:** https://datasheetspdf.com/pdf-file/1308714/NXP/RC522/1
- **Raspberry Pi GPIO Pinout:** https://pinout.xyz/
- **mfrc522-py Library:** https://github.com/mxgxw/MFRC522-python
