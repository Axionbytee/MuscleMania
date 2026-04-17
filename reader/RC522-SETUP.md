# RC522 RFID Reader Setup for Raspberry Pi

## Hardware Wiring

Connect RC522 to Raspberry Pi SPI1:

```
RC522 Pin → RPi Physical Pin → GPIO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SDA/CS   → Pin 12            → GPIO18 (hardware managed)
SCK      → Pin 40            → GPIO21
MOSI     → Pin 38            → GPIO20
MISO     → Pin 35            → GPIO19
RST      → Pin 16            → GPIO23 (default to avoid LCD conflicts)
GND      → Pin 6/9/14/20/25/30/34/39
VCC      → Pin 2/4/17/40     (3.3V)
```

**Note on RST pin:** The default is now **GPIO 23 (Pin 16)** to avoid conflicts with common LCD overlays (like Waveshare 3.5"). If you wired RST to **Pin 22 (GPIO 25)** and have a Waveshare LCD, update the scanner code below.

**Use a breadboard or solder carefully.** Triple-check your wiring before powering on.

---

## Software Setup

### 1. Enable SPI1 overlay

```bash
sudo nano /boot/firmware/config.txt
```

Add this line (if not already present):
```
dtoverlay=spi1-3cs
```

Save and exit: `Ctrl+O`, `Enter`, `Ctrl+X`

Reboot:
```bash
sudo reboot
```

Verify SPI1 is available:
```bash
ls -la /dev/spidev1.0
# Should show: crw-rw---- 1 root spi 153, 0 Apr 16 12:34 /dev/spidev1.0
```

### 2. Install dependencies

```bash
pip install mfrc522 RPi.GPIO requests
```

### 3. Test RC522 connection

Run the diagnostic tool:
```bash
cd ~/MuscleMania/reader
python3 diagnose_rc522.py
```

Expected output:
```
[1] Checking SPI1 enablement...
    ✓ /dev/spidev1.0 exists — SPI1 is enabled

[2] Testing GPIO 25 availability...
    ✓ GPIO 25 is available and can be set to OUTPUT

[3] Checking MFRC522 library...
    ✓ mfrc522 library is installed

[4] Testing MFRC522 initialization...
    ✓ MFRC522 initialized successfully on SPI1 with RST=GPIO25

All checks passed! RC522 should work.
```

### 4. If diagnostic fails

- **SPI1 not enabled**: Add `dtoverlay=spi1-3cs` to `/boot/firmware/config.txt`, reboot
- **GPIO 25 unavailable**: Your RC522 RST is wired to a different pin. Find which GPIO, then edit `pin-reader/scanner.py` line ~30:
  ```python
  PIN_RST = <your_gpio_number>  # Change 25 to your pin's GPIO number
  ```
- **MFRC522 lib missing**: Run `pip install mfrc522`

---

## Running the Scanner

```bash
cd ~/MuscleMania/reader
python3 scanner.py
```

Expected output:
```
==================================================
  MuscleMania RFID Scanner
  Backend: http://localhost:3000/api/scan
==================================================
[READY] Waiting for RFID scans...
```

Scan an RFID card. You should see:
```
[SCAN] Card detected: 1234567890
[RESULT] ACTIVE — John Doe
```

---

## Via PM2 (Startup Script)

The scanner is managed by PM2 along with the backend:

```bash
pm2 start ecosystem.config.js
pm2 logs musclemania-scanner
```

Check logs:
```bash
pm2 logs musclemania-scanner
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `GPIO: The channel sent is invalid` | RC522 RST wired to wrong pin. Run `diagnose_rc522.py` |
| `No such file or directory: '/dev/spidev1.0'` | SPI1 not enabled. Add `dtoverlay=spi1-3cs` to `/boot/firmware/config.txt`, reboot |
| No cards detected when scanning | Check wiring, especially MISO/MOSI. Verify RC522 is powered (check red LED) |
| Backend gets `UNKNOWN` status | Card UID not registered. Go to admin dashboard and add member |

---

## Pin Reference (if using different RST pin)

Common GPIO alternatives for RST:
- **GPIO 23** (Pin 16) — **DEFAULT** (best for Waveshare LCD users)
- GPIO 24 (Pin 18)
- GPIO 25 (Pin 22) — may conflict with Waveshare LCD
- GPIO 27 (Pin 13)
- GPIO 17 (Pin 11)

**If you wired RC522 RST to a different physical pin**, edit `reader/scanner.py`:
```python
PIN_RST = 23  # Change to your GPIO number
```

To find which pins are safe on your system, check `/boot/firmware/config.txt`:
```bash
cat /boot/firmware/config.txt | grep dtoverlay
```

Then map the used GPIO numbers and pick a free one from the alternatives above.
