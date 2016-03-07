#!/bin/bash

if zenity --warning --text="<span size=\"x-large\">Are you sure you want to log out?</span>" --title="Log out"; then
  SLEEP_PID=$(pgrep -s 0 sleep)
  kill -9 ${SLEEP_PID}
fi
