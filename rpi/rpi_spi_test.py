#!/usr/bin/python3

# Raspbery Pi SPI Master Code
# Board Pin 36 is used as an Active Low FPGA Logic Reset
# RPi CE0 is used for the FPGA User SPI Slave Chip Select

import time
import spidev
import RPi.GPIO as GPIO

RESET_PIN = 36
BUS_ID = 0
DEVICE_ID = 0

# Reset is on board pin 36
GPIO.setmode(GPIO.BOARD)
GPIO.setup(RESET_PIN, GPIO.OUT)

# Enable SPI
spi = spidev.SpiDev()
spi.open(BUS_ID, DEVICE_ID)

# Set SPI speed and mode
spi.max_speed_hz = 100000
spi.mode = 0

while (1):
    print ("\nReset FPGA Fabric Logic")
    GPIO.output(RESET_PIN, 0)
    time.sleep(1)
    GPIO.output(RESET_PIN, 1)
    time.sleep(2)

    print ("Issue Hardware Protocol Command, 3 Bytes")
    msg = [0xF0, 0x00, 0x00]
    retval = spi.xfer2(msg)
    print (retval)
    time.sleep(1)

    print ("Issue Zero Command, 3+ Bytes")
    msg = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    retval = spi.xfer2(msg)
    print (retval)
    time.sleep(1)

spi.close()
exit()
