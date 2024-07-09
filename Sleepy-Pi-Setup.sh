#!/usr/bin/env bash

set -eu

# trap "set +x; sleep 5; set -x" DEBUG

# Check whether we are running sudo
if [[ $EUID -ne 0 ]]; then
  	echo "This script must be run as root" 1>&2
  	exit 1
fi

# check if the OS
osInfo=$(cat /etc/os-release)
Jessie=false
Stretch=false
Buster=false
Bullseye=false
Bookworm=false
if [[ $osInfo == *"jessie"* ]]; then
    Jessie=true
elif [[ $osInfo == *"stretch"* ]]; then
   Stretch=true
elif [[ $osInfo == *"buster"* ]]; then
   Buster=true
elif [[ $osInfo == *"bullseye"* ]]; then
   Bullseye=true
elif [[ $osInfo == *"bookworm"* ]]; then
   Bookworm=true
else
    echo "This script only works on Jessie, Stretch, Buster, Bullseye or Bookworm at this time"
    exit 1
fi

echo '================================================================================ '
echo '|                                                                               |'
echo '|      Sleepy Pi Installation Script - Jessie, Stretch, Buster or Bullseye      |'
echo '|                                                                               |'
echo '================================================================================ '

## Update and upgrade
# sudo apt-get update && sudo apt-get upgrade -y

## Detecting Pi model
## list available https://elinux.org/Rpi_HardwareHistory
RPi3=false
RPi4=false
RpiCPU=$(/bin/cat /proc/cpuinfo | /bin/grep Revision | /usr/bin/cut -d ':' -f 2 | /bin/sed -e "s/ //g")
if [ "$RpiCPU" == "a02082" ]; then
    echo "Rapberry Pi 3 detected"
    RPi3=true
elif [ "$RpiCPU" == "a22082" ]; then
    echo "Rapberry Pi 3 B detected"
    RPi3=true
elif [ "$RpiCPU" == "a32082" ]; then
    echo "Rapberry Pi 3 B detected"
    RPi3=true
elif [ "$RpiCPU" == "a020d3" ]; then
    echo "Rapberry Pi 3 B+ detected"
    RPi3=true
elif [ "$RpiCPU" == "9020e0" ]; then
    echo "Rapberry Pi 3 A+ detected"
    RPi3=true
elif [ "$RpiCPU" == "9000c1" ]; then
    echo "Rapberry Pi Zero W detected"
    RPi3=true
elif [ "$RpiCPU" == "a03111" ]; then
    echo "Raspberry Pi 4 1GB detected"
    RPi4=true
elif [ "$RpiCPU" == "b03111" ]; then
    echo "Raspberry Pi 4 2GB detected"
    RPi4=true
elif [ "$RpiCPU" == "b03112" ]; then
    echo "Raspberry Pi 4 2GB detected"
    RPi4=true
elif [ "$RpiCPU" == "b03114" ]; then
    echo "Raspberry Pi 4 2GB detected"
    RPi4=true
elif [ "$RpiCPU" == "c03111" ]; then
    echo "Raspberry Pi 4 4GB detected"
    RPi4=true
elif [ "$RpiCPU" == "c03112" ]; then
    echo "Raspberry Pi 4 4GB detected"
    RPi4=true
elif [ "$RpiCPU" == "c03114" ]; then
    echo "Raspberry Pi 4 4GB detected"
    RPi4=true
 elif [ "$RpiCPU" == "d03114" ]; then
    echo "Raspberry Pi 4 8GB detected"
    RPi4=true  
 elif [ "$RpiCPU" == "902120" ]; then
    echo "Raspberry Pi Zero 2W detected"
    RPi3=true    
else
    # RaspberryPi 2 or 1... let's say it's 2...
    echo "Non-RapberryPi 3 or 4 or Zero families detected"
    RPi3=false
    RPi4=false
fi

echo 'Begin Installation ? (Y/n) '
read ReadyInput
if [[ "$ReadyInput" == "Y" || "$ReadyInput" == "y" ]]; then
    echo "Beginning installation..."
else
    echo "Aborting installation"
    exit 0
fi

if $Bookworm != true; then
  userFilePath="/home/pi"
