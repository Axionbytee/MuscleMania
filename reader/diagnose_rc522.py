#!/usr/bin/env python3

"""
MFRC522 Wiring Diagnostic Tool
Helps identify GPIO pin configuration and hardware issues
"""

import os
import sys
import subprocess
import RPi.GPIO as GPIO

def check_spi_enabled():
    """Check if SPI is enabled"""
    print("\n[1] Checking SPI Configuration...")
    try:
        with open('/boot/firmware/config.txt', 'r') as f:
            config = f.read()
        
        spi0_enabled = 'dtparam=spi=on' in config
        spi1_enabled = 'dtoverlay=spi1-3cs' in config
        
        print(f"    SPI0 enabled: {'✓' if spi0_enabled else '✗'}")
        print(f"    SPI1 overlay: {'✓' if spi1_enabled else '✗'}")
        
        if not spi0_enabled:
            print("    [FIX] Add to /boot/firmware/config.txt: dtparam=spi=on")
        if not spi1_enabled:
            print("    [FIX] Add to /boot/firmware/config.txt: dtoverlay=spi1-3cs")
            
        return spi0_enabled
    except Exception as e:
        print(f"    [ERROR] Could not read config.txt: {e}")
        return False

def check_spi_devices():
    """Check if SPI devices exist"""
    print("\n[2] Checking SPI Devices...")
    devices = ['/dev/spidev0.0', '/dev/spidev0.1', '/dev/spidev1.0', '/dev/spidev1.1']
    
    for device in devices:
        if os.path.exists(device):
            print(f"    {device}: ✓ Found")
        else:
            print(f"    {device}: ✗ Missing")

def check_gpio_pins():
    """Check GPIO pin status"""
    print("\n[3] Checking GPIO Pin Configuration...")
    print("    Default MFRC522 pins (update scanner.py if different):")
    
    pins = {
        'MOSI': 10,   # GPIO 10 (SPI0)
        'MISO': 9,    # GPIO 9  (SPI0)
        'CLK': 11,    # GPIO 11 (SPI0)
        'CS': 8,      # GPIO 8  (SPI0) - Chip Select
        'RST': 25,    # GPIO 25 - Reset pin (can change)
        'IRQ': None,  # Optional interrupt
    }
    
    print("\n    Pin Layout:")
    for name, gpio in pins.items():
        if gpio is not None:
            print(f"      {name:6s} = GPIO {gpio}")
        else:
            print(f"      {name:6s} = Not used (optional)")
    
    print("\n    [INFO] If pins don't match your wiring, update in scanner.py:")
    print("      PIN_RST = <your_reset_pin_number>")
    print("      PIN_IRQ = <your_irq_pin_number>  # if using IRQ")

def check_gpio_conflicts():
    """Check if GPIO pins are already in use"""
    print("\n[4] Checking GPIO Pin Usage...")
    
    GPIO.setmode(GPIO.BCM)
    
    # Try to check if pins are in use
    pins_to_check = [25, 24, 23, 27]  # Common pins
    
    for pin in pins_to_check:
        try:
            # Try to set as input to check if available
            GPIO.setup(pin, GPIO.IN)
            GPIO.cleanup(pin)
            print(f"    GPIO {pin}: ✓ Available")
        except RuntimeError as e:
            print(f"    GPIO {pin}: ✗ In use - {str(e)}")
        except Exception as e:
            print(f"    GPIO {pin}: ? Error - {str(e)}")

def check_python_libraries():
    """Check if required Python libraries are installed"""
    print("\n[5] Checking Python Libraries...")
    
    libraries = ['mfrc522', 'RPi.GPIO', 'spidev', 'requests']
    
    for lib in libraries:
        try:
            __import__(lib)
            print(f"    {lib}: ✓ Installed")
        except ImportError:
            print(f"    {lib}: ✗ Missing")
            print(f"          [FIX] pip3 install {lib}")

def check_rfid_module():
    """Check if RC522 is accessible via SPI"""
    print("\n[6] Checking RC522 Module Access...")
    
    try:
        import spidev
        
        spi = spidev.SpiDev()
        
        # Try to open SPI0
        try:
            spi.open(0, 0)
            print(f"    SPI0.0: ✓ Accessible")
            
            # Try to read a byte
            response = spi.readbytes(1)
            print(f"    SPI0.0 read test: ✓ Successful")
            spi.close()
        except Exception as e:
            print(f"    SPI0.0: ✗ {str(e)}")
        
        # Try SPI1 if available
        try:
            spi.open(1, 0)
            print(f"    SPI1.0: ✓ Accessible")
            spi.close()
        except:
            print(f"    SPI1.0: ✗ Not available (needs dtoverlay=spi1-3cs)")
            
    except ImportError:
        print(f"    spidev: ✗ Not installed")
        print(f"          [FIX] pip3 install spidev")
    except Exception as e:
        print(f"    Error: {str(e)}")

def main():
    print("╔════════════════════════════════════════════════════════════╗")
    print("║  MFRC522 RC522 Wiring & Configuration Diagnostic Tool    ║")
    print("╚════════════════════════════════════════════════════════════╝")
    
    if os.geteuid() != 0:
        print("\n⚠️  Running as user. Some checks may require sudo.")
        print("For full diagnostics, run: sudo python3 diagnose_rc522.py\n")
    
    # Run all checks
    check_spi_enabled()
    check_spi_devices()
    check_gpio_pins()
    check_gpio_conflicts()
    check_python_libraries()
    check_rfid_module()
    
    print("\n╔════════════════════════════════════════════════════════════╗")
    print("║  Troubleshooting Steps                                     ║")
    print("╚════════════════════════════════════════════════════════════╝")
    print("""
1. [SPI not enabled?]
   Add to /boot/firmware/config.txt:
     dtparam=spi=on
   Then reboot: sudo reboot

2. [GPIO 25 in use?]
   Check which process is using it:
     ps aux | grep python
   Or try a different RST pin in scanner.py:
     PIN_RST = 24  # or 23, 27, etc.

3. [Wiring mismatch?]
   Verify your RC522 connections match scanner.py:
     MOSI (DIN)   = GPIO 10 (SPI0)
     MISO (DOUT)  = GPIO 9  (SPI0)
     CLK (SCK)    = GPIO 11 (SPI0)
     CS (SDA)     = GPIO 8  (SPI0)
     RST          = GPIO 25 (or your pin)
     GND          = Ground
     3.3V         = 3.3V power

4. [Different SPI bus?]
   If using SPI1, update scanner.py:
     MFRC522(bus=1, device=0)

5. [Still failing?]
   Check /boot/firmware/config.txt:
     sudo cat /boot/firmware/config.txt | grep -E 'spi|i2c'
   Verify pins are wired correctly with a multimeter
   Test with: python3 scanner.py
""")

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n[INFO] Diagnostic cancelled")
    except Exception as e:
        print(f"\n[ERROR] Diagnostic failed: {e}")
        sys.exit(1)
    finally:
        try:
            GPIO.cleanup()
        except:
            pass
