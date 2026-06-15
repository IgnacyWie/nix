wifiWatcher = nil

-- On Wi-Fi change, mute the device and connect to the Tailscale VPN
function ssidChanged()
  local ssid = hs.wifi.currentNetwork()

  if ssid == nil then
    hs.alert.show("Wi-Fi Disconnected")
  else
    hs.alert.show("Connected to: " .. ssid)
  end

  if ssid == "IB_student" then
    -- Set the Volume to 0%
    hs.audiodevice.defaultOutputDevice():setVolume(0)
    hs.alert.show("Set System Volume to 0%")
  end

  if ssid ~= nil and not string.find(ssid, "KiJAster", 1, true) then
    -- Execute command to connect to EndNode Tailscale VPN
    hs.execute(
      "/Applications/Tailscale.app/Contents/MacOS/Tailscale up  --exit-node=diskstation --exit-node-allow-lan-access"
    )
    hs.alert.show("Connected to Tailscale VPN")
  end
end

wifiWatcher = hs.wifi.watcher.new(ssidChanged)
wifiWatcher:start()
