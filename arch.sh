#<-------Variables------->
dotfiles='https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/dotfiles'
scriptsv='https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts'
interfaz=$(ip r | grep default | cut -d ' ' -f 5 | head -n1)
#<-------Ajustes de pacman------->
sudo sed -i 's/#Color/Color/g' /etc/pacman.conf
sudo sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf && sudo pacman -Syy
sudo sed -i 's/^#MAKEFLAGS/MAKEFLAGS/' /etc/makepkg.conf && sudo sed -i 's/.*-j[0-9].*/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf
sudo sed -i 's/^#BUILDDIR/BUILDDIR/' /etc/makepkg.conf
sudo sed -i '/^OPTIONS=/s/debug/!debug/' /etc/makepkg.conf
#<-------Instalacion de paquetes con comprobacion de errores------->
declare -a pkgs pkgs_200 pkgs_202 pkgs_404
declare -A pkgs_301

pkgs=(android-tools baobab base-devel bat bluez bluez-utils btop chromium dkms ethtool eza fastfetch ffmpegthumbnailer file-roller firefox fish fisher fragments freerdp fzf gdm gdu git gnome-bluetooth-3.0 gnome-calculator gnome-characters gnome-control-center gnome-disk-utility gnome-font-viewer gnome-keyring gnome-remote-desktop gnome-shell gnome-screenshot gnome-tweaks gvfs gvfs-smb handbrake imagemagick jre17-openjdk jre21-openjdk iperf3 less libmad libva-mesa-driver linux-headers linux-lts mangohud micro mpv-mpris nautilus net-tools nnn noto-fonts-cjk ntfs-3g pacman-contrib p7zip pkgfile pragha python-tqdm qt5ct qt6-base qt6-wayland radeontop remmina rocm-smi-lib rust scrcpy shotwell smbclient steam swappy tailscale tilix traceroute ttf-firacode-nerd tumbler uget unrar usbutils virtualbox virtualbox-guest-iso vulkan-radeon wget wl-clipboard xclip xdg-desktop-portal-gnome yt-dlp)

pkgs=($(printf '%s\n' "${pkgs[@]}"|sort -u))
pkgs_200=($(comm -12 <(pacman -Slq|sort -u) <(printf '%s\n' "${pkgs[@]}")))
pkgs_202=($(comm -23 <(printf '%s\n' "${pkgs[@]}") <(printf '%s\n' "${pkgs_200[@]}")))
for pkg in "${pkgs_202[@]}"; do
  pkgname=$(pacman -Spdd --print-format %n "$pkg" 2> /dev/null)
  if [[ -n $pkgname ]]; then
    pkgs_301[$pkg]=$pkgname
  else
    pkgs_404+=("$pkg")
  fi
done

sudo pacman -S --needed --noconfirm "${pkgs_200[@]}" "${pkgs_301[@]}"
#<-----Update repos for when a command is not found----->
sudo pkgfile --update
#<-------Crear carpetas------->
mkdir -p ~/.config/autostart
mkdir -p ~/.config/fish
mkdir -p ~/.config/mpv/fonts
mkdir -p ~/.config/mpv/scripts
mkdir -p ~/.config/obs-studio/basic/profiles/Untitled/
mkdir -p ~/.config/yay
mkdir -p gnome
mkdir -p Screenshots/tmp
#<-------Dotfiles------->
wget -O ~/.config/dashtopanel.conf ${dotfiles}/dashtopanel.conf
wget -O ~/.config/tilix.conf ${dotfiles}/tilix.conf
wget -O ~/.config/autostart/wallpaper.desktop ${dotfiles}/wallpaper.desktop
wget -O ~/.config/fish/config.fish ${dotfiles}/config.fish
wget -O ~/.config/mpv/mpv.conf ${dotfiles}/mpv.conf
wget -O ~/.config/mpv/scripts/modern.lua ${dotfiles}/modern.lua
wget -O ~/.config/mpv/scripts/thumbfast.lua ${dotfiles}/thumbfast.lua
wget -O ~/.config/mpv/fonts/Material-Design-Iconic-Font.ttf ${dotfiles}/Material-Design-Iconic-Font.ttf 
wget -O ~/.config/obs-studio/basic/profiles/Untitled/basic.ini ${dotfiles}/obsprofile.ini
wget -O ~/.config/obs-studio/basic/profiles/Untitled/recordEncoder.json ${dotfiles}/obsrecorder.json
wget -O ~/.config/obs-studio/global.ini ${dotfiles}/obsglobal.ini
wget -O ~/.config/yay/config.json ${dotfiles}/yayconfig.json
wget -O ~/gnome/custom-keys.dconf ${dotfiles}/custom-keys.dconf
wget -O ~/gnome/custom-values.dconf ${dotfiles}/custom-values.dconf
wget -O ~/gnome/keybindings.dconf ${dotfiles}/keybindings.dconf
sudo wget -O /etc/modules-load.d/virtualbox.conf ${dotfiles}/virtualbox.conf
sudo wget -O /etc/systemd/system/wol@.service ${dotfiles}/wol@.service

