local M = {}

local log = hs.logger.new("ma-volume", "info")

local companionBundleID = "io.music-assistant.companion"
local builtinPlayerPreference = "<builtinplayer>"
local mediaControlPath = "/opt/homebrew/bin/media-control"
local sqlitePath = "/usr/bin/sqlite3"
local settingsPath = os.getenv("HOME")
  .. "/Library/Application Support/music-assistant-companion/settings.json"
local websiteDataRoot = os.getenv("HOME")
  .. "/Library/WebKit/io.music-assistant.companion/WebsiteData/Default"
local replayMarker = 0x4D41564B -- "MAVK"

local state = {
  running = false,
  authenticated = false,
  activePlayerId = nil,
  player = nil,
  mediaKnown = false,
  mediaPlaying = false,
  mediaBundleID = nil,
  nextMessageID = 0,
  pending = {},
  capturedKeys = {},
}

local startMusicAssistant
local refreshContext

local function stopTimer(timer)
  if timer then
    timer:stop()
  end
end

local function decodeJSON(value)
  local ok, decoded = pcall(hs.json.decode, value)
  if ok then
    return decoded
  end
  return nil
end

local function isExecutable(path)
  local attributes = hs.fs.attributes(path)
  return attributes ~= nil and attributes.mode == "file"
end

local function readFile(path)
  local file = io.open(path, "rb")
  if not file then
    return nil
  end
  local contents = file:read("*a")
  file:close()
  return contents
end

local function hexDecode(value)
  if not value or value == "" or value:find("[^0-9a-fA-F]") then
    return nil
  end
  return value:gsub("..", function(byte)
    return string.char(tonumber(byte, 16))
  end)
end

local function websocketURL(serverURL)
  local result = serverURL:gsub("^https://", "wss://"):gsub("^http://", "ws://")
  if not result:match("/ws$") then
    result = result:gsub("/$", "") .. "/ws"
  end
  return result
end

local function serverHost(serverURL)
  return serverURL:match("^%a[%w+.-]*://([^/:]+)")
end

local function findTokenDatabase(serverURL)
  local host = serverHost(serverURL)
  if not host then
    return nil
  end

  local ok, iterator, directory = pcall(hs.fs.dir, websiteDataRoot)
  if not ok or not iterator then
    return nil
  end

  for entry in iterator, directory do
    if entry ~= "." and entry ~= ".." then
      local originRoot = websiteDataRoot .. "/" .. entry .. "/" .. entry
      local origin = readFile(originRoot .. "/origin")
      local database = originRoot .. "/LocalStorage/localstorage.sqlite3"
      if origin and origin:find(host, 1, true) and hs.fs.attributes(database) then
        return database
      end
    end
  end
  return nil
end

local function loadToken(database, callback)
  local query = [[
SELECT hex(value)
FROM ItemTable
WHERE key IN ('ma_access_token', 'auth_token')
ORDER BY CASE key WHEN 'ma_access_token' THEN 0 ELSE 1 END
LIMIT 1;
]]

  state.tokenTask = hs.task.new(sqlitePath, function(exitCode, stdout, stderr)
    state.tokenTask = nil
    if not state.running then
      return
    end
    if exitCode ~= 0 then
      log.ef("Could not read the Music Assistant session: %s", stderr)
      callback(nil)
      return
    end

    local rawToken = hexDecode(stdout:match("([0-9a-fA-F]+)"))
    -- WebKit stores localStorage text as UTF-16LE. Access tokens are ASCII, so
    -- removing the interleaved NUL bytes avoids putting secrets in a shell or
    -- another configuration file.
    local token = rawToken and rawToken:gsub("%z", ""):match("^%s*(.-)%s*$") or nil
    callback(token ~= "" and token or nil)
  end, { database, query })

  if not state.tokenTask or not state.tokenTask:start() then
    state.tokenTask = nil
    callback(nil)
  end
end

local function scheduleMusicAssistantReconnect()
  if not state.running or state.reconnectTimer then
    return
  end
  state.reconnectTimer = hs.timer.doAfter(3, function()
    state.reconnectTimer = nil
    startMusicAssistant()
  end)
end

local function clearPending(reason)
  local pending = state.pending
  state.pending = {}
  for _, command in pairs(pending) do
    stopTimer(command.timeout)
    if command.callback then
      command.callback(false, nil, reason)
    end
  end
end

