#!/usr/bin/env bash

# Powermenu - Menú de energía (Directo y Robusto)
# Evita problemas de parsing y paths relativos

THEME="$HOME/.config/rofi/themes/powermenu.rasi"

# Opciones del menú
shutdown="  Apagar"
reboot="  Reiniciar"
lock="  Bloquear"
suspend="  Suspender"
logout="  Cerrar Sesión"

options="$shutdown\n$reboot\n$lock\n$suspend\n$logout"

if [ -f "$THEME" ]; then
    # Usar tema personalizado
    chosen="$(echo -e "$options" | rofi -dmenu -p "   ⏻   " -theme "$THEME")"
else
    # Fallback si no existe el tema
    chosen="$(echo -e "$options" | rofi -dmenu -p "⏻ ")"
fi

# Ejecutar acción seleccionada
case $chosen in
    "$shutdown") systemctl poweroff ;;
    "$reboot") systemctl reboot ;;
    "$lock") i3lock-everblush ;;
    "$suspend") systemctl suspend ;;
    "$logout") bspc quit ;;
esac
