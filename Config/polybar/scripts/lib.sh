#!/usr/bin/env bash
#==============================================================================
# Rofi API - Consistent interface for all menus
# Author: CodeBreak
# Principles: SOLID, DRY, Fail Fast, Defensive Programming
#==============================================================================

set -euo pipefail

#==============================================================================
# CONSTANTS (Inmutables para rendimiento)
#==============================================================================

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
readonly SCRIPT_DIR
readonly THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/themes"
readonly FALLBACK_THEME_DIR="${SCRIPT_DIR}/themes"

# Debug mode (activar con: DEBUG=1 script.sh)
readonly DEBUG="${DEBUG:-0}"

#==============================================================================
# HELPER FUNCTIONS (Funciones puras, sin side effects)
#==============================================================================

##
# Busca un tema en las ubicaciones estándar (XDG primero, fallback después)
# @param $1 Nombre del tema (ej: "launcher.rasi")
# @return Ruta completa del tema o cadena vacía si no existe
# @exit 0 si encontrado, 1 si no
##
theme_path() {
    local name="${1:-}"
    
    # Validación: null check
    if [[ -z "$name" ]]; then
        [[ "$DEBUG" -eq 1 ]] && echo "Warning: theme_path() llamado sin nombre de tema" >&2
        return 1
    fi
    
    # Buscar en directorio de usuario primero (XDG standard)
    if [[ -f "${THEME_DIR}/${name}" ]]; then
        echo "${THEME_DIR}/${name}"
        return 0
    fi
    
    # Fallback: directorio de scripts del proyecto
    if [[ -f "${FALLBACK_THEME_DIR}/${name}" ]]; then
        echo "${FALLBACK_THEME_DIR}/${name}"
        return 0
    fi
    
    # Tema no encontrado - logging solo en debug mode
    [[ "$DEBUG" -eq 1 ]] && echo "Warning: Tema '${name}' no encontrado en ${THEME_DIR} ni ${FALLBACK_THEME_DIR}" >&2
    return 1
}

