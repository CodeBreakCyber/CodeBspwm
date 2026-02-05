#!/usr/bin/env bash

#==============================================================================
# Instalador de Caido
# Proxy web moderno para pentesting
#==============================================================================

set -e

# Colores
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

CHECK="${GREEN}✓${NC}"
ARROW="${CYAN}➜${NC}"
INFO="${CYAN}ℹ${NC}"

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║                  Caido Installer                         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${INFO} ${CYAN}Instalando Caido...${NC}\n"

# Detectar arquitectura
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    CAIDO_ARCH="x86_64"
elif [ "$ARCH" = "aarch64" ]; then
    CAIDO_ARCH="aarch64"
else
    echo -e "${YELLOW}⚠${NC}  Arquitectura no soportada: $ARCH"
    exit 1
fi

# Obtener última versión
echo -e "${ARROW} Obteniendo última versión de Caido..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/caido/caido/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "0.37.0")
echo -e "${CHECK} Versión: $LATEST_VERSION"

# Descargar Caido
CAIDO_URL="https://github.com/caido/caido/releases/download/v${LATEST_VERSION}/caido-desktop-v${LATEST_VERSION}-linux-${CAIDO_ARCH}.AppImage"

echo -e "${ARROW} Descargando Caido..."
sudo mkdir -p /opt/caido
cd /opt/caido
sudo wget -q --show-progress "$CAIDO_URL" -O caido.AppImage || {
    echo -e "${YELLOW}⚠${NC}  Usando versión alternativa..."
    sudo wget -q --show-progress "https://caido.io/releases/latest/caido-desktop-linux-${CAIDO_ARCH}.AppImage" -O caido.AppImage
}
echo -e "${CHECK} Caido descargado"

# Dar permisos de ejecución
echo -e "${ARROW} Configurando permisos..."
sudo chmod +x caido.AppImage
echo -e "${CHECK} Permisos configurados"

# Crear launcher
echo -e "${ARROW} Creando launcher..."
sudo tee /usr/local/bin/caido > /dev/null <<'EOF'
#!/bin/bash
/opt/caido/caido.AppImage "$@"
EOF

sudo chmod +x /usr/local/bin/caido
echo -e "${CHECK} Launcher creado"

# Crear alias en zshrc
echo -e "${ARROW} Añadiendo alias a .zshrc..."
if [ -f ~/.zshrc ]; then
    if ! grep -q "alias caido" ~/.zshrc; then
        {
            echo ""
            echo "# Caido"
            echo "alias caido='/usr/local/bin/caido'"
        } >> ~/.zshrc
    fi
fi

if [ -f /root/.zshrc ]; then
    if ! sudo grep -q "alias caido" /root/.zshrc; then
        {
            echo ""
            echo "# Caido"
            echo "alias caido='/usr/local/bin/caido'"
        } | sudo tee -a /root/.zshrc > /dev/null
    fi
fi
echo -e "${CHECK} Alias configurado"

# Limpiar entradas de escritorio duplicadas y deshabilitadas
echo -e "${ARROW} Limpiando entradas duplicadas..."
sudo rm -f /usr/share/applications/caido.desktop.disabled-by-kali-menu 2>/dev/null || true
sudo rm -f ~/.local/share/applications/caido.desktop 2>/dev/null || true

# Crear entrada de escritorio única y habilitada
echo -e "${ARROW} Creando entrada de escritorio..."
sudo tee /usr/share/applications/caido.desktop > /dev/null <<EOF
[Desktop Entry]
Version=1.0
Name=Caido
Comment=Modern Web Security Testing Toolkit
Exec=/usr/local/bin/caido %U
Icon=caido
Terminal=false
Type=Application
Categories=Development;Security;Network;
StartupNotify=true
MimeType=x-scheme-handler/caido;
EOF

# Actualizar base de datos de aplicaciones
sudo update-desktop-database /usr/share/applications 2>/dev/null || true
echo -e "${CHECK} Entrada de escritorio creada y habilitada"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  ${CHECK} ${GREEN}Caido instalado correctamente!${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${INFO} ${CYAN}Cómo usar:${NC}"
echo -e "  ${ARROW} Ejecuta: ${YELLOW}caido${NC}"
echo -e "  ${ARROW} O búscalo en el menú de aplicaciones"
echo ""
echo -e "${INFO} ${CYAN}Ubicación:${NC} /opt/caido"
echo ""