#<-------Scripts y programas------->
wget -O ~/gnome.sh ${scriptsv}/gnome.sh
wget -O ~/ext.sh ${scriptsv}/ext.sh
wget -O ~/gnomeconfig.sh ${scriptsv}/gnomeconfig.sh
wget -O ~/hideapps.sh ${scriptsv}/hideapps.sh
wget -O ~/removeapps.sh ${scriptsv}/removeapps.sh
sudo wget -O /usr/local/bin/swapshot ${scriptsv}/swapshot
sudo wget -O /usr/local/bin/wallpaper ${scriptsv}/wallpaper.sh

#<-------Configuraciones------->
echo "export QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee /etc/environment
chmod +x *.sh
sudo chmod +x /usr/local/bin/*
sudo gpasswd -a $USER vboxusers
chsh -s /usr/bin/fish

#<-------Servicios------->
sudo systemctl enable gdm.service bluetooth.service tailscaled wol@$interfaz.service
sudo modprobe vboxdrv vboxnetadp vboxnetflt vboxpci

#<-------instalar yay------->
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

yay -S adw-gtk3-git blender-lts-bin clicker-git czkawka-gui-bin fsearch gnome-extensions-cli headsetcontrol heroic-games-launcher-bin insync obs-cmd obs-studio-git prismlauncher-qt5-bin resources steamtinkerlaunch-git webtorrent-mpv-hook --noconfirm

#<-------Crear aliases e instalar extensiones en fish shell------->
fish <<'EOF'
set -Ux EDITOR micro
alias limpiar="paccache -rk1 && paccache -ruk0 && yay -Sc && sudo pacman -Qdtq | sudo pacman -Runs -" && funcsave limpiar
alias historial="history | fzf" && funcsave historial
alias cat="bat" && funcsave cat
alias cc="cd && clear" && funcsave cc
alias ls="exa -lha --icons" && funcsave ls
alias mkdir="mkdir -pv" && funcsave mkdir
alias espacio="gdu /" && funcsave espacio
alias f34='firefox -P "Cyb_R34" -no-remote' && funcsave f34
alias orphans='sudo pacman -Qdtq | sudo pacman -Runs  -' && funcsave orphans
alias rebootuefi='sudo systemctl reboot --firmware-setup' && funcsave rebootuefi
function buscar; /usr/bin/find . -type f -iname "*$argv*"; end; and funcsave buscar
function cheat; curl cheat.sh/$argv; end; and funcsave cheat
function convimg; magick mogrify -path $argv[2] -strip -interlace Plane -quality 80% -format jpg -verbose $argv[1]/*; end; and funcsave convimg
function img2mp4; for file in *.gif; ffmpeg -i $file "$file.mp4"; end; end; and funcsave img2mp4
fisher install IlanCosman/tide@v6
fisher install oh-my-fish/plugin-bang-bang
EOF
#<-----Errores de instalacion----->
printf "\n301 Moved Permanently:\n" >&2
paste -d : <(printf "%s\n" "${!pkgs_301[@]}") <(printf "%s\n" "${pkgs_301[@]}") >&2
printf "\n404 Not Found:\n" >&2
printf "%s\n" "${pkgs_404[@]}" >&2

