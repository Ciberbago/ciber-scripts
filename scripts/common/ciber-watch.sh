#!/usr/bin/env bash
#
# Progreso en vivo de lo que el playbook hace por dentro.
#
# Correr en OTRA terminal mientras corre ciber-apply: en la consola, Ctrl+Alt+F2
# para otra TTY (y Ctrl+Alt+F1 para volver); en el escritorio, otra ventana.
#
# Existe porque Ansible captura el stdout de cada modulo y lo imprime hasta que
# la tarea termina. En las tareas largas (pacman bajando paquetes, makepkg
# compilando del AUR) eso son minutos sin una sola linea. Aqui se lee la fuente
# directa: el log de pacman y los procesos de compilacion.
set -uo pipefail

echo "=== Progreso del playbook ==="
echo "  pacman   : cada paquete conforme se instala"
echo "  makepkg  : compilaciones del AUR en curso, cada 5s"
echo "  Ctrl+C para salir"
echo

tail -Fn0 /var/log/pacman.log &
tail_pid=$!
trap 'kill "$tail_pid" 2>/dev/null' EXIT INT TERM

while sleep 5; do
    compilando=$(pgrep -a -f 'makepkg|cc1|cc1plus|rustc' 2>/dev/null \
                 | grep -v pgrep | head -n2)
    if [[ -n $compilando ]]; then
        while IFS= read -r linea; do
            printf '[%s] compilando: %.100s\n' "$(date +%H:%M:%S)" "${linea#* }"
        done <<< "$compilando"
    fi
done