##
# Verifica que las dependencias estén instaladas
# @param $@ Lista de comandos a verificar
# @return 0 si todos existen, 1 si falta alguno
##
check_deps() {
    local missing=()
    local cmd
    
    # Validación: al menos un comando
    if [[ $# -eq 0 ]]; then
        [[ "$DEBUG" -eq 1 ]] && echo "Warning: check_deps() llamado sin argumentos" >&2
        return 0
    fi
    
    # Verificar cada comando (optimizado: evitar subshells)
    for cmd in "$@"; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    
    # Reportar faltantes
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Dependencias faltantes: ${missing[*]}" >&2
        echo "Instala con: sudo apt install ${missing[*]}" >&2
        return 1
    fi
    
    return 0
}

#==============================================================================
# ROFI API - Funciones públicas (Interface Segregation)
#==============================================================================

##
# Genera argumentos base para rofi con tema y posicionamiento
# Usa variables de entorno para personalización: ROFI_THEME, ROFI_XOFF, ROFI_YOFF, ROFI_WIDTH
# @return Argumentos de rofi como array (optimizado para performance)
##
rofi_base_args() {
    local theme="${ROFI_THEME:-powermenu.rasi}"
    local theme_file
    local xoff="${ROFI_XOFF:-0}"
    local yoff="${ROFI_YOFF:-45}"
    local width="${ROFI_WIDTH:-20}"
    
    # Buscar tema con fallback automático
    if theme_file=$(theme_path "$theme" 2>/dev/null); then
        # Tema encontrado
        printf '%s\n' "-theme" "$theme_file" "-location" "1" "-yoffset" "$yoff" "-xoffset" "$xoff" "-width" "$width" "-no-lazy-grab"
    else
        # Fallback: usar tema por defecto de rofi (sin -theme)
        [[ "$DEBUG" -eq 1 ]] && echo "Info: Usando tema por defecto de rofi" >&2
        printf '%s\n' "-location" "1" "-yoffset" "$yoff" "-xoffset" "$xoff" "-width" "$width" "-no-lazy-grab"
    fi
}

##
# Menú dmenu genérico con argumentos base
# Función faltante que causaba error en network_menu.sh
# @param $@ Argumentos adicionales para rofi (ej: -mesg, -selected-row)
# @return Salida de rofi (opción seleccionada)
# @exit Código de salida de rofi
##
rofi_cmd() {
    # Validación: rofi debe estar instalado
    if ! command -v rofi &>/dev/null; then
        echo "Error: rofi no está instalado" >&2
        echo "Instala con: sudo apt install rofi" >&2
        return 1
    fi
    
    # Ejecutar rofi con argumentos base + argumentos adicionales
    rofi -dmenu "$(rofi_base_args)" "$@"
}

##
# Menú dmenu bajo icono con prompt personalizado
# @param $1 Prompt del menú
# @param $@ Argumentos adicionales para rofi
# @return Salida de rofi
##
rofi_cmd_under_icon() {
    local prompt="${1:-Menu}"
    shift 2>/dev/null || true  # Evitar error si no hay más argumentos
    
    # Validación: rofi instalado
    command -v rofi &>/dev/null || {
        echo "Error: rofi no está instalado" >&2
        return 1
    }
    
    rofi -dmenu -p "$prompt" "$(rofi_base_args)" "$@"
}

##
# Input de contraseña con rofi (modo password)
# @param $1 Prompt (default: "Password")
# @return Contraseña ingresada (sin echo)
##
rofi_password() {
    local prompt="${1:-Password}"
    
    # Validación: rofi instalado
    command -v rofi &>/dev/null || {
        echo "Error: rofi no está instalado" >&2
        return 1
    }
    
    rofi -dmenu -password -p "$prompt" "$(rofi_base_args)"
}

##
# Diálogo de confirmación Yes/No
# @param $1 Prompt (default: "Confirm")
# @return "Yes" o "No" (o vacío si se cancela)
##
rofi_confirm() {
    local prompt="${1:-Confirm}"
    
    # Validación: rofi instalado
    command -v rofi &>/dev/null || {
        echo "Error: rofi no está instalado" >&2
        return 1
    }
    
    # "No" seleccionado por defecto (seguridad)
    printf '%s\n%s' "No" "Yes" | rofi -dmenu -p "$prompt" "$(rofi_base_args)" -selected-row 0
}

##
# Wrapper para rofi -show (drun, run, window, ssh, combi)
# @param $1 Modo de rofi (drun, run, window, ssh, combi)
# @param $@ Argumentos adicionales
# @exit 0 si éxito, 1 si modo inválido
##
rofi_show() {
    local mode="${1:-drun}"
    shift 2>/dev/null || true
    
    # Validación: rofi instalado
    command -v rofi &>/dev/null || {
        echo "Error: rofi no está instalado" >&2
        return 1
    }
    
    # Validación: modo válido (fail fast)
    case "$mode" in
        drun|run|window|ssh|combi)
            rofi -show "$mode" "$(rofi_base_args)" "$@"
            ;;
        *)
            echo "Error: Modo de rofi inválido: '$mode'" >&2
            echo "Modos válidos: drun, run, window, ssh, combi" >&2
            return 1
            ;;
    esac
}

##
# Envía notificación si notify-send está disponible
# Fallback silencioso si no está instalado (no crítico)
# @param $@ Argumentos para notify-send
##
notify() {
    # Validación: notify-send opcional (no crítico)
    if command -v notify-send &>/dev/null; then
        notify-send "$@" 2>/dev/null || true
    else
        # Fallback silencioso - notificaciones son opcionales
        [[ "$DEBUG" -eq 1 ]] && echo "Info: notify-send no disponible, omitiendo notificación" >&2
    fi
}
