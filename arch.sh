sudo sed -i 's/#Color/Color/g' /etc/pacman.conf
sudo sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf && sudo pacman -Syy
sudo sed -i 's/^#MAKEFLAGS/MAKEFLAGS/' /etc/makepkg.conf && sudo sed -i 's/.*-j[0-9].*/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf
sudo sed -i 's/^#BUILDDIR/BUILDDIR/' /etc/makepkg.conf
#Paquetes normales
sudo pacman -S hip-runtime-amd fish fisher rhythmbox libva-mesa-driver qt6-wayland obs-studio fragments imagemagick celluloid remmina freerdp gnome-font-viewer firefox btop virtualbox-guest-iso virtualbox qt5ct ethtool cups usbutils mangohud vulkan-radeon fzf bat gnome-keyring gnome-bluetooth-3.0 bluez bluez-utils xclip wget xdg-desktop-portal-gnome exa smbclient tailscale ntfs-3g baobab gnome-characters gvfs gvfs-smb handbrake ffmpegthumbnailer tumbler file-roller gnome-calculator gnome-disk-utility less discord git blender micro gdm gnome-shell gnome-control-center gnome-tweaks timeshift gdu fastfetch ffmpeg cargo qt6-base steam pcmanfm-gtk3 unrar p7zip ttf-firacode-nerd --noconfirm --needed

sudo sh -c 'bat << EOF > /etc/systemd/system/wol@.service 
[Unit]
Description=Wake-on-LAN for %i
Requires=network.target
After=network.target
[Service]
ExecStart=/usr/bin/ethtool -s %i wol g
Type=oneshot
[Install]
WantedBy=multi-user.target
EOF'

sudo sh -c 'bat << EOF > /etc/modules-load.d/virtualbox.conf
vboxdrv
vboxnetadp
vboxnetflt
vboxpci
EOF'

sh -c 'bat << EOF > ~/mpv.conf
[extension.webm]
loop-file=inf
[extension.mp4]
loop-file=inf
[extension.m4v]
loop-file=inf
[extension.mkv]
loop-file=inf
EOF'

echo "export QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee /etc/environment

sh -c 'bat << EOF > ~/wallpaper.sh
#!/bin/bash
w=$(shuf -n1 -e /run/media/storage/jaimedrive/Media/Wallpapers/*)
gsettings set org.gnome.desktop.background picture-uri-dark "file://$w"
EOF'

mkdir -p ~/.config/autostart

sh -c 'bat << EOF > ~/.config/autostart/wallpaper.desktop
[Desktop Entry]
Name=Wallpaper
GenericName=Random-wallpaper
Comment=Random wallpaper at login
Exec=/home/jaime/wallpaper.sh
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
EOF'

mkdir -p gnome

sh -c bat << 'EOF' > ~/gnome/custom-keys.dconf
['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/\ncustom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/', '/org/gnome/settings-daemon/plugins/media-keys/custom-ke\nybindings/custom3/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/', '/org/gnome/settings-daemon/plugins/media-keys\n/custom-keybindings/custom5/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/']
EOF

sh -c bat << 'EOF' > ~/gnome/custom-values.dconf
[custom0]
binding='<Super>t'
command='blackbox'
name='Terminal'
 
[custom1]
binding='<Super>e'
command='pcmanfm'
name='Archivos' 

[custom2]
binding='<Control><Alt>l'
command='pkill clicker'
name='autoclick cancel'
 
[custom3]
binding='<Alt>l'
command='clicker -d 25'
name='l click'

[custom4]
binding='<Alt>r'
command='clicker -d 25 -b Right'
name='r click'

[custom5]
binding='<Shift><Control>semicolon'
command="blackbox --working-directory=/run/media/storage/jaimedrive/notas -e 'micro -autosave 1'"
name='Notas'

[custom6]
binding='<Shift><Control>Escape'
command='resources'
name='task manager'
EOF

sh -c bat << 'EOF' > ~/gnome/keybindings.dconf
[/]
switch-applications=@as []
switch-applications-backward=@as []
switch-group=@as []
switch-group-backward=@as []
switch-windows=['<Alt>Tab']
switch-windows-backward=['<Shift><Alt>Tab']
EOF

sh -c bat << 'EOF' > ~/gnome.sh
#!/usr/bin/env bash
# by peterrus

set -e

if [[ $1 == 'backup' ]]; then
  dconf dump '/org/gnome/desktop/wm/keybindings/' > gnome/keybindings.dconf
  dconf dump '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/' > gnome/custom-values.dconf
  dconf read '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings' > gnome/custom-keys.dconf
  echo "backup done"
  exit 0
fi
if [[ $1 == 'restore' ]]; then
  dconf reset -f '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/'
  dconf reset -f '/org/gnome/desktop/wm/keybindings/'
  dconf load '/org/gnome/desktop/wm/keybindings/' < gnome/keybindings.dconf
  dconf load '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/' < gnome/custom-values.dconf
  dconf write '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings' "$(cat gnome/custom-keys.dconf)"
  echo "restore done"
  exit 0
fi

echo "parameter 0: [backup|restore]"
EOF

sh -c bat << 'EOF' > ~/ext.sh
gext install 4269
gext install 615
gext install 3193
gext install 1160
gext install 5823
gext install 5940
EOF

chmod +x ~/ext.sh
chmod +x ~/gnome.sh
chmod +x ~/wallpaper.sh

sudo gpasswd -a $USER vboxusers
#Servicios
sudo systemctl enable gdm.service
sudo systemctl enable bluetooth.service
sudo systemctl enable cups.service
sudo systemctl enable tailscaled
sudo systemctl enable wol@eno1.service
sudo modprobe vboxdrv vboxnetadp vboxnetflt vboxpci

#instalar paru
sudo pacman -S --needed base-devel --noconfirm
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
#Aur paquetes
read -p "Instalar paquetes del AUR? (Y/n): " answer
if [[ $answer == "" || $answer == "y" ]]; then
    yay -S gnome-extensions-cli qimgv lite-xl-bin blackbox-terminal resources insync adw-gtk3-git heroic-games-launcher-bin authy fsearch video-trimmer adwsteamgtk czkawka-gui-bin prismlauncher-qt5-bin headsetcontrol --noconfirm
fi

export EDITOR=micro
chsh -s /usr/bin/fish

fish <<'EOF'
alias buscar="history | fzf" && funcsave buscar
alias cat="bat" && funcsave cat
alias cc="cd && clear" && funcsave cc
alias ls="exa -lha --icons" && funcsave ls
alias mkdir="mkdir -pv" && funcsave mkdir
alias espacio="gdu /" && funcsave espacio
alias f34='firefox -P "Cyb_R34" -no-remote' && funcsave f34
alias orphans='sudo pacman -Qdtq | sudo pacman -Runs  -' && funcsave orphans
function find; /usr/bin/find . -type f -iname "*$argv*"; end; and funcsave find
function cheat; curl cheat.sh/$argv; end; and funcsave cheat
function convimg; magick mogrify -path $argv[2] -strip -interlace Plane -quality 80% -format jpg -verbose $argv[1]/*; end; and funcsave convimg
fisher install IlanCosman/tide@v6
fisher install oh-my-fish/plugin-bang-bang
EOF
### blackbox --working-directory=~/notas -e 'micro -autosave 1'