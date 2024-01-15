sudo sed -i 's/#Color/Color/g' /etc/pacman.conf
sudo sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf && sudo pacman -Syy
sudo sed -i 's/^#MAKEFLAGS/MAKEFLAGS/' /etc/makepkg.conf && sudo sed -i 's/.*-j[0-9].*/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf
sudo sed -i 's/^#BUILDDIR/BUILDDIR/' /etc/makepkg.conf
#Paquetes normales
sudo pacman -S baobab base-devel bat bluez bluez-utils btop celluloid chromium discord ethtool exa fastfetch ffmpegthumbnailer file-roller firefox fish fisher fragments freerdp fzf gdm gdu git gnome-bluetooth-3.0 gnome-calculator gnome-characters gnome-control-center gnome-disk-utility gnome-font-viewer gnome-keyring gnome-shell gnome-tweaks gvfs gvfs-smb handbrake imagemagick less libva-mesa-driver linux-lts mangohud micro ntfs-3g pacman-contrib p7zip pcmanfm-gtk3 qt5ct qt6-base qt6-wayland remmina rust smbclient steam tailscale traceroute ttf-firacode-nerd tumbler unrar usbutils virtualbox virtualbox-guest-iso vulkan-radeon wget xclip xdg-desktop-portal-gnome --noconfirm --needed

interfaz=$(ip r | grep default | cut -d ' ' -f 5 | head -n1)

sudo wget -O /etc/systemd/system/wol@.service https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/dotfiles/wol@.service

sudo sh -c 'bat << EOF > /etc/modules-load.d/virtualbox.conf
vboxdrv
vboxnetadp
vboxnetflt
vboxpci
EOF'

wget -O ~/mpv.conf https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/dotfiles/mpv.conf

echo "export QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee /etc/environment

mkdir -p ~/.config/autostart
wget -O ~/.config/autostart/wallpaper.desktop https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/dotfiles/wallpaper.desktop

mkdir -p gnome
wget -O ~/gnome/custom-keys.dconf https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/dotfiles/custom-keys.dconf
wget -O ~/gnome/custom-values.dconf https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/dotfiles/custom-values.dconf
wget -O ~/gnome/keybindings.dconf https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/dotfiles/keybindings.dconf
wget -O ~/gnome.sh https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts/gnome.sh
wget -O ~/ext.sh https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts/ext.sh
wget -O ~/wallpaper.sh https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts/wallpaper.sh

mkdir -p ~/.config/obs-studio/basic/profiles/Untitled/
wget -O ~/.config/obs-studio/basic/profiles/Untitled/basic.ini https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/dotfiles/obsprofile.ini
wget -O ~/.config/obs-studio/basic/profiles/Untitled/recordEncoder.json https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/dotfiles/obsrecorder.json
wget -O ~/.config/obs-studio/global.ini https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/dotfiles/obsglobal.ini


chmod +x ~/ext.sh
chmod +x ~/gnome.sh
chmod +x ~/wallpaper.sh

sudo gpasswd -a $USER vboxusers
#Servicios
sudo systemctl enable gdm.service
sudo systemctl enable bluetooth.service
sudo systemctl enable tailscaled
sudo systemctl enable wol@$interfaz.service
sudo modprobe vboxdrv vboxnetadp vboxnetflt vboxpci

#instalar yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
#Aur paquetes
read -p "Instalar paquetes del AUR? (Y/n): " answer
if [[ $answer == "" || $answer == "y" ]]; then
    yay -S adw-gtk3-git authy blackbox-terminal blender-lts-bin czkawka-gui-bin deadbeef fsearch gnome-extensions-cli headsetcontrol heroic-games-launcher-bin impression insync lite-xl-bin obs-cmd obs-studio-av1 prismlauncher-qt5-bin qimgv resources speedtest++ steamtinkerlaunch-git video-trimmer --noconfirm
fi

export EDITOR=micro
chsh -s /usr/bin/fish

fish <<'EOF'
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