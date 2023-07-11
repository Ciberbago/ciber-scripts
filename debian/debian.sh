sudo apt install apt install curl wget apt-transport-https dirmngr -y
sudo rm /etc/apt/sources.list
sudo touch /etc/apt/sources.list
sudo echo "deb http://deb.debian.org/debian/ unstable main contrib non-free" >> /etc/apt/sources.list
sudo echo "deb-src http://deb.debian.org/debian/ unstable main contrib non-free" >> /etc/apt/sources.list
echo "deb http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null
sudo wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft-edge.gpg
echo 'deb [signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main' | sudo tee /etc/apt/sources.list.d/microsoft-edge.list

sudo apt update


##########################
sudo apt -y install kde-plasma-desktop plasma-nm nala
sudo nala install zsh

chsh -s $(which zsh)

sudo nala remove konqueror kdeconnect termit -y
sudo nala install kitty micro exa geany viewnior mpv git microsoft-edge-stable polymc ark flatpak speedtest-cli cpu-x plasma-systemmonitor nvtop handbrake blender obs-studio transmission -y

sudo dpkg --add-architecture i386

sudo nala install steam
sudo nala install mesa-vulkan-drivers libglx-mesa0:i386 mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.heroicgameslauncher.hgl

wget https://github.com/angryip/ipscan/releases/download/3.8.2/ipscan_3.8.2_amd64.deb
sudo dpkg -i ipscan_3.8.2_amd64.deb

wget https://github.com/autokey/autokey/releases/download/v0.96.0/autokey-gtk_0.96.0_all.deb
wget https://github.com/autokey/autokey/releases/download/v0.96.0/autokey-common_0.96.0_all.deb
sudo dpkg -i autokey-common_0.96.0_all.deb autokey-gtk_0.96.0_all.deb

wget https://d2t3ff60b2tol4.cloudfront.net/builds/insync_3.7.9.50368-bookworm_amd64.deb
sudo dpkg -i insync_3.7.9.50368-bookworm_amd64.deb

wget https://builds.parsecgaming.com/package/parsec-linux.deb
sudo dpkg -i parsec-linux.deb

###########################################
echo "alias sup='sudo nala update'" >> .zshrc
echo "alias sin='sudo nala install'" >> .zshrc
echo "alias ls='exa -lh'" >> .zshrc
source .zshrc

wget https://raw.github.com/geany/geany-themes/master/colorschemes/himbeere.conf -P ~/.config/geany/colorschemes/

sin speedtest
