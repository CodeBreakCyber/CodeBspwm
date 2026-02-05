#!/usr/bin/env bash

set -e

# Colores
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
ARROW="${CYAN}➜${NC}"
CHECK="${GREEN}✓${NC}"

echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         INSTALANDO TEMA DE PANTALLA DE BLOQUEO (PEPA)      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${ARROW} Instalando Slick Greeter (Interfaz moderna)..."
sudo apt install -y slick-greeter lightdm-settings

echo -e "${ARROW} Configurando LightDM..."

# Backup de configuración existente
if [ -f /etc/lightdm/lightdm.conf ]; then
    sudo cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.bak
fi

# Activar slick-greeter
sudo sh -c 'echo "[Seat:*]
greeter-session=slick-greeter
user-session=bspwm" > /etc/lightdm/lightdm.conf'

echo -e "${ARROW} Configurando apariencia..."

# Copiar wallpaper actual a un lugar accesible para lightdm
if [ -f "$HOME/Wallpaper/1.jpg" ]; then
    sudo cp "$HOME/Wallpaper/1.jpg" /usr/share/backgrounds/kali-bspwm-bg.jpg
else
    # Fallback si no hay wallpaper específico, buscar el primero jpg
    WALL=$(find ~/Wallpaper -name "*.jpg" | head -n 1)
    if [ -n "$WALL" ]; then
        sudo cp "$WALL" /usr/share/backgrounds/kali-bspwm-bg.jpg
    else
        echo "No se encontró wallpaper, usando default."
    fi
fi

# Configurar slick-greeter
sudo tee /etc/lightdm/slick-greeter.conf > /dev/null <<EOF
[Greeter]
background=/usr/share/backgrounds/kali-bspwm-bg.jpg
draw-user-backgrounds=false
draw-grid=false
theme-name=Kali-Dark
icon-theme-name=Papirus-Dark
font-name=Iosevka Nerd Font 11
EOF

echo -e "${CHECK} Tema de Login instalado correctamente."
echo -e "${ARROW} Se aplicará en el próximo reinicio."
