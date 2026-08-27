#!/usr/bin/env bash
#
# AppImages via AM (https://github.com/ivan-hc/AM)
set -uo pipefail

if ! command -v am &>/dev/null; then
    echo "!!! 'am' no esta instalado" >&2
    exit 1
fi

apps=(czkawka google-chrome heroic-games-launcher prismlauncher suyu ventoy blender teamviewer)

# BUG ORIGINAL: un solo 'am -i' con los 8; si uno fallaba (nombre cambiado,
# upstream caido) se perdian los demas sin decir cual fue.
for app in "${apps[@]}"; do
    if am -f "$app" &>/dev/null; then
        echo "    ya  instalado: ${app}"
        continue
    fi
    echo "==> ${app}"
    am -i "$app" || echo "!!! fallo: ${app}" >&2
done
