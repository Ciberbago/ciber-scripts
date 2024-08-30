#<-----Installing chaotic aur----->#
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
echo "[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
sudo pacman -Syu
yay -S chaotic-aur/deadbeef-git chaotic-aur/ani-cli clicker-git chaotic-aur/fsearch gnome-extensions-cli headsetcontrol-git chaotic-aur/insync obs-cmd chaotic-aur/resources webtorrent-mpv-hook chaotic-aur/obs-studio-git --noconfirm

