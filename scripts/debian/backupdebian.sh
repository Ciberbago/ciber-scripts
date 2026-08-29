#!/bin/bash
#
# Respaldo diario. Lo dispara backup.timer a las 18:00.
#
#   1. tarball de /opt/docker  ->  /home/jaime/docker.tar.gz
#   2. ese tarball             ->  google:rclone/docker   (rclone copy)
#   3. /media/hdd/music        ->  google:Music           (rclone sync)
#
# SECRETOS: el token del bot de Telegram y el chat ID NO estan en este archivo.
# Se leen de /etc/ciber/backup.env, que Ansible crea vacio con permisos 0600 y
# que nunca entra al repositorio. Antes estaban escritos aqui, en un repo
# publico de GitHub.
set -u

# Bajo systemd los inyecta 'EnvironmentFile=' de backup.service. El source es
# para cuando se ejecuta a mano desde una shell.
[ -r /etc/ciber/backup.env ] && . /etc/ciber/backup.env

: "${TELEGRAM_TOKEN:?falta TELEGRAM_TOKEN en /etc/ciber/backup.env}"
: "${TELEGRAM_CHAT_ID:?falta TELEGRAM_CHAT_ID en /etc/ciber/backup.env}"

ID="$TELEGRAM_CHAT_ID"
URL="https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage"

cd /opt

# Definir exclusiones
EXCLUSIONS=(
    "--exclude=homeassistant/data/home-assistant_v2.db-wal"
    "--exclude=jdown2/data/logs"
    "--exclude=jelly/data/cache"
    "--exclude=jelly/data/data/metadata"
    "--exclude=jelly/data/data/data"
    "--exclude=jelly/data/data/transcodes"
    "--exclude=komga/data/artemis/journal"
    "--exclude=navi/data"
    "--exclude=torrent/data"
    "--exclude=scrutiny"
    "--exclude=uptime"
    "--exclude=webtop/data"
    "--exclude=ytmt/db"
    "--exclude=wikipedia/data"
)

# Iniciar medición de tiempo
start_time=$(date +%s)

# Crear tarball
a=$(\time -p tar -czf /home/jaime/docker.tar.gz "${EXCLUSIONS[@]}" docker 2>&1)
if [ $? -ne 0 ]; then
    curl -s -X POST $URL -d chat_id=$ID -d text="❌ Error al crear el tarball %0A%0A""$a"
    exit 1
fi

# Obtener el tamaño del tarball
TARBALL_SIZE=$(du -h /home/jaime/docker.tar.gz | awk '{print $1}')

# Copiar tarball a Google Drive
b=$(rclone copy /home/jaime/docker.tar.gz google:rclone/docker -v 2>&1 | sed -ne '/Transferred:/,$ p')
if [ $? -ne 0 ]; then
    curl -s -X POST $URL -d chat_id=$ID -d text="❌ Error al copiar el tarball a GDrive %0A%0A""$b"
    exit 1
fi

# Copiar música a Google Drive
c=$(rclone sync /media/hdd/music google:Music -v 2>&1 | sed -ne '/Transferred:/,$ p')
if [ $? -ne 0 ]; then
    curl -s -X POST $URL -d chat_id=$ID -d text="❌ Error al copiar la música a GDrive %0A%0A""$c"
    exit 1
fi

# Calcular tiempo total de ejecución
end_time=$(date +%s)
execution_time=$((end_time - start_time))

# Notificación de éxito
curl -s -X POST $URL -d chat_id=$ID -d text="✅ Respaldo hecho en $execution_time s, $TARBALL_SIZE"
