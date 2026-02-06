#!/bin/bash
# Startup Sound Script for CodeBspwm
# Plays audio file from ~/.config/sound/ on system startup

SOUND_DIR="$HOME/.config/sound"
AUDIO_FILE=""

# Detect audio file
if [ -f "$SOUND_DIR/startup.mp3" ]; then 
    AUDIO_FILE="$SOUND_DIR/startup.mp3"
elif [ -f "$SOUND_DIR/startup.wav" ]; then 
    AUDIO_FILE="$SOUND_DIR/startup.wav"
fi

# Play sound if found
if [ -n "$AUDIO_FILE" ] && command -v mpv &>/dev/null; then
    mpv --no-video "$AUDIO_FILE" &
fi

exit 0
