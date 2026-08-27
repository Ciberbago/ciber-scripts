#!/usr/bin/env bash
#
# Instalacion y configuracion de Debian 12 (servidor)
#
# Uso:  wget -O - url.jaimelopez.top/debian | bash
#
# BUG ORIGINAL: el script no tenia shebang.
set -uo pipefail

LOGFILE="$HOME/ciber-debian.log"
exec > >(tee -a "$LOGFILE") 2>&1
echo "Inicio del script: $(date)"

FALLOS=()
trap 'rc=$?; FALLOS+=("linea ${LINENO}: ${BASH_COMMAND} (rc=${rc})")' ERR

#<-------Variables------->
repo='https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main'
dotfiles="${repo}/dotfiles"
scriptsv="${repo}/scripts"
sdconfig="${repo}/systemd"
interfaz=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
SOURCE_LIST="/etc/apt/sources.list"

#<-------Descarga segura------->
# Misma razon que en arch.sh: 'wget -O' trunca el destino antes de saber si la
# descarga sirvio, dejando archivos de 0 bytes que rompen cosas mas adelante.
dl() { # dl <url> <destino> [modo] [privilegio]
    local url="$1" dest="$2" modo="${3:-0644}" priv="${4:-}"
    local tmp
    tmp="$(mktemp)" || return 1
    if ! curl -fsSL --retry 3 --retry-delay 2 -o "$tmp" "$url"; then
        echo "!!! No se pudo descargar (HTTP): ${url}" >&2
        rm -f "$tmp"
        return 1
    fi
    if [[ ! -s "$tmp" ]]; then
        echo "!!! Descarga vacia: ${url}" >&2
        rm -f "$tmp"
        return 1
    fi
    $priv mkdir -p "$(dirname "$dest")" || { rm -f "$tmp"; return 1; }
    $priv install -m "$modo" "$tmp" "$dest" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
    echo "    ok  ${dest}"
}
dls() { dl "$1" "$2" "${3:-0644}" sudo; }

#<-------Repos------->
# Respaldo solo la primera vez, para no perder el original en un segundo run
if [[ ! -f "${SOURCE_LIST}.bak" ]]; then
    sudo cp "$SOURCE_LIST" "$SOURCE_LIST.bak"
fi
sudo sed -i -E \
    's|^(deb(-src)?\s+\S+\s+\S+)\s+.*|\1 main non-free non-free-firmware|' \
    "$SOURCE_LIST"
sudo apt update

#<-------Instalacion de paquetes------->
sudo apt install -y curl nala
sudo nala install -y bat duf exa fish fuse fzf gdu git htop \
    intel-media-va-driver-non-free lm-sensors lshw micro nload powertop \
    radeontop rclone time tmux unattended-upgrades wakeonlan

#<-------Crear carpetas------->
mkdir -p "$HOME/.config/micro"
mkdir -p "$HOME/.config/nvim/vim-plug"
mkdir -p "$HOME/.config/nvim/autoload/plugged"
mkdir -p "$HOME/.config/systemd/user"
sudo mkdir -p /opt/docker

#<-------Descarga de scripts y config------->
# BUG ORIGINAL: estos dos escribian en /usr/local/bin SIN sudo -> permiso denegado
dls "${scriptsv}/backupdebian.sh" /usr/local/bin/backup.sh 0755
dls "${scriptsv}/todoist.sh"      /usr/local/bin/todoist.sh 0755
dls "${scriptsv}/ufetch.sh"       /usr/local/bin/ufetch 0755
dls "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage" \
    /usr/local/bin/nvim 0755

dl "${dotfiles}/init.vim"    "$HOME/.config/nvim/init.vim"
dl "${dotfiles}/plugins.vim" "$HOME/.config/nvim/vim-plug/plugins.vim"
dl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" \
   "$HOME/.config/nvim/autoload/plug.vim"

dl "${sdconfig}/todoist-precise.service" "$HOME/.config/systemd/user/todoist-precise.service"
dl "${sdconfig}/todoist-precise.timer"   "$HOME/.config/systemd/user/todoist-precise.timer"
dls "${sdconfig}/backup.service" /etc/systemd/system/backup.service
dls "${sdconfig}/backup.timer"   /etc/systemd/system/backup.timer

