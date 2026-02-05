#!/usr/bin/env bash
#==============================================================================
# whichSystem.sh - Detecta el sistema operativo basado en el TTL
# Versión bash pura (sin dependencias de Python)
# Uso: whichSystem.sh <dirección-ip>
#==============================================================================

set -euo pipefail

#==============================================================================
# CONSTANTS
#==============================================================================

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME

# TTL ranges para diferentes sistemas
readonly TTL_LINUX_MAX=64
readonly TTL_WINDOWS_MAX=128
readonly TTL_CISCO_MAX=255

#==============================================================================
# FUNCTIONS
#==============================================================================

##
# Muestra el uso del script
##
show_usage() {
    cat <<EOF

Uso: $SCRIPT_NAME <dirección-ip>

Detecta el sistema operativo de un host basándose en el TTL del ping.

Ejemplos:
    $SCRIPT_NAME 192.168.1.1
    $SCRIPT_NAME 10.10.10.10

EOF
    exit 1
}

##
# Valida que la IP tenga formato correcto
# @param $1 Dirección IP
# @return 0 si válida, 1 si inválida
##
validate_ip() {
    local ip="$1"
    
    # Regex para validar IPv4
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        # Validar que cada octeto esté entre 0-255
        local IFS='.'
        # shellcheck disable=SC2206
        local -a octets=($ip)
        for octet in "${octets[@]}"; do
            if [[ $octet -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

##
# Obtiene el TTL haciendo ping a la IP
# @param $1 Dirección IP
# @return TTL o cadena vacía si falla
##
get_ttl() {
    local ip="$1"
    local ping_output
    local ttl
    
    # Hacer ping (1 paquete, timeout 2 segundos)
    if ping_output=$(ping -c 1 -W 2 "$ip" 2>&1); then
        # Extraer TTL de la salida
        # Formato: "ttl=64" o "TTL=64"
        ttl=$(echo "$ping_output" | grep -oiP 'ttl=\K\d+' | head -1)
        
        if [[ -n "$ttl" ]]; then
            echo "$ttl"
            return 0
        fi
    fi
    
    return 1
}

##
# Determina el sistema operativo basado en el TTL
# @param $1 TTL
# @return Nombre del sistema operativo
##
get_os_from_ttl() {
    local ttl="$1"
    
    if [[ $ttl -le $TTL_LINUX_MAX ]]; then
        echo "Linux/Unix"
    elif [[ $ttl -le $TTL_WINDOWS_MAX ]]; then
        echo "Windows"
    elif [[ $ttl -le $TTL_CISCO_MAX ]]; then
        echo "Cisco/Network Device"
    else
        echo "Unknown"
    fi
}

#==============================================================================
# MAIN
#==============================================================================

main() {
    # Validar argumentos
    if [[ $# -ne 1 ]]; then
        echo -e "\n[!] Error: Se requiere una dirección IP\n" >&2
        show_usage
    fi
    
    local ip_address="$1"
    
    # Validar formato de IP
    if ! validate_ip "$ip_address"; then
        echo -e "\n[!] Error: Formato de IP inválido: $ip_address\n" >&2
        exit 1
    fi
    
    # Obtener TTL
    local ttl
    if ! ttl=$(get_ttl "$ip_address"); then
        echo -e "\n[!] Error: No se pudo obtener el TTL de $ip_address" >&2
        echo -e "[!] Verifica que el host esté activo y accesible\n" >&2
        exit 1
    fi
    
    # Determinar sistema operativo
    local os_name
    os_name=$(get_os_from_ttl "$ttl")
    
    # Mostrar resultado
    echo -e "\n\t$ip_address (ttl -> $ttl): $os_name\n"
}

# Ejecutar main
main "$@"
