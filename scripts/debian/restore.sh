#!/bin/bash
# Restaura un respaldo de datos sobre el repo de stacks. Es la otra mitad de
# backup-datos.sh, y va en el mismo repo por una razon concreta: el formato del
# tarball y el del MANIFEST son un contrato ENTRE LOS DOS. Si uno se actualiza sin
# el otro, el restore falla al extraer.
#
# Uso:
#   restore.sh --latest                  # del tarball local de /var/tmp
#   restore.sh --file /ruta/backup.tar.gz
#   restore.sh --latest --stack jelly    # solo uno
#   restore.sh --latest --dry-run        # lista que restauraria
#   restore.sh --latest --to /mnt/nuevo  # restaura en otra raiz
#
# LO IMPORTANTE: los permisos. Un archivo extraido con el umask de quien restaura
# queda en 644 de un usuario que no es el que escribe dentro del contenedor, y las
# apps se quedan sin poder guardar: es el fallo de Sep 2026, el de "attempt to
# write a readonly database", que tumbo a la vez las apps de deudas, finanzas y
# pedidos. Por eso despues de extraer se aplica 777 a los directorios y 666 a los
# archivos de las rutas de datos, y por eso hace falta root.
#
# Variables de entorno, con default para poder probarlo a mano:
#   DOCKER_STACKS_DIR  donde vive el repo de stacks   (/opt/docker)
#   DATA_MAP           el mapa de que se respalda     (/etc/ciber/data-map.conf)
#   BACKUP_OUT_DIR     donde se busca el tarball      (/var/tmp)

set -uo pipefail

STACKS_DIR="${DOCKER_STACKS_DIR:-/opt/docker}"
MAP_FILE="${DATA_MAP:-/etc/ciber/data-map.conf}"
DEFAULT_TARBALL="${BACKUP_OUT_DIR:-/var/tmp}/docker-data.tar.gz"

TARBALL=""
ONLY_STACK=""
DRY=0
TARGET="$STACKS_DIR"

while [ $# -gt 0 ]; do
  case "$1" in
    --latest)  TARBALL="$DEFAULT_TARBALL" ;;
    --file)    shift; TARBALL="$1" ;;
    --file=*)  TARBALL="${1#--file=}" ;;
    --stack)   shift; ONLY_STACK="$1" ;;
    --stack=*) ONLY_STACK="${1#--stack=}" ;;
    --to)      shift; TARGET="$1" ;;
    --to=*)    TARGET="${1#--to=}" ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '3,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "uso: $(basename "$0") (--latest|--file RUTA) [--stack N] [--to DIR] [--dry-run]" >&2; exit 2 ;;
  esac
  shift
done

log()  { printf '%s\n' "$*"; }
warn() { printf 'AVISO  %s\n' "$*" >&2; }
die()  { printf 'ERROR  %s\n' "$*" >&2; exit 1; }

[ -n "$TARBALL" ] || die "dime de donde: --latest, o --file /ruta/al.tar.gz"
[ -f "$TARBALL" ] || die "no existe el tarball: $TARBALL
  El de esta maquina esta en $DEFAULT_TARBALL
  Para el de Drive: rclone copy google:rclone/docker/docker-data.tar.gz ."
[ -f "$MAP_FILE" ] || die "no existe $MAP_FILE"

TARGET="${TARGET%/}"
[ -n "$TARGET" ] || die "--to no puede ser vacio"

# ─── Verificacion de integridad ───────────────────────────────────────────────
# El sha256 va en el MANIFEST de al lado. El historial de versiones de Drive
# guarda el archivo anterior, pero no distingue un upload a medias de uno bueno,
# y un tarball truncado se restaura "con exito" y deja los datos a medias.
verify() {
  local tarball="$1"
  local ref=""

  # El MANIFEST va SIEMPRE al lado del tarball, con ese nombre. No puede ir dentro
  # del propio tar: lleva el sha256 de ese tar, y anadirlo lo cambiaria.
  local man; man="$(dirname "$tarball")/MANIFEST.txt"
  if [ -f "$man" ]; then
    ref="$(sed -n 's/^sha256:[[:space:]]*//p' "$man" | head -1)"
  fi

  if [ -z "$ref" ]; then
    warn "sin sha256 de referencia: no hay MANIFEST.txt en $(dirname "$tarball")"
    warn "  Sin el no puedo saber si el tarball esta entero. De Drive se bajan los dos:"
    warn "    rclone copy google:rclone/docker/docker-data.tar.gz ."
    warn "    rclone copy google:rclone/docker/MANIFEST.txt ."
    return 0
  fi

  local got; got="$(sha256sum "$tarball" | cut -d' ' -f1)"
  if [ "$got" = "$ref" ]; then
    log "ok      sha256 verificado contra el MANIFEST"
  else
    warn "sha256 NO coincide"
    warn "  esperado  $ref"
    warn "  obtenido  $got"
    warn "  El tarball esta corrupto o es de otra corrida. NO se restaura nada."
    return 1
  fi
}

