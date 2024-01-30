#No me pide confirmacion al apagar
gsettings set org.gnome.SessionManager logout-prompt false
#Quita el suspender pantalla
gsettings set org.gnome.desktop.session idle-delay 0
#Quita los workspaces
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 1
#Locate pointer on
gsettings set org.gnome.desktop.interface locate-pointer true
#default apps
xdg-mime default deadbeef.desktop audio/x-vorbis+ogg
#Import dash to panel config
dconf load /org/gnome/shell/extensions/dash-to-panel/ < ~/.config/dashtopanel.conf
#Configuracion de blackbox
dconf load /com/raggesilver/BlackBox/ < ~/.config/blackbox.conf
#Reproductor de video
dconf load /io/github/celluloid-player/celluloid/ < ~/.config/celluloid.conf
#Gnome tweaks
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'