hs.ipc.cliInstall()

for _, module in ipairs({ "wifi", "autoReload", "usb" }) do
  local ok, err = pcall(require, module)
  if not ok then
    print("Optional Hammerspoon module not loaded: " .. module .. ": " .. tostring(err))
  end
end

require("gamma-backup")
