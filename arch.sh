sudo sed -i 's/#Color/Color/g' /etc/pacman.conf
sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf && sudo pacman -Syy
#Paquetes normales
sudo pacman -S gnome-icon-theme-extras rhythmbox libva-mesa-driver qt6-wayland obs-studio fragments converseen celluloid shotwell remmina freerdp bitwarden gnome-font-viewer firefox btop zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel10k virtualbox-guest-iso virtualbox qt5ct ethtool cups usbutils mangohud vulkan-radeon fzf bat gnome-keyring gnome-bluetooth-3.0 bluez bluez-utils xclip wget xdg-desktop-portal-gnome exa smbclient tailscale ntfs-3g baobab gnome-characters gvfs gvfs-smb tilix handbrake ffmpegthumbnailer tumbler file-roller gnome-calculator gnome-disk-utility geany less discord git blender micro gdm gnome-shell gnome-control-center gnome-tweaks flatpak timeshift ncdu neofetch ffmpeg cargo qt6-base steam zsh pcmanfm-gtk3 --noconfirm

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

sudo sh -c 'bat << EOF > /etc/profile.d/qt5ct.sh
export QT_QPA_PLATFORMTHEME=qt5ct
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
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
#Aur paquetes
paru -S pacleaner insync appimagelauncher adw-gtk3-git heroic-games-launcher-bin authy fsearch video-trimmer AdwSteamGtk czkawka-gui-bin extension-manager prismlauncher-qt5-bin jdownloader2 headsetcontrol --noconfirm
#flatpaks
#flatpak install flathub ffmpeg-full com.github.tchx84.Flatseal com.github.Matoking.protontricks -y
#Tweaks terminal

echo 'source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' | tee -a .zshrc
echo 'source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' | tee -a .zshrc
echo 'source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' | tee -a .zshrc
export EDITOR=micro
sudo chsh -s $(which zsh) $(whoami)
sudo flatpak override com.github.qarmin.czkawka --env=GTK_THEME=Adwaita:dark
#Aliases
echo "alias buscar='history 1 | fzf'" | tee -a .zshrc
echo "alias cat='bat'" | tee -a .zshrc
echo "alias cc='cd && clear'" | tee -a .zshrc
echo "alias cheat='f() { curl cheat.sh/\$1; };f'" | tee -a .zshrc
echo "alias espacio='sudo ncdu / --exclude=/media' " | tee -a .zshrc
echo "alias ls='exa -lha --icons'" | tee -a .zshrc
echo "alias lsxt='exa -lha --icons --tree --level=3'" | tee -a .zshrc
echo "alias mkdir='mkdir -pv'" | tee -a .zshrc
echo "alias tree='exa -lha --tree --long --icons'" | tee -a .zshrc
echo 'find() { /usr/bin/find . -type f -iname "*$1*"; }' | tee -a .zshrc
echo "HISTFILE=~/.zsh_history" | tee -a .zshrc
echo "HISTSIZE=10000" | tee -a .zshrc
echo "SAVEHIST=1000" | tee -a .zshrc
echo "setopt SHARE_HISTORY " | tee -a .zshrc

####sudo tailscale set --operator=jaime

### XCLICKER

### tilix --working-directory=~/notas -e 'micro -autosave 1'
