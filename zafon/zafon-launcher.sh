#!/usr/bin/env bash
# Lanzador inteligente para el menú Zafon

# Detecta si hay terminal interactiva
if [ -t 1 ]; then
    # Hay terminal, ejecuta inline
    bash "$HOME"/zafon/main.sh
else
    # No hay terminal, abre una nueva ventana
    kitty bash -c "$HOME"/zafon/main.sh
fi
