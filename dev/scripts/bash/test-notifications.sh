notify-send -u low "low"
sleep 1
notify-send -u normal "normal"
sleep 1
notify-send -u critical "critical" -t 10000
sleep 1
notify-send -i /home/jamerrq/pictures/icons/beast.png "consuming coffee" \
            -h string:frcolor:#B17457 -h string:fgcolor:#603F26 \
            -h string:bgcolor:#FFEAC5
sleep 1
notify-send -i /home/jamerrq/pictures/icons/ghost.png "out of coffee" \
            -h string:frcolor:#B17457 -h string:fgcolor:#603F26 \
            -h string:bgcolor:#FFEAC5
sleep 1
notify-send -i /home/jamerrq/pictures/icons/ultra-t.png "kitty notification" \
            -h string:frcolor:#D3ECCD -h string:fgcolor:#D3ECCD \
            -h string:bgcolor:#1B2A34
# sleep 1
# sleep 10
