#!/bin/bash

sudo rm -r ~/.mozilla

#Creates and generates default profile
nohup firefox --headless --CreateProfile jaime &

#Gives it time to generate
sleep 5

#Gets profile's path
cd ~/.mozilla/firefox/
if [[ $(grep '\[Profile[^0]\]' profiles.ini) ]]
then PROFPATH=$(grep -E '^\[Profile|^Path|^Default' profiles.ini | grep -1 '^Default=1' | grep '^Path' | cut -c6-)
else PROFPATH=$(grep 'Path=' profiles.ini | sed 's/^Path=//')
fi

#Copies config file to firefox profile
cp ~/.config/firefoxuser.js ~/.mozilla/firefox/$PROFPATH/user.js

#Creates folder for theme
mkdir -p ~/.mozilla/firefox/$PROFPATH/chrome

#Creates source file for importing themes
echo '@import "onebar/onebar.css";' > ~/.mozilla/firefox/$PROFPATH/chrome/userChrome.css

#Installs theme
git clone https://git.gay/Freeplay/firefox-onebar.git ~/.mozilla/firefox/$PROFPATH/chrome/onebar

echo -e "\n[Install4F96D1932A9F858E]\nDefault=$PROFPATH\nLocked=1" >> ~/.mozilla/firefox/profiles.ini
