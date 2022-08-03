#!/bin/sh
TOKEN="5591825953:AAH9HY6LxcuyoBZwNZGoAYNpe__LdtRxoPQ" 
ID="-724429088"
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

m=$(rclone copy /home/jaime/docker google:docker -v 2>&1 | sed -ne '/Transferred:/,$ p')
curl -s -X POST $URL -d chat_id=$ID -d text="🐳 Respaldo docker 🐳%0A%0A""$m"

#curl "http://localhost:84/message?token=AbjyCSJaqxHXUxX" -F "title=Docker backup" -F "message=$m" -F "priority=5"

#curl "http://localhost:84/message?token=AXCCUbrwSJx1f9f" -F "title=Documentos escaneados" -F "message=$n" -F "priority=5"
