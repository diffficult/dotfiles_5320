-- Browser window rules.

hl.window_rule({
  name = "browser-tag-chromium",
  match = {
    class = "((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[bB]rave-origin(-beta)?|[mM]icrosoft-edge|Vivaldi-stable|helium)",
  },
  tag = "+browser +no-border",
})

hl.window_rule({
  name = "browser-tag-firefox",
  match = {
    class = "([fF]irefox|zen|Navigator|librewolf)",
  },
  tag = "+browser +no-border",
})

hl.window_rule({
  name = "browser-zen-workspace",
  match = {
    class = "^(zen|Zen)$",
  },
  workspace = 1,
})

hl.window_rule({
  name = "browser-chromium-workspace",
  match = {
    class = "^(Google-chrome|google-chrome|Chromium|chromium)$",
  },
  workspace = 5,
})

hl.window_rule({
  name = "browser-brave-workspace",
  match = {
    class = "^(brave-browser|Brave-browser)$",
  },
  workspace = 5,
})

hl.window_rule({
  name = "browser-brave-origin-workspace",
  match = {
    class = "^(brave-origin-beta|Brave-origin-beta)$",
  },
  workspace = 5,
})

hl.window_rule({
  name = "browser-zen-opaque",
  match = {
    class = "^(zen|Zen|Navigator)$",
  },
  opacity = "1 override 1 override",
})

hl.window_rule({
  name = "browser-chromium-tiled-opaque",
  match = {
    class = "^((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[bB]rave-origin-beta)$",
    float = false,
  },
  opacity = "1 override 1 override",
})

hl.window_rule({
  name = "browser-firefox-opaque",
  match = {
    class = "^([fF]irefox|librewolf)$",
  },
  opacity = "1 override 1 override",
})

hl.window_rule({
  name = "browser-video-sites-opaque",
  match = {
    initial_title = "((?i)(?:[a-z0-9-]+\\.)*youtube\\.com_/|app\\.zoom\\.us_/wc/home)",
  },
  opacity = "1.0 1.0 override",
})

hl.window_rule({
  name = "browser-comprobante-stay-focused",
  match = {
    class = "^(Navigator|zen)$",
    title = "(?i)Comprobante",
  },
  stay_focused = true,
})

hl.window_rule({
  name = "browser-zen-save-dialog",
  match = {
    class = "^(Navigator|zen|Zen)$",
    title = ".*Save as -.*",
  },
  float = true,
  center = true,
  size = "960 800",
})

hl.window_rule({
  name = "browser-zen-file-chooser",
  match = {
    initial_class = "^xdg-desktop-portal-gtk$",
  },
  float = true,
  center = true,
  size = "1100 800",
})

hl.window_rule({
  name = "browser-brave-youtube-float",
  match = {
    initial_class = "^(brave-www\\.youtube\\.com__-Default)$",
    initial_title = "^(www\\.youtube\\.com_/)$",
  },
  float = true,
  center = true,
  size = "1267 688",
})
