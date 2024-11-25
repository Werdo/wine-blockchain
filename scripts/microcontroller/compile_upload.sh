#!/bin/bash

# Variables
BOARD="esp32:esp32:esp32"
PORT="/dev/ttyUSB0"
SKETCH="WineNodeESP32/WineNodeESP32.ino"

# Compilar
echo "Compilando sketch..."
arduino-cli compile --fqbn $BOARD $SKETCH

# Subir
echo "Subiendo a ESP32..."
arduino-cli upload -p $PORT --fqbn $BOARD $SKETCH
