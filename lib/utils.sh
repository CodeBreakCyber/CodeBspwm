# Utility helpers for installer (logging, prompts, safe operations)
# shellcheck shell=bash

#==============================================================================
# COLORES PROFESIONALES (Visibles en cualquier fondo)
#==============================================================================

# ShellCheck: SC2034 - Colors are for export to scripts
# shellcheck disable=SC2034
RESET='\033[0m'
# shellcheck disable=SC2034
BOLD='\033[1m'
# shellcheck disable=SC2034
CYAN='\033[38;5;80m'
# shellcheck disable=SC2034
GREEN='\033[38;5;78m'
# shellcheck disable=SC2034
YELLOW='\033[38;5;186m'
# shellcheck disable=SC2034
RED='\033[38;5;203m'
# shellcheck disable=SC2034
BLUE='\033[38;5;111m'
# shellcheck disable=SC2034
MAGENTA='\033[38;5;176m'
# shellcheck disable=SC2034
ORANGE='\033[38;5;214m'
# shellcheck disable=SC2034
PURPLE='\033[38;5;183m'
# shellcheck disable=SC2034
TURQUOISE='\033[38;5;116m'
# shellcheck disable=SC2034
GRAY='\033[38;5;246m'
# shellcheck disable=SC2034
LAVENDER='\033[38;5;183m'

# Iconos Nerd Font (no emojis)
ICON_CHECK=""
ICON_CROSS=""
ICON_ARROW=""
ICON_INFO=""
ICON_WARN=""
ICON_PACKAGE=""
ICON_DOWNLOAD=""
ICON_COG=""
ICON_FOLDER=""

#==============================================================================
# FUNCIONES DE OUTPUT
#==============================================================================

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║        ██╗  ██╗ █████╗ ██╗     ██╗██████╗ ███████╗       ║
    ║        ██║ ██╔╝██╔══██╗██║     ██║██╔══██╗██╔════╝       ║
    ║        █████╔╝ ███████║██║     ██║██████╔╝███████╗       ║
    ║        ██╔═██╗ ██╔══██║██║     ██║██╔══██╗╚════██║       ║
    ║        ██║  ██╗██║  ██║███████╗██║██████╔╝███████║       ║
    ║        ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═════╝ ╚══════╝       ║
    ║                                                           ║
    ║                  BSPWM Environment Setup                 ║
    ║                      Version 2.0                          ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
}

print_section() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}  ${BOLD}$1${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

print_step() { echo -e "  ${ORANGE}${ICON_ARROW}${RESET} ${ORANGE}$1${RESET}"; }
print_success() { echo -e "  ${GREEN}${ICON_CHECK}${RESET} ${GREEN}$1${RESET}"; }
print_error() { echo -e "  ${RED}${ICON_CROSS}${RESET} ${RED}$1${RESET}" >&2; }
print_info() { echo -e "  ${BLUE}${ICON_INFO}${RESET} $1"; }
print_warning() { echo -e "  ${YELLOW}${ICON_WARN}${RESET} ${YELLOW}$1${RESET}"; }
print_package() { echo -e "  ${MAGENTA}${ICON_PACKAGE}${RESET} ${MAGENTA}$1${RESET}"; }
print_download() { echo -e "  ${PURPLE}${ICON_DOWNLOAD}${RESET} ${PURPLE}$1${RESET}"; }
print_config() { echo -e "  ${TURQUOISE}${ICON_COG}${RESET} ${TURQUOISE}$1${RESET}"; }
print_path() { echo -e "  ${GRAY}${ICON_FOLDER}${RESET} ${GRAY}$1${RESET}"; }

#==============================================================================
# FUNCIONES DE UTILIDAD
#==============================================================================

prompt_yes_no() {
    local msg="$1"
    local default=${2:-no}
    if [[ "${FORCE_YES:-0}" -eq 1 ]]; then
        return 0
    fi
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        print_info "DRY-RUN: prompt '${msg}' -> ${default}"
        [[ "$default" == "yes" ]] && return 0 || return 1
    fi
    while true; do
        read -r -p "$msg [y/N]: " ans
        case "$ans" in
            [YySs]*) return 0 ;;
            [Nn]*|"") return 1 ;;
            *) echo "Por favor responde s (sí) o n (no)." ;;
        esac
    done
}

# ShellCheck: SC2294 - eval negates array benefit, but used here for flexible command execution
# shellcheck disable=SC2294
run_cmd() {
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        print_info "DRY-RUN: $*"
        return 0
    fi
    eval "$@"
}

is_command() { command -v "$1" &>/dev/null; }

safe_cp() {
    local src="$1" dst="$2"
    if [[ -d "$src" ]]; then
        mkdir -p "$dst"
        cp -a "$src"/. "$dst" || return 1
    else
        cp -a "$src" "$dst" || return 1
    fi
}

backup_path() {
    local target="$1"
    local ts
    ts=$(date +%Y%m%d-%H%M%S)
    echo "${HOME}/.backup-$(basename "$target")-${ts}.tar.gz"
}
