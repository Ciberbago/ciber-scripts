# Aliases de ciber-scripts para Fish en Termux.
# eza reemplaza a ls con iconos, permisos, lista y archivos ocultos.

if status is-interactive
    if command -q eza
        alias ls='eza --icons=auto -l -a --group-directories-first --header'
        alias ll='eza --icons=auto -l --group-directories-first --header'
        alias la='eza --icons=auto -la --group-directories-first'
        alias lt='eza --icons=auto --tree --level=2 -a --group-directories-first'
    end
end
