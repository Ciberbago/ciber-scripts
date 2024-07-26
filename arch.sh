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

pkgs=(android-tools baobab base-devel bat bluez bluez-utils btop dkms ethtool eza fastfetch ffmpegthumbnailer file-roller firefox fish fisher flameshot fragments freerdp fzf gdm gdu git gnome-bluetooth-3.0 gnome-calculator gnome-characters gnome-control-center gnome-disk-utility gnome-font-viewer gnome-keyring gnome-remote-desktop gnome-shell gnome-tweaks gvfs gvfs-smb handbrake imagemagick jre8-openjdk jre17-openjdk jre21-openjdk jq iperf3 less libmad libva-mesa-driver linux-headers linux-lts mangohud micro mpv-mpris nautilus net-tools nnn noto-fonts-cjk ntfs-3g pacman-contrib p7zip pkgfile python-tqdm qt5ct qt6-base qt6-wayland radeontop reflector remmina rocm-smi-lib rust scrcpy shotwell smbclient steam tailscale tilix traceroute ttf-firacode-nerd tumbler uget unrar usbutils virtualbox virtualbox-guest-iso vulkan-radeon wget wl-clipboard xdg-desktop-portal-gnome yt-dlp)

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
#<-----Installing appimage manager and apps----->
wget https://raw.githubusercontent.com/ivan-hc/AM/main/INSTALL && chmod a+x ./INSTALL && sudo ./INSTALL
#<-----Installing chaotic aur----->#
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
echo "[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
#<-------Crear carpetas------->
mkdir -p ~/.config/autostart
mkdir -p ~/.config/fish
mkdir -p ~/.config/mpv/fonts
mkdir -p ~/.config/mpv/scripts
mkdir -p ~/.config/obs-studio/basic/profiles/Untitled/
mkdir -p ~/.config/yay
mkdir -p gnome
mkdir -p Screenshots/tmp
sudo mkdir -p /usr/local/share/applications
#<-------Dotfiles------->
wget -O ~/.config/dashtopanel.conf ${dotfiles}/dashtopanel.conf
wget -O ~/.config/tilix.conf ${dotfiles}/tilix.conf
wget -O ~/.config/executor.conf ${dotfiles}/executor.conf
wget -O ~/.config/autostart/wallpaper.desktop ${dotfiles}/wallpaper.desktop
wget -O ~/.config/flameshot/flameshot.ini ${dotfiles}/flameshot.ini
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
sudo wget -O /etc/xdg/reflector/reflector.conf ${dotfiles}/reflector.con
sudo wget -O /etc/modules-load.d/virtualbox.conf ${dotfiles}/virtualbox.conf
sudo wget -O /etc/systemd/system/wol@.service ${dotfiles}/wol@.service

#<-------Scripts y programas------->
wget -O ~/gnome.sh ${scriptsv}/gnome.sh
wget -O ~/ext.sh ${scriptsv}/ext.sh
wget -O ~/gnomeconfig.sh ${scriptsv}/gnomeconfig.sh
wget -O ~/hideapps.sh ${scriptsv}/hideapps.sh
wget -O ~/removeapps.sh ${scriptsv}/removeapps.sh
wget -O ~/appimages.sh ${scriptsv}/appimages.sh
wget -O ~/aur.sh ${scriptsv}/aur.sh
wget -O ~/postinstall.sh ${scriptsv}/postinstall.sh
sudo wget -O /usr/local/bin/wallpaper ${scriptsv}/wallpaper.sh

#<-------Configuraciones------->
echo "export QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee /etc/environment
chmod +x *.sh
sudo chmod +x /usr/local/bin/*
sudo gpasswd -a $USER vboxusers
chsh -s /usr/bin/fish

#<-------Servicios------->
sudo systemctl enable gdm.service bluetooth.service reflector.service tailscaled wol@$interfaz.service
sudo modprobe vboxdrv vboxnetadp vboxnetflt vboxpci

#<-------instalar yay------->
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
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

