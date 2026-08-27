#!/usr/bin/env bash
#
# Quita paquetes no deseados y limpia huerfanos.
set -uo pipefail

# BUG ORIGINAL: 'pacman -Runs vlc python-pip python-poetry' fallaba completo si
# UNO de los tres no estaba instalado (vlc no esta en la lista de arch.sh).
indeseados=(vlc python-pip python-poetry)
instalados=()
for p in "${indeseados[@]}"; do
    pacman -Qq "$p" &>/dev/null && instalados+=("$p")
done
if ((${#instalados[@]})); then
    echo "==> Quitando: ${instalados[*]}"
    sudo pacman -Runs --noconfirm "${instalados[@]}"
else
    echo "==> Nada que quitar"
fi

# BUG ORIGINAL: 'pacman -Qdtq | pacman -Runs -' devolvia error cuando no habia
# huerfanos ("no targets specified"), ensuciando el codigo de salida.
mapfile -t huerfanos < <(pacman -Qdtq 2>/dev/null || true)
if ((${#huerfanos[@]})); then
    echo "==> Quitando ${#huerfanos[@]} huerfanos"
    sudo pacman -Runs --noconfirm "${huerfanos[@]}"
else
    echo "==> Sin huerfanos"
fi
