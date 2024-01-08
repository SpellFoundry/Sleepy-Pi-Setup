#!/bin/bash

# SleepyPi Power Bypass Software Jumper Control Helper Script (requires i2ctools)
# Written by Alastair Cota

case $1 in
"on")
	echo "[INFO]: Enabling Power Bypass Software Jumper..."
	sudo i2cset -y 1 0x24 0xFD
;;
"off")
	echo "[INFO]: Disabling Power Bypass Software Jumper..."
	sudo i2cset -y 1 0x24 0xFF
;;
*)
  echo "SleepyPi Power Bypass Software Jumper Control Script"
	echo "Usage: softjump.sh <on|off>"
	exit 1
;;
esac

exit 0
