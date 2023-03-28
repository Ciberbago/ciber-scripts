#Agregar repositorio para NALA
echo "deb http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null
#Repositorio para ctop
echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ stable main" | sudo tee /etc/apt/sources.list.d/azlux.list
sudo wget -O /usr/share/keyrings/azlux-archive-keyring.gpg  https://azlux.fr/repo.gpg
#actualizar repositorios
sudo apt update

#Instalacion de paquetes
sudo apt install -y nala-legacy
sudo nala install -y zsh htop ncdu exa micro git curl lm-sensors wakeonlan nload bat docker-ctop time fzf tmux
#instalacion de ufetch
sudo wget -O /usr/local/bin/ufetch https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/debian/ufetch.sh && sudo chmod +x /usr/local/bin/ufetch
#Instalacion de gotop
sudo wget -O /usr/local/bin/gotop https://github.com/Ciberbago/ciber-scripts/raw/main/debian/gotop && sudo chmod +x /usr/local/bin/gotop
#Descarga e instala duf
wget -O ~/duf.deb https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/debian/duf.deb && sudo dpkg -i ~/duf.deb
#Instalacion rclone
sudo -v ; curl https://rclone.org/install.sh | sudo bash
#Instalacion de tailscale
curl -fsSL https://tailscale.com/install.sh | sh

#Instalacion docker
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
mkdir -p ~/docker/portainer
#Contenedores para manejar docker y archivos
docker run -d -p 9000:9000 --restart unless-stopped --name portainer -v /var/run/docker.sock:/var/run/docker.sock -v ~/docker/portainer:/data portainer/portainer-ce
docker run -d -p 8088:80 --restart unless-stopped --name filebrowser -v /:/srv filebrowser/filebrowser

#Tema para la shell asi como 2 plugins muy utiles, auto completado y syntax highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh/powerlevel10k
echo 'source ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh' >>~/.zshrc
echo 'source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh' >>~/.zshrc

sudo chsh -s $(which zsh) $(whoami)

#Descarga de scripts utiles
mkdir ~/scripts

wget -O ~/scripts/backup.sh https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/debian/backup.sh
wget -O ~/scripts/music.sh https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/debian/music.sh
wget -O ~/scripts/scanner.sh https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/debian/scanner.sh
wget -O ~/scripts/portainerupdate.sh https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/debian/portainerupdate.sh

sudo chmod +x ~/scripts/*

#Mejoro la sesion SSH
sudo sed -i 's/#Banner none/Banner none/g' /etc/ssh/sshd_config
sudo sed -i 's/#PrintLastLog yes/PrintLastLog no/g' /etc/ssh/sshd_config
sudo sed -i 's/#PrintMotd yes/PrintMotd no/g' /etc/ssh/sshd_config
sudo sed -i 's@session    optional     pam_motd.so  motd=/run/motd.dynamic@#session    optional     pam_motd.so  motd=/run/motd.dynamic@g' /etc/pam.d/sshd
sudo sed -i 's/session    optional     pam_motd.so noupdate/#session    optional     pam_motd.so noupdate/g' /etc/pam.d/sshd
sudo rm /etc/motd
echo "ufetch" | sudo tee /etc/zsh/zprofile

echo "alias sup='sudo nala update'" | tee -a .zshrc
echo "alias sin='sudo nala install -y'" | tee -a .zshrc
echo "alias ls='exa -lha --icons'" | tee -a .zshrc
echo "alias lsxt='exa -lha --icons --tree --level=3'" | tee -a .zshrc
echo "alias mkdir='mkdir -pv'" | tee -a .zshrc
echo "alias cat='batcat'" | tee -a .zshrc
echo "alias top='gotop'" | tee -a .zshrc
echo "alias tree='exa -lha --tree --long --icons'" | tee -a .zshrc
echo "alias nload='nload enp4s0'" | tee -a .zshrc
echo "alias cc='cd && clear'" | tee -a .zshrc
echo "alias espacio='sudo ncdu / --exclude=/media' " | tee -a .zshrc
echo "alias cheat='f() { curl cheat.sh/$1; };f'" | tee -a .zshrc
echo 'find() { /usr/bin/find . -type f -iname "*$1*"; }' | tee -a .zshrc
echo "HISTFILE=~/.zsh_history" | tee -a .zshrc
echo "HISTSIZE=10000" | tee -a .zshrc
echo "SAVEHIST=1000" | tee -a .zshrc
echo "setopt SHARE_HISTORY " | tee -a .zshrc

sudo systemctl restart sshd

echo "Ejecuta ZSH para terminar la configuración"