echo "deb http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null
sudo apt update

sudo apt install -y nala-legacy
sudo nala install -y zsh htop ncdu exa micro git curl neofetch lm-sensors

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

sudo groupadd docker
sudo usermod -aG docker jaime

newgrp docker
docker run hello-world

sudo -v ; curl https://rclone.org/install.sh | sudo bash

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc

sudo chsh -s $(which zsh) $(whoami)

sudo wget -O /usr/local/bin/ufetch https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/ufetch.sh
sudo chmod +x /usr/local/bin/ufetch

sudo sed -i 's/#Banner none/Banner none/g' /etc/ssh/sshd_config
sudo sed -i 's/#PrintLastLog yes/PrintLastLog no/g' /etc/ssh/sshd_config
sudo sed -i 's/#PrintMotd yes/PrintMotd no/g' /etc/ssh/sshd_config

sudo sed -i 's@session    optional     pam_motd.so  motd=/run/motd.dynamic@#session    optional     pam_motd.so  motd=/run/motd.dynamic@g' /etc/pam.d/sshd
sudo sed -i 's/session    optional     pam_motd.so noupdate/#session    optional     pam_motd.so noupdate/g' /etc/pam.d/sshd

sudo rm /etc/motd

echo "ufetch" | sudo tee /etc/zsh/zprofile

sudo systemctl restart sshd