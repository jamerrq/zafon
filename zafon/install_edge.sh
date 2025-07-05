#!/usr/bin/env bash
set -e

echo "[INFO] Instalando Microsoft Edge..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list'
sudo apt update
sudo apt install -y microsoft-edge-stable
rm microsoft.gpg