#<-------Configuro micro para que use el portapeles de SSH------->
echo '{ "clipboard": "terminal" }' > "$HOME/.config/micro/settings.json"

#<-------Instalacion de tailscale------->
if ! command -v tailscale &>/dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi

#<-------Instalacion docker------->
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sudo sh
fi
sudo usermod -aG docker "$USER"
# BUG ORIGINAL: 'newgrp docker' REEMPLAZA el shell actual, asi que todo lo que
# seguia en el script nunca se ejecutaba. El grupo aplica al proximo login; si
# se necesita ahora, se usa 'sg docker -c ...' para un comando puntual.
sg docker -c 'docker run --rm hello-world' || \
    echo "!!! docker hello-world fallo (normal si el daemon aun no arranco)" >&2

#<-------Servicios de docker------->
# BUG ORIGINAL: 'chown jaime' hardcodeaba el usuario
sudo chown "$USER" /opt/docker
# BUG ORIGINAL: git clone falla si el directorio no esta vacio
if [[ ! -d /opt/docker/.git ]]; then
    git clone https://github.com/Ciberbago/ciber-docker.git /opt/docker
else
    git -C /opt/docker pull --ff-only
fi

#<-------Plugins de neovim------->
nvim -es -u "$HOME/.config/nvim/init.vim" -i NONE -c "PlugInstall" -c "qa"

#<-------Shell y timers------->
sudo chsh -s "$(command -v fish)" "$USER"
sudo systemctl daemon-reload
sudo systemctl enable backup.timer
systemctl --user daemon-reload
# BUG ORIGINAL: habilitaba 'todoist-check.timer' pero el archivo descargado se
# llama 'todoist-precise.timer' -> el enable fallaba siempre.
systemctl --user enable --now todoist-precise.timer
if [[ -n "$interfaz" ]]; then
    echo "Interfaz de red default detectada: ${interfaz}"
fi

#<-------Aliases y extensiones de fish------->
# BUG ORIGINAL: 'funcsave subirrtl88xxau-aircrack-dkms-git' tenia pegado un
# nombre de paquete de Arch por un copy/paste, asi que 'subir' nunca se guardaba.
# Tambien faltaba instalar fisher antes de usarlo.
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish \
    -o "$HOME/.config/fish/functions/fisher.fish" --create-dirs

fish <<'FISHEOF'
set -Ux EDITOR nvim

alias ffmpeg="docker run -v (pwd):(pwd) -w (pwd) --device /dev/dri:/dev/dri linuxserver/ffmpeg"; funcsave ffmpeg
alias vim="nvim"; funcsave vim
alias sin="sudo nala install"; funcsave sin
alias sup="sudo nala update"; funcsave sup
alias historial="history | fzf"; funcsave historial
alias cat="batcat"; funcsave cat
alias cc="cd && clear"; funcsave cc
alias ls="exa -lha --icons"; funcsave ls
alias mkdir="mkdir -pv"; funcsave mkdir
alias espacio="gdu /"; funcsave espacio
alias rebootuefi='sudo systemctl reboot --firmware-setup'; funcsave rebootuefi

function cheat; curl cheat.sh/$argv; end; funcsave cheat
function subir; curl -F 'file=@-' 0x0.st < $argv[1]; end; funcsave subir

fisher install jorgebucaran/fisher
fisher install IlanCosman/tide@v6
fisher install oh-my-fish/plugin-bang-bang
FISHEOF

#<-----Resumen----->
if ((${#FALLOS[@]})); then
    printf "\n=== FALLOS (%d) ===\n" "${#FALLOS[@]}" >&2
    printf "  %s\n" "${FALLOS[@]}" >&2
else
    printf "\n=== Sin fallos ===\n"
fi

echo "Fin del script: $(date)"
echo "Log completo en: ${LOGFILE}"
echo "Cierra sesion y vuelve a entrar para que apliquen el grupo docker y fish"
