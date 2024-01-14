#!/usr/bin/env bash
# by peterrus

set -e

if [[ $1 == 'backup' ]]; then
  dconf dump '/org/gnome/desktop/wm/keybindings/' > gnome/keybindings.dconf
  dconf dump '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/' > gnome/custom-values.dconf
  dconf read '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings' > gnome/custom-keys.dconf
  echo "backup done"
  exit 0
fi
if [[ $1 == 'restore' ]]; then
  dconf reset -f '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/'
  dconf reset -f '/org/gnome/desktop/wm/keybindings/'
  dconf load '/org/gnome/desktop/wm/keybindings/' < gnome/keybindings.dconf
  dconf load '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/' < gnome/custom-values.dconf
  dconf write '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings' "$(cat gnome/custom-keys.dconf)"
  echo "restore done"
  exit 0
fi

echo "parameter 0: [backup|restore]"