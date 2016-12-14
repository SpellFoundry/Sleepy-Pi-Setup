#!/usr/bin/python

import RPi.GPIO as GPIO
import os, time

GPIO.setmode(GPIO.BCM)
GPIO.setup(24, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
GPIO.setup(25, GPIO.OUT)
GPIO.output(25, GPIO.HIGH)
print ("[Info] Telling Sleepy Pi we are running pin 25")

try:
    GPIO.wait_for_edge(24, GPIO.RISING)
    print "Rising edge detected on port 24. Here endeth the third lesson."
    os.system("sudo shutdown -h now")
except KeyboardInterrupt:
    pass       
GPIO.cleanup() # clean up GPIO on exit 
