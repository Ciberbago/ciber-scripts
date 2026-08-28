#!/usr/bin/env bash
#
# Chaotic-AUR (repo binario) + los paquetes que si hay que compilar del AUR.
set -uo pipefail

#<-----Chaotic-AUR----->
# Idempotente: si la llave ya esta y el repo ya esta en pacman.conf, no repite.
if ! pacman-key --list-keys 3056513887B78AEB &>/dev/null; then
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
fi
for p in chaotic-keyring chaotic-mirrorlist; do
    pacman -Qq "$p" &>/dev/null || \
        sudo pacman -U --noconfirm "https://cdn-mirror.chaotic.cx/chaotic-aur/${p}.pkg.tar.zst"
done
# BUG ORIGINAL: el bloque se agregaba con 'tee -a' en cada corrida, duplicando
# la seccion [chaotic-aur] en pacman.conf.
if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
    printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' | \
        sudo tee -a /etc/pacman.conf >/dev/null
fi
sudo pacman -Syu --noconfirm

#<-----Paquetes binarios de chaotic-aur (no requieren compilar)----->
# Estos salen de un repo normal, asi que pacman los instala directo.
chaotic=(
    ani-cli bibata-rainbow-cursor-theme fsearch fresh-editor insync
    protonplus rtl88xxau-aircrack-dkms-git linux-cachyos
    linux-cachyos-headers protontricks-git
)
disponibles=()
for p in "${chaotic[@]}"; do
    pacman -Si "chaotic-aur/${p}" &>/dev/null && disponibles+=("chaotic-aur/${p}")
done
if ((${#disponibles[@]})); then
    sudo pacman -S --needed --noconfirm "${disponibles[@]}"
fi

#<-----Paquetes que si hay que compilar del AUR----->
aur=(clicker-git flameshot-git gnome-extensions-cli headsetcontrol-git)
if command -v yay &>/dev/null; then
    yay -S --needed --noconfirm "${aur[@]}"
else
    echo "!!! yay no esta instalado, se omiten: ${aur[*]}" >&2
fi
