#!/bin/bash

# Script to display Spotify information in Waybar
# Save this file as ~/.config/waybar/scripts/spotify.sh
# Make it executable: chmod +x ~/.config/waybar/scripts/spotify.sh

# Function to get Spotify information using playerctl
get_spotify_info() {
    local status
    local artist
    local title
    local full_text

    # Check if Spotify is running
    if ! pgrep -x "spotify" > /dev/null; then
        echo '{"text": "", "tooltip": "Spotify is not running", "class": "stopped"}'
        return
    fi

    # Get info using playerctl if available
    if command -v playerctl > /dev/null 2>&1; then
        status=$(playerctl --player=spotify status 2>/dev/null || echo "Stopped")
        if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
            artist=$(playerctl --player=spotify metadata artist 2>/dev/null || echo "Unknown Artist")
            title=$(playerctl --player=spotify metadata title 2>/dev/null || echo "Unknown Title")
            # Fallback to dbus if metadata is unavailable
            if [ "$artist" = "Unknown Artist" ] || [ "$title" = "Unknown Title" ]; then
                get_spotify_dbus_info
                return
            fi
        else
            echo '{"text": "", "tooltip": "Spotify paused", "class": "paused"}'
            return
        fi
    else
        # Fallback to dbus if playerctl is not available
        get_spotify_dbus_info
        return
    fi

    # Format the text
    full_text="$artist - $title"

    # Determine icon and class based on status
    local icon
    case "$status" in
        "Playing")
            icon="▶"
            class="playing"
            ;;
        "Paused")
            icon="⏸️"
            class="paused"
            ;;
        *)
            icon=""
            class="stopped"
            ;;
    esac

    # Output JSON for Waybar
    echo "{\"text\": \"$icon $full_text\", \"tooltip\": \"$full_text\", \"class\": \"$class\"}"
}

# Function to get Spotify information using dbus
get_spotify_dbus_info() {
    local metadata
    local status
    local artist
    local title

    # Get playback status
    status=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:PlaybackStatus 2>/dev/null | grep -Po '(?<=").*(?=")' | tail -1)
    if [ -z "$status" ]; then
        echo '{"text": "", "tooltip": "Spotify unavailable", "class": "stopped"}'
        return
    fi

    # Get metadata
    metadata=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:Metadata 2>/dev/null)
    if [ -n "$metadata" ]; then
        artist=$(echo "$metadata" | grep -A 1 "xesam:artist" | grep -Po '(?<=").*(?=")' | head -1)
        title=$(echo "$metadata" | grep -A 1 "xesam:title" | grep -Po '(?<=").*(?=")' | tail -1)
        if [ -n "$artist" ] && [ -n "$title" ]; then
            full_text="$artist - $title"

            # Determine icon and class based on status
            local icon
            case "$status" in
                "Playing")
                    icon="▶"
                    class="playing"
                    ;;
                "Paused")
                    icon="⏸️"
