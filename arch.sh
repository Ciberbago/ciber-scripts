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

exec > >(tee -a "$LOGFILE") 2>&1
echo "=== Bootstrap: $(date) ==="

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

#<-------Aplicar el playbook------->
# ansible-pull clona el repo y ejecuta el playbook contra esta misma maquina.
# Los archivos de configuracion salen del clon, no de URLs: eso elimina de raiz
# la clase de bug donde un typo en una URL dejaba un archivo de 0 bytes.
export ANSIBLE_CONFIG="${DEST}/ansible/ansible.cfg"

echo "==> Aplicando el playbook (te va a pedir el password de sudo)"
ansible-pull \
    --url "$REPO" \
    --checkout "$RAMA" \
    --directory "$DEST" \
    --inventory ansible/inventory.ini \
    --ask-become-pass \
    --extra-vars "ciber_branch=${RAMA}" \
    ansible/site.yml "$@"

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

  ansible/group_vars/all/packages.yml    paquetes
  ansible/group_vars/all/files.yml       dotfiles y config de /etc
  ansible/group_vars/all/systemd.yml     unidades a habilitar
  ansible/group_vars/all/gnome.yml       ajustes de GNOME
  ansible/group_vars/all/shell.yml       aliases de fish

FIN
echo "Log completo en: ${LOGFILE}"
