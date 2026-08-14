#!/bin/bash
# spotify.sh

SCROLL_WIDTH=22
DELAY=0.4

get_player() {
    players=$(playerctl -l 2>/dev/null)
    # Prefer spotify natively first
    for p in $players; do
        if [[ "$p" == *"spotify"* ]]; then
            echo "$p"
            return
        fi
    done
    # Fallback to browsers since MPRIS often hides the actual source domain
    for p in $players; do
        if [[ "$p" == *"brave"* || "$p" == *"chromium"* || "$p" == *"firefox"* || "$p" == *"chrome"* ]]; then
            echo "$p"
            return
        fi
    done
}

last_text=""
scroll_idx=0

while true; do
    player=$(get_player)
    
    if [[ -z "$player" ]]; then
        echo '{"text": "", "class": "inactive", "tooltip": ""}'
        sleep 2
        continue
    fi
    
    status=$(playerctl -p "$player" status 2>/dev/null)
    if [[ -z "$status" || "$status" == "Stopped" ]]; then
        echo '{"text": "", "class": "inactive", "tooltip": ""}'
        sleep 2
        continue
    fi
    
    artist=$(playerctl -p "$player" metadata artist 2>/dev/null)
    title=$(playerctl -p "$player" metadata title 2>/dev/null)
    
    if [[ -n "$artist" && -n "$title" ]]; then
        text="$artist • $title"
    elif [[ -n "$title" ]]; then
        text="$title"
    else
        text="Spotify"
    fi
    
    # Icon and class
    icon=" "
    class="paused"
    if [[ "$status" == "Playing" ]]; then
        icon=" "
        class="playing"
    elif [[ "$status" == "Paused" ]]; then
        icon=" "
        class="paused"
    fi
    
    tooltip="$text"
    
    if [[ "$text" != "$last_text" ]]; then
        last_text="$text"
        scroll_idx=0
    fi
    
    len=${#text}
    if (( len > SCROLL_WIDTH )); then
        spaced_text="${text}     ${text}"
        display_text="${spaced_text:$scroll_idx:$SCROLL_WIDTH}"
        
        if [[ "$status" == "Playing" ]]; then
            (( scroll_idx = (scroll_idx + 1) % (len + 5) ))
        fi
    else
        display_text="$text"
    fi
    
    # Escape quotes for JSON
    display_text="${display_text//\"/\\\"}"
    tooltip="${tooltip//\"/\\\"}"
    
    echo "{\"text\": \"$icon  $display_text\", \"class\": \"$class\", \"tooltip\": \"$tooltip\"}"

    sleep $DELAY
done
