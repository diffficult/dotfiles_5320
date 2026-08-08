local exec_once = {
  "hyprpm reload -n &",
  "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &",
  "eval $(gnome-keyring-daemon --start) &",
  "uwsm app -- swaync",
  "/usr/libexec/xdg-desktop-portal-hyprland &",
  "/usr/libexec/xdg-desktop-portal &",
  "pactl load-module module-switch-on-connect &",
  "uwsm app -- clipse -listen",
  "uwsm app -- /home/poole/.config/hypr/scripts/waybar-with-lua-shim.sh",
  "uwsm app -- qs",
  "uwsm app -- qs -n -d -c /home/poole/.config/warmind/launcher",
  "systemctl --user start skwd-daemon.service",
  "awww-daemon &",
  "uwsm app -- /usr/lib/geoclue-2.0/demos/agent",
  -- "(sleep 10 && uwsm app -- openrgb --startminimized --profile default) &", -- Disabled: i2c-dev warnings on laptop
  "uwsm app -- dropbox &",
  "(for _ in $(seq 1 20); do busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher IsStatusNotifierHostRegistered >/dev/null 2>&1 && break; sleep 1; done; uwsm app -- env QT_QPA_PLATFORM=xcb megasync) &",
  "uwsm app -- foot --server",
}

for _, cmd in ipairs(exec_once) do
  hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.exec_cmd(cmd))
  end)
end
