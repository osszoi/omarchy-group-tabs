-- publishes every visible window group (geometry + tabs) for the eduardo.group-tabs shell
-- plugin, which draws the strip. hyprland's own bar stays there, see-through, so it still
-- reserves the space and handles clicks/drags on the tabs

local bar_height = 40
local clear = "rgba(00000000)"
local state_path = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/group-tabs.json"

hl.config({
  group = {
    groupbar = {
      height = bar_height,
      render_titles = false,
      -- with gradients off too the bar collapses to 0px
      gradients = true,
      indicator_height = 0,
      indicator_gap = 0,
      gaps_in = 0,
      gaps_out = 0,
      col = { active = clear, inactive = clear, locked_active = clear, locked_inactive = clear },
    },
  },
})

local function quote(text)
  return '"' .. text:gsub('[%c"\\]', function(char) return string.format("\\u%04x", char:byte()) end) .. '"'
end

local function tab_json(member, group)
  local tags = {}
  for _, tag in ipairs(member.tags or {}) do table.insert(tags, quote(tag)) end
  return string.format('{"title":%s,"class":%s,"tags":[%s],"current":%s}',
    quote(member.title), quote(member.class), table.concat(tags, ","), tostring(member.address == group.current.address))
end

local function group_json(id, w, border, active)
  local group, monitor = w.group, w.monitor
  local tabs, focused = {}, false
  for _, member in ipairs(group.members) do
    table.insert(tabs, tab_json(member, group))
    focused = focused or (active ~= nil and member.address == active.address)
  end
  return string.format('{"id":%d,"monitor":%s,"x":%d,"y":%d,"width":%d,"height":%d,"focused":%s,"tabs":[%s]}',
    id, quote(monitor.name),
    w.at.x - border - monitor.position.x, w.at.y - border - bar_height - monitor.position.y,
    w.size.x + border * 2, bar_height, tostring(focused), table.concat(tabs, ","))
end

local function snapshot()
  local border = hl.get_config("general.border_size")
  local active = hl.get_active_window()
  local seen, groups = {}, {}
  for _, w in ipairs(hl.get_windows()) do
    local workspace = w.workspace
    if w.group and w.mapped and w.monitor and workspace and workspace.visible and not workspace.special then
      local id = math.huge
      for _, member in ipairs(w.group.members) do id = math.min(id, member.stable_id) end
      if not seen[id] then
        seen[id] = true
        table.insert(groups, group_json(id, w.group.current, border, active))
      end
    end
  end
  return '{"groups":[' .. table.concat(groups, ",") .. "]}"
end

local published

local function publish()
  local ok, state = pcall(snapshot)
  if not ok or state == published then return end
  local file = io.open(state_path, "w")
  if not file then return end
  file:write(state)
  file:close()
  published = state
end

local function publish_soon()
  hl.timer(publish, { timeout = 20, type = "oneshot" })
end

for _, event in ipairs({
  "window.active", "window.open", "window.close", "window.title", "window.fullscreen",
  "window.move_to_workspace", "workspace.active", "workspace.special_active", "monitor.focused",
}) do
  hl.on(event, publish_soon)
end

-- resizes and regrouping fire no event at all
hl.timer(publish, { timeout = 300, type = "repeat" })
publish_soon()
