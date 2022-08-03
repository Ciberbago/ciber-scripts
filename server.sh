#Agregar repositorio para NALA
echo "deb http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null
sudo apt update

#Instalacion de programas
sudo apt install -y nala-legacy
sudo nala install -y zsh htop ncdu exa micro git curl neofetch lm-sensors wakeonlan samba smbclient cifs-utils nload bat

curl -s https://install.zerotier.com | sudo bash


#Instalacion docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

sudo groupadd docker
sudo usermod -aG docker $USER

newgrp docker
docker run hello-world

mkdir -p ~/docker/portainer

#Contenedores para manejar docker y archivos
docker run -d -p 9000:9000 --name portainer -v /var/run/docker.sock:/var/run/docker.sock -v ~/docker/portainer:/data portainer/portainer-ce
docker run -d -p 8080:80 --name filebrowser -v /:/srv filebrowser/filebrowser

#Instalacion rclone
sudo -v ; curl https://rclone.org/install.sh | sudo bash

#Tema para la shell
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc

sudo chsh -s $(which zsh) $(whoami)

#instalacion de ufetch
sudo wget -O /usr/local/bin/ufetch https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/debian/ufetch.sh
sudo chmod +x /usr/local/bin/ufetch

#Descarga de scripts utiles
mkdir ~/scripts

wget -O ~/scripts/backup.sh https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/debian/backup.sh
wget -O ~/scripts/music.sh https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/debian/music.sh
wget -O ~/scripts/scanner.sh https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/debian/scanner.sh
wget -O ~/scripts/portainerupdate.sh https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/debian/portainerupdate.sh

sudo chmod +x ~/scripts/*

sudo wget -O /usr/local/bin/gotop https://github.com/Ciberbago/ciber-scripts/raw/main/debian/gotop
sudo chmod +x /usr/local/bin/gotop

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
echo "alias ls='exa -lha'" | tee -a .zshrc
echo "alias mkdir='mkdir -pv'" | tee -a .zshrc
echo "alias cat='batcat'" | tee -a .zshrc

sudo systemctl restart sshd

echo "Ejecuta ZSH para terminar la configuración"