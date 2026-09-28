#!/usr/bin/env bash
#
# ciber-disco - agrega discos de datos a /etc/fstab, sin editarlo a mano.
#
#   sudo ciber-disco                       menu: elige el disco y el punto de montaje
#   sudo ciber-disco list                  informe; no toca nada
#   sudo ciber-disco add /dev/sdb2 /mnt/x  sin preguntas
#   sudo ciber-disco rm /mnt/x             deshacer
#
# Opciones de 'add':
#   --uid N   --gid N   propietario del montaje. SOLO para filesystems que no
#                          guardan propiedad unix (vfat, exfat, ntfs...). En un
#                          ext4 el kernel rechaza el montaje, y el comando avisa
#                          y se niega en vez de escribir una linea que no monta.
#   --sin-uid             no anadir uid/gid (implicito en ext4 y familia)
#   --chown               tras montar bien, chown del punto a --uid:--gid
#   --fsck                campo pass=2, para que fsck lo revise en el 2o pase
#   --seguro              anadir nosuid,nodev a las opciones
#
# Por que NO estan los discos en el playbook:
#
#   Un UUID en un archivo de git que no corresponde a la maquina que lo aplica
#   deja el sistema en emergency shell en CADA arranque, esperando un disco que
#   no va a aparecer. Y el hardware es por maquina: un disco de juegos en Arch y
#   uno de multimedia en Debian no tienen nada que ver. El playbook instala este
#   comando; el fstab lo escribe uno, una vez, en cada equipo.
#
# Por que escribe UUID= y no /dev/sdX:
#
#   /dev/sda1 depende del orden en que el kernel detecte los discos. Con un USB
#   enchufado, o con un disco que falla y vuelve, el mismo /dev/sda1 puede ser
#   otro. El UUID no se mueve. Ademas, /dev/sda1 aparecio en el fstab de este
#   servidor desde antes, y es exactamente el tipo de linea que un dia deja de
#   montar lo que cree que debe montar.
#
# Por que 'nofail':
#
#   Un disco de datos que no esta conectado no es motivo para que la maquina no
#   arranque. Sin 'nofail', systemd se queda esperando el disco en el boot y la
#   sesion no llega. 'x-systemd.device-timeout=10' acorta esa espera a 10 s en
#   vez de los 90 por defecto, para que el retraso sea razonable cuando falta.
#
# Que NO toca:
#
#   Las entradas de '/', '/boot', '/boot/efi' y los 'swap'. Solo edita lineas
#   suyas, las que llevan la marca '#ciber-disco' arriba. Si alguien cambio a mano
#   una entrada del sistema, esto ni se entera: es de otro.
#
# Garantias, en orden:
#
#   1. Copia /etc/fstab a /etc/fstab.bak-<fecha> antes de escribir. Siempre. Se
#      quedan las cinco ultimas.
#   2. Cuenta los errores de 'findmnt --verify' antes y despues. Si el cambio los
#      aumenta, devuelve la copia: es preferible un disco sin montar a un fstab
#      con un error mas. Si el fstab ya venia roto, esto no lo arregla pero si
#      deja seguir trabajando.
#   3. 'systemctl daemon-reload' y el montaje, para que se vea el resultado sin
#      reiniciar. Si el montaje falla, la linea se queda: el disco puede que este
#      bien y el problema sea otro.
#
# Util-linux (lsblk, findmnt) y systemd: ya estan en Arch y en Debian, asi que
# este script no necesita que se agregue ningun paquete. Por eso no se usa
# 'blkid': esta en /sbin, fuera del PATH de un usuario normal, y lsblk da el
# UUID que hace falta.

set -uo pipefail

FSTAB="${CIBER_FSTAB:-/etc/fstab}"
MARCA='#ciber-disco'
TIMEOUT=10

# Separador de los campos que salen de 'dispositivos'.
#
# NO puede ser un tabulador: bash trata el tab como espacio en el IFS, asi que
# los campos vacios (PKNAME de un disco entero, LABEL de una particion sin
# etiqueta) se collapsan y todo lo de despues se desplaza una posicion. Se
# acababa viendo /dev/sda donde deberia decir /dev/sda1, con el nombre del disco
# donde tocaba el tipo de archivo. El separador de unidades (0x1F) no es
# whitespace y no aparece en un nombre de dispositivo ni en una etiqueta.
SEP=$'\x1f'

