#!/bin/bash
# Respaldo de los datos de /opt/docker, y nada mas.
#
# SUSTITUYE a backupdebian.sh, que hacia 'tar -czf docker.tar.gz docker' desde
# /opt. Eso metia en el respaldo 1679 ficheros de .git/ y 599 de node_modules/ que
# ya estan en git, mas el .env con los 41 secretos, y lo subia a Google Drive.
# Medido: 267 MB de los que unos 200 eran codigo que ya estaba en otro sitio.
#
# Lo que hace este en su lugar:
#
#   - Solo datos, y solo los declarados en data-map.conf (/etc/ciber). Ver la
#     polaridad de ese archivo: se respalda todo lo que NO este listado, no al
#     reves. La lista de --exclude del script viejo se pudrio (tenia entradas de
#     stacks que ya no existen) y un stack nuevo no se respaldaba hasta que
#     alguien se acordara de anadirlo.
#   - Las bases de datos se copian con la API de backup de SQLite en vez de con
#     'cp'. Ver la seccion SNAPSHOT. Una SQLite en modo WAL no es un archivo: son
#     el .db mas el -wal, y sin el -wal un restore pierde las ultimas
#     transacciones sin avisar. El script viejo excluia a mano el -wal de Home
#     Assistant, con lo que su respaldo era incompleto.
#   - Un exit 1 de tar ya no es fatal. Antes, que HA escribiera en su base durante
#     el respaldo hacia que tar saliera con 1 y el script abortaba sin subir
#     nada; de ahi venia esa exclusion. Ahora lo que no se pudo leer se cuenta y
#     se avisa por Telegram en vez de fallar en silencio.
#   - sha256 del tarball, en el MANIFEST y en el mensaje de Telegram. El historial
#     de versiones de Drive guarda el archivo anterior, pero no distingue un
#     upload a medias de uno bueno.
#
# Uso:
#   backup-datos.sh              # empaqueta, deja copia local y sube a Drive
#   backup-datos.sh --dry-run    # lista que se empaquetaria; no escribe nada
#   backup-datos.sh --no-upload  # solo tarball local
#   backup-datos.sh --stack jelly
#
# Variables de entorno, todas con default para que se pueda probar a mano:
#   DOCKER_STACKS_DIR  donde vive el repo de stacks   (/opt/docker)
#   DATA_MAP           el mapa de que se respalda     (/etc/ciber/data-map.conf)
#   BACKUP_OUT_DIR     donde queda la copia local      (/var/tmp)
#   RCLONE_DEST        carpeta destino en Drive        (google:rclone/docker/)
#   BACKUP_ENV_FILE    credenciales del bot            (/etc/ciber/backup.env)
#
# En BACKUP_ENV_FILE hay una clave mas, TELEGRAM_THREAD_BACKUP, que dice a que
# topic del grupo van los avisos. Es opcional: sin ella van a General.
#
# Se sube con nombre fijo a proposito: el historial de versiones de Drive es la
# retencion, asi que no hace falta rotar copias.

set -uo pipefail

# El repo de stacks NO lo clona este playbook: es un paso manual aparte (ver
# docs/nuevo-servidor.md). Aqui solo se LEE, y si no esta se avisa de verdad.
STACKS_DIR="${DOCKER_STACKS_DIR:-/opt/docker}"
MAP_FILE="${DATA_MAP:-/etc/ciber/data-map.conf}"
OUT_DIR="${BACKUP_OUT_DIR:-/var/tmp}"
STAGE="$(mktemp -d "${TMPDIR:-/var/tmp}/backup-stage.XXXXXX")"
DEST_NAME="docker-data.tar.gz"
# Destino de rclone: el DIRECTORIO, no el nombre del archivo. En `rclone copy` el
# destino es una carpeta, asi que poner aqui el nombre del archivo hacia que se cree
# una carpeta docker-data.tar.gz/ y dentro el archivo del mismo nombre. Y el
# `--exclude` de abajo sube el MANIFEST a la Carpeta, no dentro de esa.
RCLONE_DIR="${RCLONE_DEST:-google:rclone/docker/}"

