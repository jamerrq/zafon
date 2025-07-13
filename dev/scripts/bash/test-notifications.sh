#!/bin/bash
notify-send -u low "low"
sleep 1
notify-send -u normal "normal"
sleep 1
notify-send -u critical "critical"
sleep 1
notify-send -i /home/jamerrq/pictures/icons/ultra-t.png "kitty notification" \
            -h string:frcolor:#D3ECCD -h string:fgcolor:#D3ECCD \
            -h string:bgcolor:#1B2A34
