#!/data/data/com.termux/files/usr/bin/bash

# Bootstrap idempotente para preparar una instalación nueva de Termux.
# No sobrescribe scripts ni configuraciones que ya existan.

set -u

REPO_URL="https://github.com/Ciberbago/ciber-scripts.git"
REPO_BRANCH="main"
PACKAGES_URL="https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts/termux/packages"
TEMP_DIR=""

cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

if [[ -t 1 && -z "${NO_COLOR:-}" ]] && command -v tput >/dev/null 2>&1; then
    B=$(tput bold 2>/dev/null || true)
    R=$(tput sgr0 2>/dev/null || true)
    VERDE=$(tput setaf 2 2>/dev/null || true)
    AMAR=$(tput setaf 3 2>/dev/null || true)
    ROJO=$(tput setaf 1 2>/dev/null || true)
    CIAN=$(tput setaf 6 2>/dev/null || true)
else
    B=""; R=""; VERDE=""; AMAR=""; ROJO=""; CIAN=""
fi

info() {
    printf '\n%s==> %s%s\n' "$B$CIAN" "$1" "$R"
}

warn() {
    printf '%sAviso: %s%s\n' "$AMAR" "$1" "$R" >&2
}

die() {
    printf '%sError: %s%s\n' "$ROJO" "$1" "$R" >&2
    exit 1
}

# Lee scripts/termux/packages del repo (uno por línea, # = comentario).
# Si no hay internet, usa la lista de respaldo integrada.
read_package_list() {
    local url="$1" tmpfile="$2"
    if curl -fsSL --max-time 15 "$url" -o "$tmpfile" 2>/dev/null; then
        grep -vE '^[[:space:]]*(#|$)' "$tmpfile" | awk '{print $1}'
        return 0
    fi
    return 1
}

install_packages() {
    local packages_file pkgs
    packages_file=$(mktemp "${TMPDIR:-/tmp}/ciber-packages.XXXXXX") || \
        die 'No se pudo crear un archivo temporal.'
    info 'Actualizando repositorios'
    pkg update -y || die 'No se pudieron actualizar los repositorios.'

    info 'Actualizando el sistema base (evita fallos en instalaciones frescas)'
    pkg upgrade -y || die 'No se pudo actualizar el sistema base.'

    info 'Instalando paquetes'
    if pkgs=$(read_package_list "$PACKAGES_URL" "$packages_file"); then
        printf 'Lista de paquetes tomada del repositorio.\n'
    else
        warn 'Sin acceso a la lista del repo; usando lista de respaldo.'
        pkgs=$(printf '%s\n' fish openssh git curl wget nano unzip tar eza fzf bat fresh-editor ffmpeg python-yt-dlp yt-dlp-ejs)
    fi
    rm -f "$packages_file"
    # shellcheck disable=SC2086
    pkg install -y $pkgs || die 'No se pudieron instalar todos los paquetes.'
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
    if ! command -v chsh >/dev/null 2>&1; then
        warn 'chsh no está disponible; Fish quedó instalado pero no se cambió la shell.'
        return 0
    fi
    # El chsh de Termux acepta el nombre corto; la ruta completa la rechaza.
    if chsh -s fish; then
        printf 'Fish establecida como shell (nombre corto).\n'
        return 0
    fi
    warn 'chsh -s fish falló; intentando con la ruta completa.'
    if chsh -s "$fish_path"; then
        printf 'Fish establecida como shell (ruta completa).\n'
        return 0
    fi
    printf 'ERROR: no se pudo establecer Fish como shell.\n' >&2
    printf 'Ejecuta a mano: chsh -s fish\n' >&2
    printf 'Y después abre una sesión nueva de Termux.\n' >&2
    return 1
}

hide_default_motd() {
    # Oculta el mensaje inicial de Termux para dejar solo la bienvenida propia.
    if touch "$HOME/.hushlogin" 2>/dev/null; then
        printf 'MOTD de Termux desactivado: %s\n' "$HOME/.hushlogin"
    else
        warn 'No se pudo crear ~/.hushlogin.'
    fi
}

install_user_scripts() {
    local source_dir="$1" destination name
    destination="$HOME/bin"
    mkdir -p "$destination" || die "No se pudo crear $destination."

    for name in ciber-help ciber-update ffm-tui yt-tui termux-ssh net-tui ssh-tui; do
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

install_greeting() {
    local source_file="$1/ciber-greeting.fish"
    local destination="$HOME/.config/fish/conf.d/ciber-greeting.fish"
    mkdir -p "$(dirname "$destination")" || die 'No se pudo crear la configuración de Fish.'

    if [[ -e "$destination" ]]; then
        printf 'Conservando existente: %s\n' "$destination"
    elif install -m 644 "$source_file" "$destination"; then
        printf 'Instalado: %s\n' "$destination"
    else
        warn 'No se pudo instalar el mensaje de bienvenida de Fish.'
    fi
}

install_aliases() {
    local source_file="$1/ciber-aliases.fish"
    local destination="$HOME/.config/fish/conf.d/ciber-aliases.fish"
    mkdir -p "$(dirname "$destination")" || die 'No se pudo crear la configuración de Fish.'

    if [[ -e "$destination" ]]; then
        printf 'Conservando existente: %s\n' "$destination"
    elif install -m 644 "$source_file" "$destination"; then
        printf 'Instalado: %s\n' "$destination"
    else
        warn 'No se pudo instalar los aliases de Fish.'
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
    install_greeting "$TEMP_DIR/repo/scripts/termux"
    install_aliases "$TEMP_DIR/repo/scripts/termux"
}

show_summary() {
    printf '\n%sInstalación terminada.%s\n' "$VERDE" "$R"
    printf '\nScripts disponibles:\n'
    printf '  %sciber-help%s    ayuda y sintaxis de los scripts\n' "$VERDE" "$R"
    printf '  %sciber-update%s  sincroniza scripts sin clonar el repo\n' "$VERDE" "$R"
    printf '  %sgreeting%s      bienvenida colorida de Fish\n' "$VERDE" "$R"
    printf '  %saliases%s       ls/ll/la/lt con eza en Fish\n' "$VERDE" "$R"
    printf '  %sffm-tui%s       compresión y operaciones con FFmpeg\n' "$VERDE" "$R"
    printf '  %syt-tui%s        descargas con yt-dlp\n' "$VERDE" "$R"
    printf '  %stermux-ssh%s    gestión del servidor SSH\n' "$VERDE" "$R"
    printf '  %snet-tui%s       utilidades rápidas de red\n' "$VERDE" "$R"
    printf '  %sssh-tui%s       conexiones SSH guardadas\n' "$VERDE" "$R"
    printf '\nIMPORTANTE: esta sesión sigue en Bash.\n'
    printf 'Abre una sesión NUEVA de Termux para entrar en Fish,\n'
    printf 'y verifícalo ahí con: echo $SHELL\n'
    printf '(o ejecuta: exec fish)\n'
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
    hide_default_motd
    download_repo
    show_summary
}

main "$@"
