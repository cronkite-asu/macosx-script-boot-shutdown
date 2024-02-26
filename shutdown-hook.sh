#!/bin/bash

#
# Author: Vincenzo D'Amore v.damore@gmail.com
# 20/11/2014
# Updated: Jeremy Leggat
# 20/02/2024
#
# Capture SIGTERM events to run commands before exit
#
# In MacOS the kernel sends to all user-space daemons SIGTERM at system shutdown
# or reboot. Use this script to catch this signal and run commands at shutdown.

# The function that will get called when a SIGTERM signal is recieved.
# Put commands to run on shutdown here.
function shutdown() {
  echo "$(date) $(whoami) Received a signal to shutdown"

  launchctl kill SIGKILL system/com.apple.xsan

  exit 0
}

# Initialize the script and then wait for a signal.
# Put commands to run when starting here.
function startup() {
  echo "$(date) $(whoami) Starting..."

  tail -f /dev/null &
  wait $!
}

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Catch TERM signals to run shutdown function
trap shutdown SIGTERM

# Initialize and wait for TERM signal.
startup
