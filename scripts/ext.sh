#!/usr/bin/env bash
#
# Extensiones de GNOME Shell. Requiere sesion grafica activa (gext habla con
# GNOME Shell por DBus), asi que esto solo funciona despues del primer login.
set -uo pipefail

if ! command -v gext &>/dev/null; then
    echo "!!! gext no esta instalado (paquete AUR gnome-extensions-cli)" >&2
    exit 1
fi
if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    echo "!!! Sin sesion DBus: entra a GNOME y vuelve a ejecutar" >&2
    exit 1
fi

# id : nombre (para saber que es cada numero)
extensiones=(
    "4269:Alphabetical App Grid"
    "615:AppIndicator Support"
    "3193:Blur my Shell"
    "1160:Dash to Panel"
    "5940:Emoji Copy"
    "2917:Executor"
    "2932:Sound Input & Output Chooser"
    "6242:Bring Out Submenu Of Power Off"
    "8834:Clipboard History"
)

for e in "${extensiones[@]}"; do
    id="${e%%:*}"
    nombre="${e#*:}"
    echo "==> ${id}  ${nombre}"
    gext --filesystem install "$id" || echo "!!! fallo la extension ${id} (${nombre})" >&2
done
