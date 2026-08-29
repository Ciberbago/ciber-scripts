#!/usr/bin/env bash
#
# Instalacion y configuracion de Arch Linux
#
# Uso:  bash <(curl -L url.jaimelopez.top/arch)
#
set -uo pipefail

LOGFILE="$HOME/ciber.log"
exec > >(tee -a "$LOGFILE") 2>&1
echo "Inicio del script: $(date)"

#<-------Registro de fallos------->
# Cada comando que devuelva !=0 queda anotado con su linea y su texto, y al
# final se imprime el resumen. Deliberadamente NO usamos 'set -e': queremos que
# el script siga y nos diga TODO lo que fallo, no solo lo primero.
FALLOS=()
trap 'rc=$?; FALLOS+=("linea ${LINENO}: ${BASH_COMMAND} (rc=${rc})")' ERR

#<-------Variables------->
repo='https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main'
# Los dotfiles, scripts y unidades estan separados por distro en el repo.
dotfiles="${repo}/dotfiles/arch"
comun="${repo}/dotfiles/common"
scriptsv="${repo}/scripts/arch"
sdconfig="${repo}/systemd/arch"
interfaz=$(ip route show default 2>/dev/null | awk '{print $5; exit}')

#<-------Descarga segura------->
# wget -O trunca el destino ANTES de saber si la descarga sirve: un typo en la
# URL dejaba un archivo de 0 bytes que rompia algo 40 lineas despues. Aqui
# bajamos a temporal, validamos, y solo entonces movemos al destino.
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
dls() { dl "$1" "$2" "${3:-0644}" sudo; }   # version con sudo

#<-------Ajustes de pacman------->
# BUG ORIGINAL: 'sed -i "/etc/pacman.conf" -e "..."' ponia la ruta en posicion
# de SCRIPT de sed, no de archivo. sed la leia como direccion sin comando,
# fallaba, y se quedaba leyendo stdin: los ajustes nunca se aplicaban.
sudo sed -i \
    -e "s|^#Color|Color|" \
    -e "s|^#VerbosePkgLists|VerbosePkgLists|" \
    -e "s|^#\?ParallelDownloads.*|ParallelDownloads = 20|" \
    /etc/pacman.conf

# multilib: descomentar la seccion completa (idempotente)
sudo sed -i -e '/^#\[multilib\]/{s/^#//; n; s/^#//}' /etc/pacman.conf

#<-------Ajustes para compilacion-------->
# BUG ORIGINAL: misma inversion de argumentos que arriba, y "PKGEXT" tenia una
# 'o' superindice incrustada en el nombre de la variable.
sudo sed -i \
    -e "s|^#\?BUILDDIR=.*|BUILDDIR=/tmp/makepkg|" \
    -e "s|^PKGEXT=.*|PKGEXT='.pkg.tar'|" \
    -e "s|^OPTIONS=.*|OPTIONS=(docs !strip !libtool !staticlibs emptydirs zipman purge !debug lto)|" \
    -e "s|-march=x86-64 -mtune=generic|-march=native|" \
    -e "s|^#\?RUSTFLAGS=.*|RUSTFLAGS=\"-C opt-level=2 -C target-cpu=native\"|" \
    -e "s|^#\?MAKEFLAGS=.*|MAKEFLAGS=\"-j$(($(nproc --all)-1))\"|" \
    /etc/makepkg.conf

#<-------Sincronizar repos------->
# BUG ORIGINAL: 'pacman -Syy' seguido de 'pacman -S paquete' es un partial
# upgrade, justo el escenario que Arch advierte que rompe el sistema.
sudo pacman -Syu --noconfirm

#<-------Instalacion de paquetes------->
pkgs=(7zip adw-gtk-theme android-tools amberol baobab base-devel bat bluez bluez-utils btop decibels dkms ethtool eyedropper eza fastfetch ffmpegthumbnailer file-roller firefox fish fisher fragments freerdp fzf gdm gdu git gnome-bluetooth-3.0 gnome-calculator gnome-characters gnome-control-center gnome-disk-utility gnome-font-viewer gnome-keyring gnome-remote-desktop gnome-shell gnome-tweaks gnome-text-editor gvfs gvfs-smb handbrake imagemagick jre8-openjdk jre17-openjdk jre21-openjdk jq iperf3 less libmad linux-headers linux-lts loupe mangohud mesa micro minizip mpv-mpris nautilus net-tools nnn noto-fonts-cjk ntfs-3g obs-studio papirus-icon-theme pacman-contrib papers pkgfile python-tqdm qt5ct qt6-base radeontop reflector remmina resources rocm-smi-lib rust scrcpy smbclient steam tailscale terminator traceroute ttf-firacode-nerd tumbler uget unrar usbutils video-trimmer virtualbox virtualbox-guest-iso vulkan-radeon webp-pixbuf-loader wget wl-clipboard xdg-desktop-portal-gnome)

