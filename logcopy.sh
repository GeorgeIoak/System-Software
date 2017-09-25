#!/bin/sh
#
#/home/pi/scripts/logcopy.sh
# Used to copy log file to a USB drive
# UDEV Rule calls this script
LOG=/home/pi/scripts/debug.log


date  2>&1 | tee -a $LOG
echo "\n----------------------------\n"  2>&1 | tee -a $LOG

#mount the USB Drive
mkdir -p /media/usbdrive 2>&1 | tee -a /home/pi/scripts/debug.log
mount  /dev/sda1 -t vfat /media/usbdrive 2>&1 | tee -a /home/pi/scripts/debug.log
localver=`cat /home/pi/version.txt`
echo "USB Drive was just mounted\n" 2>&1 | tee -a $LOG

if  [ -f /media/usbdrive/version.txt ]
then
  usbver=`cat /media/usbdrive/version.txt`
else
  sync
  echo "Version File not found on USB\n" 2>&1 | tee -a $LOG
  umount -l /media/usbdrive   2>&1 | tee -a $LOG 
  rmdir /media/usbdrive   2>&1 | tee -a $LOG 
  exit 0
fi

if [ "$localver" -ge "$usbver" ]
then
  echo "Version isn't new:" 2>&1 | tee -a $LOG
  echo "USB Version : " $usbver 2>&1 | tee -a $LOG
  echo "Local Version is : " $localver 2>&1 | tee -a $LOG
  sync
  umount -l /media/usbdrive   2>&1 | tee -a $LOG 
  rmdir /media/usbdrive   2>&1 | tee -a $LOG 
else

# Stop the app
#stop kiosk  | tee -a $LOG
#echo "\nkiosk was stopped\n"  2>&1 | tee -a $LOG

# Start the Stand-by Screen
#cd /home/vlc/
#echo "\nstarting standby video\n"  2>&1 | tee -a $LOG
#export LD_LIBRARY_PATH=/usr/local/hybris/lib
#su vlc -c "$PLAYER $VLCArgs $VIDEO 2>&1 | tee -a $LOG &"
#echo $!  2>&1 | tee -a $LOG

echo "Now Starting to Copy the Log Files\n" 2>&1 | tee -a $LOG
# Now copy the new files
cp -R -p /home/pi/logs/* /home/pi/backup/.   2>&1 | tee -a $LOG
chown -R pi:pi /home/pi/backup
cp -R /home/pi/logs/* /media/usbdrive/   2>&1 | tee -a $LOG 
rm -rf /home/pi/logs/*  2>&1 | tee -a $LOG
#cd /media/usbdrive/   2>&1 | tee -a $LOG
chown -R pi:pi /media/usbdrive
sync
umount -l /media/usbdrive   2>&1 | tee -a $LOG 
rmdir /media/usbdrive   2>&1 | tee -a $LOG 

#Stop the Stand-by Loop and Start the New Demo
#killall  -9  $PLAYER   2>&1 | tee -a $LOG
#echo "Just killed the standby loop\n" 2>&1 | tee -a $LOG

#start kiosk | tee -a $LOG
chown pi $LOG
chgrp pi $LOG
echo "\n----------------------------\n"  2>&1 | tee -a $LOG
#Alias for changing the file system to RO to help prevent corruptions
#mount -n -o remount,ro -t dummytype dummydev /
#echo vlc | sudo reboot now
fi

