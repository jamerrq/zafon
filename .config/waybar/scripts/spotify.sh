#!/bin/bash

# Script para mostrar información de Spotify en Waybar
# Guarda este archivo como ~/.config/waybar/scripts/spotify.sh
# Y dale permisos de ejecución: chmod +x ~/.config/waybar/scripts/spotify.sh

# Configuración
MAX_LENGTH=30  # Longitud máxima del texto
SCROLL_DELAY=0.3  # Velocidad de rotación en segundos
CACHE_FILE="/tmp/waybar_spotify_cache"
POSITION_FILE="/tmp/waybar_spotify_position"

# Función para obtener información de Spotify
get_spotify_info() {
    local status
    local artist
    local title
    local full_text
    
    # Verificar si Spotify está corriendo
    if ! pgrep -x "spotify" > /dev/null; then
        echo '{"text": "", "tooltip": "Spotify no está ejecutándose", "class": "stopped"}'
        return
    fi
    
    # Obtener información usando playerctl
    if command -v playerctl >/dev/null 2>&1; then
        status=$(playerctl --player=spotify status 2>/dev/null || echo "Stopped")
        
        if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
            artist=$(playerctl --player=spotify metadata artist 2>/dev/null || echo "Unknown Artist")
            title=$(playerctl --player=spotify metadata title 2>/dev/null || echo "Unknown Title")
            
            # Si no se puede obtener info, intentar con dbus
            if [ "$artist" = "Unknown Artist" ] || [ "$title" = "Unknown Title" ]; then
                get_spotify_dbus_info
                return
            fi
        else
            echo '{"text": "", "tooltip": "Spotify pausado", "class": "paused"}'
            return
        fi
    else
        # Fallback a dbus si playerctl no está disponible
        get_spotify_dbus_info
        return
    fi
    
    # Formatear el texto
    full_text="$artist - $title"
    
    # Determinar el icono basado en el estado
    local icon
    case "$status" in
        "Playing")
            icon=""
            class="playing"
            ;;
        "Paused")
            icon=""
            class="paused"
            ;;
        *)
            icon=""
            class="stopped"
            ;;
    esac
    
    # Si el texto es más largo que MAX_LENGTH, implementar scroll
    if [ ${#full_text} -gt $MAX_LENGTH ]; then
        local position=0
        if [ -f "$POSITION_FILE" ]; then
            position=$(cat "$POSITION_FILE")
        fi
        
        # Crear texto con scroll
        local padded_text="$full_text    "  # Añadir espacios para el loop
        local text_length=${#padded_text}
        
        if [ $position -ge $text_length ]; then
            position=0
        fi
        
        local displayed_text="${padded_text:$position:$MAX_LENGTH}"
        
        # Actualizar posición para la próxima vez
        echo $((position + 1)) > "$POSITION_FILE"
        
        echo "{\"text\": \"$icon $displayed_text\", \"tooltip\": \"$full_text\", \"class\": \"$class\"}"
    else
        echo "{\"text\": \"$icon $full_text\", \"tooltip\": \"$full_text\", \"class\": \"$class\"}"
    fi
}

# Función alternativa usando dbus directamente
get_spotify_dbus_info() {
    local metadata
    local status
    local artist
    local title
    
    # Obtener estado
    status=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:PlaybackStatus 2>/dev/null | grep -Po '(?<=").*(?=")' | tail -1)
    
    if [ -z "$status" ]; then
        echo '{"text": "", "tooltip": "Spotify no disponible", "class": "stopped"}'
        return
    fi
    
    # Obtener metadata
    metadata=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:Metadata 2>/dev/null)
    
    if [ -n "$metadata" ]; then
        artist=$(echo "$metadata" | grep -A 1 "xesam:artist" | grep -Po '(?<=").*(?=")' | head -1)
        title=$(echo "$metadata" | grep -A 1 "xesam:title" | grep -Po '(?<=").*(?=")' | tail -1)
        
        if [ -n "$artist" ] && [ -n "$title" ]; then
            full_text="$artist - $title"
            
            local icon
            local class
            case "$status" in
                "Playing")
                    icon=""
                    class="playing"
                    ;;
                "Paused")
                    icon=""
                    class="paused"
                    ;;
                *)
                    icon=""
                    class="stopped"
                    ;;
            esac
            
            # Implementar scroll si es necesario
            if [ ${#full_text} -gt $MAX_LENGTH ]; then
                local position=0
                if [ -f "$POSITION_FILE" ]; then
                    position=$(cat "$POSITION_FILE")
                fi
                
                local padded_text="$full_text    "
                local text_length=${#padded_text}
                
                if [ $position -ge $text_length ]; then
                    position=0
                fi
                
                local displayed_text="${padded_text:$position:$MAX_LENGTH}"
                echo $((position + 1)) > "$POSITION_FILE"
                
                echo "{\"text\": \"$icon $displayed_text\", \"tooltip\": \"$full_text\", \"class\": \"$class\"}"
            else
                echo "{\"text\": \"$icon $full_text\", \"tooltip\": \"$full_text\", \"class\": \"$class\"}"
            fi
        else
            echo '{"text": "", "tooltip": "Sin información de pista", "class": "stopped"}'
        fi
    else
        echo '{"text": "", "tooltip": "Spotify pausado", "class": "paused"}'
    fi
}

# Función para controles de Spotify
spotify_control() {
    case "$1" in
        "play-pause")
            if command -v playerctl >/dev/null 2>&1; then
                playerctl --player=spotify play-pause
            else
                dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
            fi
            ;;
        "next")
            if command -v playerctl >/dev/null 2>&1; then
                playerctl --player=spotify next
            else
                dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next
            fi
            ;;
        "previous")
            if command -v playerctl >/dev/null 2>&1; then
                playerctl --player=spotify previous
            else
                dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous
            fi
            ;;
    esac
}

# Verificar argumentos
case "$1" in
    "control")
        spotify_control "$2"
        ;;
    *)
        get_spotify_info
        ;;
esac