DRY=0
UPLOAD=1
ONLY_STACK=""

# while $# y no for arg in "$@": el for itera sobre una COPIA de los argumentos,
# asi que un shift dentro no surte efecto y `--stack jelly` leeria "--stack" como
# nombre de stack.
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)   DRY=1 ;;
    --no-upload) UPLOAD=0 ;;
    --stack)     shift; ONLY_STACK="${1:-}" ;;
    --stack=*)   ONLY_STACK="${1#--stack=}" ;;
    -h|--help)   sed -n '3,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "uso: $(basename "$0") [--dry-run] [--no-upload] [--stack NOMBRE]" >&2; exit 2 ;;
  esac
  shift
done

cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

# Quita la barra final de un patron de --exclude.
#
# Trampa de GNU tar: `--exclude='data/logs/'` NO excluye nada, porque el nombre
# que tar guarda para un directorio no lleva barra. Con `--exclude='data/logs'` si.
# Es de los fallos que no dan error: el backup sale bien, solo que 35 veces mas
# grande de lo que deberia, y uno se entera al mirarlo. Se normaliza aqui para
# que en data-map.conf se pueda escribir como queda legible.
norm_pat() { local p="$1"; while [ "${p%/}" != "$p" ]; do p="${p%/}"; done; printf '%s' "$p"; }

# ─── Avisos ────────────────────────────────────────────────────────────────────
# El .env vive en la raiz del repo. Se lee aqui y no via compose, para que el
# script no dependa de que exista un symlink <stack>/.env.
# Credenciales desde el archivo de entorno del sistema, con la forma VAR:? que
# aborta tambien si la variable esta VACIA, no solo si falta. Es deliberado: un
# token vacio no falla de forma ruidosa -- el curl sale con exito y el mensaje
# simplemente no llega -- asi que el fallo tiene que ocurrir aqui, antes de
# respaldar. Comprobable en cualquier momento con 'sudo ciber-secrets'.
#
# La clave es TELEGRAM_TOKEN y no TELEGRAM_BOT_TOKEN: es la que declara
# secrets.yml, y por lo tanto la que valida ciber-secrets. El nombre anterior
# venia del .env del repo de stacks, que no lo gestiona este playbook.
ENV_FILE="${BACKUP_ENV_FILE:-/etc/ciber/backup.env}"
[ -r "$ENV_FILE" ] && . "$ENV_FILE"
: "${TELEGRAM_TOKEN:?falta TELEGRAM_TOKEN en $ENV_FILE}"
: "${TELEGRAM_CHAT_ID:?falta TELEGRAM_CHAT_ID en $ENV_FILE}"
TG_TOKEN="$TELEGRAM_TOKEN"
TG_CHAT="$TELEGRAM_CHAT_ID"
# El grupo de Telegram es un foro y cada servicio tiene su topic, para que el
# OK verde de las 18:00 no se mezcle con la lavadora ni con opencode. Esta
# variable es OPCIONAL a proposito: si no esta, el aviso va a General, que es
# como funcionaba antes. Es lo que permite que este script siga siendo portable
# a otra maquina cuyo /etc/ciber/backup.env todavia no tenga la clave.
#
# El ':?' de arriba NO se usa aqui a proposito: si el topic faltara, el
# respaldo -- que es lo importante -- no debe dejar de hacerse por un detalle de
# las notificaciones. Un topic mal escrito es la misma situacion: Telegram
# devuelve 400 y el aviso se pierde, pero el respaldo sigue.
TG_THREAD="${TELEGRAM_THREAD_BACKUP:-}"
case "$TG_THREAD" in
  ''|*[!0-9]*) TG_THREAD='' ;;