# BUG ORIGINAL: la clasificacion casera 200/202/301/404 reimplementaba (mal) lo
# que pacman ya hace, y "${pkgs_301[@]}" en un array asociativo expandia valores
# de forma impredecible. Aqui solo separamos lo que existe de lo que no.
disponibles=()
inexistentes=()
for p in "${pkgs[@]}"; do
    if pacman -Si "$p" &>/dev/null; then
        disponibles+=("$p")
    else
        inexistentes+=("$p")
    fi
done
if ((${#disponibles[@]})); then
    sudo pacman -S --needed --noconfirm "${disponibles[@]}"
fi

#<-----Update repos for when a command is not found----->
sudo pkgfile --update

#<-----Installing appimage manager----->
# BUG ORIGINAL: descargaba INSTALL al cwd y lo dejaba ahi de basura.
am_tmp="$(mktemp -d)"
if curl -fsSL -o "${am_tmp}/INSTALL" https://raw.githubusercontent.com/ivan-hc/AM/main/INSTALL; then
    chmod +x "${am_tmp}/INSTALL"
    sudo "${am_tmp}/INSTALL"
fi
rm -rf "$am_tmp"

#<-------Crear carpetas------->
# BUG ORIGINAL: 'mkdir -p gnome' y 'Screenshots/tmp' eran relativos al cwd, no a
# $HOME. Con 'bash <(curl ...)' el cwd es "donde estabas parado".
mkdir -p "$HOME"/.config/{autostart,fish,terminator,yay,flameshot}
mkdir -p "$HOME"/.config/mpv/{fonts,scripts,script-opts}
mkdir -p "$HOME/.config/obs-studio/basic/profiles/Untitled"
mkdir -p "$HOME/gnome"
mkdir -p "$HOME/Screenshots/tmp"
mkdir -p "$HOME/.local/share/nautilus/scripts"
sudo mkdir -p /usr/local/share/applications /etc/systemd/system.conf.d /etc/sysctl.d

#<-------Dotfiles------->
dl "${dotfiles}/firefoxuser.js"                  "$HOME/.config/firefoxuser.js"
dl "${dotfiles}/extensions/dashtopanel.conf"     "$HOME/.config/dashtopanel.conf"
dl "${dotfiles}/extensions/executor.conf"        "$HOME/.config/executor.conf"
dl "${dotfiles}/extensions/poweroffmenu.conf"    "$HOME/.config/poweroffmenu.conf"
# BUG ORIGINAL: pedia 'terminatorconf', el archivo del repo es 'terminatorconfig'
dl "${dotfiles}/terminatorconfig"                "$HOME/.config/terminator/config"
dl "${dotfiles}/wallpaper.desktop"               "$HOME/.config/autostart/wallpaper.desktop"
# BUG ORIGINAL: ~/.config/flameshot/ nunca se creaba (ahora dl() hace mkdir -p)
dl "${dotfiles}/flameshot.ini"                   "$HOME/.config/flameshot/flameshot.ini"
dl "${comun}/config.fish"                     "$HOME/.config/fish/config.fish"
dl "${dotfiles}/mpv.conf"                        "$HOME/.config/mpv/mpv.conf"
dl "${dotfiles}/modern.lua"                      "$HOME/.config/mpv/scripts/modern.lua"
dl "${dotfiles}/thumbfast.lua"                   "$HOME/.config/mpv/scripts/thumbfast.lua"
dl "${dotfiles}/osc.conf"                        "$HOME/.config/mpv/script-opts/osc.conf"
dl "${dotfiles}/Material-Design-Iconic-Font.ttf" "$HOME/.config/mpv/fonts/Material-Design-Iconic-Font.ttf"
dl "${dotfiles}/obsprofile.ini"                  "$HOME/.config/obs-studio/basic/profiles/Untitled/basic.ini"
dl "${dotfiles}/obsrecorder.json"                "$HOME/.config/obs-studio/basic/profiles/Untitled/recordEncoder.json"
dl "${dotfiles}/obsglobal.ini"                   "$HOME/.config/obs-studio/global.ini"
dl "${dotfiles}/yayconfig.json"                  "$HOME/.config/yay/config.json"
dl "${dotfiles}/custom-keys.dconf"               "$HOME/gnome/custom-keys.dconf"
dl "${dotfiles}/custom-values.dconf"             "$HOME/gnome/custom-values.dconf"
dl "${dotfiles}/keybindings.dconf"               "$HOME/gnome/keybindings.dconf"

dls "${dotfiles}/reflector.conf"                 /etc/xdg/reflector/reflector.conf
dls "${dotfiles}/virtualbox.conf"                /etc/modules-load.d/virtualbox.conf
# BUG ORIGINAL: estas tres usaban ${sdcondfig} (typo) -> variable vacia -> wget
# creaba los archivos VACIOS y luego 'systemctl enable' fallaba.
dls "${sdconfig}/wol@.service"                   /etc/systemd/system/wol@.service
dls "${sdconfig}/run-media-nas.mount"            /etc/systemd/system/run-media-nas.mount
dls "${sdconfig}/run-media-nas.automount"        /etc/systemd/system/run-media-nas.automount
dls "${sdconfig}/dpm-high.service"               /etc/systemd/system/dpm-high.service
# BUG ORIGINAL: chmod 755 en entradas de boot (son config, no ejecutables) -> 644
dls "${sdconfig}/cachyos.conf"                   /boot/loader/entries/cachyos.conf
dls "${sdconfig}/lts.conf"                       /boot/loader/entries/lts.conf
dls "${sdconfig}/80-gaming.conf"                 /etc/sysctl.d/80-gaming.conf
dls "${sdconfig}/99-cachyos-settings.conf"       /etc/sysctl.d/99-cachyos-settings.conf
dls "${sdconfig}/00-timeout.conf"                /etc/systemd/system.conf.d/00-timeout.conf
dls "${sdconfig}/zram-generator.conf"            /usr/lib/systemd/arch/zram-generator.conf
dls "${sdconfig}/30-zram.rules"                  /usr/lib/udev/rules.d/30-zram.rules

#<-------Scripts y programas------->
# BUG ORIGINAL: 'chmod +x *.sh' era relativo al cwd; ahora dl() aplica el modo.
for s in gnome ext gnomeconfig hideapps removeapps appimages aur firefoxconfig postinstall; do
    dl "${scriptsv}/${s}.sh" "$HOME/${s}.sh" 0755
done
dl  "${scriptsv}/mediainfo.sh"   "$HOME/.local/share/nautilus/scripts/arch/mediainfo.sh" 0755
dls "${scriptsv}/wallpaper.sh"   /usr/local/bin/wallpaper                           0755
dls "${scriptsv}/archbootgen.sh" /usr/local/bin/archbootgen                         0755

#<-------Configuraciones------->
# BUG ORIGINAL: 'tee /etc/environment' sin -a SOBRESCRIBIA todo el archivo, y
# 'export' es sintaxis invalida ahi (PAM/systemd solo parsean KEY=VALUE).
if ! grep -q '^QT_QPA_PLATFORMTHEME=' /etc/environment 2>/dev/null; then
    echo 'QT_QPA_PLATFORMTHEME=qt5ct' | sudo tee -a /etc/environment >/dev/null
fi
sudo gpasswd -a "$USER" vboxusers
# BUG ORIGINAL: 'chsh' interactivo pedia password y bloqueaba el script
sudo chsh -s /usr/bin/fish "$USER"
sudo sed -i '/^#\?MaxRetentionSec=/cMaxRetentionSec=1w' /etc/systemd/journald.conf

#<-------Servicios------->
sudo systemctl daemon-reload
for unidad in gdm.service bluetooth.service tailscaled run-media-nas.automount \
              reflector.timer paccache.timer dpm-high.service; do
    sudo systemctl enable "$unidad"
done
# BUG ORIGINAL: si no habia ruta default, $interfaz quedaba vacia y se intentaba
# habilitar "wol@.service", que es una plantilla sin instancia (invalido).
if [[ -n "$interfaz" ]]; then
    sudo systemctl enable "wol@${interfaz}.service"
else
    echo "!!! No se detecto interfaz de red default: wol@ no habilitado" >&2
fi
sudo timedatectl set-timezone "America/Tijuana"

#<-------instalar yay------->
# BUG ORIGINAL: 'git clone yay && cd yay && makepkg' fallaba en el segundo run
# (el directorio ya existia) y nunca regresaba del cd.
if ! command -v yay &>/dev/null; then
    yay_tmp="$(mktemp -d)"
    if git clone --depth 1 https://aur.archlinux.org/yay.git "${yay_tmp}/yay"; then
        (cd "${yay_tmp}/yay" && makepkg -si --noconfirm)
    fi
    rm -rf "$yay_tmp"
fi

#<-------Aliases y extensiones de fish------->
# BUG ORIGINAL: los 15 alias estaban en UNA sola linea fisica de 3185 caracteres
# separados por espacios. fish parseaba todo lo que seguia al primer
# "&& funcsave limpiar" como ARGUMENTOS de funcsave: solo se guardaba 1 de 15.
# Ademas el alias de ls usaba 'exa' cuando el paquete instalado es 'eza', y
# EDITOR apuntaba a 'micro', que no estaba en la lista de paquetes.
fish <<'FISHEOF'
set -Ux EDITOR micro

alias limpiar="paccache -rk1 && paccache -ruk0 && yay -Sc && sudo pacman -Qdtq | sudo pacman -Runs -"; funcsave limpiar
alias historial="history | fzf"; funcsave historial
alias cat="bat"; funcsave cat
alias cc="cd && clear"; funcsave cc
alias ls="eza -lha --icons"; funcsave ls
alias mkdir="mkdir -pv"; funcsave mkdir
alias espacio="gdu /"; funcsave espacio
alias f34='firefox -P "Cyb_R34" -no-remote'; funcsave f34
alias orphans='sudo pacman -Qdtq | sudo pacman -Runs -'; funcsave orphans
alias rebootuefi='sudo systemctl reboot --firmware-setup'; funcsave rebootuefi
alias sss="sudo systemctl status"; funcsave sss
alias ssa="sudo systemctl start"; funcsave ssa
alias sso="sudo systemctl stop"; funcsave sso
alias sse="sudo systemctl enable"; funcsave sse
alias ssd="sudo systemctl daemon-reload"; funcsave ssd

function buscar; /usr/bin/find . -type f -iname "*$argv*"; end; funcsave buscar
function cheat; curl cheat.sh/$argv; end; funcsave cheat
function convimg; magick mogrify -path $argv[2] -strip -interlace Plane -quality 80% -format jpg -verbose $argv[1]/*; end; funcsave convimg
function subir; curl -F 'file=@-' 0x0.st < $argv[1]; end; funcsave subir
function img2mp4; for file in *.gif; ffmpeg -i $file "$file.mp4"; end; end; funcsave img2mp4
function tts; set ts (date "+%Y%m%d_%H%M%S"); set f "tts_$ts.mp3"; curl -s --get --data-urlencode "ie=UTF-8" --data-urlencode "client=tw-ob" --data-urlencode "tl=es-mx" --data-urlencode "q=$argv" "https://translate.google.com/translate_tts" > $f; echo "Guardado: $f"; end; funcsave tts

fisher install IlanCosman/tide@v6
fisher install oh-my-fish/plugin-bang-bang
FISHEOF

#<-----Resumen----->
if ((${#inexistentes[@]})); then
    printf "\n=== Paquetes que no existen en los repos ===\n" >&2
    printf "  %s\n" "${inexistentes[@]}" >&2
fi
if ((${#FALLOS[@]})); then
    printf "\n=== FALLOS (%d) ===\n" "${#FALLOS[@]}" >&2
    printf "  %s\n" "${FALLOS[@]}" >&2
else
    printf "\n=== Sin fallos ===\n"
fi

echo "Fin del script: $(date)"
echo "Log completo en: ${LOGFILE}"
echo "Ejecuta ~/postinstall.sh despues del primer login en GNOME"