# En '-o' de lsblk se pide NAME aunque no se use: el patron de extraccion busca
# la clave precedida de un espacio, y la primera columna de la salida no lo
# tiene. Con NAME delante, PATH ya nunca es la primera.

#<-------Colores------->
# Mismo criterio que el resto del repo: solo si la salida es una terminal y el
# usuario no pidio lo contrario con NO_COLOR.
if [[ -t 1 && -z "${NO_COLOR:-}" ]] && command -v tput &>/dev/null \
    && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]; then
    B=$(tput bold); R=$(tput sgr0)
    ROJO=$(tput setaf 1); VERDE=$(tput setaf 2); AMAR=$(tput setaf 3)
    AZUL=$(tput setaf 4); GRIS=$(tput setaf 8)
else
    B=""; R=""; ROJO=""; VERDE=""; AMAR=""; AZUL=""; GRIS=""
fi

#<-------Ayuda------->
ayuda() {
    awk 'NR>1 && /^set /{exit} NR>1 {sub(/^# ?/, ""); print}' "${BASH_SOURCE[0]}"
    exit "${1:-0}"
}

#<-------Permisos------->
#
# Solo las acciones que ESCRIBEN necesitan root. 'list' se deja correr sin sudo
# a proposito: es la parte que se consulta en mitad de una averia, cuando lo
# que se quiere es ver el estado sin depender de acordarse de escribir sudo.
#
# No se re-ejecuta con sudo desde aqui: si alguien lo pone por costumbre desde
# una terminal sin tty, el prompt se queda colgado sin que se vea por que. Se
# avisa de la falta y se sale.
pide_root() {
    [[ "$(id -u)" -eq 0 ]] && return 0
    echo "${ROJO}ciber-disco necesita root:${R} ponlo delante:  sudo $*" >&2
    exit 77
}

[[ -r "$FSTAB" ]] || { echo "${ROJO}No se puede leer $FSTAB${R}" >&2; exit 1; }

#<-------Parseo de lsblk------->
#
# Se pide en formato de PARES ('-P', mayuscula) y no en columnas, porque un LABEL
# puede traer espacios ('LABEL="Disco de juegos"') y con columnas separadas por
# espacios eso parte la linea por un sitio que no es. Dos trampas de lsblk aqui:
# la 'p' minuscula es '--paths' y no tiene nada que ver, y '--pairs' es
# incompatible con '--list' ('-l'): pedir las dos hace que lsblk se niegue.
#
# Cada particion sale como una linea de 8 campos separados por tabulador:
#   path  pkname  tipo  fstype  label  uuid  size  modelo-del-disco
dispositivos() {
    local linea path pk tipo fs label uuid tam modelo
    while IFS= read -r linea; do
        path=$(sed -n 's/.*[[:space:]]PATH="\([^"]*\)".*/\1/p' <<<"$linea")
        pk=$(sed -n 's/.*[[:space:]]PKNAME="\([^"]*\)".*/\1/p' <<<"$linea")
        tipo=$(sed -n 's/.*[[:space:]]TYPE="\([^"]*\)".*/\1/p' <<<"$linea")
        fs=$(sed -n 's/.*[[:space:]]FSTYPE="\([^"]*\)".*/\1/p' <<<"$linea")
        label=$(sed -n 's/.*[[:space:]]LABEL="\([^"]*\)".*/\1/p' <<<"$linea")
        uuid=$(sed -n 's/.*[[:space:]]UUID="\([^"]*\)".*/\1/p' <<<"$linea")
        tam=$(sed -n 's/.*[[:space:]]SIZE="\([^"]*\)".*/\1/p' <<<"$linea")
        # El modelo vive en la fila del disco, no en la de la particion, asi que
        # se pide aparte. Son dos o tres discos: no compensa otra pasada global.
        # Con '-p', PKNAME ya viene absoluto: anteponerle /dev daria /dev/dev/sda.
        #
        # Sin '-r' (--raw) a proposito: en modo crudo lsblk escapa los espacios
        # y el modelo sale como 'HGST\x20HTS541010A9E680'.
        modelo=''
        [[ -n "$pk" ]] && modelo=$(lsblk -dno MODEL "$pk" 2>/dev/null | head -1)
        # El separador va DENTRO del formato (0x1F en octal, que es lo que
        # expande printf), no como argumento suelto: asi el numero de %s y el de
        # argumentos no pueden descuadrarse. Con 15 argumentos y 9 %s, printf
        # reutiliza el formato y la salida sale partida en varias lineas.
        printf '%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\n' \
            "$path" "$pk" "$tipo" "$fs" "$label" "$uuid" "$tam" "$modelo"
    done < <(lsblk -nPp -o NAME,PATH,PKNAME,TYPE,FSTYPE,LABEL,UUID,SIZE 2>/dev/null)
}

