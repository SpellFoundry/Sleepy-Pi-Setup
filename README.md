# Sleepy-Pi-Setup.sh


Currently this works with Raspbian Jessie, Stretch, Buster and Bookworm, with any user name. 

1. To setup from a fresh Raspbian image, first download a full Jessie image from [Raspberry Pi downloads] and flash it onto an SD Card.

2. Download the Sleepy-Pi-Setup.sh into /hope/pi . You can do this from a terminal window with:`wget https://raw.githubusercontent.com/SpellFoundry/Sleepy-Pi-Setup/master/Sleepy-Pi-Setup.sh`

3. Make it executable by: `chmod +x Sleepy-Pi-Setup.sh`

4. Execute the script with sudo `sudo ./Sleepy-Pi-Setup.sh`

5. Reboot

Note this doesn't setup the RTC which you will need to manually do for now. For Sleepy Pi 2 see [Setting up the RTC on Jessie]

# Quick Installation

Copy and paste the following code

```sh
sudo -s
cd /usr/src
wget https://raw.githubusercontent.com/SpellFoundry/Sleepy-Pi-Setup/master/Sleepy-Pi-Setup.sh
chmod a+x Sleepy-Pi-Setup.sh
./Sleepy-Pi-Setup.sh
unlink Sleepy-Pi-Setup.sh
exit
```

[Raspberry Pi downloads]: https://www.raspberrypi.org/downloads/raspbian/

[Setting up the RTC on Jessie]: http://spellfoundry.com/setting-up-the-real-time-clock-on-raspbian-jessie/
