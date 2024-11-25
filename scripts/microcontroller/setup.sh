#!/bin/bash

# Instalar herramientas necesarias para ESP32
echo "Instalando herramientas para ESP32..."
sudo apt-get update
sudo apt-get install -y python3-pip python3-setuptools

# Instalar Arduino CLI
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
export PATH=$PATH:$HOME/bin

# Configurar Arduino CLI
arduino-cli config init
arduino-cli core update-index
arduino-cli core install esp32:esp32

# Instalar bibliotecas necesarias
arduino-cli lib install "ArduinoJson"
arduino-cli lib install "WiFi"
arduino-cli lib install "HTTPClient"
arduino-cli lib install "SHA256"

echo "Configuración completada"
