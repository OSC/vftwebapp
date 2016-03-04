#!/bin/bash

SLEEP_PID=$(pgrep -s 0 sleep)
kill -9 ${SLEEP_PID}