# Una particion es candidata a montarse si trae filesystem, no es swap y no es el
# disco entero. El filtro de FSTYPE vacio ya deja fuera los 'disk' y los 'rom',
# pero el tipo se comprueba igual: es lo que dice si esto es siquiera montable.
es_candidata() {
    local pk="$1" tipo="$2" fs="$3" uuid="$4" path="$5"
    [[ -n "$path" && -n "$fs" ]] || return 1
    case "$tipo" in disk|rom) return 1 ;; esac
    [[ "$fs" == swap ]] && return 1
    fuente_en_fstab "UUID=$uuid" && return 1
    fuente_en_fstab "$path" && return 1
    return 0
}

#<-------Parseo de fstab------->
#
# 'campo N' de una entrada. fstab(5): fuente, punto, tipo, opciones, dump, pass.
# Se separa por espacios en blanco, que es lo que acepta mount(8).
campo() { awk -v n="$2" '{print $n}' <<<"$1"; }

# Todas las entradas reales, sin comentarios ni lineas vacias.
entradas() {
    grep -vE '^[[:space:]]*(#|$)' "$FSTAB" 2>/dev/null
}

# Un punto de montaje es 'del sistema' si es el raiz, un boot o un swap. Esas
# lineas no las gestiona este script bajo ningun concepto.
es_del_sistema() {
    local src="$1" mp="$2" fs="$3"
    case "$mp" in /|/boot|/boot/efi) return 0 ;; esac
    [[ "$fs" == "swap" || "$fs" == "none" || "$src" == "none" ]] && return 0
    return 1
}

# Ya esta en el fstab este dispositivo (por UUID o por ruta)? Y este punto?
fuente_en_fstab() { entradas | awk '{print $1}' | grep -qxF "$1"; }
punto_en_fstab() { entradas | awk '{print $2}' | grep -qxF "$1"; }

