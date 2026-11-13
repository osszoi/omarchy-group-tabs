#!/usr/bin/env bash
# links the plugin into the omarchy shell and wires the hyprland side.
# order matters: hyprland reloads the moment its config is saved, and a require that
# points at a file that isn't there yet aborts the whole reload
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
ID=eduardo.group-tabs
HYPR="$HOME/.config/hypr"
LINE='require("hypr.group_tabs")'

mkdir -p "$HOME/.config/omarchy/plugins"
ln -sfn "$ROOT" "$HOME/.config/omarchy/plugins/$ID"
omarchy plugin enable "$ID"

ln -sfn "$ROOT/hypr/group_tabs.lua" "$HYPR/group_tabs.lua"
if ! grep -qF "$LINE" "$HYPR/hyprland.lua"; then
  printf '\n-- last on purpose, a failure here must not skip anything above\n%s\n' "$LINE" >> "$HYPR/hyprland.lua"
fi
echo "group tabs installed"
