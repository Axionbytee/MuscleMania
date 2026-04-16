#!/usr/bin/env python3
"""
MuscleMania — RFID Scanner for Raspberry Pi
Hardware: RC522 on SPI1 (/dev/spidev1.0)
  SDA  → Board Pin 12 (GPIO18) — SPI1 CE0 (hardware chip-select, kernel-managed)
  SCK  → Board Pin 40 (GPIO21) — SPI1 SCLK
  MOSI → Board Pin 38 (GPIO20) — SPI1 MOSI
  MISO → Board Pin 35 (GPIO19) — SPI1 MISO
  RST  → Board Pin 22 (GPIO25) — connect RC522 RST here; change PIN_RST if wired elsewhere
"""

import os
import sys
import json
import time
import requests

# Detect if running on Raspberry Pi
IS_PI = os.path.exists('/sys/firmware/devicetree/base/model')

if IS_PI:
    try:
        from mfrc522 import MFRC522
        import RPi.GPIO as GPIO
    except ImportError as e:
        print(f"[ERROR] Pi hardware libraries not found: {e}")
        print("[ERROR] Install with: pip install mfrc522 RPi.GPIO")
        sys.exit(1)
    
    # ── SPI1 Configuration ───────────────────────────────────────────────────────
    # bus=1, device=0 → /dev/spidev1.0
    # pin_ce=0  → use hardware SPI1 CE0 (Board Pin 12 / GPIO18) via spidev; no GPIO needed
    # pin_rst   → RC522 RST line; adjust PIN_RST if wired to a different GPIO
    PIN_RST = 25
    
    try:
        reader = MFRC522(bus=1, device=0, pin_rst=PIN_RST)
        print("[INFO] MFRC522 initialized on SPI1")
    except ValueError as e:
        print(f"[ERROR] Failed to initialize MFRC522: {e}")
        print("[ERROR] Check RC522 wiring and pin_rst value")
        sys.exit(1)
else:
    print("[WARNING] Not running on Raspberry Pi — scanner will be simulated")
    print("[INFO] This is normal for dev machines. Real scanning only works on Pi hardware.")
    reader = None
# ─────────────────────────────────────────────────────────────────────────────

BACKEND_URL = "http://localhost:3000/api/scan"
OFFLINE_QUEUE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "offline_queue.json")
COOLDOWN_SECONDS = 3

last_uid = None
last_scan_time = 0


def uid_to_str(uid_bytes):
    """Convert MFRC522 UID byte array to a consistent decimal string.
    Replicates SimpleMFRC522.uid_to_num() so card UIDs stay consistent with DB."""
    n = 0
    for i in range(0, 5):
        n = n * 256 + uid_bytes[i]
    return str(n)


def read_card():
    """Poll for a card using the low-level MFRC522 API.
    Returns a UID string or None if no card is in range.
    On dev machines (no Pi hardware), returns None."""
    if reader is None:
        # Dev machine — no hardware to read from
        return None
    
    (status, _tag_type) = reader.MFRC522_Request(reader.PICC_REQIDL)
    if status != reader.MI_OK:
        return None

    (status, uid) = reader.MFRC522_Anticoll()
    if status != reader.MI_OK:
        return None

    reader.MFRC522_SelectTag(uid)
    reader.MFRC522_StopCrypto1()
    return uid_to_str(uid)


def send_scan(uid_str):
    """Send a scanned UID to the backend API."""
    try:
        response = requests.post(
            BACKEND_URL,
            json={"uid": uid_str},
            timeout=5
        )
        data = response.json()
        status = data.get("status", "UNKNOWN")
        member = data.get("member")
        name = member.get("fullName", "—") if member else "Unregistered"
        print(f"  [RESULT] {status} — {name}")
        return True
    except requests.exceptions.RequestException as e:
        print(f"  [OFFLINE] Backend unreachable: {e}")
        return False


def queue_offline(uid_str):
    """Save a scan to the offline queue file when the backend is unreachable."""
    queue = []
    if os.path.exists(OFFLINE_QUEUE):
        try:
            with open(OFFLINE_QUEUE, "r") as f:
                queue = json.load(f)
        except (json.JSONDecodeError, IOError):
            queue = []

    queue.append({
        "uid": uid_str,
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S")
    })

    with open(OFFLINE_QUEUE, "w") as f:
        json.dump(queue, f, indent=2)

    print(f"  [QUEUED] Saved to offline queue ({len(queue)} pending)")


def flush_offline_queue():
    """Attempt to send all queued offline scans to the backend."""
    if not os.path.exists(OFFLINE_QUEUE):
        return

    try:
        with open(OFFLINE_QUEUE, "r") as f:
            queue = json.load(f)
    except (json.JSONDecodeError, IOError):
        return

    if not queue:
        return

    print(f"[FLUSH] Attempting to send {len(queue)} queued scan(s)...")
    remaining = []

    for entry in queue:
        success = send_scan(entry["uid"])
        if not success:
            remaining.append(entry)
            print("  [FLUSH] Backend still unreachable, keeping remaining in queue")
            remaining.extend(queue[queue.index(entry) + 1:])
            break

    if remaining:
        with open(OFFLINE_QUEUE, "w") as f:
            json.dump(remaining, f, indent=2)
    else:
        os.remove(OFFLINE_QUEUE)
        print("[FLUSH] Offline queue cleared!")


try:
    print("=" * 50)
    print("  MuscleMania RFID Scanner")
    print("  Backend:", BACKEND_URL)
    print("=" * 50)

    # Attempt to flush offline queue on startup
    flush_offline_queue()

    print("[READY] Waiting for RFID scans...\n")

    while True:
        uid_str = read_card()
        if uid_str is None:
            time.sleep(0.1)
            continue
        current_time = time.time()

        # Cooldown check — prevent double-tap of the same card
        if uid_str == last_uid and (current_time - last_scan_time) < COOLDOWN_SECONDS:
            continue

        last_uid = uid_str
        last_scan_time = current_time

        print(f"[SCAN] UID: {uid_str}")

        success = send_scan(uid_str)
        if not success:
            queue_offline(uid_str)

        print()

except KeyboardInterrupt:
    print("\n[EXIT] Cleaning up GPIO...")
    GPIO.cleanup()
    print("[EXIT] Scanner stopped.")
