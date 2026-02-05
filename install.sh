#!/usr/bin/env bash
#==============================================================================
# KaliBspwm - Instalador Profesional
# Versión: 2.1
# Descripción: Script de instalación automatizada para entorno BSPWM en Kali
# Autor: CodeBreak
# Repositorio: https://github.com/CodeBreakCyber/CodeBspwm
#==============================================================================

set -euo pipefail

#==============================================================================
# INICIALIZACIÓN - Detectar directorio del proyecto + flags
#==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${XDG_CONFIG_HOME:=$HOME/.config}"

# CLI flags: --yes, --dry-run, --backup, --install-dir
DRY_RUN=0
# ShellCheck: SC2034 - Suppress unused variable (intended for future use)
# shellcheck disable=SC2034
export FORCE_YES=0
DO_BACKUP=1
INSTALL_DIR="${SCRIPT_DIR}"

while [[ ${#} -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --yes|-y) FORCE_YES=1; shift ;;
        --no-backup) DO_BACKUP=0; shift ;;
        --install-dir) INSTALL_DIR="$2"; shift 2 ;;
        --help|-h) echo "Usage: $0 [--dry-run] [--yes] [--no-backup] [--install-dir PATH]"; exit 0 ;;
        *) break ;;
    esac
done

# Prefer library files from repo; provide minimal fallback only if absolutely required
if [[ -f "${SCRIPT_DIR}/lib/config.sh" ]]; then
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/lib/config.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/lib/utils.sh"
else
    # Minimal, safe fallback (keeps installer usable for quick fixes).
    # ShellCheck: SC2317 - Suppress unreachable warnings for fallback block
    # shellcheck disable=SC2317
    {
    echo "Aviso: lib/utils.sh no encontrada. Usando fallback mínimo. Considera restaurar 'lib/utils.sh' desde el repo." >&2
    print_banner() { clear; echo "== KaliBspwm Installer (fallback) =="; }
    print_section() { echo; echo "== $1 =="; echo; }
    print_step() { echo "- $1"; }
    print_success() { echo "[OK] $1"; }
    print_error() { echo "[ERROR] $1" >&2; }
    print_info() { echo "[INFO] $1"; }
    print_warning() { echo "[WARN] $1"; }
    install_package() { if [[ $DRY_RUN -eq 1 ]]; then print_info "DRY-RUN: apt install -y $1"; else sudo apt install -y "$1"; fi }
    install_packages() { for p in "$@"; do install_package "$p"; done; }
    release_apt_lock() { sudo killall -9 apt apt-get dpkg 2>/dev/null || true; sudo rm -f /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/lib/dpkg/lock-frontend /var/cache/apt/archives/lock || true; sudo dpkg --configure -a || true; }
    is_command() { command -v "$1" &>/dev/null; }
    has_internet() { ping -c 1 -W 3 8.8.8.8 &>/dev/null || ping -c 1 -W 3 1.1.1.1 &>/dev/null; }
    is_debian_based() { [[ -f /etc/debian_version ]]; }
    has_disk_space() { df / | awk 'NR==2 {print $4}' | awk '{exit ($1 < 2000000)}'; }
    }
fi

# Normalize INSTALL_DIR (allow --install-dir)
INSTALL_DIR="$(cd "${INSTALL_DIR}" && pwd)"
print_info "Install dir: ${INSTALL_DIR}"

# Asegurar que las funciones de validación estén disponibles
is_command() { command -v "$1" &>/dev/null; }
is_debian_based() { [[ -f /etc/debian_version ]]; }
has_disk_space() { df / | awk 'NR==2 {print $4}' | awk '{exit ($1 < 2000000)}'; }
has_internet() { ping -c 1 -W 3 8.8.8.8 &>/dev/null || ping -c 1 -W 3 1.1.1.1 &>/dev/null; }
get_disk_space() { df -h / | awk 'NR==2 {print $4}'; }
release_apt_lock() { sudo killall -9 apt apt-get dpkg 2>/dev/null || true; sudo rm -f /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/lib/dpkg/lock-frontend /var/cache/apt/archives/lock || true; sudo dpkg --configure -a || true; }


# Compatibilidad: adaptadores a nombres usados históricamente en install.sh
is_installed() { is_command "$1"; }
is_polybar_installed() { is_command polybar; }
is_bspwm_configured() { [[ -f "${HOME}/.config/bspwm/bspwmrc" && -f "${HOME}/.config/sxhkd/sxhkdrc" ]]; }
is_burpsuite_pro_installed() { [[ -f "${BURPSUITE_INSTALL_DIR:-/opt/burpsuite-pro}/BurpLoaderKeygen.jar" || -f /opt/burpsuite-pro/BurpLoaderKeygen.jar ]]; }
is_caido_installed() { [[ -f "${CAIDO_INSTALL_DIR:-/opt/caido}/caido.AppImage" || -f /opt/caido/caido.AppImage ]]; }
is_zram_configured() { systemctl is-enabled zramswap &>/dev/null || systemctl is-active zramswap &>/dev/null; }

