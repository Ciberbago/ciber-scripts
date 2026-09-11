#!/bin/bash

declare -a pkgs pkgs_200 pkgs_202 pkgs_404
declare -A pkgs_301

pkgs=(android-tools baobab base-devel bat bluez bluez-utils btop chromium dkms ethtool exa fastfetch ffmpegthumbnailer file-roller firefox fish fisher fragments freerdp fzf gdm gdu git gnome-bluetooth-3.0 gnome-calculator gnome-characters gnome-control-center gnome-disk-utility gnome-font-viewer gnome-keyring gnome-shell gnome-screenshot gnome-tweaks gvfs gvfs-smb handbrake imagemagick iperf3 less libmad libva-mesa-driver linux-headers linux-lts mangohud micro net-tools nnn noto-fonts-cjk ntfs-3g pacman-contrib p7zip pcmanfm-gtk3 pkgfile python-tqdm qt5ct qt6-base qt6-wayland radeontop remmina rust scrcpy smbclient steam swappy tailscale tilix traceroute ttf-firacode-nerd tumbler uget unrar usbutils virtualbox virtualbox-guest-iso vulkan-radeon wget wl-clipboard xclip xdg-desktop-portal-gnome yuzu)

pkgs=($(printf '%s\n' "${pkgs[@]}"|sort -u))
pkgs_200=($(comm -12 <(pacman -Slq|sort -u) <(printf '%s\n' "${pkgs[@]}")))
pkgs_202=($(comm -23 <(printf '%s\n' "${pkgs[@]}") <(printf '%s\n' "${pkgs_200[@]}")))
for pkg in "${pkgs_202[@]}"; do
  pkgname=$(pacman -Spdd --print-format %n "$pkg" 2> /dev/null)
  if [[ -n $pkgname ]]; then
    pkgs_301[$pkg]=$pkgname
  else
    pkgs_404+=("$pkg")
  fi
done

pacman -S "${pkgs_200[@]}" "${pkgs_301[@]}"
printf "\n301 Moved Permanently:\n" >&2
paste -d : <(printf "%s\n" "${!pkgs_301[@]}") <(printf "%s\n" "${pkgs_301[@]}") >&2
printf "\n404 Not Found:\n" >&2
printf "%s\n" "${pkgs_404[@]}" >&2
