#!/bin/bash

# See if we are online yet
#if ping -c 1 -q www.6r6t63.com
#if ping -c 1 -q www.google.com
#then 
#  echo "fail\n"
#else
#  echo "pass\n"
#fi
for ((num=1;num < 4;num++))
do
 ping -c1 -q www.6r6t63.com
 if  [ "$?" != 0 ]
 then
   echo -e "Ping results ${i} failed\n"
 else
   echo -e "Ping results ${i} passed\n"
 fi
sleep 1
done

ping -c 1 -q www.google.com
if  [ "$?" != 0 ]
then
  echo -e "Ping results failed\n"
else
  echo -e "Ping results passed\n"
fi

for ((i=1;i < 3;i++))
do
  ping -c1 -q www.dropbox.com
  if  [ "$?" != 0 ]
  then
    echo -e "Ping results ${i} failed\n"
    online=0
    echo -e $online "\n"
  else
    echo -e "Ping results ${i} passed\n"
    online=1
    echo -e $online "\n"
    break
  fi
  sleep 1
done

if [ $online ]
then
  echo -e "We're online\n"
else
  echo -e "Not online, exiting script\n"
  exit 0
fi


sudo /usr/bin/fbi -T 3 -d /dev/fb0 --noverbose /opt/sonanutech-logo.png
exit 0
