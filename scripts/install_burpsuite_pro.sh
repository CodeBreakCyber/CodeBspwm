#!/usr/bin/env bash

#==============================================================================
# Instalador de Burp Suite Professional
# Descarga e instala Burp Suite Pro con loader/keygen
#==============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Símbolos
CHECK="${GREEN}✓${NC}"
ARROW="${BLUE}➜${NC}"
INFO="${CYAN}ℹ${NC}"

BURP_DIR="/opt/burpsuite-pro"
LOADER_URL="https://github.com/h3110w0r1d-y/BurpLoaderKeygen/releases/latest/download/BurpLoaderKeygen.jar"
LOADER_URL_ALT1="https://github.com/x-Ai/BurpSuiteLoader/releases/latest/download/BurpLoaderKeygen.jar"
LOADER_URL_ALT2="https://raw.githubusercontent.com/h3110w0r1d-y/BurpLoaderKeygen/main/BurpLoaderKeygen.jar"

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║           Burp Suite Professional Installer              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Validar si ya está instalado
if [[ -f "/opt/burpsuite-pro/BurpLoaderKeygen.jar" ]] && [[ -f "/usr/local/bin/burpsuite-pro" ]]; then
    echo -e "${CHECK} ${GREEN}Burp Suite Professional ya está instalado${NC}"
    echo -e "${INFO} ${CYAN}Ubicación:${NC} /opt/burpsuite-pro"
    echo -e "${INFO} ${CYAN}Launcher:${NC} /usr/local/bin/burpsuite-pro"
    echo ""
    echo -e "${YELLOW}¿Deseas reinstalar? Esto eliminará la instalación actual (S/n)${NC}"
    read -r -n 1 response
    echo ""
    if [[ ! "$response" =~ ^[Ss]$ ]]; then
        echo -e "${INFO} Instalación cancelada"
        exit 0
    fi
    
    echo -e "${ARROW} Eliminando instalación anterior..."
    sudo rm -rf "$BURP_DIR"
    sudo rm -f /usr/local/bin/burpsuite-pro
    sudo rm -f /usr/bin/burpsuitepro
    sudo rm -f /usr/share/applications/burpsuite-professional.desktop
    sudo rm -f /usr/share/applications/burp-suite-professional.desktop
    echo -e "${CHECK} Limpieza completada"
fi

# Eliminar Burp Suite Community y residuos
if dpkg -l | grep -q "^ii.*burpsuite"; then
    echo -e "${ARROW} Eliminando Burp Suite Community..."
    sudo apt remove --purge -y burpsuite 2>/dev/null || true
    sudo apt autoremove -y 2>/dev/null || true
    echo -e "${CHECK} Burp Suite Community eliminado"
fi

# Limpieza adicional de binarios antiguos
sudo rm -f /usr/bin/burpsuitepro 2>/dev/null || true
sudo rm -f /usr/local/bin/burpsuitepro 2>/dev/null || true


echo -e "${INFO} ${CYAN}Instalando Burp Suite Professional...${NC}\n"

# Verificar Java
if ! command -v java &> /dev/null; then
    echo -e "${ARROW} Instalando Java..."
    sudo apt update -qq
    sudo apt install -y default-jdk -qq
    echo -e "${CHECK} Java instalado"
fi

# Crear directorio
echo -e "${ARROW} Creando directorio de instalación..."
sudo mkdir -p "$BURP_DIR"
cd "$BURP_DIR"
echo -e "${CHECK} Directorio creado"

