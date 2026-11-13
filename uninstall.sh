#!/usr/bin/env bash
# back to hyprland's own group bar
set -euo pipefail

ID=eduardo.group-tabs
HYPR="$HOME/.config/hypr"

# the require goes before the file it loads, same reason install.sh adds it last
sed -i '/last on purpose, a failure here must not skip anything above/d; /require("hypr.group_tabs")/d' "$HYPR/hyprland.lua"
rm -f "$HYPR/group_tabs.lua" "${XDG_RUNTIME_DIR:-/tmp}/group-tabs.json"

omarchy plugin disable "$ID" || true
if [[ -L $HOME/.config/omarchy/plugins/$ID ]]; then rm "$HOME/.config/omarchy/plugins/$ID"; fi
echo "group tabs removed"