skip_if_installed() {
    local name=$1
    local check_command=$2
    if eval "$check_command"; then
        print_warning "$name ya está instalado, omitiendo..."
        return 0
    fi
    return 1
}

check_apt_lock() {
    print_step "Verificando bloqueos de APT..."
    release_apt_lock || true
    print_success "APT liberado y listo"
}

check_root() {
    if is_command id && is_command awk; then :; fi
    if [[ "$(id -u)" -eq 0 ]]; then
        print_error "No ejecutes este script como root"
        print_info "Usa: ./install.sh"
        exit 1
    fi
}

check_distro() {
    if ! is_debian_based; then
        print_error "Este script solo funciona en distribuciones basadas en Debian/Kali"
        exit 1
    fi
}

check_internet() {
    print_step "Verificando conexión a Internet..."
    if ! has_internet; then
        print_error "No hay conexión a Internet"
        exit 1
    fi
    print_success "Conexión a Internet OK"
}

check_disk_space() {
    print_step "Verificando espacio en disco..."
    if ! has_disk_space; then
        print_error "Espacio insuficiente. Se requieren al menos 2GB"
        print_info "Disponible: $(get_disk_space || echo 'desconocido')"
        exit 1
    fi
    print_success "Espacio en disco suficiente ($(get_disk_space))"
}

# Valores por defecto para símbolos usados en prompts (en caso de fallback)
: "${ARROW:='➜'}"
: "${CHECK:='✓'}"
: "${CROSS:='✗'}"
: "${STAR:='★'}"
: "${INFO:='ℹ'}"

#==============================================================================
# INSTALACIÓN DE DEPENDENCIAS
#==============================================================================

update_system() {
    print_section "ACTUALIZACIÓN DE SISTEMA"
    
    print_info "¿Deseas buscar y aplicar actualizaciones del sistema?"
    read -p "$(echo -e "${ARROW} (S/n): ")" -n 1 -r
    echo ""
    if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then
        print_step "Actualizando lista de paquetes..."
        sudo apt update -qq
        print_success "Lista de paquetes actualizada"
        
        print_step "Actualizando paquetes del sistema..."
        sudo apt upgrade -y
        print_success "Sistema actualizado"
    else
        print_info "Actualización omitida por el usuario"
    fi
}

show_disk_space() {
    local YELLOW='\033[1;33m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'
    # ShellCheck: SC2155 - Split assignment
    local available
    available=$(df / | awk 'NR==2 {print $4}')
    local used
    used=$(df / | awk 'NR==2 {print $3}')
    local available_gb
    available_gb=$(awk "BEGIN {printf \"%.1f\", $available/1024/1024}")
    local used_gb
    used_gb=$(awk "BEGIN {printf \"%.1f\", $used/1024/1024}")
    
    echo -e "  ${YELLOW}\uf0a0${NC} Espacio: ${YELLOW}${used_gb}GB usado${NC} | ${GREEN}${available_gb}GB disponible${NC}"
}