local function resetMusicAssistant(reason)
  state.authenticated = false
  state.activePlayerId = nil
  state.player = nil
  state.contextInFlight = false
  clearPending(reason or "Music Assistant disconnected")
end

local function sendCommand(command, args, callback, timeoutSeconds)
  if not state.ws or state.ws:status() ~= "open" then
    if callback then
      callback(false, nil, "Music Assistant is not connected")
    end
    return false
  end

  state.nextMessageID = state.nextMessageID + 1
  local messageID = "hammerspoon-volume-" .. tostring(state.nextMessageID)
  local message = {
    message_id = messageID,
    command = command,
  }
  if args ~= nil then
    message.args = args
  end

  local pending = { callback = callback }
  state.pending[messageID] = pending
  pending.timeout = hs.timer.doAfter(timeoutSeconds or 3, function()
    if state.pending[messageID] ~= pending then
      return
    end
    state.pending[messageID] = nil
    if callback then
      callback(false, nil, "Music Assistant command timed out")
    end
  end)

  local ok = pcall(function()
    state.ws:send(hs.json.encode(message), false)
  end)
  if not ok then
    state.pending[messageID] = nil
    stopTimer(pending.timeout)
    if callback then
      callback(false, nil, "Could not send Music Assistant command")
    end
    return false
  end
  return true
end

local function updateActivePlayer(user)
  local preferences = type(user) == "table" and user.preferences or nil
  local playerID = type(preferences) == "table" and preferences.activePlayerId or nil
  if playerID == builtinPlayerPreference or playerID == "" then
    playerID = nil
  end

  if playerID ~= state.activePlayerId then
    state.activePlayerId = playerID
    state.player = nil
  end

  if not playerID then
    state.contextInFlight = false
    return
  end

  sendCommand("players/get", { player_id = playerID, raise_unavailable = false }, function(ok, player)
    state.contextInFlight = false
    if ok and type(player) == "table" and player.player_id == state.activePlayerId then
      state.player = player
    elseif not ok then
      state.player = nil
    end
  end)
end

refreshContext = function()
  if not state.running or not state.authenticated or state.contextInFlight then
    return
  end
  state.contextInFlight = true
  sendCommand("auth/me", nil, function(ok, user)
    if not ok then
      state.contextInFlight = false
      state.player = nil
      return
    end
    updateActivePlayer(user)
  end)
end

local function handleMusicAssistantMessage(rawMessage)
  local message = decodeJSON(rawMessage)
  if type(message) ~= "table" then
    return
  end

  if message.server_version and message.server_id and not state.authenticated then
    sendCommand("auth", {
      token = state.token,
      device_name = "Hammerspoon volume keys",
    }, function(ok, result, err)
      if not ok or type(result) ~= "table" or type(result.user) ~= "table" then
        log.ef("Music Assistant authentication failed: %s", err or "unknown error")
        resetMusicAssistant("Music Assistant authentication failed")
        if state.ws then
          state.ws:close()
        end
        return
      end
      state.authenticated = true
      updateActivePlayer(result.user)
      log.i("Music Assistant volume-key bridge connected")
    end, 5)
    return
  end

  if message.message_id then
    local pending = state.pending[tostring(message.message_id)]
    if not pending then
      return
    end
    state.pending[tostring(message.message_id)] = nil
    stopTimer(pending.timeout)
    if pending.callback then
      if message.error_code then
        pending.callback(false, nil, message.details or tostring(message.error_code))
      else
        pending.callback(true, message.result, nil)
      end
    end
    return
  end

  if message.event == "player_updated"
    and message.object_id == state.activePlayerId
    and type(message.data) == "table"
  then
    state.player = state.player or {}
    for key, value in pairs(message.data) do
      state.player[key] = value
    end
  elseif message.event == "player_removed" and message.object_id == state.activePlayerId then
    state.player = nil
  end
end

local function connectMusicAssistant(serverURL, token)
  state.serverURL = serverURL
  state.token = token
  local url = websocketURL(serverURL)

  state.ws = hs.websocket.new(url, function(status, message)
    if not state.running then
      return
    end
    if status == "received" then
      handleMusicAssistantMessage(message)
    elseif status == "closed" or status == "fail" then
      resetMusicAssistant(message or status)
      state.ws = nil
      scheduleMusicAssistantReconnect()
    end
  end)
end

