local menubar = hs.menubar.new()
local user = os.getenv("USER") or "ignacywielogorski"
local home = os.getenv("HOME") or "/Users/ignacywielogorski"
local stateDir = home .. "/.local/state/gamma-restic-backup"
local successMarker = stateDir .. "/last-success"
local stderrLog = home .. "/Library/Logs/gamma-restic-backup/launchd-stderr.log"
local backupCommand = "/etc/profiles/per-user/" .. user .. "/bin/gamma-restic-backup"
local restorePicker = home .. "/.local/scripts/backup-restore-picker"
local backupDoc = home .. "/nix/backup.md"

local runningTask = nil

local function shellQuote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function formatAge(seconds)
  if not seconds then
    return "never"
  end

  if seconds < 60 then
    return "just now"
  elseif seconds < 3600 then
    return string.format("%d min ago", math.floor(seconds / 60))
  elseif seconds < 86400 then
    return string.format("%d h ago", math.floor(seconds / 3600))
  else
    return string.format("%d d ago", math.floor(seconds / 86400))
  end
end

local function fileModifiedAt(path)
  local attributes = hs.fs.attributes(path)
  if attributes then
    return attributes.modification
  end
  return nil
end

local function fileSize(path)
  local attributes = hs.fs.attributes(path)
  if attributes then
    return attributes.size or 0
  end
  return 0
end

local function asTemplate(image)
  if not image then
    return nil
  end

  if image.setTemplate then
    image:setTemplate(true)
  elseif image.template then
    image:template(true)
  end

  return image
end

local function systemImage(name, fallbackName)
  if hs.image.systemImageFromName then
    local ok, image = pcall(hs.image.systemImageFromName, name)
    if ok and image then
      return asTemplate(image)
    end
  end

  return asTemplate(hs.image.imageFromName(fallbackName or "NSStatusAvailable"))
end

local icons = {
  ok = systemImage("externaldrive.badge.checkmark", "NSStatusAvailable"),
  stale = systemImage("externaldrive.badge.exclamationmark", "NSStatusPartiallyAvailable"),
  failed = systemImage("externaldrive.badge.xmark", "NSStatusUnavailable"),
  running = systemImage("arrow.triangle.2.circlepath", "NSRefreshTemplate"),
  unknown = systemImage("externaldrive", "NSStatusNone"),
}

local function statusFromFiles()
  if runningTask then
    return "running", "Backup is running", nil
  end

  local successAt = fileModifiedAt(successMarker)
  if not successAt then
    return "unknown", "No successful backup marker found", nil
  end

  local now = os.time()
  local age = now - successAt
  local stderrAt = fileModifiedAt(stderrLog)
  local stderrHasContent = fileSize(stderrLog) > 0

  if stderrHasContent and stderrAt and stderrAt > successAt and (now - stderrAt) < 172800 then
    return "failed", "stderr log changed after the last success", age
  elseif age > 172800 then
    return "failed", "Last successful backup is older than 48 hours", age
  elseif age > 86400 then
    return "stale", "Last successful backup is older than 24 hours", age
  else
    return "ok", "Last successful backup is recent", age
  end
end

local function openInTerminal(command)
  local script = string.format(
    'tell application "Terminal"\nactivate\ndo script %q\nend tell',
    command
  )
  hs.execute("/usr/bin/osascript -e " .. shellQuote(script), true)
end

local updateMenu

local function runBackupNow()
  if runningTask then
    hs.notify.new({ title = "Gamma Restic Backup", informativeText = "Backup is already running." }):send()
    return
  end

  runningTask = hs.task.new("/bin/zsh", function(exitCode)
    runningTask = nil

    if exitCode == 0 then
      hs.notify.new({ title = "Gamma Restic Backup", informativeText = "Backup completed successfully." }):send()
    else
      hs.notify.new({ title = "Gamma Restic Backup Failed", informativeText = "Exit code: " .. tostring(exitCode) }):send()
    end

    updateMenu()
    return true
  end, { "-lc", shellQuote(backupCommand) })

  updateMenu()
  runningTask:start()
end

updateMenu = function()
  local status, reason, age = statusFromFiles()

  if menubar then
    menubar:setIcon(icons[status] or icons.unknown)
    menubar:setTooltip("Gamma Restic Backup: " .. reason)
    menubar:setMenu({
      { title = "Gamma Restic Backup", disabled = true },
      { title = "Status: " .. reason, disabled = true },
      { title = "Last success: " .. formatAge(age), disabled = true },
      { title = "Repository: b2:gamma-backup-restic:gamma", disabled = true },
      { title = "-" },
      { title = "Back Up Now", fn = runBackupNow, disabled = runningTask ~= nil },
      { title = "Restore Files…", fn = function() openInTerminal(shellQuote(restorePicker)) end },
      { title = "Open Backup Logs", fn = function() hs.execute("/usr/bin/open " .. shellQuote(home .. "/Library/Logs/gamma-restic-backup"), true) end },
      { title = "Open Backup Documentation", fn = function() hs.execute("/usr/bin/open " .. shellQuote(backupDoc), true) end },
      { title = "Refresh Status", fn = updateMenu },
    })
  end
end

if menubar then
  updateMenu()
  hs.timer.doEvery(60, updateMenu)
end
