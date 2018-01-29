#!/bin/bash

# Prepare to shutdown, change the splash screen
sudo /usr/bin/fbi -T 3 -d /dev/fb0 --noverbose /opt/sonanutech-shutdown.png
sleep 1
sudo shutdown -h now
exit 0
