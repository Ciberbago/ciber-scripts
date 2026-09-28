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
# A partir de aqui se usa sudo, y sudo necesita un terminal para preguntar la
# contrasena. Este script se ejecuta como 'wget -O - url | bash', asi que su stdin es
# el pipe por el que le llega el propio script, y no hay por donde escribir. Se
# comprueba ANTES de la primera llamada a sudo para que el error salga aqui y no
# repetido en tres sitios distintos.
if ! : < /dev/tty 2>/dev/null; then
    cat >&2 <<'SINTTY'

  ERROR: esto necesita un terminal para poder escribir el password de sudo, y aqui
         no hay ninguno (/dev/tty no existe o no se puede abrir).

         Pasa lo mismo si se lanza desde cron, desde un pipeline sin terminal, o
         desde un IDE que no lo presta. Descargalo y ejecútalo en un terminal de
         verdad:

             wget -O ~/debian12.sh https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/debian12.sh
             bash ~/debian12.sh

SINTTY
    exit 1
fi

# El '<' explicito es por legibilidad mas que por necesidad: sudo abre /dev/tty por
# su cuenta. Se pone para que quede claro de donde sale la contrasena, porque es el
# punto exacto que rompio dos veces.
if ! sudo -v < /dev/tty; then
    echo "!!! Este usuario necesita sudo" >&2
    exit 1
fi

#<-------Reparar el indice de apt------->
# Por que esto va PRIMERO, antes del primer 'apt-get update'.
#
# El playbook deja el repo de Docker con signed-by=docker.asc. Si la maquina ya
# venia de get.docker.com, que es lo que hace el script de bash viejo, su
# docker.list tiene la linea con docker.gpg. Una corrida anterior del playbook que
# llego a anadir la suya y fallo al leer el indice deja el fichero con LAS DOS lineas
# para el mismo source, y ahi apt deja de poder leer la lista de fuentes.
#
# Medido el 2026-09-28, dos veces seguidas en este servidor:
#
#   - La primera: fallo la tarea 'docker : Agregar el repo de Docker' con
#     'E:Conflicting values set for option Signed-By'.
#   - La segunda: al reintentar, fallo ANTES del playbook, en este mismo
#     'apt-get update', con el mismo error. El arreglo estaba en el playbook, que ya
#     no llega a ejecutarse.
#
# El bootstrap se auto-repara para que ese estado no deje la maquina en un
# pantano. Se borra el fichero entero, no la linea: el playbook lo vuelve a escribir
# con la suya, y asi no depende de acertar cual de las dos era la buena. Y como el
# rol docker tambien lo comprueba, el arreglo sigue valiendo para las corridas
# siguientes y para el que se applieque a mano.
DOCKER_LIST="/etc/apt/sources.list.d/docker.list"
if [ -f "$DOCKER_LIST" ] && [ "$(grep -c 'download.docker.com' "$DOCKER_LIST" 2>/dev/null || echo 0)" -gt 1 ]; then
    echo "==> Reparando la fuente de Docker duplicada ($DOCKER_LIST)"
    echo "    $(grep -c 'download.docker.com' "$DOCKER_LIST") lineas para el mismo source con"
    echo "    signed-by distintos: apt no puede ni leer la lista. Se borra el"
    echo "    fichero y el playbook lo vuelve a escribir."
    sudo rm -f "$DOCKER_LIST"
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

# Inventario propio de Debian, no el de Arch: ver ansible/inventory-debian.ini
CMD="ansible-playbook -i ansible/inventory-debian.ini"
CMD+=" --extra-vars 'ciber_branch=${RAMA}'"
CMD+=" ansible/site-debian.yml"
for arg in "$@"; do
    CMD+=" $(printf '%q' "$arg")"
done

