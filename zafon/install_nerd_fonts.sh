#!/usr/bin/env bash
set -e

FONT_LIST="$(dirname "$0")/fonts-to-install.txt"
INSTALL_DIR="$HOME/.local/share/fonts"
NERD_FONTS_VERSION="v3.4.0"

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m'

mkdir -p "$INSTALL_DIR"

total=$(grep -cve '^\s*$' "$FONT_LIST")
count=1

while read -r font; do
    [ -z "$font" ] && continue
    if ls "$INSTALL_DIR"/*"$font"* &>/dev/null; then
        echo -e "${YELLOW}[$count/$total] $font Nerd Font ya está instalada. saltando.${NC}"
    else
        echo -e "${BLUE}[$count/$total] instalando $font Nerd Font...${NC}"
        url="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/${font}.tar.xz"
        tempdir=$(mktemp -d)
        archive="$tempdir/${font}.tar.xz"
        if curl -fLo "$archive" "$url"; then
            if tar -tJf "$archive" &>/dev/null; then
                tar -xJf "$archive" -C "$INSTALL_DIR"
                echo -e "${GREEN}✓ $font instalada correctamente.${NC}"
            else
                echo -e "${RED}✗ $font: El archivo no es un tar.xz válido.${NC}"
            fi
        else
            echo -e "${RED}✗ error descargando $font. Revisa el nombre o la conexión.${NC}"
        fi
        rm -rf "$tempdir"
    fi
    count=$((count+1))
done < "$FONT_LIST"

echo -e "${BLUE}[INFO] actualizando caché de fuentes...${NC}"
fc-cache -fv "$INSTALL_DIR"

echo -e "${GREEN}[INFO] fuentes instaladas${NC}"
