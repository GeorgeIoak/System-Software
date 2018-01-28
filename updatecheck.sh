#!/bin/bash
#
#/home/pi/scripts/updatecheck.sh
# Used to check if a new version is available
# UDEV Rule calls this script
LOG=/home/pi/scripts/debug.log
cd /home/pi/scripts

date  2>&1 | tee -a $LOG
echo -e "\n----------------------------\n"  2>&1 | tee -a $LOG

localver=`cat /home/pi/version.txt`
# Load System Updating Screen
echo -e "Loading system update screen\n" 2>&1 | tee -a $LOG
sudo /usr/bin/fbi -T 3 -d /dev/fb0 --noverbose /opt/sonanutech-updating.png 2>&1 | tee -a $LOG

date  2>&1 | tee -a $LOG
# See if we are online yet
for ((i=1;i < 20;i++))
do
  ping -c1 -q www.dropbox.com
  if  [ "$?" != 0 ]
  then
    echo -e "Ping results ${i} failed\n" 2>&1 | tee -a $LOG
    online=0
  else
    echo -e "Ping results ${i} passed\n" 2>&1 | tee -a $LOG
    online=1
    break
  fi
  date  2>&1 | tee -a $LOG
  sleep 1
done

if [ $online ]
then
  echo -e "We're online now\n" 2>&1 | tee -a $LOG
else
  echo -e "Not online, exiting script\n" 2>&1 | tee -a $LOG
  echo -e "Loading logo splash screen\n" 2>&1 | tee -a $LOG
  sudo /usr/bin/fbi -T 3 -d /dev/fb0 --noverbose /opt/sonanutech-logo.png 2>&1 | tee -a $LOG
  exit 0
fi

# Get latest version number from the internet
wget -O cloudversion.txt https://www.dropbox.com/s/e96lzqk1k6chj75/version.txt 2>&1 | tee -a $LOG
if  [ "$?" != 0 ]
then
  echo -e "Version File not found online\n" 2>&1 | tee -a $LOG
  cd /home/pi
  echo -e "Loading logo splash screen\n" 2>&1 | tee -a $LOG
  sudo /usr/bin/fbi -T 3 -d /dev/fb0 --noverbose /opt/sonanutech-logo.png 2>&1 | tee -a $LOG
  exit 0
else
  cloudversion=`cat /home/pi/scripts/cloudversion.txt`
fi

if [ "$localver" -ge "$cloudversion" ]
then
  echo -e "Version isn't new:" 2>&1 | tee -a $LOG
  echo -e "Cloud Version : " $cloudversion 2>&1 | tee -a $LOG
  echo -e "Local Version is : " $localver 2>&1 | tee -a $LOG
  rm cloudversion.txt
  cd /home/pi
  echo -e "Loading logo splash screen\n" 2>&1 | tee -a $LOG
  sudo /usr/bin/fbi -T 3 -d /dev/fb0 --noverbose /opt/sonanutech-logo.png 2>&1 | tee -a $LOG
  exit 0
else

# Stop the app
sudo service sonanutech stop | tee -a $LOG
echo -e "\nSonanuTech app was stopped\n"  2>&1 | tee -a $LOG

echo -e "Now Starting to Copy the new app\n" 2>&1 | tee -a $LOG
# Now copy the new app

wget https://www.dropbox.com/s/6wssw5xa2ru7uh7/qml.tar 2>&1 | tee -a $LOG

if  [ "$?" != 0 ]
then
  echo -e "Problem getting new app file\n" 2>&1 | tee -a $LOG
  rm /home/pi/scripts/cloudversion.txt
  cd /home/pi
  echo -e "Loading logo splash screen\n" 2>&1 | tee -a $LOG
  sudo /usr/bin/fbi -T 3 -d /dev/fb0 --noverbose /opt/sonanutech-logo.png 2>&1 | tee -a $LOG
  exit 0
else
  tar -xf qml.tar 2>&1 | tee -a $LOG
fi

echo -e "Now Starting to Copy the new checksum file\n" 2>&1 | tee -a $LOG
# Now copy the checksum
wget https://www.dropbox.com/s/0ukzp1a38dbnl1r/qml.md5 2>&1 | tee -a $LOG
if  [ "$?" != 0 ]
then
  echo -e "Problem getting new MD5 file\n" 2>&1 | tee -a $LOG
  rm /home/pi/scripts/qml.md5
  rm /home/pi/scripts/cloudversion.txt
  rm /home/pi/scripts.qml.tar
  cd /home/pi
  echo -e "Loading logo splash screen\n" 2>&1 | tee -a $LOG
  sudo /usr/bin/fbi -T 3 -d /dev/fb0 --noverbose /opt/sonanutech-logo.png 2>&1 | tee -a $LOG
  exit 0
else
  newmd5=`cat /home/pi/scripts/qml.md5`
fi

echo -e "Now going to validate the download\n" 2>&1 | tee -a $LOG
#Compare checksums
md5sum --status -c qml.md5
if [ "$?" = 0 ]
then
    # The MD5 sum matched
    echo -e "Good download, checksums match\n" 2>&1 | tee -a $LOG
    chmod +x qml
    mv /home/pi/qml /home/pi/backup/.
    mv /home/pi/scripts/qml /home/pi/.
    rm /home/pi/scripts/qml.md5
    cp -f /home/pi/scripts/cloudversion.txt /home/pi/version.txt
    rm /home/pi/scripts/cloudversion.txt
    rm /home/pi/scripts/qml
    rm /home/pi/scripts/qml.tar

    #Start the app
    echo -e "Starting the new app now\n" 2>&1 | tee -a $LOG
    sudo service sonanutech start
    #Verify that the app is running
    sudo systemctl is-active sonanutech >/dev/null
    if [ "$?" != 0 ]
    then
      echo -e "The app isn't running for some reason\n" 2>&1 | tee -a $LOG
      # Todo add code to retry or do something useful
      # like maybe copy back the old version and check
      # for now just try again
      sudo service sonanutech stop
      sudo service sonanutech start
      cd /home/pi
    else
      echo -e "The new app is running now" 2>&1 | tee -a $LOG
    fi
else
    # The MD5 sum didn't match
    echo -e "Bad download, checksums don't match\n" 2>&1 | tee -a $LOG
    rm /home/pi/scripts/qml
    rm /home/pi/scripts/qml.md5
    rm /home/pi/scripts/qml.tar
    rm /home/pi/scripts/cloudversion.txt
    # Need to start the old version again
    echo -e "Starting the old app now\n" 2>&1 | tee -a $LOG
    cd /home/pi
    sudo service sonanutech start

    if [ "$?" != 0 ]
    then
      echo -e "The app isn't running for some reason\n" 2>&1 | tee -a $LOG
      # Todo add code to retry or do something useful
      # like maybe copy back the old version and check
    else
      echo -e "The old app is running now" 2>&1 | tee -a $LOG
      cd /home/pi
    fi
    echo -e "Loading logo splash screen\n" 2>&1 | tee -a $LOG
    sudo /usr/bin/fbi -T 3 -d /dev/fb0 --noverbose /opt/sonanutech-logo.png 2>&1 | tee -a $LOG
    exit 0
fi
fi