install_base_dependencies() {
    print_section "INSTALANDO DEPENDENCIAS BASE"
    
    local packages=(
        "build-essential"
        "git"
        "vim"
        "curl"
        "wget"
    )
    
    local packages_to_install=()
    for package in "${packages[@]}"; do
        packages_to_install+=("$package")
    done
    
    if [ ${#packages_to_install[@]} -gt 0 ]; then
        print_step "Instalando dependencias base en lote..."
        if sudo apt install -y "${packages_to_install[@]}"; then
            print_success "Dependencias base instaladas correctamente"
        else
            print_error "Fallo al instalar dependencias base. Verifica tu conexión a internet o bloqueos de apt."
            exit 1
        fi
    fi
}

install_bspwm_dependencies() {
    print_section "INSTALANDO DEPENDENCIAS DE BSPWM"
    
    print_step "Instalando librerías de desarrollo..."
    sudo apt install -y \
        xcb libxcb-util0-dev libxcb-ewmh-dev libxcb-randr0-dev \
        libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-xinerama0-dev \
        libasound2-dev libxcb-xtest0-dev libxcb-shape0-dev
    print_success "Librerías de desarrollo instaladas"
}

install_polybar_dependencies() {
    print_section "INSTALANDO DEPENDENCIAS DE POLYBAR"
    
    print_step "Instalando dependencias de compilación..."
    sudo apt install -y \
        cmake cmake-data pkg-config python3-sphinx libcairo2-dev \
        libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev \
        python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev \
        libxcb-icccm4-dev libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev \
        libasound2-dev libpulse-dev libjsoncpp-dev libmpdclient-dev \
        libuv1-dev libnl-genl-3-dev
    print_success "Dependencias de Polybar instaladas"
}

install_picom_dependencies() {
    print_section "INSTALANDO DEPENDENCIAS DE PICOM"
    
    print_step "Instalando Picom y dependencias..."
    sudo apt install -y \
        meson picom libxext-dev libxcb1-dev libxcb-damage0-dev libxcb-dpms0-dev \
        libxcb-xfixes0-dev libxcb-shape0-dev libxcb-render-util0-dev \
        libxcb-render0-dev libxcb-composite0-dev libxcb-image0-dev \
        libxcb-present-dev libxcb-xinerama0-dev libpixman-1-dev \
        libdbus-1-dev libconfig-dev libgl1-mesa-dev libpcre2-dev \
        libevdev-dev uthash-dev libev-dev libx11-xcb-dev libxcb-glx0-dev \
        libpcre3 libpcre3-dev libepoxy-dev
    print_success "Dependencias de Picom instaladas"
}

install_additional_packages() {
    print_section "INSTALANDO COMPONENTES DEL ENTORNO Y UTILIDADES"
    
    local packages=(
        "kitty:Terminal moderno"
        "feh:Gestor de wallpapers"
        "scrot:Capturas de pantalla"
        "scrub:Borrado seguro"
        "rofi:Lanzador de aplicaciones"
        "xclip:Portapapeles"
        "bat:Cat mejorado"
        "locate:Búsqueda de archivos"
        "ranger:Gestor de archivos"
        "fastfetch:Alternativa moderna a Neofetch"
        "suckless-tools:Herramientas (incluye wmname para Java)"
        "acpi:Info de batería"
        "bspwm:Window Manager"
        "sxhkd:Gestor de atajos"
        "imagemagick:Procesamiento de imágenes"
        "cmatrix:Efectos visuales"
        "iproute2:Herramientas de red modernas"
        "network-manager:Gestor de red"
        "pulseaudio:Sistema de audio"
        "pulseaudio-utils:Utilidades de audio"
        "pavucontrol:Control de volumen"
        "alsa-utils:Utilidades ALSA"
        "htop:Monitor de procesos"
        "btop:Monitor de sistema moderno"
        "lm-sensors:Sensores del sistema"
        "zram-tools:Optimización de memoria"
        "xdotool:Automatización X11"
        "jq:Procesador JSON"
        "dunst:Notificaciones"
        "libnotify-bin:Envío de notificaciones"
        "brightnessctl:Control de brillo"
        "fonts-noto:Fuentes Noto"
        "fonts-noto-color-emoji:Emojis"
        "fonts-font-awesome:Iconos Font Awesome"
        "default-jdk:Java Development Kit"
        "i3lock-color:Bloqueo de pantalla"
    )
    
    local packages_list=()
    
    for package_info in "${packages[@]}"; do
        local package="${package_info%%:*}"
        packages_list+=("$package")
    done
    
    if [ ${#packages_list[@]} -gt 0 ]; then
        print_step "Instalando componentes y utilidades en una sola transacción (Optimizado)..."
        # Instalación en bloque para eficiencia (O(1) transacción vs O(n))
        if sudo apt install -y "${packages_list[@]}"; then
            print_success "Todos los componentes instalados correctamente"
        else
            print_error "Fallo al instalar componentes adicionales. Revisa el log de apt anterior."
            exit 1
        fi
    fi
}

#==============================================================================
# COMPILACIÓN E INSTALACIÓN
#==============================================================================

install_polybar() {
    print_section "COMPILANDO E INSTALANDO POLYBAR"
    
    mkdir -p ~/github
    cd ~/github
    
        if [ ! -d "polybar" ]; then
        print_step "Clonando repositorio de Polybar..."
        git clone --recursive https://github.com/polybar/polybar
        print_success "Repositorio clonado"
    fi
    
    cd polybar
    print_step "Compilando Polybar (esto puede tardar unos minutos)..."
    mkdir -p build
    cd build
    cmake .. -DBUILD_DOC=OFF -DBUILD_TESTS=OFF
    print_step "Configurando Polybar..."
    # ShellCheck: SC2046 - Quote this
    make -j"$(nproc)"
    print_step "Compilando Polybar..."
    print_success "Polybar compilado"
    
    print_step "Instalando Polybar..."
    sudo make install
    print_success "Polybar instalado"
    
    # Limpieza para ahorrar espacio
    cd ~/github
    rm -rf polybar
    print_success "Limpieza de archivos de compilación completada"
}

install_picom_from_source() {
    print_section "COMPILANDO E INSTALANDO PICOM"
    
    mkdir -p ~/github
    cd ~/github
    
    if [ ! -d "picom" ]; then
        print_step "Clonando repositorio de Picom..."
        git clone https://github.com/FT-Labs/picom.git
        print_success "Repositorio clonado"
    fi
    
    cd picom
    print_step "Actualizando submódulos..."
    git submodule update --init --recursive
    print_success "Submódulos actualizados"
    
    print_step "Compilando Picom..."
    meson --buildtype=release . build
    print_step "Configurando Picom..."
    ninja -C build
    print_step "Compilando Picom..."
    print_success "Picom compilado"
    
    print_step "Instalando Picom..."
    sudo ninja -C build install
    print_success "Picom instalado"
    
    # Limpieza para ahorrar espacio
    cd ~/github
    rm -rf picom
    print_success "Limpieza de archivos de compilación completada"
}

#==============================================================================
# CONFIGURACIÓN DE SHELL
#==============================================================================

# Usar SCRIPT_DIR que ya fue definido al inicio
INSTALL_DIR="${SCRIPT_DIR}"

install_powerlevel10k() {
    print_section "INSTALANDO POWERLEVEL10K"
    
    print_step "Clonando Powerlevel10k para usuario..."
    rm -rf ~/.powerlevel10k
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k
    print_success "Powerlevel10k clonado para usuario"
    
    print_step "Clonando Powerlevel10k para root..."
    sudo rm -rf /root/.powerlevel10k
    sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.powerlevel10k
    print_success "Powerlevel10k clonado para root"
}

install_zsh_plugins() {
    print_section "INSTALANDO PLUGINS DE ZSH"
    
    print_step "Instalando zsh-syntax-highlighting..."
    sudo apt install -y zsh-syntax-highlighting
    print_success "zsh-syntax-highlighting instalado"
    
    print_step "Instalando zsh-autosuggestions..."
    sudo apt install -y zsh-autosuggestions
    print_success "zsh-autosuggestions instalado"
    
    print_step "Instalando plugin sudo..."
    sudo mkdir -p /usr/share/zsh-sudo
    sudo wget -q https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh \
        -O /usr/share/zsh-sudo/sudo.plugin.zsh
    print_success "Plugin sudo instalado"
}

#==============================================================================
# CONFIGURACIÓN DE ARCHIVOS
#==============================================================================

setup_directories() {
    print_section "CONFIGURANDO DIRECTORIOS"

    local src="${INSTALL_DIR}/Wallpaper"
    local dst="${HOME}/Pictures/Wallpapers"

    print_step "Creando directorio de Wallpapers (${dst})..."
    if [[ $DRY_RUN -eq 1 ]]; then
        print_info "DRY-RUN: mkdir -p ${dst}"
    else
        mkdir -p "${dst}"
    fi

    if [[ -d "${src}" && $(ls -A "${src}" 2>/dev/null) ]]; then
        print_step "Copiando wallpapers desde ${src} -> ${dst} (preservando permisos)..."
        if [[ $DRY_RUN -eq 1 ]]; then
            print_info "DRY-RUN: cp -v ${src}/* ${dst}/"
        else
            cp -v "${src}"/* "${dst}/" 2>/dev/null || print_warning "Algunos wallpapers no se copiaron (permisos/archivos vacíos)"
        fi
        print_success "Wallpapers copiados"
    else
        print_warning "No se encontraron wallpapers en ${src}; se omite copia"
    fi

    print_step "Creando directorio de Screenshots (~/${XDG_CONFIG_HOME##*/})..."
    if [[ $DRY_RUN -eq 1 ]]; then
        print_info "DRY-RUN: mkdir -p ${HOME}/ScreenShots"
    else
        mkdir -p "${HOME}/ScreenShots"
    fi
    print_success "Directorio de Screenshots creado"
}

install_fonts() {
    print_section "INSTALANDO FUENTES"

    local src_fonts_dir="${INSTALL_DIR}/fonts/HNF"
    local dst_user="${HOME}/.local/share/fonts/HNF"
    # ShellCheck: SC2034 - Intentional unused (planned system-wide install)
    # shellcheck disable=SC2034
    local dst_sys="/usr/local/share/fonts/HNF"

    if [[ -d "${src_fonts_dir}" && $(ls -A "${src_fonts_dir}" 2>/dev/null) ]]; then
        print_step "Instalando HackNerd Fonts (usuario -> ${dst_user})..."
        if [[ $DRY_RUN -eq 1 ]]; then
            print_info "DRY-RUN: cp -r ${src_fonts_dir}/* ${dst_user}/"
        else
            mkdir -p "${dst_user}"
            cp -rf "${src_fonts_dir}/"* "${dst_user}/" || print_warning "Algunos archivos de fuente no pudieron copiarse"
        fi
        print_success "HackNerd Fonts instaladas (usuario)"
    else
        print_warning "No se encontraron fuentes HackNerd en ${src_fonts_dir}; omitiendo"
    fi

    # Polybar fonts (try user first, fallback to system)
    local polybar_fonts_src="${INSTALL_DIR}/Config/polybar/fonts"
    if [[ -d "${polybar_fonts_src}" ]]; then
        print_step "Instalando fuentes de Polybar al directorio de usuario..."
        if [[ $DRY_RUN -eq 1 ]]; then
            print_info "DRY-RUN: cp -r ${polybar_fonts_src}/* ${HOME}/.local/share/fonts/"
        else
            mkdir -p "${HOME}/.local/share/fonts/"
            cp -rf "${polybar_fonts_src}/"* "${HOME}/.local/share/fonts/" || sudo cp -rf "${polybar_fonts_src}/"* /usr/share/fonts/truetype/polybar/ || true
        fi
        print_success "Fuentes de Polybar instaladas"
    else
        print_warning "No se encontró ${polybar_fonts_src}; omitiendo instalación de fuentes de Polybar"
    fi

    print_step "Actualizando caché de fuentes..."
    if [[ $DRY_RUN -eq 1 ]]; then
        print_info "DRY-RUN: fc-cache -f"
    else
        fc-cache -f || true
    fi
    print_success "Caché de fuentes actualizado"
}

setup_configs() {
    print_section "INSTALANDO CONFIGURACIONES"

    local src_config_dir="${INSTALL_DIR}/Config"
    local dst_config_dir="${XDG_CONFIG_HOME}"
    local ts
    ts=$(date +%Y%m%d-%H%M%S)

    if [[ ! -d "${src_config_dir}" ]]; then
        print_error "No se encontró ${src_config_dir}; abortando configuración"
        return 1
    fi

    if [[ -d "${dst_config_dir}" && "$DO_BACKUP" -eq 1 && "$DRY_RUN" -eq 0 ]]; then
        local backup_file="${HOME}/.config-backup-kalibspwm-${ts}.tar.gz"
        print_step "Creando backup de ${dst_config_dir} -> ${backup_file}"
        tar -czf "${backup_file}" -C "${HOME}" ".config" || print_warning "No se pudo crear backup completo"
        print_success "Backup creado: ${backup_file}"
    else
        print_info "No se creó backup (ya inexistente, dry-run o --no-backup)"
    fi

    print_step "Copiando configuraciones a ${dst_config_dir} (se preservarán permisos)"
    if [[ $DRY_RUN -eq 1 ]]; then
        print_info "DRY-RUN: rsync -a --exclude='*.bak' ${src_config_dir}/ ${dst_config_dir}/"
    else
        mkdir -p "${dst_config_dir}"
        rsync -a --exclude='.git' --exclude='README.md' "${src_config_dir}/" "${dst_config_dir}/"
        # Asegurar que los scripts sean ejecutables
        find "${dst_config_dir}" -type f -name "*.sh" -exec chmod +x {} \; || true
    fi
    print_success "Configuraciones copiadas"

    # Fix crítico: Asegurar temas de Rofi
    print_step "Restaurando temas de Rofi (Wifi/Power)..."
    mkdir -p ~/.config/rofi/themes
    cp -r "${src_config_dir}/rofi/themes/"* ~/.config/rofi/themes/
    print_success "Temas de Rofi asegurados"

    if [[ -f "${INSTALL_DIR}/lsd.deb" ]]; then
        print_step "Instalando LSD (si aplica)"
        if command -v lsd &>/dev/null; then
             print_info "LSD ya está instalado, omitiendo .deb local"
        else
            if [[ $DRY_RUN -eq 1 ]]; then
                print_info "DRY-RUN: dpkg -i ${INSTALL_DIR}/lsd.deb"
            else
                sudo dpkg -i "${INSTALL_DIR}/lsd.deb" &> /dev/null || true
            fi
            print_success "LSD (operación intentada)"
        fi
    fi
}

setup_shell_configs() {
    print_section "CONFIGURANDO SHELL"
    
    local ruta="$INSTALL_DIR"
    
    print_step "Configurando .zshrc para usuario..."
    rm -rf ~/.zshrc
    cp "$ruta"/.zshrc ~/.zshrc
    cp "$ruta"/.p10k.zsh ~/.p10k.zsh
    print_success "Shell de usuario configurado"
    
    print_step "Configurando .zshrc para root..."
    sudo cp "$ruta"/.p10k.zsh-root /root/.p10k.zsh
    sudo ln -sf ~/.zshrc /root/.zshrc
    print_success "Shell de root configurado"
}

setup_scripts() {
    print_section "INSTALANDO SCRIPTS"
    
    local ruta="$INSTALL_DIR"
    
    print_step "Instalando whichSystem.sh..."
    sudo cp "$ruta"/Config/bin/whichSystem.sh /usr/local/bin/
    sudo chmod +x /usr/local/bin/whichSystem.sh
    print_success "whichSystem.sh instalado"
    
    print_step "Instalando script de screenshot..."
    sudo cp "$ruta"/Config/bin/screenshot.sh /usr/local/bin/screenshot
    sudo chmod +x /usr/local/bin/screenshot
    print_success "Script de screenshot instalado"
}

set_permissions() {
    print_section "CONFIGURANDO PERMISOS"
    
    print_step "Asignando permisos a scripts de BSPWM..."
    chmod +x ~/.config/bspwm/bspwmrc
    chmod +x ~/.config/bspwm/scripts/bspwm_resize
    chmod +x ~/.config/bspwm/scripts/move_win.sh
    print_success "Permisos de BSPWM configurados"
    
    print_step "Asignando permisos a scripts de Polybar..."
    chmod +x ~/.config/bin/ethernet_status.sh
    chmod +x ~/.config/bin/htb_status.sh
    chmod +x ~/.config/bin/htb_target.sh
    chmod +x ~/.config/polybar/launch.sh
    print_success "Permisos de Polybar configurados"
}

setup_i3lock() {
    print_section "CONFIGURANDO I3LOCK"
    
    local ruta="$INSTALL_DIR"
    
    print_step "Instalando i3lock-everblush..."
    sudo cp -R "$ruta"/Components/i3lock-color-everblush/i3lock-everblush /usr/bin
    sudo chmod +x /usr/bin/i3lock-everblush
    print_success "i3lock-everblush instalado"
    
    print_step "Configurando comando de bloqueo..."
    xfconf-query --create -c xfce4-session -p /general/LockCommand -t string -s "i3lock-everblush" &> /dev/null || true
    print_success "Comando de bloqueo configurado"
}

#==============================================================================
# EXTRAS Y PERSONALIZACIÓN
#==============================================================================

install_burpsuite_pro() {
    print_section "INSTALANDO BURP SUITE PROFESSIONAL"

    local ruta="$INSTALL_DIR"
    
    # El script install_burpsuite_pro.sh maneja la validación y pregunta al usuario
    chmod +x "$ruta/scripts/install_burpsuite_pro.sh"
    "$ruta/scripts/install_burpsuite_pro.sh"
}

install_caido() {
    print_section "INSTALANDO CAIDO"

    # Verificar si ya está instalado
    if skip_if_installed "Caido" "is_caido_installed"; then
        return 0
    fi
    
    local ruta="$INSTALL_DIR"
    
    print_step "Ejecutando instalador de Caido..."
    chmod +x "$ruta"/scripts/install_caido.sh
    "$ruta"/scripts/install_caido.sh
    print_success "Caido instalado"
}

setup_zram() {
    print_section "CONFIGURANDO ZRAM"

    # Verificar si ya está configurado
    if skip_if_installed "ZRAM" "is_zram_configured"; then
        return 0
    fi
    
    local ruta="$INSTALL_DIR"
    
    print_step "Ejecutando configuración de ZRAM..."
    chmod +x "$ruta"/scripts/setup_zram.sh
    "$ruta"/scripts/setup_zram.sh
    print_success "ZRAM configurado"
}

apply_system_optimizations() {
    print_section "APLICANDO OPTIMIZACIONES DEL SISTEMA"

    local ruta="$INSTALL_DIR"
    
    print_step "Ejecutando optimizaciones..."
    chmod +x "$ruta"/scripts/system_optimizations.sh
    "$ruta"/scripts/system_optimizations.sh
    print_success "Optimizaciones aplicadas"
}

setup_rofi_theme() {
    print_section "CONFIGURACIÓN DE ROFI (TEMA PEPA)"
    
    local ruta="$INSTALL_DIR"
    
    print_step "Configurando temas de Rofi..."
    mkdir -p ~/.config/rofi/themes
    
    # Copiar temas base y dependencias (.rasi)
    # ShellCheck: SC2088 - tilde expansion fix
    print_info "Ruta de destino: $HOME/.config/rofi/themes"
    
    # Copiar archivos individuales para asegurar que se copian las dependencias (colors.rasi, fonts.rasi)
    if [[ -d "$ruta/Config/polybar/scripts/themes" ]]; then
        cp "$ruta/Config/polybar/scripts/themes/"*.rasi ~/.config/rofi/themes/
        
        # Copiar shared themes si existen
        if [[ -d "$ruta/Config/polybar/scripts/themes/shared" ]]; then
             cp "$ruta/Config/polybar/scripts/themes/shared/"*.rasi ~/.config/rofi/themes/
        fi
        
        print_success "Temas copiados exitosamente"
    else
        print_error "No se encontró el directorio de temas en: $ruta/Config/polybar/scripts/themes"
    fi

    print_step "Instalando scripts de menús..."
    mkdir -p ~/.config/polybar/scripts
    cp "$ruta/Config/polybar/scripts/"*.sh ~/.config/polybar/scripts/
    chmod +x ~/.config/polybar/scripts/*.sh
    print_success "Scripts instalados y ejecutables"
}


setup_login_theme() {
    print_section "CONFIGURACIÓN DE PANTALLA DE LOGIN"
    
    local ruta="$INSTALL_DIR"
    
    print_step "Configurando Slick Greeter..."
    chmod +x "$ruta/scripts/install_login_theme.sh"
    "$ruta/scripts/install_login_theme.sh"
    print_success "Tema de login configurado"
}

#==============================================================================
# PERSONALIZACIÓN DE BOOT (Agregado v2.2)
#==============================================================================

setup_boot_customization() {
    print_section "PERSONALIZACIÓN DE ARRANQUE (BOOT)"
    
    print_info "¿Deseas aplicar la Personalización Visual del Arranque? (Plymouth Glitch + GRUB Tela + Sonido)"
    read -p "$(echo -e "${ARROW} (S/n): ")" -n 1 -r
    echo ""
    if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then
        
        # 1. Plymouth (Animación de carga)
        print_step "Instalando temas de Plymouth..."
        sudo apt install -y plymouth plymouth-themes
        
        # Clonar temas de adi1090x
        if [ ! -d "/usr/share/plymouth/themes/adi1090x-pack" ]; then 
            mkdir -p ~/github
            git clone https://github.com/adi1090x/plymouth-themes.git ~/github/plymouth-themes
            sudo cp -r ~/github/plymouth-themes/pack_3/* /usr/share/plymouth/themes/
            # Seleccionar tema 'glitch' (o 'abstract_ring_alt' como alternativa)
            sudo plymouth-set-default-theme -R glitch || print_warning "No se pudo establecer el tema glitch automáticamente"
        fi
        print_success "Plymouth configurado"

        # 2. GRUB Theme (Menú visual)
        print_step "Instalando tema visual para GRUB..."
        if [ ! -d "/tmp/grub2-themes" ]; then
            git clone https://github.com/vinceliuice/grub2-themes.git /tmp/grub2-themes
            cd /tmp/grub2-themes
            sudo ./install.sh -t tela -s 1080p -b
        fi
        print_success "Tema GRUB instalado"

        # 3. Sonido de Arranque
        print_step "Configurando sonido de arranque..."
        sudo apt install -y mpv
        
        # Script
        sudo tee /usr/local/bin/startup-sound.sh > /dev/null << 'EOF'
#!/bin/bash
SOUND_DIR="$HOME/.config/sound"
AUDIO_FILE=""
if [ -f "$SOUND_DIR/startup.mp3" ]; then AUDIO_FILE="$SOUND_DIR/startup.mp3"; 
elif [ -f "$SOUND_DIR/startup.wav" ]; then AUDIO_FILE="$SOUND_DIR/startup.wav"; fi

if [ -n "$AUDIO_FILE" ] && command -v mpv &>/dev/null; then
    mpv --no-video "$AUDIO_FILE" &
fi
exit 0
EOF
        sudo chmod +x /usr/local/bin/startup-sound.sh
        
        # Service
        sudo tee /etc/systemd/system/startup-sound.service > /dev/null << EOF
[Unit]
Description=Startup Sound
After=graphical.target

[Service]
Type=oneshot
User=$USER
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/$USER/.Xauthority
ExecStart=/usr/local/bin/startup-sound.sh

[Install]
WantedBy=graphical.target
EOF
        sudo systemctl enable startup-sound.service
        mkdir -p ~/.config/sound
        print_success "Servicio de sonido configurado (Coloca tu archivo en ~/.config/sound/startup.mp3)"

        # 4. Configurar /etc/default/grub
        print_step "Ajustando configuración de GRUB..."
        sudo sed -i 's/GRUB_TIMEOUT=0/GRUB_TIMEOUT=10/' /etc/default/grub
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' /etc/default/grub
        # Asegurar OS-Prober
        if grep -q "GRUB_DISABLE_OS_PROBER" /etc/default/grub; then
             sudo sed -i 's/GRUB_DISABLE_OS_PROBER=true/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
        else
             echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a /etc/default/grub
        fi
        sudo update-grub
        print_success "GRUB actualizado (TIMEOUT=10s)"
        
    else
        print_info "Personalización de Boot omitida"
    fi
}

#==============================================================================
# FUNCIÓN PRINCIPAL
#==============================================================================

main() {
    print_banner
    
    # Validaciones
    check_root
    check_distro
    check_internet
    check_disk_space
    check_apt_lock
    
    # Mostrar espacio inicial
    echo ""
    show_disk_space
    echo ""
    
    print_info "Iniciando instalación de KaliBspwm..."
    sleep 2
    
    # Actualización del sistema
    update_system
    echo ""
    show_disk_space
    
    # Instalación de dependencias
    install_base_dependencies
    echo ""
    show_disk_space
    
    install_bspwm_dependencies
    echo ""
    show_disk_space
    
    install_polybar_dependencies
    echo ""
    show_disk_space
    
    install_picom_dependencies
    echo ""
    show_disk_space
    
    install_additional_packages
    echo ""
    show_disk_space
    
    # Compilación e instalación
    install_polybar
    install_picom_from_source
    
    # Configuración de shell
    install_powerlevel10k
    install_zsh_plugins
    
    # Configuración de archivos
    setup_directories
    install_fonts
    setup_configs
    setup_rofi_theme
    setup_shell_configs
    setup_scripts
    
    print_step "Corrigiendo atajos en sxhkdrc..."
    sed -i 's|burpsuite-pro|/usr/local/bin/burpsuite-pro|g' ~/.config/sxhkd/sxhkdrc
    print_success "Atajos de sxhkd corregidos"
    
    set_permissions
    
    # Personalización de Boot (v2.2)
    setup_boot_customization
    
    setup_i3lock
    
    print_section "INSTALACIÓN COMPLETADA"
    # Configurar permisos de nuevos módulos
    print_step "Configurando permisos de nuevos módulos..."
    chmod +x ~/.config/bin/memory_module.sh
    chmod +x ~/.config/bin/volume_module.sh
    
    print_step "Configurando permisos de nuevos menús..."
    chmod +x ~/.config/polybar/scripts/launcher.sh
    chmod +x ~/.config/polybar/scripts/powermenu.sh
    chmod +x ~/.config/polybar/scripts/network_menu.sh
    print_success "Permisos configurados"
    
    # Limpieza
    print_section "LIMPIANDO ARCHIVOS TEMPORALES"
    
    # Regresar al directorio seguro antes de eliminar
    cd "$INSTALL_DIR"
    
    print_step "Eliminando repositorios temporales..."
    rm -rf ~/github
    print_success "Archivos temporales eliminados"
    
    # Instalaciones opcionales
    echo ""
    print_section "COMPONENTES OPCIONALES"
    echo ""
    
    # Burp Suite Professional
    print_info "¿Deseas instalar Burp Suite Professional?"
    print_warning "Incluye loader/keygen, Jython y JRuby"
    read -p "$(echo -e "${ARROW} (S/n): ")" -n 1 -r
    echo ""
    if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then
        install_burpsuite_pro
    else
        print_info "Burp Suite Professional omitido"
    fi
    
    echo ""
    
    # Caido
    print_info "¿Deseas instalar Caido?"
    print_warning "Proxy web moderno para pentesting"
    read -p "$(echo -e "${ARROW} (S/n): ")" -n 1 -r
    echo ""
    if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then
        install_caido
    else
        print_info "Caido omitido"
    fi
    
    echo ""
    
    # ZRAM
    print_info "¿Deseas configurar ZRAM?"
    print_warning "Recomendado para sistemas con 8GB RAM o menos"
    read -p "$(echo -e "${ARROW} (S/n): ")" -n 1 -r
    echo ""
    if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then
        setup_zram
    else
        print_info "ZRAM omitido"
    fi

    echo ""
    
    # Optimizaciones del sistema
    print_info "¿Deseas aplicar optimizaciones de rendimiento?"
    print_warning "CPU Governor, I/O Tuning, etc."
    read -p "$(echo -e "${ARROW} (S/n): ")" -n 1 -r
    echo ""
    if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then
        apply_system_optimizations
    else
        print_info "Optimizaciones omitidas"
    fi

    if pgrep -x "bspwm" > /dev/null; then
        print_step "Recargando BSPWM y SXHKD para aplicar cambios inmediatos..."
        bspc wm -r &>/dev/null || true
        pkill -USR1 -x sxhkd || sxhkd &>/dev/null &
        print_success "Entorno recargado"
    fi

    print_section "INSTALACIÓN FINALIZADA"
    print_success "KaliBspwm se ha instalado correctamente"
    print_info "Por favor, reinicie la sesión para aplicar los cambios"
}

# Ejecución
main "$@"