# ─── Rutas de datos ───────────────────────────────────────────────────────────
# stack -> datos, con lo que diga data-map.conf.
#
# Los stacks se enumeran del DISCO, no del manifiesto, por lo mismo que en
# bin/backup: el manifiesto dice que entra todo lo que no este listado, asi que
# listar solo las lineas del manifiesto dejaria fuera justo a los stacks que se
# respaldan por defecto (vibecode, fb, dockge, url, tracktor...). Y aqui el fallo es
# peor que en el backup: un stack al que no se le aplica el chmod se queda en 755/644
# y sus apps no pueden escribir. Es el fallo de Sep 2026, entero.
declare -A MAP=()
while IFS=$'\t' read -r s d; do
  [ -z "$s" ] && continue
  MAP["$s"]="$d"
done < <(awk -F'  +' '
  /^#/ { next } /^[[:space:]]/ { next } /^[[:space:]]*$/ { next } NF < 2 { next }
  { print $1 "\t" $2 }
' "$MAP_FILE")

declare -a STACKS=()
for dir in "$STACKS_DIR"/*/; do
  d="$(basename "$dir")"
  { [ -f "$dir/compose.yaml" ] || [ -f "$dir/docker-compose.yml" ]; } || continue
  STACKS+=("$d")
done

# ─── Chequeo previo ───────────────────────────────────────────────────────────
if [ "$DRY" = "0" ]; then
  verify "$TARBALL" || exit 1
  if [ "$(id -u)" != "0" ] && [ "$TARGET" = "$STACKS_DIR" ]; then
    die "hay que correrlo como root (sudo bin/restore).
  Sin root los archivos quedan con el umask de tu usuario y las apps se quedan sin
  poder escribir. Es el fallo de Sep 2026. Con --to a otro sitio si puedes sin sudo."
  fi
  mkdir -p "$TARGET"
fi

# ─── Que hay dentro ───────────────────────────────────────────────────────────
contenido() {
  tar -tf "$TARBALL" 2>/dev/null | awk -F/ 'NF >= 2 { print $1 "/" $2 }' | sort -u
}

log "tarball  $TARBALL"
log "raiz     $TARGET"
log ""
log "contenido:"
contenido | sed 's/^/  /'

# ─── Extraccion ───────────────────────────────────────────────────────────────
if [ "$DRY" = "1" ]; then
  log ""
  log "dry-run: restauraria lo de arriba. No se ha escrito nada."
  exit 0
fi

# El MANIFEST va fuera del arbol de datos: no es de ningun stack.
tmp_man="$(mktemp)"
if tar -xf "$TARBALL" -C "$TARGET" --exclude='MANIFEST.txt' 2>/dev/null; then
  log "ok      extraido"
else
  die "fallo la extraccion. El tarball puede estar corrupto (comprueba el sha256 de arriba)"
fi
tar -xf "$TARBALL" -C "$tmp_man" "MANIFEST.txt" 2>/dev/null || true
rm -f "$tmp_man"

# ─── Permisos ─────────────────────────────────────────────────────────────────
# El orden importa y no es capricho:
#   directorios 777, archivos 666
# 777 primero porque un directorio sin permiso de escritura impide hacer chmod
# dentro de el. Y 666 en vez de 644 porque quien escribe en el contenedor es
# www-data (uid 82 en php:8.3-fpm-alpine), que no es el dueno del archivo.
#
# Se aplica solo a las rutas de datos declaradas en el manifiesto, no a todo lo
# extraido: codigo y configuracion no tienen por que ser escribibles por todo el
# mundo, y abrirlos seria una sorpresa en un equipo nuevo.
chmod_datos() {
  local stack="$1" datos="$2" base="$TARGET/$stack/$datos"
  [ -e "$base" ] || return 0
  log "permisos $stack/$datos"
  chmod 777 "$base" 2>/dev/null
  find "$base" -type d -exec chmod 777 {} + 2>/dev/null
  find "$base" -type f -exec chmod 666 {} + 2>/dev/null
}

echo
for stack in "${STACKS[@]}"; do
  # Del manifiesto si hay linea; si no, el default del backup: data/ entero.
  datos="${MAP[$stack]:-data/}"
  [ -n "$ONLY_STACK" ] && [ "$stack" != "$ONLY_STACK" ] && continue
  [ "$datos" = "OFF" ] && continue
  datos="${datos%/}"
  [ -n "$datos" ] || continue
  [ -e "$TARGET/$stack/$datos" ] || continue
  chmod_datos "$stack" "$datos"
done

# ─── Symlinks de .env ─────────────────────────────────────────────────────────
# Los stacks leen ${PORT_*} del .env de su directorio, y no lo ven si no hay
# symlink. Es lo que hace bin/sync-env; se llama al final para que un stack nuevo
# en el clon reciba el suyo sin tener que acordarse.
if [ -f "$TARGET/.env" ] && [ "$TARGET" = "$STACKS_DIR" ]; then
  log ""
  log "symlinks de .env"
  "$STACKS_DIR/bin/sync-env" 2>&1 | sed 's/^/  /' | head -20
else
  log ""
  # El $ antes de {PORT_*} va escapado: sin eso bash intenta expandarlo y revienta
  # con "bad substitution", que es lo unico que se ve del fallo.
  [ -f "$TARGET/.env" ] || warn "no hay $TARGET/.env: los stacks veran los \${PORT_*} vacios"
fi

# ─── Resumen ──────────────────────────────────────────────────────────────────
log ""
log "restaurado. Falta:"
log "  1. .env con los valores reales (si no lo copiaste antes)"
log "  2. bin/sync-env          <- ya corrido si el .env estaba"
log "  3. levantar los stacks:  for d in */; do (cd \"\$d\" && docker compose up -d); done"
