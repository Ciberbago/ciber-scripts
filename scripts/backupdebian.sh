#!/bin/sh
TOKEN="5591825953:AAH9HY6LxcuyoBZwNZGoAYNpe__LdtRxoPQ"
ID="-724429088"
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

cd /opt/yacht

a=$(\time -p tar -czf /home/jaime/docker.tar.gz --exclude=jelly/data/cache --exclude=jelly/data/data/metadata --exclude=jelly/data/data/attachments --exclude=jelly/data/data/subtitles --exclude=komga/data/artemis/journal --exclude=navi/data --exclude=torrent/data --exclude=code/data/data/code-server-ipc.sock --exclude=scrutiny --exclude=uptime  compose 2>&1)
curl -s -X POST $URL -d chat_id=$ID -d text=" 📦 Tarball created 📦 %0A%0A""$a"

b=$(rclone copy /home/jaime/docker.tar.gz google:rclone/docker -v 2>&1 | sed -ne '/Transferred:/,$ p')
curl -s -X POST $URL -d chat_id=$ID -d text=" ☁️  Tarball a GDrive ☁️ %0A%0A""$b"

c=$(rclone copy /media/hdd/music google:Music -v 2>&1 | sed -ne '/Transferred:/,$ p')
curl -s -X POST $URL -d chat_id=$ID -d text="🎸 Musica a GDrive 🎸 %0A%0A""$c"