esac
# Sin token no se avisa y el backup sigue: notificar no es un requisito para
# respaldar. Los scripts viejos traian un bot y un chat ID hardcodeados que no
# Coincidian con el .env.
aviso() {
  local extra=()
  [ -n "$TG_THREAD" ] && extra=(--data-urlencode "message_thread_id=$TG_THREAD")
  curl -s -m 20 -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=$TG_CHAT" --data-urlencode "text=$1" \
    ${extra[@]+"${extra[@]}"} >/dev/null 2>&1
}
log()  { printf '%s\n' "$*"; }
warn() { printf 'AVISO  %s\n' "$*" >&2; }

[ -f "$MAP_FILE" ] || { echo "ERROR no existe $MAP_FILE" >&2; exit 1; }

# Si el repo de stacks no esta, esto respaldaria cero stacks y dira "listo", que es
# el peor fallo posible: 30 dias de respaldos vacios con un OK en Telegram. El repo
# no lo clona este playbook -- es un paso manual (docs/nuevo-servidor.md) -- asi
# que en un servidor recien aprovisionado esto es lo primero que pasa.
#
# Se comprueba aqui y no al final del bucle, para que el aviso sea el primer
# mensaje y no algo que haya que rebuscar en un scroll de 40 lineas.
[ -d "$STACKS_DIR" ] || {
  echo "ERROR no existe $STACKS_DIR" >&2
  echo "       El repo de stacks no lo clona este playbook. Es un paso manual:" >&2
  echo "         git clone git@github.com:Ciberbago/ciber-docker.git $STACKS_DIR" >&2
  echo "       Ver docs/nuevo-servidor.md" >&2
  exit 1
}

# ─── Lectura del manifiesto ────────────────────────────────────────────────────
# stack -> "datos|incluye|excluye|snapshot", en un associative array.
#
# Las lineas que empiezan por espacio son continuacion de la nota de la linea
# anterior, no un stack. Se descartan. Tambien las que no tienen al menos dos
# campos (un stack sin `datos` no se puede respaldar).
declare -A MAP
declare -A MAP_HAS=()

while IFS=$'\t' read -r s d i e k; do
  [ -z "$s" ] && continue
  MAP["$s"]="$d|${i:--}|${e:--}|${k:--}"
  MAP_HAS["$s"]=1
