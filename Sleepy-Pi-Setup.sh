#!/bin/bash

# trap "set +x; sleep 5; set -x" DEBUG

# Check whether we are running sudo
if [[ $EUID -ne 0 ]]; then
  	echo "This script must be run as root" 1>&2
  	exit 1
fi

# check if it is Jessie
osInfo=$(cat /etc/os-release)
if [[ $osInfo == *"jessie"* ]]; then
    Jessie=true
else
    echo "This script only works on Jessie at this time"
    exit 1
fi

echo '================================================================================ '
echo '|                                                                               |'
echo '|                   Sleepy Pi Installation Script - Jessie                      |'
echo '|                                                                               |'
echo '================================================================================ '

##Update and upgrade
#sudo apt-get update && sudo apt-get upgrade -y

## Start Installation
echo 'Do you want to setup for a RPi 3 (Y) or Non-RPi 3 (n) ? (Y/n) '
read RpiInput
if [ "$RpiInput" == "Y" ]; then
    echo "RPi 3 selected..."
    RPi3=true
else
    echo "Non-Rpi 3 (other Rpi) selected..."
    RPi3=false
fi

echo 'Begin Installation ? (Y/n) '
read ReadyInput
if [ "$ReadyInput" == "Y" ]; then
    echo "Beginning installation..."
else
    echo "Aborting installation"
    exit 0
fi

##-------------------------------------------------------------------------------------------------
##-------------------------------------------------------------------------------------------------
## Test Area
# echo every line 
set +x

# exit 0
## End Test Area

##-------------------------------------------------------------------------------------------------
##-------------------------------------------------------------------------------------------------

## Install Arduino
echo 'Installing Arduino IDE...'
program="arduino"
condition=$(which $program 2>/dev/null | grep -v "not found" | wc -l)
if [ $condition -eq 0 ] ; then
    apt-get install arduino
    # create the default sketchbook and libraries that the IDE would normally create on first run
    mkdir /home/pi/sketchbook
    mkdir /home/pi/sketchbook/libraries
else
    echo "Arduino IDE is already installed - skipping"
fi

##-------------------------------------------------------------------------------------------------

## Enable Serial Port
# Findme look at using sed to toggle it
echo 'Enable Serial Port...'
#echo "enable_uart=1" | sudo tee -a /boot/config.txt
if grep -q 'enable_uart=1' /boot/config.txt; then
    echo 'enable_uart=1 is already set - skipping'
else
    echo 'enable_uart=1' | sudo tee -a /boot/config.txt
fi
if [ $RPi3 != true ]; then
    if grep -q 'core_freq=400' /boot/config.txt; then
        echo 'The frequency of GPU processor core is set to 400MHz already - skipping'
    else
        echo 'core_freq=400' | sudo tee -a /boot/config.txt
        fi
    else
        if grep -q 'core_freq=250' /boot/config.txt; then
            echo 'The frequency of GPU processor core is set to 250MHz already - skipping'
        else
            echo 'core_freq=250' | sudo tee -a /boot/config.txt
            fi
        fi


## Disable Serial login
echo 'Disabling Serial Login...'
if [ $RPi3 != true ]; then
    # Non-RPi3
    systemctl stop serial-getty@ttyAMA0.service
    systemctl disable serial-getty@ttyAMA0.service
else
    # Rpi 3
    systemctl stop serial-getty@ttyS0.service
    systemctl disable serial-getty@ttyS0.service
fi

## Disable Boot info
echo 'Disabling Boot info...'
#sudo sed -i'bk' -e's/console=ttyAMA0,115200.//' -e's/kgdboc=tty.*00.//'  /boot/cmdline.txt
sed -i'bk' -e's/console=serial0,115200.//'  /boot/cmdline.txt

## Link the Serial Port to the Arduino IDE
echo 'Link Serial Port to Arduino IDE...'
if [ $RPi3 != true ]; then
    # Anything other than Rpi 3
    wget https://raw.githubusercontent.com/SpellFoundry/Sleepy-Pi-Setup/master/80-sleepypi.rules
    mv /home/pi/80-sleepypi.rules /etc/udev/rules.d/
fi
# Note: On Rpi3 GPIO serial port defaults to ttyS0 which is what we want

##-------------------------------------------------------------------------------------------------

## Setup the Reset Pin
echo 'Setup the Reset Pin...'
program="autoreset"
condition=$(which $program 2>/dev/null | grep -v "not found" | wc -l)
if [ $condition -eq 0 ]; then
    wget https://github.com/spellfoundry/avrdude-rpi/archive/master.zip
    unzip master.zip
    cd ./avrdude-rpi-master/
    cp autoreset /usr/bin
    cp avrdude-autoreset /usr/bin
    mv /usr/bin/avrdude /usr/bin/avrdude-original
    cd /home/pi
    rm -f /home/pi/master.zip
    rm -R -f /home/pi/avrdude-rpi-master
    ln -s /usr/bin/avrdude-autoreset /usr/bin/avrdude
else
    echo "$program is already installed - skipping..."
fi

##-------------------------------------------------------------------------------------------------

## Getting Sleepy Pi to shutdown the Raspberry Pi
echo 'Setting up the shutdown...'
cd ~
if grep -q 'shutdowncheck.py' /etc/rc.local; then
    echo 'shutdowncheck.py is already setup - skipping...'
