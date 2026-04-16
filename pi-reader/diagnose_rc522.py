#!/usr/bin/env python3
"""
RC522 Diagnostic Tool — Identify GPIO and SPI issues on Raspberry Pi
Helps debug: pin conflicts, SPI enablement, GPIO availability
"""

import os
import subprocess
import sys

def check_spi():
    """Check if SPI1 is enabled"""
    print("\n[1] Checking SPI1 enablement...")
    if os.path.exists('/dev/spidev1.0'):
        print("    ✓ /dev/spidev1.0 exists — SPI1 is enabled")
        return True
    else:
        print("    ✗ /dev/spidev1.0 NOT found — SPI1 may not be enabled")
        print("    → Add 'dtoverlay=spi1-3cs' to /boot/config.txt and reboot")
        return False

def check_gpio_available():
    """Test GPIO 25 availability"""
    print("\n[2] Testing GPIO 25 availability...")
    try:
        import RPi.GPIO as GPIO
        GPIO.setmode(GPIO.BCM)
        try:
            GPIO.setup(25, GPIO.OUT)
            print("    ✓ GPIO 25 is available and can be set to OUTPUT")
            GPIO.cleanup()
            return True
        except ValueError as e:
            print(f"    ✗ GPIO 25 setup failed: {e}")
            print("    → The pin may be in use, reserved, or invalid")
            GPIO.cleanup()
            return False
    except ImportError:
        print("    ✗ RPi.GPIO not installed")
        print("    → Install with: pip install RPi.GPIO")
        return False

def check_mfrc522_lib():
    """Check if MFRC522 library is installed"""
    print("\n[3] Checking MFRC522 library...")
    try:
        from mfrc522 import MFRC522
        print("    ✓ mfrc522 library is installed")
        return True
    except ImportError:
        print("    ✗ mfrc522 library not found")
        print("    → Install with: pip install mfrc522")
        return False

def test_mfrc522_init():
    """Test MFRC522 initialization"""
    print("\n[4] Testing MFRC522 initialization...")
    try:
        from mfrc522 import MFRC522
        try:
            reader = MFRC522(bus=1, device=0, pin_rst=25)
            print("    ✓ MFRC522 initialized successfully on SPI1 with RST=GPIO25")
            return True
        except ValueError as e:
            print(f"    ✗ MFRC522 init failed: {e}")
            print("\n    Troubleshooting:")
            print("    - If error mentions 'invalid channel', GPIO 25 may be in use")
            print("    - Try different RST pin numbers (23, 24, 27)")
            print("    - Verify RC522 is wired to the correct pins")
            return False
        except Exception as e:
            print(f"    ✗ Unexpected error: {e}")
            return False
    except ImportError:
        print("    ✗ mfrc522 not installed")
        return False

def check_pin_usage():
    """Check GPIO pin assignments"""
    print("\n[5] Checking GPIO pin assignments...")
    print("    Expected wiring for RC522 on SPI1:")
    print("    - RST  → GPIO 25 (Pin 22)")
    print("    - SDA/CS → GPIO 18 (Pin 12) — hardware managed")
    print("    - SCK  → GPIO 21 (Pin 40)")
    print("    - MOSI → GPIO 20 (Pin 38)")
    print("    - MISO → GPIO 19 (Pin 35)")
    print("\n    If RST is wired to a different pin, update:")
    print("    PIN_RST = <your_gpio_number>")
    print("    in pi-reader/scanner.py line ~30")

def main():
    print("=" * 60)
    print("  MuscleMania RC522 Diagnostic Tool")
    print("=" * 60)
    
    results = {
        "SPI1": check_spi(),
        "GPIO 25": check_gpio_available(),
        "MFRC522 lib": check_mfrc522_lib(),
    }
    
    if all(results.values()):
        print("\n[4] Testing MFRC522 initialization...")
        results["MFRC522 init"] = test_mfrc522_init()
    else:
        check_pin_usage()
    
    print("\n" + "=" * 60)
    print("  Summary")
    print("=" * 60)
    
    for check, passed in results.items():
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"  {status}: {check}")
    
    if all(results.values()):
        print("\n  All checks passed! RC522 should work.")
    else:
        print("\n  Some checks failed. Fix the issues above and try again.")
    
    print("=" * 60)

if __name__ == "__main__":
    main()
