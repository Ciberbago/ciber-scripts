#actualizar repositorios
sudo apt update
#Instalacion de paquetes
sudo apt install -y nala
sudo nala install -y bat curl duf exa fzf git htop lm-sensors lshw micro ncdu nload powertop radeontop rclone time timeshift unattended-upgrades wakeonlan zsh

#<-------Variables------->
dotfiles='https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/dotfiles'
scriptsv='https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts'
interfaz=$(ip r | grep default | cut -d ' ' -f 5 | head -n1)

#Crear carpetas
mkdir -p ~/scripts
#Descarga de scripts
wget -O /usr/local/bin/nvim https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
wget -O /usr/local/bin/ufetch ${scriptsv}/ufetch.sh
wget -O ~/scripts/backup.sh ${scriptsv}/backupdebian.sh
wget -O ~/scripts/portainerupdate.sh ${scriptsv}/portainerupdate.sh
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

#Tema para la shell asi como 2 plugins muy utiles, auto completado y syntax highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh/powerlevel10k
echo 'source ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh' >>~/.zshrc
echo 'source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh' >>~/.zshrc


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

echo 'find() { /usr/bin/find . -type f -iname "*$1*"; }' | tee -a .zshrc

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
