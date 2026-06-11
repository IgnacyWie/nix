{ ... }:

{
  xdg.configFile."ghostty/config".text = ''
    # My Ghostty Terminal config file

    theme = iTerm2 Tango Dark
    font-family = MesloLGS Nerd Font Mono
    font-size = 19
    term = xterm-256color

    # Add some nice looking padding
    window-padding-x = 8
    window-padding-y = 3

    macos-titlebar-style = tabs

    quit-after-last-window-closed = true

    confirm-close-surface = false

    # Dvorak-QWERTY command-key workaround.

    # Copy/Paste (Physical QWERTY C & V -> Dvorak J & K)
    keybind = cmd+j=copy_to_clipboard
    keybind = cmd+k=paste_from_clipboard

    # Surface Management (Physical QWERTY W, T, N -> Dvorak ,, Y, B)
    keybind = cmd+,=close_surface
    keybind = cmd+y=new_tab
    keybind = cmd+b=new_window

    # App Controls (Physical QWERTY Q -> Dvorak ')
    keybind = cmd+'=quit

    # Settings (Physical QWERTY , -> Dvorak W)
    keybind = cmd+w=reload_config
  '';
}
