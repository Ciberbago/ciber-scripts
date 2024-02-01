if status is-interactive
    # Commands to run in interactive sessions can go here
    echo ""
    fastfetch --config /usr/share/fastfetch/presets/neofetch.jsonc
    set fish_greeting ""
    set -gx EDITOR micro
end