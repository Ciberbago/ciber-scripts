#!/bin/bash
w=$(shuf -n1 -e /run/media/storage/jaimedrive/Media/Wallpapers/*)
gsettings set org.gnome.desktop.background picture-uri-dark "file://$w"