done < <(awk -F'  +' '
  /^#/     { next }                     # comentario
  /^[[:space:]]/ { next }               # continuacion de la nota de arriba
  /^[[:space:]]*$/ { next }             # vacia
  NF < 2   { next }                     # no es una definicion de stack
  { print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 }
' "$MAP_FILE")

[ "${#MAP[@]}" -gt 0 ] || { echo "ERROR el manifiesto no define ningun stack" >&2; exit 1; }

# ─── Los stacks se enumeran del disco, NO del manifiesto ───────────────────────
# El manifiesto dice que se respalda todo lo que no este listado, asi que la lista
# de stacks sale de los directorios que tienen compose. Si se partiese de las lineas
# del manifiesto, los stacks sin linea —justo los que se respaldan por defecto—
# no se respaldarian nunca, y sin decir nada. Que es justo el fallo que هذا
# manifiesto vino a arreglar.
declare -a STACKS=()
for dir in "$STACKS_DIR"/*/; do
  d="$(basename "$dir")"
  { [ -f "$dir/compose.yaml" ] || [ -f "$dir/docker-compose.yml" ]; } || continue
  STACKS+=("$d")
done
[ "${#STACKS[@]}" -gt 0 ] || { echo "ERROR no encuentro ningun stack con compose" >&2; exit 1; }

# ─── SNAPSHOT ─────────────────────────────────────────────────────────────────
# Una SQLite en modo WAL no es un archivo: son el .db mas el -wal, y sin el -wal
# un restore pierde las ultimas transacciones sin avisar. Ademas, copiar el .db a
# mitad de escritura puede dejar un archivo inconsistente.
#
# La API de backup de SQLite (Connection.backup) resuelve ambas: lee la base con
# su propio lector y escribe un .db unico, checkpointeado, sin -wal ni -shm que
# acompanar. No requiere parar el contenedor.
#
# Se hace desde el HOST, no con `docker exec`: las bases estan en bind mounts, asi
# que el host las ve, y no depende de que la imagen traiga python3 ni sqlite3
# (la de jellyfin es .NET y la de nextexplorer es Go: ninguna tiene python3). De
# paso funciona con el contenedor parado.
snapshot_sqlite() {
  local stack="$1" rel="$2"
  local abs="$STACKS_DIR/$stack/$rel" out="$STAGE/$stack/$rel"

  if [ "$DRY" = "1" ]; then
    [ -f "$abs" ] && log "  snapshot  $stack/$rel (dry-run)" || warn "$stack/$rel: no existe"
    return 0
  fi

  [ -f "$abs" ] || { warn "$stack/$rel: no existe, sin snapshot"; return 1; }
  [ -r "$abs" ] || { warn "$stack/$rel: sin permiso de lectura; corre el backup como root"; return 1; }
  mkdir -p "$(dirname "$out")"

  if python3 -c "
import sqlite3
src = sqlite3.connect('file:$abs?mode=ro', uri=True)
dst = sqlite3.connect('$out')
src.backup(dst)
dst.close(); src.close()
" 2>>"$LOGFILE" && [ -s "$out" ]; then
    log "  snapshot  $stack/$rel ($(du -h "$out" 2>/dev/null | cut -f1))"
    return 0
  fi

  # Ultimo recurso: copiar tal cual. Se anota en el MANIFEST para que no pase por
  # consistente. Peor que un snapshot, pero no peor que antes.
  warn "$stack/$rel: el snapshot fallo, se copia SIN consolidar"
  cp -a "$abs" "$out" || return 1
  for ext in -wal -shm; do
    [ -f "$abs$ext" ] && cp -a "$abs$ext" "$out$ext"
  done
  INCONSISTENTE+=("$stack/$rel")
  return 0
}

# ─── Armado del tarball ───────────────────────────────────────────────────────
# Se tara SIN comprimir mientras se monta, porque hay que ir añadiendo stack a
# stack con `tar -rf` y gzip no admite anexar a un archivo ya comprimido. Se
# comprime al final, una sola vez.
TAR_RAW="$STAGE/${DEST_NAME%.gz}"
LOGFILE="$STAGE/tar.log"
: > "$LOGFILE"

packs=0
skipped=0

declare -a INCONSISTENTE=()

for stack in "${STACKS[@]}"; do
  # Del manifiesto si hay linea; si no, los valores por defecto: todo el arbol de
  # data/, sin excludes y sin snapshot. Un stack sin linea en data-map.conf se
  # respalda entero, que es de lo que va el manifiesto.
  if [ -n "${MAP_HAS[$stack]:-}" ]; then
    IFS='|' read -r datos inc exc snap <<< "${MAP[$stack]}"
  else
    datos="data/"; inc="-"; exc="-"; snap="-"
  fi

  [ -n "$ONLY_STACK" ] && [ "$stack" != "$ONLY_STACK" ] && continue
  if [ "$datos" = "OFF" ]; then log "off      $stack"; skipped=$((skipped+1)); continue; fi

  dir="$STACKS_DIR/$stack"
  [ -d "$dir" ] || continue
  if [ ! -e "$dir/$datos" ]; then
    log "vacio    $stack (no existe $datos)"; skipped=$((skipped+1)); continue
  fi

  log "empaqueta $stack  (datos: $datos)"

  # Los .db con snapshot se stagean y se anaden con su ruta real. El archivo vivo
  # se excluye del arbol de datos para que no lo pise: el que va al tar es el
  # consistente. Este es el punto donde el bug de siempre hacia dano.
  snap_ok=0
  if [ "$snap" != "-" ]; then
    for one in $snap; do
      snapshot_sqlite "$stack" "$one" && snap_ok=$((snap_ok+1))
    done
  fi

  tarargs=(--ignore-failed-read --warning=no-file-changed)

  # `datos` puede venir como data/ o como data. Sin normalizarlo aqui, "data/" + "/"
  # produce data// y las rutas del tar salen con doble barra.
  base="$datos"; [ "$base" != "${base%/}" ] && base="${base%/}"

  # Que entra: la lista de `incluye` resuelta con el glob de bash, o el arbol
  # entero de `datos`.
  #
  # El glob lo resuelve bash, no tar. GNU tar no tiene --include (es de bsdtar), y
  # ademas mezcla de forma sutil los --exclude con los patrones posicionales.
  # Resuelto aqui, cada member es una ruta real y se sabe exactamente que entra.
  #
  # Todo lleva delante el prefijo del stack, y se tara desde la raiz del repo y no
  # desde el directorio del stack. Con `cd $stack && tar ./data` lo que se guarda se
  # llama `data/...` a secas, y al restaurar en /opt/docker los datos de jelly,
  # homeassistant y komga caen todos encima en ./data/.
  members=()
  if [ "$inc" != "-" ]; then
    for g in $inc; do
      for m in "$dir/$base"/$g; do
        [ -e "$m" ] && members+=("$stack/${m#"$dir"/}")
      done
    done
    if [ "${#members[@]}" -eq 0 ]; then
      log "vacio    $stack (los globs de incluye no casan con nada)"
      skipped=$((skipped+1))
      continue
    fi
  else
    members=("$stack/$datos")
  fi

  if [ "$DRY" = "1" ]; then
    log "  dry-run: ${#members[@]} member(s) -> $(printf '%s ' "${members[@]}")"
    packs=$((packs+1))
    continue
  fi

  # Los excludes llevan delante el stack y el `datos`, porque en el manifiesto son
  # relativos a `datos` (jdown2 pone `logs/`, no `data/logs`). Los de `snapshot` solo
  # el stack, porque nombran un fichero que se copia de otra forma.
  for e in $exc; do
    [ "$e" != "-" ] && tarargs+=("--exclude=$stack/$base/$(norm_pat "$e")")
  done
  if [ "$snap_ok" -gt 0 ]; then
    for one in $snap; do tarargs+=("--exclude=$stack/$(norm_pat "$one")"); done
  fi

  # 1) los .db consistentes, con la ruta del stack
  if [ "$snap_ok" -gt 0 ]; then
    ( cd "$STAGE" && tar -rf "$TAR_RAW" "$stack" 2>>"$LOGFILE" )
  fi
  # 2) el arbol de datos
  ( cd "$STACKS_DIR" && tar -rf "$TAR_RAW" "${tarargs[@]}" "${members[@]}" 2>>"$LOGFILE" )
  packs=$((packs+1))
done

if [ "$DRY" = "1" ]; then
  echo
  log "dry-run: $packs stack(s) a empaquetar, $skipped sin datos. No se escribio nada."
  exit 0
fi

# Lo que tar no pudo leer queda en tar.log. Sin esto, un Permission denied en
# medio del scroll es indistinguible de un exit 0: el backup "sale bien" y
# le faltan a Home Assistant los .storage/ (auth, integraciones, http), que
# son 600 root y solo se leen como root. Un respaldo al que le falta la auth no es
# un respaldo: es un archivo que ocupa sitio.
#
# Asi que se cuenta, se apunta en el MANIFEST, y se sale con 1 y un aviso que lo
# diga. Se sube igual: medio respaldo es mejor que ninguno, pero nunca sin
# avisar de que lo es.
declare -a FALTAN=()
if [ -s "$LOGFILE" ]; then
  # mapfile, no FALTAN=("$(...)"): entrecomillado, las 6 lineas caen en un solo
  # elemento y el recuento sale 1.
  mapfile -t FALTAN < <(grep -E 'Cannot open|Permission denied|Cannot stat' "$LOGFILE" | sort -u)
fi
if [ "${#FALTAN[@]}" -gt 0 ]; then
  warn "INCOMPLETO: tar no pudo leer ${#FALTAN[@]} cosa(s). El respaldo se sube igual, pero le falta esto:"
  printf '    %s\n' "${FALTAN[@]}" | head -20
  [ "${#FALTAN[@]}" -gt 20 ] && warn "    ... y ${#FALTAN[@]} mas (ver $LOGFILE)"
  if [ "$(id -u)" != "0" ]; then
    warn "Corre como root (sudo bin/backup) y desaparecen: lo que no se lee suele ser 600 root."
  fi
fi

[ -f "$TAR_RAW" ] || { warn "no se genero tarball"; exit 1; }

# Comprimir. gzip no admite anexar, por eso se tara en crudo y se comprime aqui, ya
# con los excludes puestos y las rutas con el prefijo del stack dentro.
log "comprime"
gzip -f "$TAR_RAW" || { warn "fallo la compresion"; exit 1; }
TAR="$STAGE/$DEST_NAME"
[ -f "$TAR" ] || { warn "no se genero el tarball comprimido"; exit 1; }

# ─── MANIFEST ─────────────────────────────────────────────────────────────────
MANIFEST="$STAGE/MANIFEST.txt"
TOTAL_SHA="$(sha256sum "$TAR" | cut -d' ' -f1)"
SIZE_BYTES="$(stat -c %s "$TAR")"
SIZE_H="$(du -h "$TAR" | cut -f1)"

{
  echo "# MANIFEST del backup de datos"
  echo "generado:  $(date -u +%FT%TZ)"
  echo "host:      $(hostname)"
  echo "tarball:   $DEST_NAME"
  echo "bytes:     $SIZE_BYTES"
  echo "sha256:    $TOTAL_SHA"
  echo
  echo "# Contenido por stack (entradas en el tar):"
  # `tar -tf` y no `-tvf`: con -tv la ultima columna es el nombre partido por
  # espacios, y jdown2 y jelly tienen ficheros tipo "Sony Bravia (2013).xml", con
  # lo que p[1] salia "(" y el inventario era basura.
  tar -tf "$TAR" 2>/dev/null | awk -F/ 'NF >= 2 { c[$1]++ } END { for (s in c) print "#   " s "  " c[s] }' | sort
  if [ "${#INCONSISTENTE[@]}" -gt 0 ]; then
    echo
    echo "# AVISO: copiados SIN consolidar (el snapshot fallo). Un restore de estos"
    echo "# puede perder la ultima transaccion:"
    printf '#   %s\n' "${INCONSISTENTE[@]}"
  fi
  if [ "${#FALTAN[@]}" -gt 0 ]; then
    echo
    echo "# INCOMPLETO: ${#FALTAN[@]} cosa(s) que no se pudieron leer. Este respaldo"
    echo "# NO es completo. Suele ser 600 root -> corre el backup con sudo."
    printf '#   %s\n' "${FALTAN[@]}"
  fi
} > "$MANIFEST"

log ""
log "tarball  $SIZE_H  ($packs stack(s), $skipped sin datos)"
log "sha256   $TOTAL_SHA"

# ─── Copia local ──────────────────────────────────────────────────────────────
mkdir -p "$OUT_DIR" 2>/dev/null
LOCAL="$OUT_DIR/$DEST_NAME"
if ! cp -f "$TAR" "$LOCAL" 2>/dev/null; then
  warn "no se pudo copiar a $OUT_DIR (permisos); queda solo en el staging"
  LOCAL="$TAR"
fi
cp -f "$MANIFEST" "$OUT_DIR/MANIFEST.txt" 2>/dev/null

# ─── Subida ───────────────────────────────────────────────────────────────────
if [ "$UPLOAD" = "1" ]; then
  if ! command -v rclone >/dev/null 2>&1; then
    warn "rclone no esta instalado: el tarball queda solo en $LOCAL"
  else
    log "sube     $RCLONE_DIR"
    # --checksum: si Drive ya tiene el mismo archivo, no lo resubre. Si el token
    # de rclone esta caducado se avisa y se sigue: la copia local ya esta hecha.
    # SIN PIPE para comprobar el resultado. El estado de salida de un pipeline es el
    # del ULTIMO comando, y con '| sed' ese ultimo es sed, que siempre sale con 0:
    # un rclone fallido se daba por buena la subida y no saltava ni un aviso.
    # Medido el 2026-09-28, y era el MANIFEST el que se quedaba sin subir.
    if rclone copy "$TAR" "$RCLONE_DIR" --checksum -v > "$STAGE/rclone.log" 2>&1; then
      sed -ne '/Transferred:/,$ p' "$STAGE/rclone.log"

      # El destino es el DIRECTORIO, no 'google:rclone/docker/MANIFEST.txt'. En
      # 'rclone copy' el destino es una carpeta, asi que poner el nombre del archivo
      # hace que rclone intente crear un directorio con ese nombre, y si ya existe
      # como archivo falla con 'is a file not a directory'. rclone pone el nombre
      # local tal cual, que aqui ya es MANIFEST.txt.
      #
      # Y si esto falla es FALLO y no aviso: sin el MANIFEST, el tarball de Drive no
      # se puede verificar al restaurar, y restore.sh avisaria de que no hay sha256
      # de referencia y seguiria adelante. Un respaldo que no se puede comprobar es
      # medio respaldo.
      if ! rclone copy "$MANIFEST" "$RCLONE_DIR" --checksum >> "$STAGE/rclone.log" 2>&1; then
        warn "el tarball subio pero el MANIFEST no. En Drive NO se podra verificar."
        sed 's/^/    /' "$STAGE/rclone.log" | tail -3
        aviso "❌ Backup: subio el tarball pero no el MANIFEST, asi que el respaldo
de Drive no se puede verificar al restaurar. El local si: $LOCAL"
        exit 1
      fi
    else
      warn "rclone fallo al subir. El tarball esta en $LOCAL."
      aviso "❌ Backup: fallo la subida a Drive. El tarball quedo en $LOCAL
sha256 $TOTAL_SHA"
      echo "$STAGE" > "${TMPDIR:-/var/tmp}/backup-stage-pendiente"
      trap - EXIT
      exit 1
    fi
  fi
fi

log "listo    $LOCAL"
log "sha256   $TOTAL_SHA"

if [ "${#FALTAN[@]}" -gt 0 ]; then
  log ""
  warn "este respaldo es INCOMPLETO: le faltan ${#FALTAN[@]} cosa(s). Mira el MANIFEST."
  aviso "⚠️ Backup INCOMPLETO: $SIZE_H, $packs stack(s), pero ${#FALTAN[@]} cosa(s) no se pudieron leer.
Suele ser 600 root. Corre 'sudo bin/backup'.
sha256 $TOTAL_SHA"
  exit 1
fi

if [ "${#INCONSISTENTE[@]}" -gt 0 ]; then
  log ""
  warn "${#INCONSISTENTE[@]} base(s) se copiaron SIN consolidar: ${INCONSISTENTE[*]}"
  aviso "⚠️ Backup: $SIZE_H, $packs stack(s), pero ${#INCONSISTENTE[@]} base(s) sin consolidar:
${INCONSISTENTE[*]}
sha256 $TOTAL_SHA"
  exit 1
fi

aviso "✅ Backup de datos: $SIZE_H, $packs stack(s), $skipped sin datos
sha256 $TOTAL_SHA"

exit 0
