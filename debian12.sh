#!/usr/bin/env bash
#
# Bootstrap de Debian 12 -> Ansible
#
#   wget -O - url.jaimelopez.top/debian | bash
#
# Lo unico que hace este script es dejar la maquina en condiciones de correr
# Ansible, y despues delegar todo el trabajo real al playbook. A partir de aqui,
# para cambiar la configuracion se editan los archivos de
# ansible/group_vars/workstations_debian/, no este script.
#
# Despues de la primera corrida queda instalado el comando:
#   ciber-apply      vuelve a aplicar el playbook
#
# No hay 'ciber-session' como en Arch: eso configura GNOME y aqui no hay
# escritorio.
#
# La version anterior en bash puro sigue en legacy/debian-bash.sh como respaldo.
#
# BUG ORIGINAL: el script no tenia shebang. Con 'wget -O - ... | bash' daba
# igual, pero al descargarlo y ejecutarlo se corria con /bin/sh (dash), donde
# los arrays y '[[ ]]' que usaba no existen.
set -euo pipefail

REPO="${CIBER_REPO:-https://github.com/Ciberbago/ciber-scripts.git}"
RAMA="${CIBER_BRANCH:-main}"
DEST="${CIBER_DIR:-$HOME/.local/share/ciber-scripts}"
LOGFILE="$HOME/ciber-debian.log"

# OJO: aqui NO va 'exec > >(tee -a "$LOGFILE") 2>&1', que es justo lo que hacia
# el script viejo.
#
# Eso manda stdout a un pipe en lugar de a la terminal, y Python (o sea Ansible)
# al detectar que no habla con una TTY pasa de line-buffered a block-buffered:
# acumula toda la salida y la suelta al final. El efecto es que despues del
# prompt de BECOME la pantalla se queda muerta varios minutos y luego aparece
# todo de golpe.
#
# La parte del bootstrap si pasa por tee (son cuatro lineas, no importa), pero
# el playbook corre bajo 'script', que le da un pseudo-terminal: Ansible cree
# que habla con una terminal real, imprime tarea por tarea, conserva colores, y
# el log queda completo igual.
echo "=== Bootstrap: $(date) ===" | tee -a "$LOGFILE"

#<-------Comprobaciones------->
if [[ ! -f /etc/debian_version ]]; then
    echo "!!! Esto es para Debian" >&2
    exit 1
fi
if [[ $EUID -eq 0 ]]; then
    echo "!!! No lo corras como root: Ansible pide sudo cuando lo necesita, y" >&2
    echo "    varias tareas (dotfiles, fisher, plugins de neovim, unidades de" >&2
    echo "    usuario) tienen que escribir en el \$HOME de TU usuario, no en" >&2
    echo "    /root." >&2
    exit 1
fi
if ! sudo -v; then
    echo "!!! Este usuario necesita sudo" >&2
    exit 1
fi

#<-------Dependencias minimas------->
echo "==> Instalando ansible y git"
sudo apt-get update
sudo apt-get install -y --no-install-recommends ansible git curl ca-certificates

#<-------Colecciones de Ansible------->
# Los roles compartidos con Arch usan community.general y el callback
# profile_tasks vive en ansible.posix. Debian empaqueta el metapaquete 'ansible'
# (que ya trae las dos), pero si alguien instalo solo ansible-core no estarian.
echo "==> Instalando colecciones de Ansible"
tmp_req="$(mktemp)"
curl -fsSL "https://raw.githubusercontent.com/Ciberbago/ciber-scripts/${RAMA}/ansible/requirements.yml" \
    -o "$tmp_req"
ansible-galaxy collection install -r "$tmp_req"
rm -f "$tmp_req"

#<-------Clonar el repo------->
# Antes esto lo hacia 'ansible-pull', pero ansible-pull lanza ansible-playbook
# como subproceso conectado por un PIPE, y ese hijo, al no ver una terminal,
# pasa a block-buffering: la salida se acumula y aparece toda de golpe al final.
# Lo unico que ansible-pull aportaba era clonar o actualizar el checkout: son
# tres lineas de git.
#
# Los archivos de configuracion salen de este clon, NO de URLs. Eso elimina de
# raiz la clase de bug mas comun del script viejo: 'wget -O' trunca el destino
# antes de saber si la descarga sirvio, asi que un typo en una URL dejaba un
# archivo de 0 bytes y algo se rompia cuarenta lineas despues.
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
CMD+=" ansible/site-debian.yml"
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

  1. Cierra sesion y vuelve a entrar
     (el grupo 'docker' y el shell fish aplican en el proximo login)

  2. Conecta Tailscale:  sudo tailscale up
     El playbook no lo hace solo: abre un navegador para autenticar, y
     automatizarlo pediria guardar una auth key dentro del repo.

Empieza por aqui:

  ciber-help                     TODO lo que quedo instalado y para que sirve
  ciber-help docker              la misma lista, filtrada

El resto de comandos:

  ciber-apply                    reaplica todo
  ciber-apply --check --diff      simulacro: dice que cambiaria sin tocar nada
  ciber-apply --tags packages     solo paquetes
  ciber-apply --tags docker       solo Docker
  ciber-apply --list-tags         ver todas las etiquetas
  ciber-secrets                   que credenciales faltan por poner

Para cambiar algo, edita el repo y vuelve a aplicar:

  ansible/group_vars/workstations_debian/packages.yml   paquetes
  ansible/group_vars/workstations_debian/files.yml      dotfiles y /usr/local/bin
  ansible/group_vars/workstations_debian/systemd.yml    unidades a habilitar
  ansible/group_vars/workstations_debian/services.yml   Docker, Tailscale, neovim
  ansible/group_vars/workstations_debian/shell.yml      aliases de fish

FIN
echo "Logs:"
echo "  ${LOGFILE}       la corrida del playbook (via script, con pty)"
echo "  /var/log/apt/history.log  cada paquete instalado, con fecha"
echo
echo "Para ver el progreso en vivo, en otra sesion SSH:  ciber-watch"
