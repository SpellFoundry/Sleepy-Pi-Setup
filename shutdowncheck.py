#!/usr/bin/python

import RPi.GPIO as GPIO
import os

GPIO.setmode(GPIO.BCM)
GPIO.setup(24, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
GPIO.setup(25, GPIO.OUT)
GPIO.output(25, GPIO.HIGH)
print ("[Info] Telling Sleepy Pi we are running pin 25")

try:
    GPIO.wait_for_edge(24, GPIO.RISING)
    print ("Sleepy Pi requesting shutdown on pin 24")
    os.system("sudo shutdown -h now")
except KeyboardInterrupt:
    pass       
GPIO.cleanup()
