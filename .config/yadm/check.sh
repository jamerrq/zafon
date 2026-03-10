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

# Replace Jetbrains/Default font with FiraCode Nerd Font in Waybar style
waybar_style="$HOME/.config/waybar/style.css"
if [[ -f "$waybar_style" ]]; then
    if grep -q "font-family: FiraCode Nerd Font" "$waybar_style"; then
        echo -e "${GREEN}OK${NC}: FiraCode font in waybar"
    else
        echo -e "${YELLOW}Setting Waybar font to FiraCode Nerd Font${NC}"
        sed -i 's/font-family: '\''JetBrainsMono Nerd Font'\'';/font-family: FiraCode Nerd Font;/' "$waybar_style"
    fi
fi

echo "Checks complete."