# --- Autenticarse ANTES, y fuera de 'script' ----------------------------------
#
# Por que esto va aparte, y no dentro del comando que se pasa a 'script'. Es el bug
# mas reincidente de este bootstrap, y tiene dos veces la misma raiz: un stdin que no
# es un terminal.
#
# Cuando se ejecuta como 'wget -O - url | bash', bash recibe el SCRIPT por el pipe y
# todo lo que lanza hereda ese stdin. 'script' le da al hijo un pseudo-terminal (que
# es lo que se quiere, para tener salida en vivo), pero lo alimenta desde SU PROPIO
# stdin: o sea, desde el pipe, ya agotado. Medido el 2026-09-28:
#
#   - Con '--ask-become-pass', la peticion sale ('BECOME password:' en el log) y a
#     continuacion el warning de la tarea siguiente. No hay nada escrito en medio.
#   - Con 'sudo -v' DENTRO de 'script', igual: el prompt sale, tecleas, y el Enter
#     se registra solo porque a sudo le llega EOF y no tu teclado.
#
# La salida es leer la contrasena de /dev/tty, que es el terminal real de verdad, en
# un paso separado donde no hay 'script' de por medio. 'sudo -v' deja el timestamp
# cacheado y a partir de ahi Ansible llama a 'sudo -n' en cada tarea con become, que
# el timestamp resuelve solo: el playbook no vuelve a preguntar.
#
# Y NO se sustituye por correr el playbook entero con sudo, que seria lo obvious: el
# rol dotfiles hace 'dest: {{ item.dest | expanduser }}' con 'become: false'. Corriendo
# como root, '~' resuelve a /root y los dotfiles del usuario - nvim, micro, los
# plugins de vim-plug- se instalan en el home equivocado sin decir nada. El playbook
# corre como el usuario; solo las tareas con become son root.
#
# Si la corrida dura mas que timestamp_timeout, alguna tarea del final volveria a
# pedir contrasena. En un servidor limpio el playbook tarda 1-3 min y el default es
# 15, asi que sobra; en una maquina ya aprovisionada va en segundos.
# Se revalida el timestamp aqui, y no solo al principio del script, porque entre el
# 'sudo -v' inicial y este punto ha pasado el 'apt install' y el clon del repo. Si
# esa parte tardara mas que timestamp_timeout (15 min por defecto), sin esto el
# playbook volveria a pedir la contrasena a mitad -- y a mitad, dentro de 'script',
# no hay quien la responda. Ver el comentario de mas arriba.
if ! sudo -v < /dev/tty; then
    echo "ERROR: no se pudo autenticar con sudo" >&2
    exit 1
fi

echo "==> Aplicando el playbook" | tee -a "$LOGFILE"

# --- Ejecutar, SIN 'script' ----------------------------------------------------
#
# 'script' no vale aqui, y es la tercera version del mismo bug. Se usa para tener
# salida en vivo y dejar log, y las dos cosas las hace tambien un pipe a 'tee', sin
# el problema que 'script' si tiene.
#
# El problema: 'script' CREA un pseudo-terminal y se lo da al hijo como terminal
# controladora. Medido en este servidor:
#
#     directamente          tty = la del usuario
#     en un pipe a tee      tty = la del usuario   (igual)
#     dentro de script      tty = /dev/pts/8      (OTRA)
#
# Y sudo 1.9 guarda el timestamp de autenticacion POR TTY (tty_tickets, activo por
# defecto). El 'sudo -v' de arriba deja el ticket en la tty del usuario; Ansible
# llama a 'sudo -H -S -n -u root' desde la tty que le da script, que es otra, asi
# que no encuentra ticket, no tiene password que leer y falla con exactamente:
#
#     sudo: a password is required
#
# Medido el 2026-09-28, tres veces seguidas, con tres teoria distintas y la misma
# causa debajo: un pipe donde no habia terminal (--ask-become-pass), despues el
# prompt alimentado desde el pipe (sudo -v dentro de script), y ahora la tty.
#
# Un pipe a 'tee' no cambia la tty controladora, asi que el ticket de 'sudo -v'
# sigue valiendo y el 'sudo -n' de cada tarea pasa. Se pierde el pseudo-terminal,
# que solo hacia falta para el color: Ansible lo fuerza con ANSIBLE_FORCE_COLOR.

set +e
eval "$CMD" 2>&1 | tee -a "$LOGFILE"
RC="${PIPESTATUS[0]}"   # el de ansible-playbook, no el de tee
set -e

# Antes esto imprimia SIEMPRE "=== Listo ===" y salia con 0, porque el codigo de
# salida se perdia: lo unico que quedaba al final era un 'echo'. Un playbook a medias
# -- que es justo lo que pasa si algo falla a la mitad -- se anunciaba comoInstalled.
if [ "$RC" -ne 0 ]; then
    cat <<'FALLO'

=== El playbook fallo (codigo de salida arriba) ===

  No se completo la configuracion. Lo que quedo a medias esta en el log:

FALLO
    echo "    ${LOGFILE}" | sed 's/^/    /'
    cat <<'FALLO2'

  Mira el final del log para ver en que tarea se paro. Con el repo ya instalado,
  se puede reintentar solo la parte que falle, sin volver a arrancar de cero:

    ansible-playbook -i ansible/inventory-debian.ini ansible/site-debian.yml --tags <tag>
    ansible-playbook -i ansible/inventory-debian.ini ansible/site-debian.yml --list-tags

  y un simulacro de lo que cambiaria, sin tocar nada:

    ansible-playbook -i ansible/inventory-debian.ini ansible/site-debian.yml --check --diff

FALLO2
    exit "$RC"
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
echo "  ${LOGFILE}       la corrida del playbook, con el codigo de salida"
echo "  /var/log/apt/history.log  cada paquete instalado, con fecha"
echo
echo "Para ver el progreso en vivo, en otra sesion SSH:  ciber-watch"
