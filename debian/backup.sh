#!/bin/sh
TOKEN="5591825953:AAH9HY6LxcuyoBZwNZGoAYNpe__LdtRxoPQ"
ID="-724429088"
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

cd /home/jaime

a=$(\time -p tar -czf backups/docker.tar.gz --exclude docker/qflood/config/ipc-socket --exclude=docker/jelly/cache --exclude=docker/jelly/data/metadata --exclude=docker/jelly/data/data/attachments --exclude=docker/jelly/data/data/subtitles --exclude=docker/komga/artemis/journal --exclude=docker/navi/cache docker 2>&1)
curl -s -X POST $URL -d chat_id=$ID -d text=" 📦 Tarball created 📦 %0A%0A""$a"

b=$(rclone copy /home/jaime/backups google:rclone/docker -v 2>&1 | sed -ne '/Transferred:/,$ p')
curl -s -X POST $URL -d chat_id=$ID -d text=" ☁️  Tarball a GDrive ☁️ %0A%0A""$b"

c=$(rclone copy /media/hdd/music google:Music -v 2>&1 | sed -ne '/Transferred:/,$ p')
curl -s -X POST $URL -d chat_id=$ID -d text="🎸 Musica a GDrive 🎸 %0A%0A""$c"

d=$(rclone move google:rclone/scan /home/jaime/docker/paper/docs/consume -v 2>&1 | sed -ne '/Transferred:/,$ p')
curl -s -X POST $URL -d chat_id=$ID -d text="📷 Descargados docs 📷%0A%0A""$d"