# Descargar Burp Suite (última versión)
echo -e "${ARROW} Descargando Burp Suite Professional..."
if command -v jq &> /dev/null; then
    BURP_VERSION=$(curl -s https://portswigger.net/burp/releases/data 2>/dev/null | jq -r '.ResultSet.Results[0].version' 2>/dev/null || echo "2023.12.1")
else
    BURP_VERSION="2023.12.1"
fi

BURP_URL="https://portswigger-cdn.net/burp/releases/download?product=pro&version=${BURP_VERSION}&type=Jar"
sudo wget -q --show-progress "$BURP_URL" -O burpsuite_pro.jar || {
    echo -e "${YELLOW}Usando URL alternativa...${NC}"
    sudo wget -q --show-progress "https://portswigger-cdn.net/burp/releases/professional-community-2023-12-1.jar" -O burpsuite_pro.jar
}
echo -e "${CHECK} Burp Suite descargado"

# Descargar Loader/Keygen con múltiples URLs de respaldo
echo -e "${ARROW} Descargando BurpLoaderKeygen..."

# Primero verificar si existe en el repositorio local (BurpLoaderKeygen.jar o loader.jar)
LOCAL_LOADER="$(dirname "$0")/../resources/burpsuite/BurpLoaderKeygen.jar"
LOCAL_LOADER_ALT="$(dirname "$0")/../resources/burpsuite/loader.jar"

if [[ -f "$LOCAL_LOADER" ]] && [[ -s "$LOCAL_LOADER" ]]; then
    echo -e "${CHECK} Usando BurpLoaderKeygen.jar del repositorio local"
    sudo cp "$LOCAL_LOADER" BurpLoaderKeygen.jar
elif [[ -f "$LOCAL_LOADER_ALT" ]] && [[ -s "$LOCAL_LOADER_ALT" ]]; then
    echo -e "${CHECK} Usando loader.jar del repositorio local"
    sudo cp "$LOCAL_LOADER_ALT" BurpLoaderKeygen.jar
elif sudo wget -q --show-progress "$LOADER_URL" -O BurpLoaderKeygen.jar && [[ -s BurpLoaderKeygen.jar ]]; then
    echo -e "${CHECK} Loader descargado desde GitHub (principal)"
elif sudo wget -q --show-progress "$LOADER_URL_ALT1" -O BurpLoaderKeygen.jar && [[ -s BurpLoaderKeygen.jar ]]; then
    echo -e "${CHECK} Loader descargado desde fuente alternativa 1"
elif sudo wget -q --show-progress "$LOADER_URL_ALT2" -O BurpLoaderKeygen.jar && [[ -s BurpLoaderKeygen.jar ]]; then
    echo -e "${CHECK} Loader descargado desde fuente alternativa 2"
else
    echo -e "${RED}${CROSS} Error: No se pudo descargar BurpLoaderKeygen desde ninguna fuente${NC}"
    echo -e "${YELLOW}Opciones:${NC}"
    echo -e "  1. Descarga manual desde: https://github.com/h3110w0r1d-y/BurpLoaderKeygen"
    echo -e "  2. O desde: https://github.com/x-Ai/BurpSuiteLoader"
    echo -e "  3. Coloca el archivo en: ${BURP_DIR}/BurpLoaderKeygen.jar"
    echo -e "${INFO} Puedes continuar la instalación sin el loader, pero necesitarás activar Burp manualmente"
    # ShellCheck: SC2162 - read -r
    read -r -p "Presiona ENTER para continuar sin loader o Ctrl+C para cancelar..."
fi

# Verificar que el archivo descargado sea válido (solo si existe)
if [[ -f BurpLoaderKeygen.jar ]] && [[ ! -s BurpLoaderKeygen.jar ]]; then
    echo -e "${YELLOW}${WARN} BurpLoaderKeygen.jar está vacío, se omitirá${NC}"
    sudo rm -f BurpLoaderKeygen.jar
fi

# Instalar Jython (para extensiones Python en Burp)
echo -e "${ARROW} Descargando Jython..."
sudo wget -q --show-progress https://repo1.maven.org/maven2/org/python/jython-standalone/2.7.3/jython-standalone-2.7.3.jar -O jython-standalone.jar
echo -e "${CHECK} Jython descargado"

# Instalar JRuby (para extensiones Ruby en Burp)
echo -e "${ARROW} Descargando JRuby..."
sudo wget -q --show-progress "https://repo1.maven.org/maven2/org/jruby/jruby-complete/9.4.5.0/jruby-complete-9.4.5.0.jar" -O jruby-complete.jar
echo -e "${CHECK} JRuby descargado"

# Crear script de lanzamiento
echo -e "${ARROW} Creando launcher..."
sudo tee /usr/local/bin/burpsuite-pro > /dev/null <<'EOF'
#!/bin/bash
# Burp Suite Professional Launcher
# Configuración persistente en ~/.BurpSuite

# Crear directorio de configuración si no existe
BURP_CONFIG_DIR="${HOME}/.BurpSuite"
mkdir -p "${BURP_CONFIG_DIR}"

# Cambiar al directorio de instalación
cd /opt/burpsuite-pro

# Iniciar BurpLoaderKeygen con configuración persistente
# La licencia se guardará en ~/.BurpSuite/
java -Duser.home="${BURP_CONFIG_DIR}" -jar BurpLoaderKeygen.jar
EOF

sudo chmod +x /usr/local/bin/burpsuite-pro
echo -e "${CHECK} Launcher creado"

# Crear alias en zshrc
echo -e "${ARROW} Añadiendo alias a .zshrc..."
if [ -f ~/.zshrc ]; then
    if ! grep -q "alias burpsuite-pro" ~/.zshrc; then
        # ShellCheck: SC2129 - Group redirects
        {
            echo ""
            echo "# Burp Suite Professional"
            echo "alias burpsuite-pro='/usr/local/bin/burpsuite-pro'"
        } >> ~/.zshrc
    fi
fi

if [ -f /root/.zshrc ]; then
    if ! sudo grep -q "alias burpsuite-pro" /root/.zshrc; then
        {
            echo ""
            echo "# Burp Suite Professional"
            echo "alias burpsuite-pro='/usr/local/bin/burpsuite-pro'"
        } | sudo tee -a /root/.zshrc > /dev/null
    fi
fi
echo -e "${CHECK} Alias configurado"

# Limpiar entradas de escritorio duplicadas
echo -e "${ARROW} Limpiando entradas duplicadas..."
sudo rm -f /usr/share/applications/burpsuite-pro.desktop 2>/dev/null || true
sudo rm -f ~/.local/share/applications/burpsuite-pro.desktop 2>/dev/null || true

# Crear entrada de escritorio única
echo -e "${ARROW} Creando entrada de escritorio..."
sudo tee /usr/share/applications/burpsuite-professional.desktop > /dev/null <<EOF
[Desktop Entry]
Version=1.0
Name=Burp Suite Professional
Comment=Web Application Security Testing
Exec=/usr/local/bin/burpsuite-pro
Icon=burpsuite
Terminal=false
Type=Application
Categories=Development;Security;Network;
StartupNotify=true
EOF
echo -e "${CHECK} Entrada de escritorio creada y habilitada"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  ${CHECK} ${GREEN}Burp Suite Professional instalado correctamente!${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

#==============================================================================
# ACTIVACIÓN MANUAL DE LICENCIA
#==============================================================================

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${INFO} ${CYAN}ACTIVACIÓN DE LICENCIA REQUERIDA${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠${NC}  Burp Suite requiere activación manual la primera vez"
echo ""
echo -e "${INFO} ${CYAN}Pasos para activar:${NC}"
echo -e "  ${ARROW} Se abrirá el BurpLoaderKeygen"
echo -e "  ${ARROW} Haz clic en ${YELLOW}'Run'${NC} para iniciar Burp Suite"
echo -e "  ${ARROW} En Burp, ve a ${YELLOW}'Manual activation'${NC}"
echo -e "  ${ARROW} Copia la ${YELLOW}'License Request'${NC} al keygen"
echo -e "  ${ARROW} Copia la ${YELLOW}'License Response'${NC} a Burp"
echo -e "  ${ARROW} Haz clic en ${YELLOW}'Next'${NC} para activar"
echo ""
echo -e "${YELLOW}¿Deseas realizar la activación ahora? (S/n)${NC}"
read -r -n 1 activate_now
echo ""

if [[ "$activate_now" =~ ^[Ss]$ ]] || [[ -z "$activate_now" ]]; then
    echo -e "${ARROW} Iniciando BurpLoaderKeygen..."
    echo -e "${INFO} ${CYAN}Sigue los pasos de activación en la ventana que se abrirá${NC}"
    echo ""
    
    # Iniciar el loader en segundo plano
    cd "$BURP_DIR"
    java -jar BurpLoaderKeygen.jar &
    BURP_PID=$!
    
    echo -e "${INFO} Presiona ${YELLOW}ENTER${NC} cuando hayas completado la activación..."
    echo -e "${INFO} O presiona ${YELLOW}Ctrl+C${NC} si deseas cancelar"
    
    # Esperar a que el usuario complete la activación
    if read -r; then
        echo ""
        echo -e "${CHECK} ${GREEN}Activación completada${NC}"
        
        # Intentar cerrar el loader si sigue abierto
        if kill -0 $BURP_PID 2>/dev/null; then
            kill $BURP_PID 2>/dev/null || true
        fi
    else
        # Usuario canceló (Ctrl+C)
        echo ""
        echo -e "${YELLOW}⚠${NC}  Activación cancelada por el usuario"
        
        # Cerrar el loader
        if kill -0 $BURP_PID 2>/dev/null; then
            kill $BURP_PID 2>/dev/null || true
        fi
    fi
else
    echo -e "${INFO} Activación manual omitida"
    echo -e "${INFO} Podrás activar Burp Suite más tarde ejecutando: ${YELLOW}burpsuite-pro${NC}"
fi

echo ""
echo -e "${INFO} ${CYAN}Cómo usar Burp Suite:${NC}"
echo -e "  ${ARROW} Ejecuta: ${YELLOW}burpsuite-pro${NC}"
echo -e "  ${ARROW} O búscalo en el menú de aplicaciones"
echo ""
echo -e "${INFO} ${CYAN}Ubicación:${NC} ${BURP_DIR}"
echo ""
