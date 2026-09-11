#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# === COLORES ===
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

# Verifica si el script se ejecuta como root
if [[ "$EUID" -ne 0 ]]; then
  echo -e "${RED}${BOLD}ERROR:${RESET} Este script debe ejecutarse como root. Usa: sudo $0"
  exit 1
fi

ENTRIES_DIR="/boot/loader/entries"
ESP_MOUNTPOINT="/boot"

echo -e "${CYAN}${BOLD}Detectando kernels instalados y generando entradas para systemd-boot...${RESET}"

# Crear el directorio de entradas si no existe
mkdir -p "$ENTRIES_DIR"

# Respaldo de entradas anteriores por seguridad
BACKUP_DIR="${ENTRIES_DIR}.bak.$(date +%Y%m%d-%H%M%S)"
echo -e "${YELLOW}Resguardando entradas actuales en: $BACKUP_DIR${RESET}"
cp -a "$ENTRIES_DIR" "$BACKUP_DIR" || true

# Eliminar entradas antiguas
echo -e "${YELLOW}Limpiando entradas antiguas en $ENTRIES_DIR...${RESET}"
rm -f "$ENTRIES_DIR"/*.conf

# Obtener la partición raíz
ROOT_PARTITION=$(findmnt -no SOURCE /)
ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PARTITION")

if [[ -z "$ROOT_PARTUUID" ]]; then
    echo -e "${RED}${BOLD}¡ERROR:${RESET} No se pudo determinar el PARTUUID de la partición raíz ($ROOT_PARTITION)!"
    exit 1
fi

echo -e "${GREEN}PARTUUID detectado:${RESET} $ROOT_PARTUUID"

# Detectar el sistema de archivos raíz
ROOT_FS_TYPE=$(findmnt -no FSTYPE /)
echo -e "${GREEN}Sistema de archivos raíz:${RESET} $ROOT_FS_TYPE"

# Detectar kernels instalados
KERNEL_BASENAMES=$(find /usr/lib/modules -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | \
                   grep -v 'extramodules' | \
                   sed -E 's/.*-arch.*/linux/' | \
                   sed -E 's/.*-lts.*/linux-lts/' | \
                   sed -E 's/.*-zen.*/linux-zen/' | \
                   sed -E 's/.*-hardened.*/linux-hardened/' | \
                   sed -E 's/([0-9]+\.[0-9]+\.[0-9]+-[0-9]+-)(.*)/\1linux-\2/' | \
                   sed -E 's/[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-(.*)/\1/' | \
                   sed -E 's/^linux-linux/linux/' | \
                   sort -u)

if [[ -z "$KERNEL_BASENAMES" ]]; then
    echo -e "${RED}${BOLD}No se detectaron kernels instalados. Abortando.${RESET}"
    exit 1
fi

for KERNEL_BASE_NAME in $KERNEL_BASENAMES; do
    VMLINUZ="$ESP_MOUNTPOINT/vmlinuz-$KERNEL_BASE_NAME"
    INITRAMFS="$ESP_MOUNTPOINT/initramfs-$KERNEL_BASE_NAME.img"
    INITRAMFS_FALLBACK="$ESP_MOUNTPOINT/initramfs-$KERNEL_BASE_NAME-fallback.img"

    if [[ ! -f "$VMLINUZ" ]]; then
        echo -e "${YELLOW}Advertencia: No se encontró $VMLINUZ. Saltando $KERNEL_BASE_NAME.${RESET}"
        continue
    fi

    if [[ ! -f "$INITRAMFS" || ! -f "$INITRAMFS_FALLBACK" ]]; then
        echo -e "${YELLOW}Advertencia: Faltan initramfs para $KERNEL_BASE_NAME. Saltando.${RESET}"
        continue
    fi

    ENTRY_FILE="${KERNEL_BASE_NAME}.conf"
    ENTRY_PATH="$ENTRIES_DIR/$ENTRY_FILE"

    case "$KERNEL_BASE_NAME" in
        "linux") ENTRY_TITLE="Arch Linux" ;;
        "linux-lts") ENTRY_TITLE="Arch Linux LTS" ;;
        "linux-zen") ENTRY_TITLE="Arch Linux ZEN" ;;
        "linux-hardened") ENTRY_TITLE="Arch Linux Hardened" ;;
        *)
            SUFFIX=$(echo "$KERNEL_BASE_NAME" | sed 's/^linux-//')
            ENTRY_TITLE="Arch Linux $(echo "$SUFFIX" | sed 's/\b\(.\)/\U\1/g')" ;;
    esac

    echo -e "${CYAN}Generando entrada:${RESET} ${BOLD}$ENTRY_TITLE${RESET}"

    ENTRY_CONTENT="title   $ENTRY_TITLE
linux   /vmlinuz-$KERNEL_BASE_NAME
initrd  /initramfs-$KERNEL_BASE_NAME.img
initrd  /initramfs-$KERNEL_BASE_NAME-fallback.img
options root=PARTUUID=$ROOT_PARTUUID zswap.enabled=0 rw rootfstype=$ROOT_FS_TYPE"

    if [[ -f "$ESP_MOUNTPOINT/intel-ucode.img" ]]; then
        ENTRY_CONTENT+="
initrd  /intel-ucode.img"
    elif [[ -f "$ESP_MOUNTPOINT/amd-ucode.img" ]]; then
        ENTRY_CONTENT+="
initrd  /amd-ucode.img"
    fi

    echo "$ENTRY_CONTENT" > "$ENTRY_PATH"
    echo -e "${GREEN}Entrada creada:${RESET} $ENTRY_PATH"
    echo -e "${CYAN}--------------------------------------------------${RESET}"
done

# Establecer kernel por defecto solo si existe
DEFAULT_KERNEL="linux-cachyos"
DEFAULT_ENTRY="$ENTRIES_DIR/$DEFAULT_KERNEL.conf"
LOADER_CONF="$ESP_MOUNTPOINT/loader/loader.conf"

echo -e "${CYAN}Actualizando loader.conf...${RESET}"

{
    if [[ -f "$DEFAULT_ENTRY" ]]; then
        echo "default ${DEFAULT_KERNEL}.conf"
    else
        echo -e "${YELLOW}Nota: No se encontró ${DEFAULT_KERNEL}.conf, se omitirá 'default'.${RESET}" >&2
    fi
    echo "timeout 3"
} > "$LOADER_CONF"

echo -e "${GREEN}Archivo loader.conf actualizado:${RESET}"
cat "$LOADER_CONF"

echo -e "${BOLD}${GREEN}Script finalizado. Entradas de systemd-boot generadas correctamente.${RESET}"

