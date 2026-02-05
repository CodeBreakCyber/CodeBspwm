#!/usr/bin/env bash
#==============================================================================
# Menu Manager - Toggle de menús Rofi
# Descripción: Gestiona el comportamiento toggle de menús desplegables
#==============================================================================

set -euo pipefail

MENU_NAME="${1:-}"
MENU_CMD="${2:-}"
PID_DIR="${XDG_RUNTIME_DIR:-/tmp}/polybar_menus"
PID_FILE="${PID_DIR}/${MENU_NAME}.pid"

mkdir -p "${PID_DIR}"

# Kill existing menu -> toggle behavior: if running, kill and exit (toggle); else start
kill_existing_menu() {
    if [[ -f "${PID_FILE}" ]]; then
        local old_pid
        old_pid=$(<"${PID_FILE}")
        if kill -0 "${old_pid}" 2>/dev/null; then
            kill "${old_pid}" 2>/dev/null || true
            rm -f "${PID_FILE}" || true
            return 0  # indicate we killed an existing menu (toggle)
        fi
        rm -f "${PID_FILE}" || true
    fi
    return 1
}

run_menu() {
    # Start the menu in its own process group so it can be killed cleanly
    setsid bash -c "${MENU_CMD}" &
    local menu_pid=$!
    # atomic write
    (umask 077; printf "%s" "${menu_pid}" > "${PID_FILE}")
    trap '[[ -f "${PID_FILE}" ]] && rm -f "${PID_FILE}"' EXIT HUP INT TERM
    wait "${menu_pid}" 2>/dev/null || true
    rm -f "${PID_FILE}" || true
}

main() {
    if [[ -z "${MENU_NAME}" ]] || [[ -z "${MENU_CMD}" ]]; then
        echo "Uso: $0 <nombre_menu> <comando_menu>"
        exit 1
    fi

    if kill_existing_menu; then
        # Toggled off
        exit 0
    fi

    run_menu
}

main
