#!/bin/bash
#
#/home/pi/scripts/updatecheck.sh
# Used to check if a new version is available
# UDEV Rule calls this script
LOG=/home/pi/scripts/debug.log
upfile=/home/pi/scripts/download/ready-for-update
dldir=/home/pi/scripts/download
localver=`cat /home/pi/version.txt`
qmlMD5link=https://www.dropbox.com/s/0ukzp1a38dbnl1r/qml.md5
analyseMD5link=https://www.dropbox.com/s/j5o3jhukj9vt758/analyse.md5
qmllink=https://www.dropbox.com/s/6wssw5xa2ru7uh7/qml.tar
versionlink=https://www.dropbox.com/s/e96lzqk1k6chj75/version.txt

cd $dldir

cleanup() {
  echo -e "Cleanup called, deleting downloads\n" 2>&1 | tee -a $LOG
  rm -f "$dldir"/*
}

goodbye() {
  cd /home/pi
  echo -e "Goodbye called, time to leave\n" 2>&1 | tee -a $LOG
  echo -e "Loading logo splash screen\n" 2>&1 | tee -a $LOG
  sudo /usr/bin/fbi -T 3 -d /dev/fb0 --noverbose /opt/sonanutech-logo.png 2>&1 | tee -a $LOG
  exit 0
}

copyfiles() {
  mv -f /home/pi/qml /home/pi/backup/.
  mv -f "$dldir"/qml /home/pi/.
  mv -f /home/pi/analyse /home/pi/backup/.
  mv -f "$dldir"/analyse /home/pi.
  cp -f "$dldir"/cloudversion.txt /home/pi/version.txt
}

startnewapp() {
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
}

date  2>&1 | tee -a $LOG
echo -e "\n----------------------------\n"  2>&1 | tee -a $LOG

if [ -f "$upfile" ]
then
  #Update was downloaded, time to install
  # Stop the app
  sudo /usr/bin/fbi -T 3 -d /dev/fb0 --noverbose /opt/sonanutech-updating.png 2>&1 | tee -a $LOG
  sudo service sonanutech stop | tee -a $LOG
  echo -e "\nSonanuTech app was stopped\n"  2>&1 | tee -a $LOG
  copyfiles
  cleanup
  startnewapp
  goodbye
fi

#Need to check if an update is available
# Load System Update Check Screen
echo -e "Loading system update screen\n" 2>&1 | tee -a $LOG
sudo /usr/bin/fbi -T 3 -d /dev/fb0 --noverbose /opt/sonanutech-checking.png 2>&1 | tee -a $LOG

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
  goodbye
fi

# Get latest version number from the internet
wget -N -O cloudversion.txt $versionlink 2>&1 | tee -a $LOG
if  [ "$?" != 0 ]
then
  echo -e "Version File not found online\n" 2>&1 | tee -a $LOG
  cleanup
  goodbye
else
  cloudversion=`cat /home/pi/scripts/download/cloudversion.txt`
fi

if [ "$localver" -ge "$cloudversion" ]
then
  echo -e "Version isn't new:" 2>&1 | tee -a $LOG
  echo -e "Cloud Version : " $cloudversion 2>&1 | tee -a $LOG
  echo -e "Local Version is : " $localver 2>&1 | tee -a $LOG
  cleanup
  goodbye
fi

echo -e "Now Starting to dowload the new app\n" 2>&1 | tee -a $LOG
wget -N $qmllink 2>&1 | tee -a $LOG
if  [ "$?" != 0 ]
then
  echo -e "Problem getting new app file\n" 2>&1 | tee -a $LOG
  cleanup
  goodbye
else
  #files has full paths that I want to remove and extract here
  tar -xf qml.tar -C . --strip-components=2 2>&1 | tee -a $LOG
fi

echo -e "Now downloading the qml checksum file\n" 2>&1 | tee -a $LOG
wget -N $qmlMD5link 2>&1 | tee -a $LOG
if  [ "$?" != 0 ]
then
  echo -e "Problem getting qml MD5 file\n" 2>&1 | tee -a $LOG
  cleanup
  goodbye
else
  newqmlmd5=`cat /home/pi/scripts/download/qml.md5`
fi

echo -e "Now downloading the analyse checksum file\n" 2>&1 | tee -a $LOG
wget -N $analyseMD5link 2>&1 | tee -a $LOG
if  [ "$?" != 0 ]
then
  echo -e "Problem getting analyse MD5 file\n" 2>&1 | tee -a $LOG
  cleanup
  goodbye
else
  newanalysemd5=`cat /home/pi/scripts/download/analyse.md5`
fi

echo -e "Now going to validate the qml download\n" 2>&1 | tee -a $LOG
#Compare checksums
md5sum --status -c qml.md5
if [ "$?" != 0 ]
then
    # The MD5 sum didn't match
    echo -e "Bad qml download, checksums don't match\n" 2>&1 | tee -a $LOG
    cleanup
    goodbye
else
    # The qml MD5 sum matched
    echo -e "Good download, qml checksums match\n" 2>&1 | tee -a $LOG
fi

echo -e "Now going to validate the analyse download\n" 2>&1 | tee -a $LOG
#Compare checksums
md5sum --status -c analyse.md5
if [ "$?" != 0 ]
then
    # The MD5 sum didn't match
    echo -e "Bad analyse download, checksums don't match\n" 2>&1 | tee -a $LOG
    cleanup
    goodbye
else
    # The analyse MD5 sum matched
    echo -e "Good download, analyse checksums match\n" 2>&1 | tee -a $LOG
fi

# We made it to here so we got a good download
touch $upfile
exit 0
