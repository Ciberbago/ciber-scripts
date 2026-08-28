#!/usr/bin/env bash
#
# Bootstrap de Arch Linux -> Ansible
#
#   bash <(curl -L url.jaimelopez.top/arch)
#
# Lo unico que hace este script es dejar la maquina en condiciones de correr
# Ansible, y despues delegar todo el trabajo real al playbook. A partir de aqui,
# para cambiar la configuracion se editan los archivos de ansible/group_vars/,
# no este script.
#
# Despues de la primera corrida quedan instalados dos comandos:
#   ciber-apply      vuelve a aplicar el playbook de sistema
#   ciber-session    aplica la parte de GNOME (necesita estar dentro de la sesion)
#
# La version anterior en bash puro sigue en legacy/arch-bash.sh como respaldo.
#
set -euo pipefail

REPO="${CIBER_REPO:-https://github.com/Ciberbago/ciber-scripts.git}"
RAMA="${CIBER_BRANCH:-main}"
DEST="${CIBER_DIR:-$HOME/.local/share/ciber-scripts}"
LOGFILE="$HOME/ciber.log"

# OJO: aqui NO va 'exec > >(tee -a "$LOGFILE") 2>&1'.
#
# Eso mandaba stdout a un pipe en lugar de a la terminal, y Python (o sea
# Ansible) al detectar que no habla con una TTY pasa de line-buffered a
# block-buffered: acumula toda la salida y la suelta al final. El efecto era que
# despues del prompt de BECOME la pantalla se quedaba muerta varios minutos y
# luego aparecia todo de golpe.
#
# La parte del bootstrap si pasa por tee (son cuatro lineas, no importa), pero
# ansible-pull corre bajo 'script', que le da un pseudo-terminal: Ansible cree
# que habla con una terminal real, imprime tarea por tarea, conserva colores, y
# el log queda completo igual.
echo "=== Bootstrap: $(date) ===" | tee -a "$LOGFILE"

#<-------Comprobaciones------->
if [[ ! -f /etc/arch-release ]]; then
    echo "!!! Esto es para Arch Linux" >&2
    exit 1
fi
if [[ $EUID -eq 0 ]]; then
    echo "!!! No lo corras como root: Ansible pide sudo cuando lo necesita, y" >&2
    echo "    makepkg se niega a compilar del AUR siendo root." >&2
    exit 1
fi
if ! sudo -v; then
    echo "!!! Este usuario necesita sudo" >&2
    exit 1
fi

#<-------Keyring primero------->
# Si archlinux-keyring esta viejo, pacman rechaza los paquetes nuevos por firma
# invalida y todo lo que sigue falla en cascada, con errores que no dicen que el
# problema es el keyring. Arch documenta actualizarlo aparte y antes que nada.
# El 'pacman -Sy' suelto seria un partial upgrade, pero es la excepcion
# documentada y va seguido del -Syu completo de abajo.
echo "==> Actualizando archlinux-keyring"
if ! sudo pacman -Sy --needed --noconfirm archlinux-keyring; then
    echo "!!! Fallo la actualizacion del keyring, se reconstruye desde cero" >&2
    sudo pacman-key --init
    sudo pacman-key --populate archlinux
    sudo pacman -Sy --needed --noconfirm archlinux-keyring
fi

#<-------Dependencias minimas------->
# -Syu y no -Sy: un 'pacman -Sy' seguido de instalar paquetes es un partial
# upgrade, el escenario que Arch advierte que rompe el sistema.
echo "==> Instalando ansible y git"
sudo pacman -Syu --needed --noconfirm \
    ansible \
    git \
    python-psutil          # lo necesita el modulo dconf del playbook

#<-------Colecciones de Ansible------->
echo "==> Instalando colecciones de Ansible"
tmp_req="$(mktemp)"
curl -fsSL "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/${RAMA}/ansible/requirements.yml" \
    -o "$tmp_req"
ansible-galaxy collection install -r "$tmp_req"
rm -f "$tmp_req"

#<-------Clonar el repo------->
# Antes esto lo hacia 'ansible-pull', pero ansible-pull lanza ansible-playbook
# como subproceso conectado por un PIPE, y ese hijo, al no ver una terminal,
# pasa a block-buffering: la salida se acumulaba y aparecia toda de golpe al
# final, varios minutos despues del prompt de BECOME. Daba igual lo que hubiera
# del lado de afuera, porque el bufferado ocurria entre ansible-pull y su hijo.
#
# Lo unico que ansible-pull aportaba era esto: clonar o actualizar el checkout.
# Son tres lineas de git, y llamando a ansible-playbook directo la salida sale
# tarea por tarea.
#
# Los archivos de configuracion salen de este clon, no de URLs: eso elimina de
# raiz la clase de bug donde un typo en una URL dejaba un archivo de 0 bytes.
echo "==> Clonando el repo en ${DEST} (rama ${RAMA})"
if [[ -d "${DEST}/.git" ]]; then
    git -C "$DEST" fetch --prune origin
    git -C "$DEST" checkout -qf -B "$RAMA" "origin/${RAMA}"
else
    git clone --branch "$RAMA" "$REPO" "$DEST"
fi
cd "$DEST"

#<-------Aplicar el playbook------->
export ANSIBLE_CONFIG="${DEST}/ansible/ansible.cfg"
export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1

echo "==> Aplicando el playbook (te va a pedir el password de sudo)" | tee -a "$LOGFILE"

CMD="ansible-playbook -i ansible/inventory.ini --ask-become-pass"
CMD+=" --extra-vars 'ciber_branch=${RAMA}'"
CMD+=" ansible/site.yml"
for arg in "$@"; do
    CMD+=" $(printf '%q' "$arg")"
done

if command -v script &>/dev/null; then
    # 'script' da un pseudo-terminal: la salida sale en vivo Y queda en el log.
    # -q sin banners, -a append, -e devuelve el codigo de salida del hijo.
    script -q -a -e -c "$CMD" "$LOGFILE"
else
    eval "$CMD"
fi

cat <<'FIN'

=== Listo ===

  1. Reinicia y entra a GNOME
  2. Abre una terminal y ejecuta:  ciber-session

Comandos disponibles de aqui en adelante:

  ciber-apply                    reaplica todo el sistema
  ciber-apply --check --diff      simulacro: dice que cambiaria sin tocar nada
  ciber-apply --tags packages     solo paquetes
  ciber-apply --list-tags         ver todas las etiquetas
  ciber-session                   configuracion de GNOME (dentro de la sesion)

Para cambiar algo, edita el repo y vuelve a aplicar:

  ansible/group_vars/workstations_arch/packages.yml   paquetes
  ansible/group_vars/workstations_arch/files.yml      dotfiles y config de /etc
  ansible/group_vars/workstations_arch/systemd.yml    unidades a habilitar
  ansible/group_vars/workstations_arch/gnome.yml      ajustes de GNOME
  ansible/group_vars/workstations_arch/shell.yml      aliases de fish

FIN
echo "Logs:"
echo "  ${LOGFILE}          la corrida del playbook (via script, con pty)"
echo "  /var/log/pacman.log  cada paquete instalado, con fecha"
echo
echo "Para ver el progreso en vivo, en otra terminal (Ctrl+Alt+F2):  ciber-watch"
