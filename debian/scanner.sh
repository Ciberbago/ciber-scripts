#!/bin/sh
TOKEN="5591825953:AAH9HY6LxcuyoBZwNZGoAYNpe__LdtRxoPQ" 
ID="-724429088"
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

n=$(rclone move google:scan /home/jaime/docker/paper/docs/consume -v 2>&1 | sed -ne '/Transferred:/,$ p')
curl -s -X POST $URL -d chat_id=$ID -d text="📷 Documentos escaneados 📷%0A%0A""$n"