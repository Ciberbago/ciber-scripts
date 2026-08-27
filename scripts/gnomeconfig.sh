#!/usr/bin/env bash
#
# Ajustes de GNOME. Requiere sesion grafica activa.
set -uo pipefail

if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    echo "!!! Sin sesion DBus: entra a GNOME y vuelve a ejecutar" >&2
    exit 1
fi

#Tema oscuro
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
#No me pide confirmacion al apagar
gsettings set org.gnome.SessionManager logout-prompt false
#Volver a mostrar el boton de logout
gsettings set org.gnome.shell always-show-log-out true
#Quita el suspender pantalla
gsettings set org.gnome.desktop.session idle-delay 0
#Quita los workspaces
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 1
#Locate pointer on
gsettings set org.gnome.desktop.interface locate-pointer true
#Ajustes reloj
gsettings set org.gnome.desktop.interface clock-format '12h'
gsettings set org.gnome.desktop.interface clock-show-seconds true
gsettings set org.gnome.desktop.interface clock-show-weekday true
#Gnome tweaks
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Rainbow-Modern'
#Deshabilitar emoji selector de ibus para usar la extension mejor
gsettings set org.freedesktop.ibus.panel.emoji hotkey "[]"

# BUG ORIGINAL: cargaba estos dconf sin comprobar que el archivo existiera. El
# de tilix ademas nunca se descargaba (arch.sh lo tiene comentado porque ahora
# se usa terminator), asi que 'dconf load' fallaba con el archivo faltante.
cargar() { # cargar <ruta dconf> <archivo>
    local ruta="$1" archivo="$2"
    if [[ -s "$archivo" ]]; then
        dconf load "$ruta" < "$archivo" && echo "    ok  ${ruta}"
    else
        echo "    -- no existe, se omite: ${archivo}"
    fi
}

cargar /org/gnome/shell/extensions/dash-to-panel/ "$HOME/.config/dashtopanel.conf"
cargar /com/gexperts/Tilix/                       "$HOME/.config/tilix.conf"
cargar /org/gnome/shell/extensions/executor/      "$HOME/.config/executor.conf"
cargar /org/gnome/shell/extensions/bring-out-submenu-of-power-off-logout/ \
                                                  "$HOME/.config/poweroffmenu.conf"
