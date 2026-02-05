#!/bin/bash

# Directorio de Wallpapers
WALL_DIR="$HOME/Pictures/Wallpapers"
CACHE_FILE="$HOME/.fehbg"

# Verificar si existe el directorio
if [ ! -d "$WALL_DIR" ]; then
    notify-send -u critical "Wallpaper Error" "No existe $WALL_DIR"
    exit 1
fi

# Seleccionar un wallpaper aleatorio
RANDOM_WALL=$(find "$WALL_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)

if [ -n "$RANDOM_WALL" ]; then
    # Aplicar con feh
    feh --bg-fill "$RANDOM_WALL"

    # Generar versión lockscreen: Blur + Spider MAX RESALTE + branding "Code"
    if command -v convert &> /dev/null; then
        convert "$RANDOM_WALL" \
            -resize 1920x1080^ -gravity center -extent 1920x1080 \
            -blur 0x20 \
            -fill black -colorize 50% \
            -colorspace sRGB \
            \
            \( ~/.cache/spider_red_base.png -colorspace sRGB -background white -shadow 100x4+0+0 \) -gravity center -composite \
            \( ~/.cache/spider_red_base.png -colorspace sRGB -background red -shadow 100x12+0+0 \) -gravity center -composite \
            \( ~/.cache/spider_red_base.png -colorspace sRGB \) -gravity center -composite \
            \
            ~/.cache/lock_wallpaper.png
    else
        cp "$RANDOM_WALL" ~/.cache/lock_wallpaper.png
    fi
    
    # Guardar para persistencia (esto se ejecuta al inicio en bspwmrc)
    echo "#!/bin/sh" > "$CACHE_FILE"
    echo "feh --bg-fill '$RANDOM_WALL'" >> "$CACHE_FILE"
    chmod +x "$CACHE_FILE"
    
    # Notificar
    WALL_NAME=$(basename "$RANDOM_WALL")
    notify-send -u low -i "preferences-desktop-wallpaper" "Wallpaper" "Cambiado a: $WALL_NAME"
else
    notify-send -u normal "Wallpaper" "No hay imágenes en $WALL_DIR"
fi
