-- Media app window rules.

hl.window_rule({
  name = "media-tag-app",
  match = {
    class = "^(mpv|Mpv|vlc|zoom|org\\.kde\\.kdenlive|com\\.obsproject\\.Studio|com\\.github\\.PintaProject\\.Pinta|imv|org\\.gnome\\.NautilusPreviewer)$",
  },
  tag = "+media",
})

hl.window_rule({
  name = "media-mpv-float-opaque",
  match = {
    class = "^(mpv|Mpv)$",
  },
  float = true,
  keep_aspect_ratio = true,
  opacity = "1 override 1 override",
})

hl.window_rule({
  name = "media-ytmpv-quality-stream",
  match = {
    title = "^((720p|1080p|480p) - /watch\\?v.*)$",
  },
  size = "1132 679",
  workspace = 2,
  keep_aspect_ratio = true,
  move = "14 747",
})

hl.window_rule({
  name = "media-ytmpv-main-video",
  match = {
    title = "^(watch\\?v.*)$",
  },
  size = "1132 679",
  workspace = 2,
  keep_aspect_ratio = true,
  move = "14 747",
})

hl.window_rule({
  name = "media-webcam-cam01",
  match = {
    title = "^(101)$",
  },
  size = "1132 680",
  workspace = 2,
  keep_aspect_ratio = true,
  move = "14 53",
})

hl.window_rule({
  name = "media-ncmpcpp-float",
  match = {
    title = "(ncmpcpp)",
  },
  float = true,
  size = "1200 676",
  move = "13 755",
})

hl.window_rule({
  name = "media-spotify-workspace-5",
  match = {
    class = "^(Spotify|spotify)$",
  },
  workspace = 5,
})

hl.window_rule({
  name = "media-satty-float",
  match = {
    class = "^(com\\.gabm\\.satty)$",
  },
  float = true,
  center = true,
  size = "1936 1089",
})

hl.window_rule({
  name = "media-viewer-workspace-7",
  match = {
    class = "^(Gpicview|gpicview|Zathura|zathura|org.pwmt.zathura|swayimg_.*)$",
  },
  workspace = 7,
  tag = "+no-border",
})
