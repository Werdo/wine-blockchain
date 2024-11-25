#!/bin/bash

# Variables
PORT="/dev/ttyUSB0"
BAUD_RATE=115200

# Monitorear puerto serie
echo "Monitoreando puerto serie..."
arduino-cli monitor -p $PORT -c baudrate=$BAUD_RATE