startMusicAssistant = function()
  if not state.running or state.tokenTask then
    return
  end

  local settings = hs.json.read(settingsPath)
  local serverURL = type(settings) == "table" and settings.last_server_url or nil
  if type(serverURL) ~= "string" or serverURL == "" then
    log.w("Music Assistant has no current server; using normal Mac volume keys")
    scheduleMusicAssistantReconnect()
    return
  end

  local database = findTokenDatabase(serverURL)
  if not database then
    log.w("Could not locate the Music Assistant session; using normal Mac volume keys")
    scheduleMusicAssistantReconnect()
    return
  end

  loadToken(database, function(token)
    if not token then
      log.w("Music Assistant is not signed in; using normal Mac volume keys")
      scheduleMusicAssistantReconnect()
      return
    end
    connectMusicAssistant(serverURL, token)
  end)
end

local function updateMediaState(payload)
  stopTimer(state.emptyMediaTimer)
  state.emptyMediaTimer = nil

  if type(payload) ~= "table" or next(payload) == nil then
    -- media-control emits an empty snapshot before the populated one. Wait a
    -- moment before treating it as "nothing playing" so keys do not briefly
    -- switch targets during a metadata refresh.
    state.emptyMediaTimer = hs.timer.doAfter(0.35, function()
      state.emptyMediaTimer = nil
      state.mediaKnown = true
      state.mediaPlaying = false
      state.mediaBundleID = nil
    end)
    return
  end

  if payload.playing ~= nil then
    state.mediaKnown = true
    state.mediaPlaying = payload.playing == true
    state.mediaBundleID = payload.bundleIdentifier
  end
end

local function consumeMediaControlOutput(output)
  state.mediaBuffer = (state.mediaBuffer or "") .. (output or "")
  while true do
    local newline = state.mediaBuffer:find("\n", 1, true)
    if not newline then
      break
    end
    local line = state.mediaBuffer:sub(1, newline - 1)
    state.mediaBuffer = state.mediaBuffer:sub(newline + 1)
    local event = decodeJSON(line)
    if type(event) == "table" and event.type == "data" then
      updateMediaState(event.payload)
    end
  end
end

local function scheduleMediaMonitorRestart()
  if not state.running or state.mediaRestartTimer then
    return
  end
  state.mediaRestartTimer = hs.timer.doAfter(3, function()
    state.mediaRestartTimer = nil
    M.startMediaMonitor()
  end)
end

function M.startMediaMonitor()
  if not state.running or state.mediaTask then
    return
  end
  if not isExecutable(mediaControlPath) then
    state.mediaKnown = false
    log.w("media-control is unavailable; using normal Mac volume keys")
    scheduleMediaMonitorRestart()
    return
  end

  state.mediaBuffer = ""
  state.mediaTask = hs.task.new(mediaControlPath, function(exitCode, stdout, stderr)
    state.mediaTask = nil
    consumeMediaControlOutput(stdout)
    state.mediaKnown = false
    if state.running then
      log.wf("media-control stopped (exit %d): %s", exitCode, stderr)
      scheduleMediaMonitorRestart()
    end
  end, function(_, stdout, stderr)
    consumeMediaControlOutput(stdout)
    if stderr and stderr ~= "" then
      log.w(stderr)
    end
    return true
  end, {
    "stream",
    "--no-diff",
    "--debounce=100",
    "--no-artwork",
    "--allow-missing-title",
  })

  if not state.mediaTask or not state.mediaTask:start() then
    state.mediaTask = nil
    state.mediaKnown = false
    scheduleMediaMonitorRestart()
  end
end

local function contains(values, expected)
  if type(values) ~= "table" then
    return false
  end
  for _, value in ipairs(values) do
    if value == expected then
      return true
    end
  end
  return false
end

local function isGrouped(player)
  if type(player.group_members) ~= "table" then
    return false
  end
  if player.type == "group" then
    return #player.group_members > 0
  end
  for _, playerID in ipairs(player.group_members) do
    if playerID ~= player.player_id then
      return true
    end
  end
  return false
end

local function canRouteKey(key)
  if not state.mediaKnown then
    return false
  end
  if state.mediaPlaying and state.mediaBundleID ~= companionBundleID then
    return false
  end
  if not state.authenticated or not state.activePlayerId or not state.player then
    return false
  end

  local player = state.player
  if player.available == false or player.powered == false then
    return false
  end
  if key == "MUTE" then
    if isGrouped(player) then
      return player.group_volume_muted ~= nil
    end
    return player.mute_control ~= "none"
  end
  return contains(player.supported_features, "volume_set")
