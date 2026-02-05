#!/bin/sh

target_file="$HOME/.config/bin/target"

if [ ! -f "$target_file" ]; then
    echo "%{F#cf9fff}ﲅ %{F#666666}No target"
    exit 0
fi

ip_target=$(awk '{print $1}' "$target_file")
name_target=$(awk '{print $2}' "$target_file")

if [ "$ip_target" ] && [ "$name_target" ]; then
    echo "%{A1:echo -n $ip_target | xclip -selection clipboard & notify-send -u low 'HTB Target' 'Target Copiado $ip_target':}%{F#cf9fff}什 %{F#ffffff}$ip_target - $name_target%{A}"
elif [ "$ip_target" ]; then
    echo "%{A1:echo -n $ip_target | xclip -selection clipboard & notify-send -u low 'HTB Target' 'Target Copiado $ip_target':}%{F#cf9fff}什 %{F#ffffff}$ip_target%{A}"
else
    echo "%{F#cf9fff}ﲅ %{F#666666}No target"
fi

