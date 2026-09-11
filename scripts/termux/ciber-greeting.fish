# Bienvenida de ciber-scripts para Fish en Termux.

if status is-interactive
    # Suprime el saludo por defecto de Fish ("Welcome to fish...").
    set -g fish_greeting ""

    set -l bold
    set -l cyan
    set -l green
    set -l yellow
    set -l reset

    if not set -q NO_COLOR
        set bold (set_color --bold)
        set cyan (set_color cyan)
        set green (set_color green)
        set yellow (set_color yellow)
        set reset (set_color normal)
    end

    printf '\n%s✨ Bienvenido a Termux%s\n\n' "$bold$cyan" "$reset"
    printf '%s🛠️  Comandos disponibles:%s\n' "$bold$yellow" "$reset"
    printf '  %s%-14s%s Ver ayuda y sintaxis\n' "$green" 'ciber-help' "$reset"
    printf '  %s%-14s%s Sincronizar scripts\n' "$green" 'ciber-update' "$reset"
    printf '  %s%-14s%s Herramientas para vídeo\n' "$green" 'ffm-tui' "$reset"
    printf '  %s%-14s%s Descargar vídeo o audio\n' "$green" 'yt-tui' "$reset"
    printf '  %s%-14s%s Administrar SSH\n' "$green" 'termux-ssh' "$reset"
    printf '  %s%-14s%s Utilidades de red\n' "$green" 'net-tui' "$reset"
    printf '\n%s💡 Usa ciber-help para ver ejemplos%s\n\n' "$bold$cyan" "$reset"
end
