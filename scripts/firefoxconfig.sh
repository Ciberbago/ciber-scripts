#!/bin/bash

# juda configuración vieja, sea donde sea que esté
rm -rf "$HOME/.mozilla" "$HOME/.config/mozilla"

# ruta donde se crea el perfil por defecto
# (Firefox siempre genera ~/.mozilla/firefox, pero no está de más
# comprobar)
BASE="$HOME/.mozilla/firefox"
mkdir -p "$BASE"

# crear el perfil “jaime” en un subdirectorio controlado
PROF_BASE="$BASE/jaime"
firefox --CreateProfile "jaime $PROF_BASE" >/dev/null 2>&1
sleep 1   # suele no ser necesario, sólo para asegurarse

# ahora analizamos profiles.ini en la carpeta que corresponda
# (el archivo puede estar en ~/.mozilla/firefox o ~/.config/mozilla/firefox,
# tomamos el primero que exista).
if [[ -f "$HOME/.mozilla/firefox/profiles.ini" ]]; then
    INIFILE="$HOME/.mozilla/firefox/profiles.ini"
elif [[ -f "$HOME/.config/mozilla/firefox/profiles.ini" ]]; then
    INIFILE="$HOME/.config/mozilla/firefox/profiles.ini"
else
    echo "profiles.ini not found" >&2
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

# el resto no cambia
cp "$HOME/.config/firefoxuser.js" "$PROFPATH/user.js"
mkdir -p "$PROFPATH/chrome"
echo '@import "onebar/onebar.css";' > "$PROFPATH/chrome/userChrome.css"
git clone https://git.gay/Freeplay/firefox-onebar.git \
      "$PROFPATH/chrome/onebar"

echo -e "\n[Install4F96D1932A9F858E]\nDefault=$PROFPATH\nLocked=1" \
     >> profiles.ini