#!/data/data/com.termux/files/usr/bin/bash

# Bootstrap idempotente para preparar una instalación nueva de Termux.
# No sobrescribe scripts ni configuraciones que ya existan.

set -u

REPO_URL="https://github.com/Ciberbago/ciber-scripts.git"
REPO_BRANCH="main"
TEMP_DIR=""

cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

info() {
    printf '\n==> %s\n' "$1"
}

warn() {
    printf 'Aviso: %s\n' "$1" >&2
}

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

install_packages() {
    info 'Actualizando repositorios'
    pkg update -y || die 'No se pudieron actualizar los repositorios.'

    info 'Instalando paquetes'
    pkg install -y \
        fish \
        openssh \
        git \
        curl \
        wget \
        nano \
        unzip \
        tar \
        ffmpeg \
        python-yt-dlp \
        yt-dlp-ejs || die 'No se pudieron instalar todos los paquetes.'
}

setup_storage() {
    info 'Solicitando acceso al almacenamiento de Android'
    termux-setup-storage || warn 'termux-setup-storage terminó con un aviso.'

    printf 'Espera a que Android muestre el permiso y pulsa Permitir si aparece.\n'
    for _ in {1..10}; do
        [[ -d "$HOME/storage/shared" ]] && return 0
        sleep 1
    done

    if [[ ! -d "$HOME/storage/shared" ]]; then
        warn 'No se detectó ~/storage/shared.'
        warn 'Puedes conceder el permiso después y volver a ejecutar este script.'
    fi
}

setup_fish() {
    local fish_path
    fish_path=$(command -v fish) || {
        warn 'No se encontró Fish después de instalarlo.'
        return 0
    }

    info 'Configurando Fish como shell predeterminada'
    if command -v chsh >/dev/null 2>&1; then
        chsh -s "$fish_path" || warn 'No se pudo establecer Fish como shell predeterminada.'
    else
        warn 'chsh no está disponible; Fish quedó instalado pero no se cambió la shell.'
    fi
}

install_user_scripts() {
    local source_dir="$1" destination name
    destination="$HOME/bin"
    mkdir -p "$destination" || die "No se pudo crear $destination."

    for name in ffm-tui yt-tui termux-ssh; do
        if [[ -e "$destination/$name" ]]; then
            printf 'Conservando existente: %s\n' "$destination/$name"
            continue
        fi
        if install -m 700 "$source_dir/$name" "$destination/$name"; then
            printf 'Instalado: %s\n' "$destination/$name"
        else
            warn "No se pudo instalar $name."
        fi
    done

    if command -v fish >/dev/null 2>&1; then
        fish -c 'fish_add_path "$HOME/bin"' || \
            warn 'No se pudo añadir ~/bin al PATH de Fish.'
    fi
}

download_repo() {
    TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ciber-scripts.XXXXXX") || \
        die 'No se pudo crear un directorio temporal.'

    info 'Descargando scripts desde ciber-scripts'
    git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$TEMP_DIR/repo" || \
        die 'No se pudo clonar el repositorio.'

    [[ -d "$TEMP_DIR/repo/scripts/termux" ]] || \
        die 'El repositorio no contiene scripts/termux.'
    install_user_scripts "$TEMP_DIR/repo/scripts/termux"
}

show_summary() {
    printf '\nInstalación terminada.\n'
    printf '\nScripts disponibles:\n'
    printf '  ffm-tui       compresión y operaciones con FFmpeg\n'
    printf '  yt-tui        descargas con yt-dlp\n'
    printf '  termux-ssh    gestión del servidor SSH\n'
    printf '\nSi Fish no se activó en esta sesión, ejecuta:\n'
    printf '  exec fish\n'
    printf '\nPara configurar SSH:\n'
    printf '  termux-ssh\n'
    printf '  Selecciona primero configurar contraseña y después iniciar servidor.\n'
}

main() {
    [[ -n "${PREFIX:-}" ]] || die 'Este script debe ejecutarse dentro de Termux.'
    command -v pkg >/dev/null 2>&1 || die 'No se encontró pkg.'

    install_packages
    setup_storage
    setup_fish
    download_repo
    show_summary
}

main "$@"
