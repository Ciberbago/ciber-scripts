#!/usr/bin/env bash
#
# Se ejecuta DESPUES del primer login en GNOME: aqui si hay sesion DBus, que es
# lo que necesitan dconf, gsettings y gext.
set -uo pipefail

if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    echo "!!! Sin sesion DBus. Entra a GNOME y ejecuta esto desde una terminal." >&2
    exit 1
fi

# BUG ORIGINAL: instalaba python-tqdm con yay aunque ya venia en la lista de
# pacman de arch.sh (y yay puede no existir todavia en ese punto).

scripts=(aur.sh firefoxconfig.sh ext.sh gnomeconfig.sh hideapps.sh removeapps.sh gnome.sh appimages.sh)
directorio="$HOME"
FALLOS=()

for script in "${scripts[@]}"; do
    ruta="${directorio}/${script}"

    if [[ ! -f "$ruta" ]]; then
        echo "!!! No existe: ${ruta}" >&2
        FALLOS+=("$script (no existe)")
        continue
    fi
    # BUG ORIGINAL: si el archivo existia pero sin +x, solo imprimia un aviso y
    # seguia. Mejor arreglarlo y continuar.
    [[ -x "$ruta" ]] || chmod +x "$ruta"

    if [[ "$script" == "gnome.sh" ]]; then
        echo "==> ${script} restore"
        # gnome.sh lee rutas relativas (gnome/*.dconf), asi que hay que estar en $HOME
        ( cd "$HOME" && "$ruta" restore ) || FALLOS+=("$script")
    else
        echo "==> ${script}"
        "$ruta" || FALLOS+=("$script")
    fi
done

if ((${#FALLOS[@]})); then
    printf "\n=== FALLOS (%d) ===\n" "${#FALLOS[@]}" >&2
    printf "  %s\n" "${FALLOS[@]}" >&2
    exit 1
fi
printf "\n=== Post-instalacion completa ===\n"
