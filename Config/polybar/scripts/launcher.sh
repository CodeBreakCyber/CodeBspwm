#!/usr/bin/env bash

# Launcher - Menú de aplicaciones (Directo y Robusto)
# Evita problemas de parsing y paths relativos

THEME="$HOME/.config/rofi/themes/launcher.rasi"

if [ -f "$THEME" ]; then
    # Force Icon via theme-str (Highest Priority) and generic placeholder
    rofi -show drun -theme "$THEME" -theme-str 'configuration { display-drun: "  "; }' -theme-str 'entry { placeholder: "Buscar..."; }'
else
    # Fallback si no existe el tema
    rofi -show drun -theme-str 'configuration { display-drun: "  "; }'
fi
