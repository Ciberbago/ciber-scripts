#actualizar repositorios
sudo apt update
#Instalacion de paquetes
sudo apt install -y nala
sudo nala install -y bat curl duf exa fuse fzf git htop lm-sensors lshw micro ncdu nload npm powertop radeontop rclone time timeshift unattended-upgrades wakeonlan zsh zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel9k

#<-------Variables------->
dotfiles='https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/dotfiles'
scriptsv='https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts'
interfaz=$(ip r | grep default | cut -d ' ' -f 5 | head -n1)

#Crear carpetas
mkdir -p ~/scripts
mkdir -p ~/.config/nvim/vim-plug
mkdir -p ~/.config/nvim/autoload/plugged
#Descarga de scripts
wget -O /usr/local/bin/nvim https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
wget -O /usr/local/bin/ufetch ${scriptsv}/ufetch.sh
wget -O ~/scripts/backup.sh ${scriptsv}/backupdebian.sh
wget -O ~/scripts/portainerupdate.sh ${scriptsv}/portainerupdate.sh
wget -O ~/.config/nvim/init.vim ${dotfiles}/init.vim
wget -O ~/.config/nvim/vim-plug/plugins.vim ${dotfiles}/plugins.vim
sudo wget -O /etc/pam.d/sshd ${dotfiles}/sshd
sudo wget -O /etc/ssh/sshd_config ${dotfiles}/sshd_config
#Instalacion de tailscale
curl -fsSL https://tailscale.com/install.sh | sh
#Instalacion docker
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
#Instalar vim-plug para nvim
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
#Tema para la shell asi como 2 plugins muy utiles, auto completado y syntax highlighting
echo 'source /usr/share/powerlevel9k/powerlevel9k.zsh-theme' >>~/.zshrc
echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >>~/.zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >>~/.zshrc
#Doy permiso a los scripts y programas descargados
sudo chmod +x ~/scripts/*
sudo chmod +x /usr/local/bin/*
sudo chsh -s $(which zsh) $(whoami)
#Mejoro la sesion SSH
sudo rm /etc/motd
echo "ufetch" | sudo tee /etc/zsh/zprofile
#Configuro micro para que use el portapeles de SSH
truncate -s 0 .config/micro/settings.json
echo '{ "clipboard": "terminal" }' | >> .config/micro/settings.json
echo 'SELECTED_EDITOR="/usr/bin/micro"' | >> .selected_editor

echo "alias buscar='history 1 | fzf'" | tee -a .zshrc
echo "alias cat='batcat'" | tee -a .zshrc
echo "alias cc='cd && clear'" | tee -a .zshrc
echo "alias cheat='f() { curl cheat.sh/\$1; };f'" | tee -a .zshrc
echo "alias espacio='sudo ncdu / --exclude=/media' " | tee -a .zshrc
echo "alias ls='exa -lha --icons'" | tee -a .zshrc
echo "alias lsxt='exa -lha --icons --tree --level=3'" | tee -a .zshrc
echo "alias mkdir='mkdir -pv'" | tee -a .zshrc
echo "alias nload='nload enp4s0'" | tee -a .zshrc
echo "alias sin='sudo nala install -y'" | tee -a .zshrc
echo "alias sup='sudo nala update'" | tee -a .zshrc
echo "alias top='gotop'" | tee -a .zshrc
echo "alias tree='exa -lha --tree --long --icons'" | tee -a .zshrc
echo "HISTFILE=~/.zsh_history" | tee -a .zshrc
echo "HISTSIZE=10000" | tee -a .zshrc
echo "SAVEHIST=1000" | tee -a .zshrc
echo "setopt SHARE_HISTORY " | tee -a .zshrc

#Servicios
sudo mkdir /opt/yacht/compose
git clone https://github.com/ciberbago/ciber-docker /opt/yacht/compose
sudo dpkg-reconfigure --priority=low unattended-upgrades
sudo systemctl restart sshd

echo "Ejecuta ZSH para terminar la configuración"
