Plymoth has a default splash screen which can be replaced. The sonanutech-logo.png is a 800x480 sized file to match the 
screen setting of the 7" display and also in the /boot/config.txt file

sudo cp sonanutech-logo.png /usr/share/plymouth/themes/pix/splash.png

to run qml at startup:

sudo update-rc.d sonanutech defaults

mkdir /home/pi/scripts/download
mkdir /home/pi/logs

tar -C / -cf qml.tar home/pi/qml home/pi/analyse

g++ -o analyse analyse.cpp

pi@SonanuTech-Pi:~ $ md5sum -b qml >qml.md5
pi@SonanuTech-Pi:~ $ md5sum -b analyse >analyse.md5

To change the host name you just need to open two files, /etc/hosts and /etc/hostname, and replace the word raspberrypi with your chosen hostname
