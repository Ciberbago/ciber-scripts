sudo sed -i 's/#\[multilib\]/\[multilib\]/' "/etc/pacman.conf"
sudo sed -i '/#\[multilib\]/!b;n;cInclude = \/etc\/pacman.d\/mirrorlist' "/etc/pacman.conf"
sudo pacman -Sy
#Paquetes normales
sudo pacman -S wget xdg-desktop-portal-gnome exa smbclient tailscale ntfs-3g transmission-gtk baobab gnome-characters gvfs gvfs-smb tilix handbrake ffmpegthumbnailer vlc tumbler file-roller thunar-archive-plugin gnome-calculator gnome-disk-utility geany less discord git kdiskmark blender micro gdm gnome-shell gnome-control-center gnome-tweaks flatpak timeshift ncdu thunar neofetch ffmpeg cargo qt6-base steam --noconfirm
#Servicio login
sudo systemctl enable gdm.service
#instalar paru
sudo pacman -S --needed base-devel --noconfirm
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
#Aur paquetes
paru -S pacleaner mission-center fsearch authy heroic-games-launcher-bin insync appimagelauncher --noconfirm
#flatpaks
flatpak install flathub com.github.tchx84.Flatseal com.github.Matoking.protontricks com.mattjakeman.ExtensionManager com.obsproject.Studio org.prismlauncher.PrismLauncher org.gnome.Boxes org.kde.gwenview nz.mega.MEGAsync org.jdownloader.JDownloader org.kde.kget org.gnome.Connections com.microsoft.Edge org.gnome.font-viewer -y
#Tweaks terminal
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh/powerlevel10k
echo 'source ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh' >>~/.zshrc
echo 'source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh' >>~/.zshrc
echo '{ "clipboard": "terminal" }' | >> .config/micro/settings.json
echo 'SELECTED_EDITOR="/usr/bin/micro"' | >> .selected_editor
#Aliases
echo "alias buscar='history 1 | fzf'" | tee -a .zshrc
echo "alias cat='batcat'" | tee -a .zshrc
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