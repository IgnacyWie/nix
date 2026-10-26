-- spolszcz: restore Polish diacritics in the current selection via a hotkey.
--
-- Bound to ⌃⌥P (ctrl+alt+p). It copies the selection, runs it through the
-- offline restorer, and pastes the diacritised text back over the selection.
-- The original clipboard contents are restored afterwards.

local M = {}

local SCRIPT = os.getenv("HOME") .. "/.local/scripts/spolszcz"

-- Pipe `selection` through the restorer (stdin -> stdout) using a temp file,
-- since io.popen cannot both write and read a single process.
local function restore(selection)
  local tmp = os.tmpname()
  local infile = io.open(tmp, "w")
  if not infile then return nil end
  infile:write(selection)
  infile:close()

  local pipe = io.popen("'" .. SCRIPT .. "' < '" .. tmp .. "' 2>/dev/null")
  local out = pipe and pipe:read("*a") or nil
  if pipe then pipe:close() end
  os.remove(tmp)
  return out
end

local function run()
  local savedClipboard = hs.pasteboard.getContents()

  hs.eventtap.keyStroke({ "cmd" }, "c", 0)
  hs.timer.usleep(150000) -- let the frontmost app populate the pasteboard

  local selection = hs.pasteboard.getContents()
  if not selection or selection == "" then
    hs.alert.show("Spolszcz: nothing selected")
    if savedClipboard then hs.pasteboard.setContents(savedClipboard) end
    return
  end

  local restored = restore(selection)
  if not restored or restored == "" then
    hs.alert.show("Spolszcz: restorer failed")
    if savedClipboard then hs.pasteboard.setContents(savedClipboard) end
    return
  end

  hs.pasteboard.setContents(restored)
  hs.eventtap.keyStroke({ "cmd" }, "v", 0)

  -- Restore the user's previous clipboard once the paste has landed.
  if savedClipboard then
    hs.timer.doAfter(0.3, function()
      hs.pasteboard.setContents(savedClipboard)
    end)
  end
end

M.bind = function()
  hs.hotkey.bind({ "ctrl", "alt" }, "p", run)
end

return M
