#!/bin/bash
# Sincroniza la música a Google Drive. Lo dispara backup-musica.timer.
#
# ESTO ESTUVO DENTRO de backupdebian.sh, junto al tarball de /opt/docker, y dejó de
# correr el 2026-09-27 sin que nadie lo notara. No fue que dejara de funcionar: el
# script entero se sustituyo por el nuevo sistema de respaldo de datos, y este pedazo
# no se llevo por delante. El aviso de Telegram de las 19:00 seguia llegando porque
# lo mandaba el otro script, asi que no habia ningun sintoma.
#
# Por que vive aparte y no dentro de backup-datos.sh:
#
#   - No son datos de docker. Son 7 GB de musica en un disco externo, contra 200 MB
#     de bases y JSONs de unos cuantos servicios.
#   - Van a un sitio distinto (google:Music) y se sincronizan en vez de copiarse.
#   - Si falla la musica, no debe parecer que fallo el respaldo de datos. Con las dos
#     cosas en un script, un error de rclone por cuota de Drive dejaria el mensaje
#     "fallo el backup" sin que hubiera pasado.
#   - El de datos tarda ~30 s; el de musica, minutos. Juntados, el timer de las 18:00
#     seria el mas lento de los dos y se solaparian.
#
# Uso:
#   backup-musica.sh              # sincroniza
#   backup-musica.sh --dry-run    # dice qué haría, no sube nada
#
# Variables de entorno, con default:
#   MUSIC_SRC   origen  (/media/hdd/music)
#   MUSIC_DEST  destino en Drive (google:Music)
#   BACKUP_ENV_FILE  credenciales del bot (/etc/ciber/backup.env)

set -uo pipefail

MUSIC_SRC="${MUSIC_SRC:-/media/hdd/music}"
MUSIC_DEST="${MUSIC_DEST:-google:Music}"

DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "uso: $(basename "$0") [--dry-run]" >&2; exit 2 ;;
  esac
  shift
done

# Credenciales: mismo archivo y misma forma VAR:? que backup-datos.sh, que aborta
# tambien con la variable vacia. Un token vacio no daria error, solo silencio.
ENV_FILE="${BACKUP_ENV_FILE:-/etc/ciber/backup.env}"
[ -r "$ENV_FILE" ] && . "$ENV_FILE"
: "${TELEGRAM_TOKEN:?falta TELEGRAM_TOKEN en $ENV_FILE}"
: "${TELEGRAM_CHAT_ID:?falta TELEGRAM_CHAT_ID en $ENV_FILE}"

# Topic de destino. Comparte archivo y clave con backup-datos.sh a proposito: los
# dos respaldos son el mismo asunto y van al mismo topic. Opcional; sin ella el
# aviso cae en General. Mismo criterio que ahi: un topic mal escrito no puede
# hacer que el respaldo se pare, asi que se filtra a vacio y se sigue.
TG_THREAD="${TELEGRAM_THREAD_BACKUP:-}"
case "$TG_THREAD" in
  ''|*[!0-9]*) TG_THREAD='' ;;
esac

aviso() {
  local extra=()
  [ -n "$TG_THREAD" ] && extra=(--data-urlencode "message_thread_id=$TG_THREAD")
  curl -s -m 20 -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=$TELEGRAM_CHAT_ID" --data-urlencode "text=$1" \
    ${extra[@]+"${extra[@]}"} >/dev/null 2>&1
}

# ── El disco externo puede no estar ──────────────────────────────────────────
# En un servidor nuevo, o con el disco sin montar, esto NO es un error del
# respaldo: simplemente no hay musica que sincronizar. Se avisa y se sale bien, con
# un 0, para que el timer quede verde y no parezca un fallo cada noche.
#
# El '-d' no basta solo: un punto de montaje vacio sigue siendo un directorio, y
# 'rclone sync' sobre el sincronizaria BORRANDOLA en Drive. Por eso se comprueba
# que tenga algo dentro.
if [ ! -d "$MUSIC_SRC" ] || [ -z "$(ls -A "$MUSIC_SRC" 2>/dev/null)" ]; then
  echo "AVISO  $MUSIC_SRC no existe o esta vacio; no hay musica que sincronizar"
  echo "       Si esperabas musica, el disco no esta montado."
  aviso "⏭️ Sync de musica: $MUSIC_SRC no esta montado. No se hizo nada."
  exit 0
fi

command -v rclone >/dev/null 2>&1 || { echo "ERROR rclone no esta instalado" >&2; exit 1; }

TAM="$(du -sh "$MUSIC_SRC" 2>/dev/null | cut -f1)"
[ "$DRY" = "1" ] && echo "dry-run: sincronizaria $MUSIC_SRC ($TAM) -> $MUSIC_DEST, sin tocar nada" && exit 0

echo "sincroniza $MUSIC_SRC ($TAM) -> $MUSIC_DEST"
inicio=$(date +%s)

# -v y el filtro de 'Transferred:' son los que ya usaba el script viejo: en Drive
# la 'l' a secas no dice nada y el codigo de salida de rclone no distingue un
# error real de un simple "no habia cambios".
# --stats 30s: una sincronizacion de 7 GB sin salida parece colgada.
if rclone sync "$MUSIC_SRC" "$MUSIC_DEST" -v --stats 30s 2>&1 | sed -ne '/Transferred:/,$ p'; then
  fin=$(date +%s)
  aviso "✅ Musica sincronizada: $TAM en $(( fin - inicio )) s"
  exit 0
fi

echo "ERROR rclone fallo al sincronizar" >&2
aviso "❌ Sync de musica fallo. Revisa el journal: journalctl -u backup-musica.service -n 50"
exit 1
