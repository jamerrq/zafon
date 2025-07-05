#!/usr/bin/env bash
set -e

# Script interactivo para instalar paquetes especiales
MENU_OPTIONS=(
  "Instalar Docker"
  "Instalar Brave Browser"
  "Instalar Visual Studio Code"
  "Instalar Microsoft Edge"
  "Salir"
)

select opt in "${MENU_OPTIONS[@]}"; do
  case $opt in
    "Instalar Docker")
      bash "$(dirname "$0")/install_docker.sh"
      ;;
    "Instalar Brave Browser")
      bash "$(dirname "$0")/install_brave.sh"
      ;;
    "Instalar Visual Studio Code")
      bash "$(dirname "$0")/install_code.sh"
      ;;
    "Instalar Microsoft Edge")
      bash "$(dirname "$0")/install_edge.sh"
      ;;
    "Salir")
      break
      ;;
    *)
      echo "Opción inválida.";;
  esac
done
