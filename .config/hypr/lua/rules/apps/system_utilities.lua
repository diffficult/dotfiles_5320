-- System utility window rules.

hl.window_rule({
  name = "system-tag-floating-window",
  match = {
    tag = "floating-window",
  },
  float = true,
  center = true,
  size = "875 600",
})

hl.window_rule({
  name = "system-hypr-cheatsheet-float",
  match = {
    class = "^(hypr-cheatsheet)$",
    title = "^(Hypr Cheatsheet)$",
  },
  tag = "+floating-window +pop",
  float = true,
  center = true,
  size = "556 840",
})

hl.window_rule({
  name = "system-tag-media-opaque",
  match = {
    tag = "+media",
  },
  opaque = true,
})

hl.window_rule({
  name = "system-tag-pop-rounding",
  match = {
    tag = "pop",
  },
  rounding = 8,
})

hl.window_rule({
  name = "system-tag-noidle",
  match = {
    tag = "noidle",
  },
  idle_inhibit = "always",
})

hl.window_rule({
  name = "system-pavucontrol-float",
  match = {
    class = "^(org\\.pulseaudio\\.pavucontrol|pavucontrol|Pavucontrol)$",
  },
  float = true,
})

hl.window_rule({
  name = "system-pavucontrol-size",
  match = {
    class = "^(org\\.pulseaudio\\.pavucontrol)$",
  },
  center = true,
  size = "1000 800",
})

hl.window_rule({
  name = "system-pavucontrol-scratchpad",
  match = {
    class = "^(pavucontrol|Pavucontrol)$",
  },
  workspace = "special:scratchpad silent",
})

hl.window_rule({
  name = "system-blueman-float",
  match = {
    class = "^(blueman-manager|Blueman-manager)$",
  },
  float = true,
  center = true,
  size = "600 680",
})

hl.window_rule({
  name = "system-network-manager-float",
  match = {
    class = "^(nm-connection-editor)$",
  },
  float = true,
  center = true,
  size = "600 500",
})

hl.window_rule({
  name = "system-openrgb-float",
  match = {
    initial_class = "^(org\\.openrgb\\.OpenRGB)$",
  },
  float = true,
  center = true,
  size = "1142 560",
})

hl.window_rule({
  name = "system-polychromatic-float",
  match = {
    class = "^(polychromatic)$",
  },
  float = true,
  center = true,
  size = "1000 500",
})

hl.window_rule({
  name = "system-qt5ct-float",
  match = {
    class = "^(qt5ct)$",
  },
  float = true,
  center = true,
  size = "600 680",
})

hl.window_rule({
  name = "system-gsimplecal-float",
  match = {
    class = "^(gsimplecal)$",
  },
  float = true,
  move = "cursor -34 0",
})

hl.window_rule({
  name = "system-seahorse-float",
  match = {
    class = "^(seahorse|Seahorse)$",
  },
  float = true,
})

hl.window_rule({
  name = "system-protonvpn-float",
  match = {
    class = "^(protonvpn)$",
  },
  float = true,
})

hl.window_rule({
  name = "system-syncthing-float",
  match = {
    class = "^(syncthing-gtk)$",
  },
  float = true,
  center = true,
  size = "900 700",
})

hl.window_rule({
  name = "system-megasync-main-dp2",
  match = {
    class = "^(MEGAsync)$",
    title = "^(MEGAsync)$",
  },
  float = true,
  move = "4705 259",
})

hl.window_rule({
  name = "system-megasync-secondary-float",
  match = {
    class = "^(MEGAsync)$",
    title = "^(Settings|Files|window|Window)$",
  },
  float = true,
  center = true,
})

hl.window_rule({
  name = "system-gnome-software-float",
  match = {
    class = "^(org\\.gnome\\.Software)$",
  },
  float = true,
  center = true,
  size = "1100 1000",
})

hl.window_rule({
  name = "system-gearlever-float",
  match = {
    class = "^(it\\.mijorus\\.gearlever)$",
  },
  float = true,
  center = true,
})

hl.window_rule({
  name = "system-bottles-float",
  match = {
    class = "^(com\\.usebottles\\.bottles)$",
  },
  float = true,
  center = true,
  size = "1420 901",
})

hl.window_rule({
  name = "system-nvidia-settings-float",
  match = {
    class = "^(nvidia-settings)$",
  },
  float = true,
  center = true,
  size = "1050 750",
})

hl.window_rule({
  name = "system-obsidian-workspace-10",
  match = {
    class = "^(obsidian)$",
  },
  workspace = 10,
})

hl.window_rule({
  name = "system-disks-float",
  match = {
    class = "^(org\\.gnome\\.DiskUtility)$",
  },
  float = true,
  center = true,
  size = "1140 780",
})

hl.window_rule({
  name = "system-calculator-float",
  match = {
    class = "^(org\\.gnome\\.Calculator)$",
  },
  float = true,
  center = true,
  size = "427 616",
})

hl.window_rule({
  name = "system-gnome-weather-float",
  match = {
    class = "^(org\\.gnome\\.Weather)$",
  },
  float = true,
  center = true,
  size = "1040 620",
})

hl.window_rule({
  name = "system-gnome-usage-float",
  match = {
    class = "^(org\\.gnome\\.Usage)$",
  },
  float = true,
  center = true,
  size = "1040 620",
})

hl.window_rule({
  name = "system-gnome-logs-float",
  match = {
    class = "^(org\\.gnome\\.Logs)$",
  },
  float = true,
  center = true,
  size = "1260 740",
})

hl.window_rule({
  name = "system-office-workspace-6",
  match = {
    class = "^(libreoffice.*|Gimp|gimp)$",
  },
  workspace = 6,
})

hl.window_rule({
  name = "system-vm-workspace-10",
  match = {
    class = "^(Virt-manager|virt-manager|RustDesk|rustdesk|protonvpn|winboat|Winboat)$",
  },
  workspace = 10,
})

hl.window_rule({
  name = "system-qemu-opaque",
  match = {
    class = "qemu",
  },
  opaque = true,
})

hl.window_rule({
  name = "system-scrcpy-float",
  match = {
    class = "^(scrcpy)$",
  },
  float = true,
  size = "2350 1280",
})

hl.window_rule({
  name = "system-notification-daemon-no-focus",
  match = {
    class = "^(mako|dunst)$",
  },
  no_focus = true,
})

hl.window_rule({
  name = "system-notification-title-no-focus",
  match = {
    title = "^(Notification)$",
  },
  no_focus = true,
})

hl.window_rule({
  name = "system-clipse-float",
  match = {
    class = "^(clipse-float)$",
  },
  float = true,
  center = true,
  size = "800 600",
})
