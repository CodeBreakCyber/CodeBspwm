#!/usr/bin/env bash

# Network Menu with Action Submenu & Navigation
# Author: CodeBreak
THEME="$HOME/.config/rofi/themes/network_menu.rasi"

# Compatibility
export LC_ALL=C
export LANG=C

# Singleton Check: Prevent multiple instances
if pidof rofi >/dev/null; then
    killall rofi
    exit 0
fi

# --- Colors ---
GREEN="#8ccf7e"
RED="#e57474"


# --- Logic ---

# Get current status
get_status() {
    if nmcli -t radio wifi | grep -qi "enabled"; then
        echo "ON"
    else
        echo "OFF"
    fi
}

# Get current SSID (INSTANT way using iwgetid)
get_ssid() {
    # iwgetid is much faster than nmcli
    iwgetid -r || echo ""
}

# Rofi Command (Main Menu with Status)
rofi_cmd() {
    # Generate Message
    STATUS=$(get_status)
    # ... (rest of getting message logic is inside rofi_cmd usually? No wait, checking view)
    # The view shows rofi_cmd calls rofi -dmenu.
    # Wait, the view in step 1657 line 41 starts rofi_cmd, but lines 42-50 are generating MSG.
    # I need to see where rofi is CALLED.
    # It must be further down.
    # I will read more lines.
    STATUS=$(get_status)
    if [ "$STATUS" = "ON" ]; then
        SSID=$(get_ssid)
        if [ -n "$SSID" ]; then
            MSG="<span color='$GREEN' size='small'>  Conectado: <b>$SSID</b></span>"
        else
            MSG="<span color='$RED' size='small'>睊  Desconectado (Wifi ON)</span>"
        fi
    else
        MSG="<span color='$RED' size='small'>睊  Wifi Desactivado</span>"
    fi

    # Flags for single-click interaction (Bash Arrays)
    ROFI_FLAGS=(-i -markup-rows -me-select-entry "" -me-accept-entry "MousePrimary")

    if [ -f "$THEME" ]; then
        rofi -dmenu -p "$1" -theme "$THEME" -mesg "$MSG" -theme-str 'entry { placeholder: "Buscar..."; }' "${ROFI_FLAGS[@]}" "$@"
    else
        rofi -dmenu -p "$1" -mesg "$MSG" "${ROFI_FLAGS[@]}" "$@"
    fi
}

# Rofi Simple Command (Submenus - INSTANT, No Input Bar)
rofi_simple_cmd() {
    ROFI_FLAGS=(-i -markup-rows -me-select-entry "" -me-accept-entry "MousePrimary")
    # Hide inputbar for clean look
    THEME_STR='inputbar { enabled: false; } window { width: 250px; } listview { lines: 2; }'
    
    if [ -f "$THEME" ]; then
        rofi -dmenu -p "$1" -theme "$THEME" -theme-str "$THEME_STR" "${ROFI_FLAGS[@]}"
    else
        rofi -dmenu -p "$1" -theme-str "$THEME_STR" "${ROFI_FLAGS[@]}"
    fi
}

# Submenu for specific network Actions
submenu() {
    local NETWORK="$1"
    local STATUS="$2"  # connected or not
    
    # Define options
    if [ "$STATUS" = "connected" ]; then
        echo -e "  Desconectar\n❌  Cancelar" | rofi_simple_cmd "Opciones: $NETWORK"
    else
        echo -e "  Conectar\n❌  Cancelar" | rofi_simple_cmd "Opciones: $NETWORK"
    fi
}

# --- Main Loop ---

