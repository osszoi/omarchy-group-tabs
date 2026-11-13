# Group tabs for Omarchy

An [Omarchy](https://omarchy.org) shell plugin that draws the tab strip of Hyprland window groups, in place of Hyprland's own group bar.

- **Clean titles**: the ` - Google Chrome` / ` - Chromium` suffix is dropped.
- **Who is who**: a Chrome window tagged `browser:<profile directory>` (for example `browser:Profile 1`) shows that profile's avatar and name. Any other window shows its app icon.
- **Active tab**: brighter text and an underline that slides between tabs. It dims when the group is not focused.
- **Theme**: colours come from the current Omarchy theme.

Hyprland's bar stays where it was, see-through. It still reserves the space and still handles clicks, drags and scrolling on the tabs; this plugin only paints.

## Install

```bash
git clone https://github.com/osszoi/omarchy-group-tabs ~/Work/personal/omarchy-group-tabs
~/Work/personal/omarchy-group-tabs/install.sh
```

`install.sh` links the plugin into `~/.config/omarchy/plugins`, enables it, links `hypr/group_tabs.lua` into `~/.config/hypr` and adds `require("hypr.group_tabs")` as the last line of `hyprland.lua`.

Doing it by hand: put the Lua file in place **before** adding the `require`, and keep the `require` last. Hyprland reloads as soon as its config is saved, and a `require` that fails aborts everything after it.

`uninstall.sh` puts Hyprland's own bar back.

## How it works

`hypr/group_tabs.lua` runs inside Hyprland. It makes the native group bar transparent and writes every visible group (position, tabs, active tab) to `$XDG_RUNTIME_DIR/group-tabs.json`, on window events and every 300 ms when something changed.

`GroupTabs.qml` watches that file and keeps one `TabStrip.qml` per group: a layer surface on the bottom layer, placed exactly where the native bar is. Being on the bottom layer, floating and fullscreen windows cover it like they cover any tiled window.

## Limits

- The strip does not slide with the window during workspace or retile animations. It hides and fades back in once the window has settled.
- Resizing a tile with the mouse fires no event, so the strip follows on the next 300 ms tick.
- A group inside a special workspace can lose its tabs behind windows of the normal workspace.
- While the Omarchy shell restarts the strip is blank. Clicks keep working.
