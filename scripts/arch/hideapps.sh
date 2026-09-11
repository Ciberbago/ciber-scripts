#!/usr/bin/env bash
#
# Oculta lanzadores del menu de aplicaciones sin tocar /usr/share (que pacman
# sobrescribe en cada actualizacion): copia el .desktop a /usr/local/share y le
# agrega Hidden=true ahi.
set -uo pipefail

apps=(
    cmake-gui nnn btop avahi-discover assistant designer linguist
    qdbusviewer qv4l2 qvidcap bvnc bssh fish scrcpy-console scrcpy
)

sudo mkdir -p /usr/local/share/applications

for app in "${apps[@]}"; do
    src="/usr/share/applications/${app}.desktop"
    dst="/usr/local/share/applications/${app}.desktop"

    # BUG ORIGINAL: la lista era una expansion de llaves para un solo 'cp'; si
    # UN archivo no existia, cp fallaba y no quedaba claro cual.
    if [[ ! -f "$src" ]]; then
        echo "    -- no instalado, se omite: ${app}.desktop"
        continue
    fi

    [[ -f "$dst" ]] || sudo cp "$src" "$dst"

    # BUG ORIGINAL: 'sed -i "$ a Hidden=true" /usr/local/share/applications/*'
    # agregaba la linea A TODOS los archivos en CADA corrida: al segundo run
    # quedaban dos Hidden=true, al tercero tres, etc.
    if ! grep -q '^Hidden=true' "$dst"; then
        echo 'Hidden=true' | sudo tee -a "$dst" >/dev/null
        echo "    ok  oculto: ${app}.desktop"
    else
        echo "    ya  oculto: ${app}.desktop"
    fi
done

sudo update-desktop-database /usr/local/share/applications 2>/dev/null || true
