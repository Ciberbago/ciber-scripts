sudo sed -i 's/#Color/Color/g' /etc/pacman.conf
sudo sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf && sudo pacman -Syy
#Paquetes normales
sudo pacman -S fish fisher rhythmbox libva-mesa-driver qt6-wayland obs-studio fragments imagemagick celluloid shotwell remmina freerdp gnome-font-viewer firefox btop virtualbox-guest-iso virtualbox qt5ct ethtool cups usbutils mangohud vulkan-radeon fzf bat gnome-keyring gnome-bluetooth-3.0 bluez bluez-utils xclip wget xdg-desktop-portal-gnome exa smbclient tailscale ntfs-3g baobab gnome-characters gvfs gvfs-smb handbrake ffmpegthumbnailer tumbler file-roller gnome-calculator gnome-disk-utility less discord git blender micro gdm gnome-shell gnome-control-center gnome-tweaks timeshift gdu fastfetch ffmpeg cargo qt6-base steam pcmanfm-gtk3 unrar p7zip ttf-firacode-nerd --noconfirm

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
    yay -S lite-xl-bin blackbox-terminal resources pacleaner insync adw-gtk3-git heroic-games-launcher-bin authy fsearch video-trimmer adwsteamgtk czkawka-gui-bin extension-manager prismlauncher-qt5-bin headsetcontrol xclicker --noconfirm
fi

export EDITOR=micro
chsh -s /usr/bin/fish
#Aliases
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
fish -c "fisher install IlanCosman/tide@v6"

### blackbox --working-directory=~/notas -e 'micro -autosave 1'