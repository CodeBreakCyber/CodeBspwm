#!/bin/bash

# Este script requiere permisos de root para cambiar el fondo de LightDM
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root (sudo)"
  exit
fi

WALL_DIR="/home/andres/Pictures/Wallpapers"
TARGET_FILE="/usr/share/desktop-base/kali-theme/login/background"

# Seleccionar aleatorio
RANDOM_WALL=$(find "$WALL_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)

if [ -n "$RANDOM_WALL" ]; then
    echo "Cambiando fondo de Login a: $(basename "$RANDOM_WALL")"
    cp "$RANDOM_WALL" "$TARGET_FILE"
    chmod 644 "$TARGET_FILE" # Asegurar lectura global
    echo "¡Hecho! El próximo login tendrá nuevo fondo."
else
    echo "No encontré imágenes en $WALL_DIR"
fi