end

local function replaySystemKey(key)
  for _, isDown in ipairs({ true, false }) do
    local event = hs.eventtap.event.newSystemKeyEvent(key, isDown)
    event:setProperty(hs.eventtap.event.properties.eventSourceUserData, replayMarker)
    event:post()
  end
end

local function dispatchMusicAssistantKey(key)
  local player = state.player
  if not player then
    return false
  end

  local grouped = isGrouped(player)
  local command
  local args = { player_id = player.player_id }
  if key == "SOUND_UP" then
    command = grouped and "group_volume_up" or "volume_up"
  elseif key == "SOUND_DOWN" then
    command = grouped and "group_volume_down" or "volume_down"
  elseif key == "MUTE" then
    command = grouped and "group_volume_mute" or "volume_mute"
    if grouped then
      args.muted = player.group_volume_muted ~= true
    else
      args.muted = player.volume_muted ~= true
    end
  else
    return false
  end

  local sent = sendCommand("players/cmd/" .. command, args, function(ok, _, err)
    if not ok then
      state.player = nil
      log.wf("Music Assistant volume command failed: %s", err or "unknown error")
      replaySystemKey(key)
      refreshContext()
      return
    end
    if key == "MUTE" then
      if grouped then
        player.group_volume_muted = args.muted
      else
        player.volume_muted = args.muted
      end
    end
  end, 2)
  return sent
end

local function handleSystemKey(event)
  if event:getProperty(hs.eventtap.event.properties.eventSourceUserData) == replayMarker then
    return false
  end

  local key = event:systemKey()
  if not key or not ({ SOUND_UP = true, SOUND_DOWN = true, MUTE = true })[key.key] then
    return false
  end

  if not key.down then
    if state.capturedKeys[key.key] then
      state.capturedKeys[key.key] = nil
      return true
    end
    return false
  end

  local flags = event:getFlags()
  if flags.cmd or flags.alt or flags.ctrl or not canRouteKey(key.key) then
    return false
  end

  if dispatchMusicAssistantKey(key.key) then
    state.capturedKeys[key.key] = true
    return true
  end
  return false
end

function M.status()
  local player = state.player
  local grouped = player and isGrouped(player) or false
  local volume = nil
  local muted = nil
  if player then
    if grouped then
      volume = player.group_volume
      muted = player.group_volume_muted
    else
      volume = player.volume_level
      muted = player.volume_muted
    end
  end
  return {
    running = state.running,
    mediaKnown = state.mediaKnown,
    mediaPlaying = state.mediaPlaying,
    mediaBundleID = state.mediaBundleID,
    authenticated = state.authenticated,
    activePlayerID = state.activePlayerId,
    activePlayerName = player and (player.display_name or player.name) or nil,
    activePlayerGrouped = grouped,
    activePlayerVolume = volume,
    activePlayerMuted = muted,
    interceptingVolume = canRouteKey("SOUND_UP"),
    interceptingMute = canRouteKey("MUTE"),
  }
end

function M.start()
  if state.running then
    return M
  end
  state.running = true
  M.startMediaMonitor()
  startMusicAssistant()
  state.contextTimer = hs.timer.doEvery(2, refreshContext)
  state.eventTap = hs.eventtap.new({ hs.eventtap.event.types.systemDefined }, handleSystemKey):start()
  return M
end

function M.stop()
  state.running = false
  if state.eventTap then
    state.eventTap:stop()
    state.eventTap = nil
  end
  stopTimer(state.contextTimer)
  stopTimer(state.reconnectTimer)
  stopTimer(state.mediaRestartTimer)
  stopTimer(state.emptyMediaTimer)
  state.contextTimer = nil
  state.reconnectTimer = nil
  state.mediaRestartTimer = nil
  state.emptyMediaTimer = nil
  if state.mediaTask then
    state.mediaTask:terminate()
    state.mediaTask = nil
  end
  if state.tokenTask then
    state.tokenTask:terminate()
    state.tokenTask = nil
  end
  if state.ws then
    state.ws:close()
    state.ws = nil
  end
  for _, pending in pairs(state.pending) do
    stopTimer(pending.timeout)
  end
  state.pending = {}
  resetMusicAssistant("Music Assistant volume-key bridge stopped")
  state.mediaKnown = false
  state.capturedKeys = {}
  return M
end

return M.start()