#<-------Informe------->
informe() {
    local e src mp fs
    local datos=0 libres=0
    local -a Ausentes=() Dupes=()

    echo "${B}Discos declarados en $FSTAB${R}"
    printf '  %-38s %-18s %-9s %s\n' 'FUENTE' 'PUNTO' 'TIPO' 'ESTADO'
    while read -r e; do
        src=$(campo "$e" 1); mp=$(campo "$e" 2); fs=$(campo "$e" 3)
        local estado
        if es_del_sistema "$src" "$mp" "$fs"; then
            estado="${GRIS}sistema${R}"
            printf '  %-38s %-18s %-9s %s\n' "$src" "$mp" "$fs" "$estado"
            continue
        fi
        datos=$((datos + 1))
        if [[ "$src" == UUID=* || "$src" == LABEL=* || "$src" == PARTUUID=* ]]; then
            local clave="${src#*=}"; clave="${clave#*\\}"
            if ! dispositivos | cut -f5 | grep -qxF "$clave"; then
                estado="${ROJO}NO EXISTE${R}"
                Ausentes+=("$e")
            else
                estado="${VERDE}ok${R}"
            fi
        else
            if [[ -e "$src" ]]; then
                estado="${VERDE}ok${R}"
            else
                estado="${ROJO}NO EXISTE${R}"
                Ausentes+=("$e")
            fi
        fi
        # Montado de verdad ahora mismo, o solo declarado.
        if findmnt -n -o TARGET --target "$mp" 2>/dev/null | grep -qxF "$mp"; then
            [[ "$estado" == "${VERDE}ok${R}" ]] && estado="${VERDE}montado${R}"
        else
            estado="$estado ${AMAR}(sin montar)${R}"
        fi
        printf '  %-38s %-18s %-9s %s\n' "$src" "$mp" "$fs" "$estado"
    done < <(entradas)

    # Puntos repetidos: en Arch tenia DOS entradas para /run/media/storage, la
    # segunda duplicaba a la primera y 'mount -a' montaba dos veces el mismo sitio.
    local dup
    while read -r dup; do
        [[ -n "$dup" ]] || continue
        local veces
        veces=$(entradas | awk -v m="$dup" '$2==m' | wc -l)
        if ((veces > 1)); then
            Dupes+=("$dup ($veces veces)")
        fi
    done < <(entradas | awk '{print $2}' | sort | uniq -d)

    ((datos == 0)) && echo "  ${GRIS}(ninguno: este es el sistema, no hay discos de datos)${R}"

    # Candidatos: particiones con filesystem que no estan en el fstab.
    local d pk tipo fsl label uuid tam modelo
    while IFS=$SEP read -r path pk tipo fsl label uuid tam modelo; do
        es_candidata "$pk" "$tipo" "$fsl" "$uuid" "$path" || continue
        libres=$((libres + 1))
    done < <(dispositivos)

    echo
    if ((libres > 0)); then
        echo "${B}Particiones con filesystem, sin usar en el fstab:${R}"
        local n=0
        while IFS=$SEP read -r path pk tipo fsl label uuid tam modelo; do
            es_candidata "$pk" "$tipo" "$fsl" "$uuid" "$path" || continue
            n=$((n + 1))
            printf '  %s%d%s %-12s %-7s %-14s %-38s %s\n' \
                "$B" "$n" "$R" "$path" "$tam" "$fsl" "${label:-(sin etiqueta)}" \
                "${GRIS}${modelo:-disco}${R}"
            printf '  %s  %s%s\n' "$GRIS" "UUID=$uuid" "$R"
        done < <(dispositivos)
        echo
        echo "  ${GRIS}Se omiten las particiones sin filesystem: es la particion"
        echo "  reservada de Microsoft que Windows deja al formatear, y no es"
        echo "  un olvido. Se agrega con:  sudo ciber-disco${R}"
    else
        echo "${B}Libres:${R} ninguna particion con filesystem queda sin declarar."
    fi

    if ((${#Ausentes[@]} > 0)); then
        echo
        echo "${ROJO}${B}Entradas cuyo disco no esta en la maquina:${R}"
        printf '  %s\n' "${Ausentes[@]}"
        echo "  ${GRIS}Suele ser un disco que se cambio, o un UUID de otra maquina."
        echo "  Con 'nofail' no rompen el arranque, pero tampoco montan nada.${R}"
    fi
    if ((${#Dupes[@]} > 0)); then
        echo
        echo "${ROJO}${B}Puntos de montaje repetidos:${R}"
        printf '  %s\n' "${Dupes[@]}"
        echo "  ${GRIS}Dos entradas para el mismo sitio: 'mount -a' monta dos veces.${R}"
    fi
}

#<-------Escritura------->
CUPDOS=5

# cuantos errores de verdad tiene este fstab ahora mismo
errores_de() {
    findmnt --verify --tab-file "$1" 2>&1 | grep -c '\[E\]' || true
}

respaldo() {
    local destino
    destino="${FSTAB}.bak-$(date +%Y%m%d-%H%M%S)"
    cp -a "$FSTAB" "$destino" || return 1
    # Se quedan las CUPDOS copias mas recientes. Sin esto, /etc se llena de
    # backups de a poco: son unos cientos de bytes cada uno, pero el que se
    # necesita para deshacer SIEMPRE es el ultimo, y el resto solo sirve para
    # saber que se toco el fstab.
    local -a viejos=()
    mapfile -t viejos < <(ls -1t "${FSTAB}".bak-* 2>/dev/null | tail -n +$((CUPDOS + 1)))
    if ((${#viejos[@]} > 0)); then
        rm -f -- "${viejos[@]}"
        # A stderr, no a stdout: quien llama hace 'copia=$(respaldo)' y el aviso
        # se comeria la ruta de la copia.
        echo "  ${GRIS}cortadas ${#viejos[@]} copias viejas (se quedan $CUPDOS)${R}" >&2
    fi
    echo "$destino"
}

# Valida el fstab que se acaba de escribir, comparandolo con como estaba ANTES.
#
# No basta con 'if findmnt --verify falla, revertir', porque en una maquina cuyo
# fstab ya venia roto (un UUID de un disco que se cambio, un punto que no
# existe todavia) el verify falla SIEMPRE y este comando se negaria a agregar
# cualquier cosa, sin dejar arreglar el archivo. Lo que interesa no es que el
# fstab sea perfecto, sino que ESTE cambio no lo empeore: por eso se cuentan
# los errores antes y despues, y solo se revierte si crecen.
validar_o_revertir() {
    local copia="$1" base="$2" ahora salida
    ahora=$(errores_de "$FSTAB")
    if ((ahora <= base)); then
        return 0
    fi
    echo "${ROJO}El fstab nuevo tiene $((ahora - base)) error(es) mas. Se devuelve la copia.${R}" >&2
    salida=$(findmnt --verify --tab-file "$FSTAB" 2>&1)
    echo "$salida" >&2
    cp -a "$copia" "$FSTAB"
    systemctl daemon-reload 2>/dev/null
    echo "${AMAR}Vuelto a $copia. Revisa la salida de 'findmnt --verify' de arriba.${R}" >&2
    return 1
}

# El criterio NO es "es ntfs o no". Es SI EL FILESYSTEM GUARDA PROPIEDAD UNIX.
#
#   - Si la guarda (ext4, xfs, btrfs, f2fs, zfs), 'uid=' y 'gid=' son parametros
#     INVALIDOS de montaje y el kernel rechaza el montaje entero:
#         fsconfig() failed: ext4: Unknown parameter 'uid'
#     No es un aviso ni una opcion ignorada: la linea no monta. Y anadirla por
#     "por si acaso" es justo el error, porque el resultado no es un disco sin
#     permisos, es un disco que no aparece.
#   - Si NO la guarda (vfat, exfat, ntfs, iso9660...), el propietario no esta en
#     el medio y el montaje es el UNICO sitio donde se puede poner.
#
# Comprobado el 2026-09-28 en una maquina Arch: la linea de /run/media/games
# llevo semanas con 'uid=1000,gid=1000' sobre un ext4, y no montaba.
sin_permisos_unix() {
    case "$1" in
        vfat | fat | fat12 | fat16 | fat32 | msdos | exfat | exfat3 | \
        ntfs | ntfs3 | ntfs-3g | fuseblk | iso9660 | udf) return 0 ;;
        *) return 1 ;;
    esac
}

agregar() {
    local mp="$2" uid_="$3" gid_="$4" con_uid="$5" fsck="$6" seguro="$7" chown_="${8:-0}"

    # La validacion del punto de montaje va AQUI y no en el menu, para que la
    # forma con argumentos no se la salte. mount(8) acepta un punto relativo y
    # lo resuelve contra el directorio actual, asi que 'ciber-disco add /dev/sdb1
    #_relative' escribia una linea que solo servia desde el directorio desde el
    # que se habia escrito. Lo Pillaba 'findmnt --verify' despues, pero mas vale
    # no escribir para luego dar marcha atras.
    case "$mp" in
        /*) ;;
        *) echo "${ROJO}El punto de montaje tiene que empezar por /: '$mp'${R}" >&2
           return 2 ;;
    esac
    case "$mp" in
        /|/boot|/boot/efi)
            echo "${ROJO}$mp es un punto del sistema. Este script no lo toca.${R}" >&2
            return 2 ;;
    esac
    if punto_en_fstab "$mp"; then
        echo "${ROJO}$mp ya esta en $FSTAB. Usa otro punto.${R}" >&2
        return 2
    fi
    if findmnt -n -o TARGET --target "$mp" 2>/dev/null | grep -qxF "$mp"; then
        echo "${AMAR}Aviso: $mp ya es un punto de montaje en marcha.${R}" >&2
        echo "${AMAR}Si no es un disco tuyo, no sigas.${R}" >&2
        return 2
    fi

    # El tipo que se escribe no es siempre el que dice lsblk. En NTFS se elige el
    # driver: 'ntfs-3g' es el de FUSE, en espacio de usuario, y es el que traia
    # esta maquina de antes; 'ntfs3' es el del kernel y va mas rapido. Se escribe
    # el que exista instalado, y se dice cual se eligio.
    local fsl uuid ruta pk tdis
    IFS=$SEP read -r ruta pk tdis fsl _ uuid _ _ < <(
        dispositivos | awk -F'\037' -v p="$1" '$1==p {print; exit}'
    )
    [[ -n "$fsl" && -n "$uuid" ]] || {
        echo "${ROJO}$1 no tiene un filesystem legible, o no existe.${R}" >&2
        return 1
    }

    local tipo="$fsl"
    if [[ "$fsl" == ntfs ]]; then
        if command -v ntfs-3g &>/dev/null || [[ -x /usr/bin/ntfs-3g ]]; then
            tipo=ntfs-3g
        else
            tipo=ntfs3
        fi
        echo "${GRIS}NTFS: se escribe tipo '$tipo' (el que hay instalado).${R}"
    fi

    local opts="defaults"
    # Aqui se decide lo de uid/gid. Ver sin_permisos_unix(): depende del
    # filesystem, no de que el disco sea nuestro.
    local quiere_chown=0
    if [[ "$con_uid" == 1 ]]; then
        if sin_permisos_unix "$tipo"; then
            opts+=",uid=$uid_,gid=$gid_,umask=0022"
        else
            # ext4 y familia: la propiedad esta DENTRO del disco. Escribir uid=
            # haria que el montaje fallara entero, asi que no se escribe, y se
            # dice que hacer en su lugar.
            quiere_chown=1
        fi
    fi
    [[ "$seguro" == 1 ]] && opts+=",nosuid,nodev"
    opts+=",nofail,x-systemd.device-timeout=$TIMEOUT"

    local linea="UUID=$uuid $mp $tipo $opts 0 $((fsck == 1 ? 2 : 0))"

    echo
    echo "${B}Se va a agregar:${R}"
    echo "  $MARCA $1 $(date +%F)"
    echo "  $linea"
    if ((quiere_chown == 1)); then
        echo
        echo "${GRIS}$tipo guarda los permisos en el disco, no en el montaje, asi"
        echo "que la linea no lleva uid=. Es correcto, pero comprueba el"
        echo "propietario del punto de montaje:${R}"
        echo "  ls -ld $mp"
        if ((chown_ == 1)); then
            echo "  ${GRIS}(--chown: se hara despues de montar)${R}"
        else
            echo "  ${GRIS}Si es de root y lo necesitas tuyo, despues de montar:"
            echo "  sudo chown $uid_:$gid_ $mp"
            echo "  o agrega el disco con --chown y se hace solo.${R}"
        fi
    fi

    # El punto de montaje se crea antes de escribir. Si se escribiera primero y
    # fallara el mkdir, la proxima vez que se montara el disco se montaria sobre
    # un directorio que en realidad no existe.
    if ! mkdir -p "$mp"; then
        echo "${ROJO}No se pudo crear $mp${R}" >&2
        return 1
    fi

    # La linea base se cuenta ANTES de escribir. Se compara despues: si el fstab
    # ya venia roto, esto no puede arreglarlo pero si dejar seguir adelante.
    local copia base
    base=$(errores_de "$FSTAB")
    copia=$(respaldo) || { echo "${ROJO}No se pudo copiar $FSTAB${R}" >&2; return 1; }
    printf '%s %s\n%s\n' "$MARCA" "$1" "$linea" >>"$FSTAB" || {
        echo "${ROJO}No se pudo escribir en $FSTAB${R}" >&2
        cp -a "$copia" "$FSTAB"
        return 1
    }
    echo "  copia: $copia"

    validar_o_revertir "$copia" "$base" || return 1

    systemctl daemon-reload

    # Montar aqui es lo que convierte esto en algo comprobable: sin esto, el
    # comando diria 'listo' y el disco seguiria sin montar hasta el reinicio.
    if mount "$mp" 2>/dev/null; then
        local src
        src=$(findmnt -n -o SOURCE --target "$mp" 2>/dev/null)
        echo "${VERDE}Montado en $mp desde $src${R}"
    else
        echo "${AMAR}La linea quedo escrita pero no se pudo montar $mp.${R}"
        echo "${AMAR}Revisa:  mount $mp${R}"
        return 1
    fi

    # El chown va DESPUES de montar, nunca antes: cambiar el propietario de un
    # punto de montaje que no lo esta solo afecta al directorio vacio de encima,
    # y al montar se pierde. Se hace sobre la raiz del filesystem, que es lo que
    # se acaba de montar de verdad.
    if ((chown_ == 1)); then
        if chown "$uid_:$gid_" "$mp" 2>/dev/null; then
            echo "${VERDE}Propietario de $mp cambiado a $uid_:$gid_${R}"
        else
            echo "${AMAR}No se pudo hacer chown $uid_:$gid_ $mp${R}"
            echo "${AMAR}Revisa si el filesystem lo soporta y si el disco esta lleno.${R}"
        fi
    fi

    echo "${GRIS}Desmontar para dejarlo como en un arranque limpio:  umount $mp${R}"
}

quitar() {
    local mp="$1"
    punto_en_fstab "$mp" || {
        echo "${ROJO}$mp no esta en $FSTAB${R}" >&2
        return 1
    }

    # El numero de linea se busca con awk y no con grep porque el punto puede
    # llevar '/' o '.', que en una expresion regular no son literales. En vez de
    # escapar a mano, se compara el campo 2 tal cual.
    local num
    num=$(awk -v mp="$mp" '!/^[ \t]*#/ && NF >= 2 && $2 == mp { print NR; exit }' "$FSTAB")
    [[ -n "$num" ]] || {
        echo "${ROJO}$mp no esta en $FSTAB${R}" >&2
        return 1
    }

    # Solo se borra si la entrada es nuestra. Una linea escrita a mano no se toca,
    # ni aunque el punto coincida: esto administra lo que escribio el.
    local con_marca=0
    if ((num > 1)) && [[ "$(sed -n "$((num - 1))p" "$FSTAB")" == "$MARCA "* ]]; then
        con_marca=1
    fi
    if ((con_marca == 0)); then
        echo "${ROJO}$mp esta en $FSTAB pero no lo agrego $MARCA.${R}" >&2
        echo "${AMAR}No se toca. Si lo quieres quitar, editalo a mano.${R}" >&2
        return 1
    fi

    local copia base
    base=$(errores_de "$FSTAB")
    copia=$(respaldo) || return 1
    # Las dos lineas de una vez. En una sola pasada de sed, '4d;5d' borra
    # exactamente la marca y su entrada, y los numeros siguen siendo los del
    # archivo original: si se hiciese en dos llamadas, la segunda buscaria la
    # linea equivocada.
    sed -i "$((num - 1))d;${num}d" "$FSTAB"
    validar_o_revertir "$copia" "$base" || return 1
    systemctl daemon-reload

    if findmnt -n -o TARGET --target "$mp" 2>/dev/null | grep -qxF "$mp"; then
        umount "$mp" 2>/dev/null \
            && echo "${VERDE}Desmontado $mp${R}" \
            || echo "${AMAR}No se pudo desmontar $mp. Esta en uso.${R}"
    fi
    echo "  copia: $copia"
}

#<-------Menu------->
menu() {
    local -a paths=() tams=() labels=()
    local path pk tipo fsl label uuid tam modelo

    # El menu acepta las mismas banderas que 'add', para que no haya dos formas
    # de hacer lo mismo. Solo se leen las que tienen sentido aqui.
    local m_u=1000 m_g=1000 m_sin_uid=0 m_chown=0 m_fsck=0 m_seguro=0 a
    for a in "$@"; do
        case "$a" in
            --chown) m_chown=1 ;;
            --sin-uid) m_sin_uid=1 ;;
            --fsck) m_fsck=1 ;;
            --seguro) m_seguro=1 ;;
            --uid | --gid) ;;
            --*) echo "Opcion desconocida: $a" >&2; exit 64 ;;
        esac
    done

    while IFS=$SEP read -r path pk tipo fsl label uuid tam modelo; do
        es_candidata "$pk" "$tipo" "$fsl" "$uuid" "$path" || continue
        paths+=("$path"); tams+=("$tam"); labels+=("$label")
    done < <(dispositivos)

    if ((${#paths[@]} == 0)); then
        informe
        echo
        echo "${GRIS}No hay particiones libres. Si el disco es nuevo y esta vacio,"
        echo "formatealo antes (mkfs.ext4 /dev/sdX1) y ya aparecera aqui.${R}"
        return 0
    fi

    # El punto sugerido sale de la etiqueta, en minusculas y sin espacios, que es
    # como se nombra en /run/media. Editable de todas formas.
    slug() {
        local s
        s=$(tr '[:upper:]' '[:lower:]' <<<"$1" | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')
        [[ -n "$s" ]] || s=disco
        printf '%s' "$s"
    }

    echo "${B}Particiones con filesystem, sin declarar:${R}"
    local i
    for i in "${!paths[@]}"; do
        local etiqueta="${labels[$i]:-(sin etiqueta)}"
        printf '  %s%d%s %-12s %-7s %-16s  ->  /run/media/%s\n' \
            "$B" "$((i + 1))" "$R" "${paths[$i]}" "${tams[$i]}" "$etiqueta" \
            "$(slug "${labels[$i]}")"
    done

    local num
    read -r -p "Numero (nada = salir): " num || return 0
    [[ -n "$num" ]] || return 0
    if ! [[ "$num" =~ ^[0-9]+$ ]] || ((num < 1 || num > ${#paths[@]})); then
        echo "${ROJO}Eso no es uno de los de la lista.${R}" >&2
        return 2
    fi
    local idx=$((num - 1))
    local sugerido="/run/media/$(slug "${labels[$idx]}")"

    local mp="$sugerido" otro=''
    read -r -p "Punto de montage [$sugerido]: " otro || return 1
    [[ -n "$otro" ]] && mp="$otro"

    case "$mp" in
        /*) ;;
        *) echo "${ROJO}El punto de montaje tiene que empezar por /.${R}" >&2; return 2 ;;
    esac
    if punto_en_fstab "$mp"; then
        echo "${ROJO}$mp ya esta en $FSTAB. Usa otro punto.${R}" >&2
        return 2
    fi

    agregar "${paths[$idx]}" "$mp" "$m_u" "$m_g" \
        "$((1 - m_sin_uid))" "$m_fsck" "$m_seguro" "$m_chown"
}

#<-------Argumentos------->
ACCION="${1:-menu}"
# Los argumentos se guardan ANTES del shift: si no, 'menu' nunca veria las
# banderas que se escribieron delante, y 'ciber-disco --chown' acabaria
# mostrando la ayuda en vez de abrir el menu.
TODOS=("$@")
[[ $# -gt 0 ]] && shift

# El menu escribe al final, asi que tambien es cosa de root.
case "$ACCION" in
    -h|--help|help) ayuda 0 ;;
    list|ls|estado) informe; exit $? ;;
    # Sin subcomando, o con banderas sueltas: menu. Asi 'sudo ciber-disco' y
    # 'sudo ciber-disco --chown' hacen lo mismo, que es lo que espera la gente.
    menu | --chown | --sin-uid | --fsck | --seguro)
        pide_root "$0"
        # La forma ${arr[@]+"${arr[@]}"} es la que no rompe con 'set -u' cuando
        # el array esta vacio, que es el caso normal de 'ciber-disco' a secas.
        menu ${TODOS[@]+"${TODOS[@]}"}
        ;;
    add)
        pide_root "$0 add"
        [[ $# -ge 2 ]] || { echo "Uso: $0 add <dispositivo> <punto> [opciones]" >&2; exit 64; }
        dev="$1"; mp="$2"; shift 2
        u=1000; g=1000; con_uid=1; fsck=0; seguro=0; chown_=0
        # Se apunta si el uid/gid se pidio a mano, para poder avisar cuando el
        # filesystem no lo acepta en vez de ignorarlo en silencio.
        uid_pedido=0
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --uid)   u="$2"; uid_pedido=1; shift 2 ;;
                --gid)   g="$2"; uid_pedido=1; shift 2 ;;
                --sin-uid) con_uid=0; shift ;;
                --fsck)  fsck=1; shift ;;
                --seguro) seguro=1; shift ;;
                --chown) chown_=1; shift ;;
                *) echo "Opcion desconocida: $1" >&2; exit 64 ;;
            esac
        done
        # Acepta ruta, UUID= o el UUID pelado, y tambien LABEL=. Se resuelve todo
        # por UUID antes de escribir, que es lo que va a acabar en el fstab.
        caso="${dev#LABEL=}"; caso="${dev#UUID=}"
        path=$(dispositivos | awk -F'\037' -v d="$dev" -v c="$caso" \
            '$1==d || $6==c || ("LABEL=" $5)==d {print $1; exit}')
        [[ -n "$path" ]] || { echo "${ROJO}No encuentro '$dev'.${R}" >&2; exit 1; }

        # Si el usuario pidio --uid a mano sobre un filesystem que guarda la
        # propiedad, se dice ANTES de escribir nada, porque el resultado de
        # ignorarlo en silencio es una linea que no va a montar.
        if ((uid_pedido == 1)); then
            fst="$(dispositivos | awk -F'\037' -v p="$path" '$1==p {print $4; exit}')"
            if ! sin_permisos_unix "$fst"; then
                echo "${ROJO}$fst no acepta 'uid=' como opcion de montaje.${R}" >&2
                echo "${AMAR}El kernel rechaza el montaje entero:" >&2
                echo "  fsconfig() failed: $fst: Unknown parameter 'uid'${R}" >&2
                echo >&2
                echo "El propietario esta DENTRO del disco, no en el fstab. Usa:" >&2
                echo "  --sin-uid --chown    # escribe la linea limpia y hace chown al montar" >&2
                exit 64
            fi
        fi

        agregar "$path" "$mp" "$u" "$g" "$con_uid" "$fsck" "$seguro" "$chown_"
        ;;
    rm|quitar)
        pide_root "$0 rm"
        [[ $# -ge 1 ]] || { echo "Uso: $0 rm <punto-de-montaje>" >&2; exit 64; }
        quitar "$1"
        ;;
    *) ayuda 64 ;;
esac
