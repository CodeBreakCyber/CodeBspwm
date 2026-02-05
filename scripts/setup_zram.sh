#!/usr/bin/env bash

#==============================================================================
# Configuración de ZRAM para mejor rendimiento
# Comprime la RAM para aumentar la capacidad efectiva
#==============================================================================

set -e

# Colores
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

CHECK="${GREEN}✓${NC}"
ARROW="${CYAN}➜${NC}"

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║              ZRAM Configuration Setup                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${ARROW} Configurando ZRAM para mejor rendimiento...\n"

# Instalar zram-tools
echo -e "${ARROW} Instalando zram-tools..."
sudo apt update -qq
sudo apt install -y zram-tools -qq
echo -e "${CHECK} zram-tools instalado"

# Configurar zram
echo -e "${ARROW} Configurando parámetros de ZRAM..."
sudo tee /etc/default/zramswap > /dev/null <<EOF
# Compression algorithm
# lz4 is fastest, zstd has better compression
ALGO=lz4

# Percentage of RAM to use for zram
# 50% is recommended for most systems
PERCENT=50

# Priority for zram swap
# Higher = preferred over disk swap
PRIORITY=100
EOF
echo -e "${CHECK} Configuración creada"

# Habilitar y iniciar servicio
echo -e "${ARROW} Habilitando servicio de ZRAM..."
sudo systemctl enable zramswap 2>/dev/null || true
sudo systemctl restart zramswap 2>/dev/null || true
echo -e "${CHECK} Servicio habilitado"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  ${CHECK} ${GREEN}ZRAM configurado correctamente!${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${ARROW} Verificando estado de ZRAM..."
echo ""
sudo swapon --show
echo ""
echo -e "${ARROW} Uso de memoria actual:"
free -h
echo ""
