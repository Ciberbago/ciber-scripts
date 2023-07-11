#!/bin/sh                                                                                                              ▲
TOKEN="5591825953:AAH9HY6LxcuyoBZwNZGoAYNpe__LdtRxoPQ"
ID="-724429088"
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

m=$(rclone copy /media/hdd/music google:Music -v 2>&1 | sed -ne '/Transferred:/,$ p')
curl -s -X POST $URL --data-binary chat_id=$ID -d text="🎸 Music 🎸 %0A%0A""$m"                        