else
  # List all directories in /home
  directories=($(ls -d /home/* | sed 's:/*$::'))
  
  # Get the number of directories
  dir_count=${#directories[@]}
  
  if [ $dir_count -eq 1 ]; then
      # If there's only one directory, set the variable to that directory
      userFilePath=${directories[0]}
      echo "Only one directory found: $selected_dir"
  else
      # If there are multiple directories, prompt the user to choose one
      echo "Multiple directories found:"
      for i in "${!directories[@]}"; do
          echo "$i) ${directories[$i]}"
      done
  
      # Ask the user to choose a directory
      while true; do
          read -p "Select a directory by number: " choice
          if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -ge 0 ] && [ $choice -lt $dir_count ]; then
              userFilePath=${directories[$choice]}
              break
          else
              echo "Invalid choice. Please enter a number between 0 and $((dir_count-1))."
          fi
      done
  fi
  
  # Output the selected directory
  echo "Selected directory: $userFilePath"

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
echo 'Do you want to install the Arduino IDE?'
read ArduinoInput
if [[ "$ArduinoInput" == "Y" || "$ArduinoInput" == "y" ]]; then
    echo 'Installing Arduino IDE...'
    program="arduino"
    condition=$(which $program 2>/dev/null | grep -v "not found" | wc -l)
    if [ $condition -eq 0 ] ; then
        apt-get install -y arduino
        # create the default sketchbook and libraries that the IDE would normally create on first run
        mkdir $userFilePath/sketchbook
        mkdir $userFilePath/sketchbook/libraries
    else
        echo "Arduino IDE is already installed - skipping"
    fi
else
    echo "Skipping Arduino installation"
fi

##-------------------------------------------------------------------------------------------------

# filepath for the boot partition
# Prior to Bookworm, Raspberry Pi OS stored the boot partition at /boot/. Since Bookworm, the boot partition is located at /boot/firmware/.
if $Bookworm != true; then
  filepath="/boot"
else
  filepath="/boot/firmware"

## Enable Serial Port
# Findme look at using sed to toggle it
echo 'Enable Serial Port...'
#echo "enable_uart=1" | sudo tee -a /boot/config.txt
if grep -q 'enable_uart=1' $filepath/config.txt; then
    echo 'enable_uart=1 is already set - skipping'
else
    echo 'enable_uart=1' | sudo tee -a $filepath/config.txt
fi
if grep -q 'core_freq=250' $filepath/config.txt; then
    echo 'The frequency of GPU processor core is set to 250MHz already - skipping'
else
    echo 'core_freq=250' | sudo tee -a $filepath
fi
  

## Disable Serial login
echo 'Disabling Serial Login...'
set +x
if [ $RPi3 != true ] || [ $RPi4 != true ]; then
    # Non-RPi3 or 4
    systemctl stop serial-getty@ttyAMA0.service
    systemctl disable serial-getty@ttyAMA0.service
else
    # Rpi 3 or 4
    systemctl stop serial-getty@ttyS0.service
    systemctl disable serial-getty@ttyS0.service
fi

## Disable Boot info
echo 'Disabling Boot info...'
#sudo sed -i'bk' -e's/console=ttyAMA0,115200.//' -e's/kgdboc=tty.*00.//'  /boot/cmdline.txt
sed -i'bk' -e's/console=serial0,115200.//'  $filepath/cmdline.txt

## Link the Serial Port to the Arduino IDE
echo 'Link Serial Port to Arduino IDE...'
if [ $RPi3 != true ] || [ $RPi4 != true ]; then
    # Anything other than Rpi 3
    wget https://raw.githubusercontent.com/SpellFoundry/Sleepy-Pi-Setup/master/80-sleepypi.rules
    mv $userFilePath/80-sleepypi.rules /etc/udev/rules.d/
fi
# Note: On Rpi3 or 4 GPIO serial port defaults to ttyS0 which is what we want

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
    cd $userFilePath
    rm -f $userFilePath/master.zip
    rm -R -f $userFilePath/avrdude-rpi-master
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
    mkdir -p $userFilePath/bin
    mkdir -p $userFilePath/bin/SleepyPi
    wget https://raw.githubusercontent.com/SpellFoundry/Sleepy-Pi-Setup/master/shutdowncheck.py
    mv -f shutdowncheck.py $userFilePath/bin/SleepyPi
    sed -i '/exit 0/i python $userFilePath/bin/SleepyPi/shutdowncheck.py &' /etc/rc.local
    # echo "python $userFilePath/bin/SleepyPi/shutdowncheck.py &" | sudo tee -a /etc/rc.local
fi

##-------------------------------------------------------------------------------------------------
echo 'Do you want to add the Sleepy Pi to the Arduino Enviroment?'
read ArduinoEnvInput
if [[ "$ArduinoEnvInput" == "Y" || "$ArduinoEnvInput" == "y" ]]; then
    ## Adding the Sleepy Pi to the Arduino environment
    echo 'Adding the Sleepy Pi to the Arduino environment...'
    # ...setup sketchbook
    mkdir -p $userFilePath/sketchbook
    # ...setup sketchbook/libraries
    mkdir -p $userFilePath/sketchbook/libraries
    # .../sketchbook/hardware
    mkdir -p $userFilePath/sketchbook/hardware
    # .../sketchbook/hardware/sleepy_pi2
    if [ -d "$userFilePath/sketchbook/hardware/sleepy_pi2" ]; then
        echo "sketchbook/hardware/sleepy_pi2 exists - skipping..."
    else
        mkdir $userFilePath/sketchbook/hardware/sleepy_pi2
        wget https://raw.githubusercontent.com/SpellFoundry/Sleepy-Pi-Setup/master/boards.txt
        mv boards.txt $userFilePath/sketchbook/hardware/sleepy_pi2
    fi

    # .../sketchbook/hardware/sleepy_pi
    if [ -d "$userFilePath/sketchbook/hardware/sleepy_pi" ]; then
        echo "sketchbook/hardware/sleepy_pi exists - skipping..."
    else
        mkdir $userFilePath/sketchbook/hardware/sleepy_pi
        wget https://raw.githubusercontent.com/SpellFoundry/Sleepy-Pi-Setup/master/boards.txt
        mv boards.txt $userFilePath/sketchbook/hardware/sleepy_pi
    fi

    ## Setup the Sleepy Pi Libraries
    echo 'Setting up the Sleepy Pi Libraries...'
    cd $userFilePath/sketchbook/libraries/
    if [ -d "$userFilePath/sketchbook/libraries/SleepyPi2" ]; then
        echo "SleepyPi2 Library exists - skipping..."
        # could do a git pull here?
    else
        echo "Installing SleepyPi 2 Library..."
        git clone https://github.com/SpellFoundry/SleepyPi2.git
    fi
    if [ -d "$userFilePath/sketchbook/libraries/SleepyPi" ]; then
        echo "SleepyPi Library exists - skipping..."
        # could do a git pull here?
    else
        echo "Installing SleepyPi Library..."
        git clone https://github.com/SpellFoundry/SleepyPi.git
    fi

    if [ -d "$userFilePath/sketchbook/libraries/Time" ]; then
        echo "Time Library exists - skipping..."
    else
        echo "Installing Time Library..."
        git clone https://github.com/PaulStoffregen/Time.git
    fi

    if [ -d "$userFilePath/sketchbook/libraries/LowPower" ]; then
        echo "LowPower Library exists - skipping..."
    else
        echo "Installing LowPower Library..."
        git clone https://github.com/rocketscream/Low-Power.git
        # rename the directory as Arduino doesn't like the dash
        mv $userFilePath/sketchbook/libraries/Low-Power $userFilePath/sketchbook/libraries/LowPower
    fi


    # Sleepy Pi 1
    if [ -d "$userFilePath/sketchbook/libraries/DS1374RTC" ]; then
        echo "DS1374RTC Library exists - skipping..."
    else
        echo "Installing DS1374RTC Library..."
        git clone https://github.com/SpellFoundry/DS1374RTC.git
    fi

    # Sleepy Pi 2
    if [ -d "$userFilePath/sketchbook/libraries/PCF8523" ]; then
        echo "PCF8523 Library exists - skipping..."
    else
        echo "Installing PCF8523 Library..."
        git clone https://github.com/SpellFoundry/PCF8523.git
    fi


    if [ -d "$userFilePath/sketchbook/libraries/PinChangeInt" ]; then
        echo "PinChangeInt Library exists - skipping..."
    else
        echo "Installing PinChangeInt Library..."
        git clone https://github.com/GreyGnome/PinChangeInt.git
    fi
    cd ~
else
    echo "Adding the Sleepy Pi to the Arduino environment skipped"
fi



##-------------------------------------------------------------------------------------------------

# install i2c-tools
echo 'Enable I2C...'
if grep -q '#dtparam=i2c_arm=on' $filepath/config.txt; then
  # uncomment
  sed -i '/dtparam=i2c_arm/s/^#//g' $filepath/config.txt
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
echo "Sleepy Pi setup complete!"
echo  "Would you like to reboot now? Y/n"
read RebootInput
if [ "$RebootInput" == "Y" ]; then
    echo "Now rebooting..."
    sleep 3
    reboot
fi
exit 0
##-------------------------------------------------------------------------------------------------



