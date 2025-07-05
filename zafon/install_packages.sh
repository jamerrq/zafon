#!/usr/bin/env bash

PKG_LIST="$(dirname "$0")/packages-base.txt"

# Detecta gestor de paquetes
if command -v apt &>/dev/null; then
    INSTALL="sudo apt install -y"
elif command -v dnf &>/dev/null; then
    INSTALL="sudo dnf install -y"
elif command -v pacman &>/dev/null; then
    INSTALL="sudo pacman -S --noconfirm"
else
    echo "[ERROR] no se detectó un gestor de paquetes soportado."
    exit 1
fi

echo "[INFO] instalando paquetes base..."
while read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    echo "[INFO] instalando $pkg..."
    if ! $INSTALL "$pkg"; then
        echo "[ADVERTENCIA] falló la instalación de $pkg, continuando con el siguiente."
    fi
done < "$PKG_LIST"

echo "[INFO] instalación de dependencias base completada."
exit 0
