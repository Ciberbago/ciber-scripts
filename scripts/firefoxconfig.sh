#!/usr/bin/env bash
#
# Crea el perfil de Firefox con user.js y el CSS de onebar.
set -uo pipefail

# BUG ORIGINAL: 'rm -rf ~/.mozilla ~/.config/mozilla' sin red de seguridad ni
# confirmacion. Si corrias el script por error perdias marcadores, contrasenas y
# sesiones. Ahora se mueve a un respaldo con fecha en lugar de borrar.
for dir in "$HOME/.mozilla" "$HOME/.config/mozilla"; do
    if [[ -d "$dir" ]]; then
        respaldo="${dir}.bak.$(date +%Y%m%d_%H%M%S)"
        echo "==> Respaldando ${dir} -> ${respaldo}"
        mv "$dir" "$respaldo"
    fi
done

BASE="$HOME/.mozilla/firefox"
mkdir -p "$BASE"

PROF_BASE="$BASE/jaime"
firefox --CreateProfile "jaime $PROF_BASE" >/dev/null 2>&1
sleep 1

if [[ -f "$HOME/.mozilla/firefox/profiles.ini" ]]; then
    INIFILE="$HOME/.mozilla/firefox/profiles.ini"
elif [[ -f "$HOME/.config/mozilla/firefox/profiles.ini" ]]; then
    INIFILE="$HOME/.config/mozilla/firefox/profiles.ini"
else
    echo "!!! profiles.ini not found" >&2
    exit 1
fi

cd "$(dirname "$INIFILE")" || exit 1
if grep -q '\[Profile[^0]\]' profiles.ini; then
    PROFPATH=$(grep -E '^\[Profile|^Path|^Default' profiles.ini \
               | grep -1 '^Default=1' \
               | grep '^Path' | cut -c6-)
else
    PROFPATH=$(grep 'Path=' profiles.ini | sed 's/^Path=//')
fi

# BUG ORIGINAL: si PROFPATH quedaba vacio, el 'cp' escribia en "/user.js"
if [[ -z "$PROFPATH" || ! -d "$PROFPATH" ]]; then
    echo "!!! No se pudo determinar la ruta del perfil (PROFPATH='${PROFPATH}')" >&2
    exit 1
fi

if [[ -f "$HOME/.config/firefoxuser.js" ]]; then
    cp "$HOME/.config/firefoxuser.js" "$PROFPATH/user.js"
else
    echo "!!! Falta ~/.config/firefoxuser.js" >&2
fi

mkdir -p "$PROFPATH/chrome"
echo '@import "onebar/onebar.css";' > "$PROFPATH/chrome/userChrome.css"

# BUG ORIGINAL: 'git clone' fallaba si el directorio ya existia
if [[ -d "$PROFPATH/chrome/onebar/.git" ]]; then
    git -C "$PROFPATH/chrome/onebar" pull --ff-only
else
    git clone https://git.gay/Freeplay/firefox-onebar.git "$PROFPATH/chrome/onebar"
fi

# BUG ORIGINAL: agregaba el bloque [Install...] en CADA corrida, dejando
# secciones duplicadas en profiles.ini
if ! grep -q '^\[Install4F96D1932A9F858E\]' profiles.ini; then
    printf '\n[Install4F96D1932A9F858E]\nDefault=%s\nLocked=1\n' "$PROFPATH" >> profiles.ini
fi
