#!/usr/bin/env bash
set -e

# Entra al alternate screen buffer
printf '\033[?1049h'
cleanup() { printf '\033[?1049l'; }
trap cleanup EXIT

function install_gum(){
    if ! command -v gum &>/dev/null; then
        echo "gum no está instalado. Instalando..."
        if command -v apt &>/dev/null; then
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
            sudo apt update && sudo apt install gum
        else
            echo "por favor instala gum manualmente."
            exit 1
        fi
    fi
}

install_gum

# función para centrar texto en la terminal
function define_center() {
  center() {
    local term_width
    term_width=$(tput cols)
    while IFS= read -r line; do
      printf "%*s\n" $(((${#line} + term_width) / 2)) "$line"
    done
  }
}

define_center

# Función para gradiente por línea
function print_gradient_ascii_lines() {
    local ascii_file="$1"
    # local start_r=255 start_g=100 start_b=100   # Color inicial (rojo claro)
    # local end_r=100 end_g=200 end_b=255         # Color final (azul claro)
    local start_r=235 start_g=49 start_b=20 #eb3114
    local end_r=252 end_g=240 end_b=146 #fcf092
    local lines total_lines i r g b

    mapfile -t lines < "$ascii_file"
    total_lines=${#lines[@]}

    for i in "${!lines[@]}"; do
        # Interpolación lineal de color
        r=$((start_r + (end_r - start_r) * i / (total_lines - 1)))
        g=$((start_g + (end_g - start_g) * i / (total_lines - 1)))
        b=$((start_b + (end_b - start_b) * i / (total_lines - 1)))
        printf "\033[38;2;%d;%d;%dm%s\033[0m\n" "$r" "$g" "$b" "${lines[$i]}"
    done
}

# Función para gradiente por carácter
function print_gradient_ascii_chars() {
    local ascii_file="$1"
    local start_r=255 start_g=100 start_b=100   # (255, 100, 100)
    local end_r=100 end_g=200 end_b=255         # (100, 200, 255)
    local lines total_lines i j len r g b ch

    mapfile -t lines < "$ascii_file"
    total_lines=${#lines[@]}

    for i in "${!lines[@]}"; do
        len=${#lines[$i]}
        for j in $(seq 0 $((len - 1))); do
            # Gradiente horizontal (por carácter)
            r=$((start_r + (end_r - start_r) * j / (len - 1)))
            g=$((start_g + (end_g - start_g) * j / (len - 1)))
            b=$((start_b + (end_b - start_b) * j / (len - 1)))
            ch="${lines[$i]:$j:1}"
            printf "\033[38;2;%d;%d;%dm%s\033[0m" "$r" "$g" "$b" "$ch"
        done
        printf "\n"
    done
}

# mostrar arte ASCII solo al inicio
function show_ascii {
    clear
    print_gradient_ascii_lines "$(dirname "$0")/zafon.ascii" | center
    # print_gradient_ascii_chars "$(dirname "$0")/zafon.ascii" | center
    local timeout=${1:-2.5}
    sleep "$timeout"
}

show_ascii 2.5

while true; do
  clear
  # banner
  center <<< "=== ZAFON ==="
  echo
  MENU_OPTIONS=(
    "instalar paquetes base"
    "instalar paquetes especiales"
    "instalar fuentes nerd-fonts"
    "mostrar ascii"
    "salir"
  )

  CHOICE=$(printf '%s\n' "${MENU_OPTIONS[@]}" | gum choose --header " elige una opción ")

  case "$CHOICE" in
    "instalar paquetes base")
      bash "$(dirname "$0")/install_packages.sh"
      read -rp "[INFO] presiona Enter para continuar..."
      ;;
    "instalar paquetes especiales")
      bash "$(dirname "$0")/install_special.sh"
      read -rp "[INFO] presiona Enter para continuar..."
      ;;
    "instalar fuentes nerd-fonts")
      bash "$(dirname "$0")/install_nerd_fonts.sh"
      read -rp "[INFO] presiona Enter para continuar..."
      ;;
    "mostrar ascii")
      show_ascii 0
      read -rp "[INFO] presiona Enter para continuar..."
      ;;
    "salir")
      echo "[INFO] saliendo..."
      clear
      exit 0
      ;;
    *)
      echo "[ERROR] opción inválida."
      exit 1
      ;;
  esac
done
