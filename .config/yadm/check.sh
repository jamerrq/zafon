#!/bin/bash

echo "Checking Omarchy customizations..."

GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
NC='\e[0m' # No Color

echo "Refreshing Omarchy configurations to their latest defaults..."
omarchy-refresh-hyprland >/dev/null 2>&1
omarchy-refresh-waybar >/dev/null 2>&1
echo -e "${GREEN}OK${NC}: Latest Omarchy defaults loaded"

# Check Hyprland core
hyprland_conf="$HOME/.config/hypr/hyprland.conf"
target_line="source = ~/.config/hypr/nikki.conf"

if [[ ! -f "$hyprland_conf" ]]; then
    echo -e "${RED}Warning: $hyprland_conf does not exist.${NC}"
else
    if ! grep -q "$target_line" "$hyprland_conf"; then
        echo -e "${YELLOW}Adding '$target_line' to $hyprland_conf${NC}"
        echo "" >> "$hyprland_conf"
        echo "$target_line" >> "$hyprland_conf"
    else
        echo -e "${GREEN}OK${NC}: hyprland customizations (nikki.conf)"
    fi
fi


# Check Omarchy Templates
check_template() {
    local filepath="$1"
    local required_content="$2"
    local template_name="$3"
    local expanded_path="${filepath/#\~/$HOME}"
    
    if [[ ! -f "$expanded_path" ]]; then
        echo -e "${RED}Error: Template $expanded_path is missing. Make sure to pull it from YADM.${NC}"
        return
    fi
    
    if ! grep -qF "$required_content" "$expanded_path"; then
        echo -e "${YELLOW}Warning: $expanded_path is missing expected customization: $required_content${NC}"
    else
        echo -e "${GREEN}OK${NC}: template for $template_name"
    fi
}

check_template "~/.config/omarchy/themed/mako.ini.tpl" "border-radius=10" "mako"
check_template "~/.config/omarchy/themed/walker.css.tpl" "border-radius: 10px;" "walker"

# Replace Omarchy logo with Arch Linux logo in Waybar
waybar_config="$HOME/.config/waybar/config.jsonc"
if [[ -f "$waybar_config" ]]; then
    if grep -q "󰣇" "$waybar_config"; then
        echo -e "${GREEN}OK${NC}: arch logo in waybar"
    else
        echo -e "${YELLOW}Replacing Omarchy logo with Arch logo in $waybar_config${NC}"
        sed -i 's/"format": "<span font='\''omarchy'\''>\\ue900<\/span>"/"format": "󰣇"/' "$waybar_config"
    fi
fi

# Ensure FiraCode Nerd Font is set system-wide
current_font=$(omarchy-font-current 2>/dev/null)
if [[ "$current_font" != *"FiraCode"* ]]; then
    echo -e "${YELLOW}Setting system font to FiraCode Nerd Font${NC}"
    omarchy-font-set "FiraCode Nerd Font" >/dev/null 2>&1
else
    echo -e "${GREEN}OK${NC}: FiraCode font is set system-wide"
fi

# Integrate custom wallpapers into current theme's background folder before refresh
THEME_NAME=$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null)
if [[ -n "$THEME_NAME" && -d "$HOME/.config/yadm/wallpapers/" ]]; then
    echo "Syncing custom YADM wallpapers into theme: $THEME_NAME"
    mkdir -p "$HOME/.config/omarchy/backgrounds/$THEME_NAME/"
    cp -u "$HOME/.config/yadm/wallpapers/"* "$HOME/.config/omarchy/backgrounds/$THEME_NAME/" 2>/dev/null
    echo -e "${GREEN}OK${NC}: Custom wallpapers integrated successfully"
fi

echo "Compiling Omarchy templates..."
omarchy-theme-refresh >/dev/null 2>&1
echo -e "${GREEN}OK${NC}: Theme templates refreshed"

# Set the beloved tux wallpaper as default if available
tux_wallpaper="$HOME/.config/omarchy/backgrounds/$THEME_NAME/gruvbox_tux.png"
if [[ -n "$THEME_NAME" && -f "$tux_wallpaper" ]]; then
    omarchy-theme-bg-set "$tux_wallpaper" >/dev/null 2>&1
    echo -e "${GREEN}OK${NC}: Set tux wallpaper"
fi

echo "Checks complete. Reloading services..."
omarchy-restart-walker >/dev/null 2>&1
makoctl reload >/dev/null 2>&1

notify-send -t 3000 "Omarchy Sync" "Applied capablanca customizations over omarchy successfully"
echo -e "${GREEN}OK${NC}: Services reloaded and customizations applied successfully!"