else
    [ ! -d /home/pi/bin  ] && mkdir /home/pi/bin
    [ ! -d /home/pi/bin/SleepyPi  ] && mkdir /home/pi/bin/SleepyPi
    wget https://raw.githubusercontent.com/SpellFoundry/Sleepy-Pi-Setup/master/shutdowncheck.py
    mv -f shutdowncheck.py /home/pi/bin/SleepyPi
    sed -i '/exit 0/i python /home/pi/bin/SleepyPi/shutdowncheck.py &' /etc/rc.local
    # echo "python /home/pi/bin/SleepyPi/shutdowncheck.py &" | sudo tee -a /etc/rc.local
fi

##-------------------------------------------------------------------------------------------------

## Adding the Sleepy Pi to the Arduino environment
echo 'Adding the Sleepy Pi to the Arduino environment...'
# ...setup sketchbook
if [ -d "/home/pi/sketchbook" ]
then
    echo "sketchbook exists - skipping..."
else
    mkdir /home/pi/sketchbook
fi
# ...setup sketchbook/libraries
if [ -d "/home/pi/sketchbook/libraries" ]
then
    echo "sketchbook/libraries exists - skipping..."
else
    mkdir /home/pi/sketchbook/libraries
fi
# .../sketchbook/hardware
if [ -d "/home/pi/sketchbook/hardware" ]; then
    echo "sketchbook/hardware exists - skipping..."
else
    mkdir /home/pi/sketchbook/hardware 
fi
# .../sketchbook/hardware/sleepy_pi2
if [ -d "/home/pi/sketchbook/hardware/sleepy_pi2" ]; then
    echo "sketchbook/hardware/sleepy_pi2 exists - skipping..."
else
    mkdir /home/pi/sketchbook/hardware/sleepy_pi2
    wget https://raw.githubusercontent.com/SpellFoundry/Sleepy-Pi-Setup/master/boards.txt
    mv boards.txt /home/pi/sketchbook/hardware/sleepy_pi2
fi

# .../sketchbook/hardware/sleepy_pi
if [ -d "/home/pi/sketchbook/hardware/sleepy_pi" ]; then
    echo "sketchbook/hardware/sleepy_pi exists - skipping..."
else
    mkdir /home/pi/sketchbook/hardware/sleepy_pi
    wget https://raw.githubusercontent.com/SpellFoundry/Sleepy-Pi-Setup/master/boards.txt
    mv boards.txt /home/pi/sketchbook/hardware/sleepy_pi
fi

## Setup the Sleepy Pi Libraries
echo 'Setting up the Sleepy Pi Libraries...'
cd /home/pi/sketchbook/libraries/
if [ -d "/home/pi/sketchbook/libraries/sleepy_pi2" ]; then
    echo "sleepy_pi2 Library exists - skipping..."
    # could do a git pull here?
else
    echo "Installing SleepyPi 2 Library..."
    git clone https://github.com/SpellFoundry/SleepyPi2.git
fi
if [ -d "/home/pi/sketchbook/libraries/sleepy_pi" ]; then
    echo "sleepy_pi Library exists - skipping..."
    # could do a git pull here?
else
    echo "Installing SleepyPi Library..."
    git clone https://github.com/SpellFoundry/SleepyPi.git
fi

if [ -d "/home/pi/sketchbook/libraries/Time" ]; then
    echo "Time Library exists - skipping..."
else
    echo "Installing Time Library..."
    git clone https://github.com/PaulStoffregen/Time.git
fi

if [ -d "/home/pi/sketchbook/libraries/LowPower" ]; then
    echo "LowPower Library exists - skipping..."
else
    echo "Installing LowPower Library..."
    git clone https://github.com/rocketscream/Low-Power.git
    # rename the directory as Arduino doesn't like the dash
    mv /home/pi/sketchbook/libraries/Low-Power /home/pi/sketchbook/libraries/LowPower
fi


 # Sleepy Pi 1
if [ -d "/home/pi/sketchbook/libraries/DS1374RTC" ]; then
    echo "DS1374RTC Library exists - skipping..."
else
    echo "Installing DS1374RTC Library..."
    git clone https://github.com/SpellFoundry/DS1374RTC.git
fi

# Sleepy Pi 2
if [ -d "/home/pi/sketchbook/libraries/PCF8523" ]; then
    echo "PCF8523 Library exists - skipping..."
else
    echo "Installing PCF8523 Library..."
    git clone https://github.com/SpellFoundry/PCF8523.git
fi


if [ -d "/home/pi/sketchbook/libraries/PinChangeInt" ]; then
    echo "PinChangeInt Library exists - skipping..."
else
    echo "Installing PinChangeInt Library..."
    git clone https://github.com/GreyGnome/PinChangeInt.git
fi
cd ~


##-------------------------------------------------------------------------------------------------

# install i2c-tools
echo 'Enable I2C...'
if grep -q '#dtparam=i2c_arm=on' /boot/config.txt; then
  # uncomment
  sed -i '/dtparam=i2c_arm/s/^#//g' /boot/config.txt
else
  echo 'i2c_arm parameter already set - skipping...'
fi

echo 'Install i2c-tools...'
if hash i2cget 2>/dev/null; then
    echo 'i2c-tools are installed already - skipping...'
else
    sudo apt-get install -y i2c-tools
fi

##-------------------------------------------------------------------------------------------------
echo "Sleepy Pi setup complete! Please reboot."
exit 0
##-------------------------------------------------------------------------------------------------



