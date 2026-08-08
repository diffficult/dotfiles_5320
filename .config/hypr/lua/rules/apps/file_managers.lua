-- File manager window rules.

hl.window_rule({
  name = "file-manager-tag-app",
  match = {
    class = "^(nautilus|Nautilus|nemo|Nemo|thunar|Thunar|caja|Caja)$",
  },
  tag = "+file-manager",
})

hl.window_rule({
  name = "file-manager-workspace-3",
  match = {
    class = "^(Nautilus|nautilus|Nemo|nemo|Thunar|thunar)$",
  },
  workspace = 3,
})

hl.window_rule({
  name = "file-manager-default-float",
  match = {
    class = "^(nautilus|Nautilus|nemo|Nemo|thunar|Thunar)$",
  },
  float = true,
  center = true,
  size = "1200 700",
})

hl.window_rule({
  name = "file-manager-archive-float",
  match = {
    class = "^(file-roller|File-roller|org\\.gnome\\.FileRoller)$",
  },
  float = true,
  center = true,
})

hl.window_rule({
  name = "file-manager-sushi-preview",
  match = {
    class = "^(org\\.gnome\\.sushi)$",
  },
  float = true,
  center = true,
})

hl.window_rule({
  name = "file-manager-custom-preview",
  match = {
    class = "^(imv|nemo-preview)$",
  },
  float = true,
  center = true,
})

hl.window_rule({
  name = "file-manager-swayimg-preview",
  match = {
    class = "^(swayimg.*)$",
  },
  float = true,
  center = true,
  tag = "+no-border",
})

hl.window_rule({
  name = "file-manager-browse-dialog",
  match = {
    class = "^(nemo|nautilus|caja|thunar)$",
    title = "^(Browse)$",
  },
  float = true,
})