while true; do
    STATUS=$(get_status)
    CURRENT_SSID=$(get_ssid)

    # Build Main Menu Options
    if [ "$STATUS" = "ON" ]; then
        # Title Item (Inactive)
        MENU_ITEMS="<b>Redes Disponibles</b>"
        
        # List networks (FAST: No rescan on startup)
        LIST=$(nmcli -t -f SSID dev wifi list --rescan no | grep -v '^$' | sort -u)
        
        # Count real lines (non-empty)
        COUNT=$(echo "$LIST" | grep -cve '^\s*$')
        
        # If STILL empty, show Manual Scan Option
        if [ "$COUNT" -eq 0 ]; then
            MENU_ITEMS="$MENU_ITEMS\n↻ Escanear Redes"
        else
            # Format List
            if [ -n "$CURRENT_SSID" ]; then
                # Display: SSID (bold) ... (Conectado)
                CONNECTED_LINE="<b>$CURRENT_SSID</b> <span size='small' color='$GREEN'><i>(Conectado)</i></span>"
                OTHER_NETWORKS=$(echo "$LIST" | grep -vFx "$CURRENT_SSID")
                MENU_ITEMS="$MENU_ITEMS\n$CONNECTED_LINE\n$OTHER_NETWORKS\n↻ Escanear Redes"
            else
                MENU_ITEMS="$MENU_ITEMS\n$LIST\n↻ Escanear Redes"
            fi
        fi
    else
        MENU_ITEMS="Toggle Wifi ON/OFF"
    fi

    # Show Menu
    CHOSEN=$(echo -e "$MENU_ITEMS" | rofi_cmd "  ")

    # Exit if user pressed Esc or closed menu
    if [ -z "$CHOSEN" ]; then
        exit 0
    fi

    # Clean up chosen string
    # shellcheck disable=SC2001
    CLEAN_CHOSEN=$(echo "$CHOSEN" | sed 's/<[^>]*>//g')
    CLEAN_CHOSEN=$(echo "$CLEAN_CHOSEN" | awk '{$1=$1};1') # Trim

    # If "Conectado" implies the ssid
    if [[ "$CHOSEN" == *"Conectado"* ]]; then
        CLEAN_CHOSEN="$CURRENT_SSID"
    fi

    # Handle Special Cases
    if [[ "$CLEAN_CHOSEN" == "Redes Disponibles" ]]; then
         continue
    fi
    
    if [[ "$CLEAN_CHOSEN" == *"Escanear Redes"* ]]; then
        notify-send -t 2000 -u low "Escaneando redes..."
        nmcli device wifi rescan
        continue
    fi
    
    if [[ "$CLEAN_CHOSEN" == "Toggle Wifi ON/OFF" ]]; then
         if [ "$STATUS" = "ON" ]; then
            nmcli radio wifi off
            notify-send -t 1000 -u low "Wifi Desactivado"
         else
            nmcli radio wifi on
            notify-send -t 1000 -u low "Wifi Activado"
         fi
         # Refresh loop to show updated status
         continue
    fi

    # Extract SSID
    # If it was the connected line with markup, we already mapped it to CURRENT_SSID
    REAL_SSID="$CLEAN_CHOSEN"

    # Check connection status for Submenu
    if [ "$REAL_SSID" = "$CURRENT_SSID" ]; then
        ACTION=$(submenu "$REAL_SSID" "connected")
        
        if [[ "$ACTION" == *"Desconectar"* ]]; then
            nmcli device disconnect wlan0
            notify-send -t 1000 -u low "Desconectado de $REAL_SSID"
            exit 0
        elif [[ "$ACTION" == *"Cancelar"* ]]; then
            continue # Go back to main menu
        elif [ -z "$ACTION" ]; then
            exit 0 # If Submenu closed with Esc/Click-Outside, CLOSE EVERYTHING
        fi
    else
        # Not connected network
        ACTION=$(submenu "$REAL_SSID" "disconnected")
        
        if [[ "$ACTION" == *"Conectar"* ]]; then
             # Check if saved
            SAVED=$(nmcli -t -f NAME connection show | grep -x "$REAL_SSID")
            
            if [ -n "$SAVED" ]; then
                nmcli connection up "$REAL_SSID" && notify-send -t 1000 -u low "Conectado a $REAL_SSID"
            else
                pass=$(echo "" | rofi -dmenu -p "Password ($REAL_SSID)" -password -theme "$THEME")
                if [ -z "$pass" ]; then continue; fi # If password prompt cancelled
                
                if nmcli device wifi connect "$REAL_SSID" password "$pass"; then
                    notify-send -t 1000 -u low "Conectado a $REAL_SSID"
                else
                    notify-send -t 1000 -u low "Fallo la conexión"
                fi
            fi
            exit 0
        elif [[ "$ACTION" == *"Cancelar"* ]]; then
            continue # Go back to main menu
        elif [ -z "$ACTION" ]; then
            exit 0 # If Submenu closed with Esc/Click-Outside, CLOSE EVERYTHING
        fi
    fi
done
