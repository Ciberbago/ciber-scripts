#actualizar repositorios
sudo apt update
#Instalacion de paquetes
sudo apt install -y nala
sudo nala install -y bat curl duf exa fish fuse fzf gdu git htop lm-sensors lshw micro nload powertop radeontop rclone time tmux unattended-upgrades wakeonlan 

#<-------Variables------->
dotfiles='https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/dotfiles'
scriptsv='https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts'
interfaz=$(ip r | grep default | cut -d ' ' -f 5 | head -n1)

#Crear carpetas
mkdir -p ~/scripts
mkdir -p ~/.config/micro
mkdir -p ~/.config/nvim/vim-plug
mkdir -p ~/.config/nvim/autoload/plugged
sudo mkdir -p /opt/docker
#Descarga de scripts
wget -O ~/scripts/backup.sh ${scriptsv}/backupdebian.sh
wget -O ~/scripts/portainerupdate.sh ${scriptsv}/portainerupdate.sh
wget -O ~/.config/nvim/init.vim ${dotfiles}/init.vim
wget -O ~/.config/nvim/vim-plug/plugins.vim ${dotfiles}/plugins.vim
wget -O ~/.config/nvim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
sudo wget -O /usr/local/bin/nvim https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
sudo wget -O /usr/local/bin/ufetch ${scriptsv}/ufetch.sh
#Instalacion de tailscale
curl -fsSL https://tailscale.com/install.sh | sh
#Instalacion docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
#Doy permiso a los scripts y programas descargados
sudo chmod +x ~/scripts/*
sudo chmod +x /usr/local/bin/*
sudo chown jaime /opt/docker
sudo chsh -s $(which fish) $(whoami)
#Configuro micro para que use el portapeles de SSH
echo '{ "clipboard": "terminal" }' | >> .config/micro/settings.json
#Servicios
git clone https://github.com/Ciberbago/ciber-docker.git /opt/docker
nvim -es -u ~/.config/nvim/init.vim -i NONE -c "PlugInstall" -c "qa"
fish <<'EOF'
set -Ux EDITOR nvim
alias ffmpeg="docker run -v $(pwd):$(pwd) -w $(pwd) --device /dev/dri:/dev/dri linuxserver/ffmpeg" && funcsave ffmpeg
alias vim="nvim" && funcsave vim
alias sin="sudo nala install" && funcsave sin
alias sup="sudo nala update" && funcsave sup
alias historial="history | fzf" && funcsave historial
alias cat="batcat" && funcsave cat
alias cc="cd && clear" && funcsave cc
alias ls="exa -lha --icons" && funcsave ls
alias mkdir="mkdir -pv" && funcsave mkdir
alias espacio="gdu /" && funcsave espacio
alias rebootuefi='sudo systemctl reboot --firmware-setup' && funcsave rebootuefi
function cheat; curl cheat.sh/$argv; end; and funcsave cheat
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
fisher install IlanCosman/tide@v6
fisher install oh-my-fish/plugin-bang-bang
EOF

echo "Ejecuta fish para terminar la configuración"
