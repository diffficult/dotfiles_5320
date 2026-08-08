-- Gaming window rules.

hl.window_rule({
  name = "gaming-steam-tag",
  match = {
    class = "^(steam|Steam|steam_app_.*)$",
  },
  tag = "+gaming",
})

hl.window_rule({
  name = "gaming-retroarch-tag",
  match = {
    class = "com.libretro.RetroArch",
  },
  tag = "+gaming",
})

hl.window_rule({
  name = "gaming-winboat-float",
  match = {
    class = "^winboat$",
  },
  float = true,
  center = true,
})

hl.window_rule({
  name = "gaming-steam-ui-float",
  match = {
    class = "^(steam|Steam)$",
  },
  float = true,
  center = true,
  workspace = 8,
})

hl.window_rule({
  name = "gaming-steam-client-main",
  match = {
    class = "^(steam|Steam)$",
    title = "^(steam|Steam)$",
  },
  opacity = "1 override 1 override",
  size = "2350 1280",
})

hl.window_rule({
  name = "gaming-steam-friends-list",
  match = {
    class = "^(steam|Steam)$",
    title = "^(Friends List)$",
  },
  size = "460 800",
})

hl.window_rule({
  name = "gaming-steam-idle-inhibit",
  match = {
    class = "^(steam|Steam)$",
  },
  idle_inhibit = "fullscreen",
  workspace = 8,
})

hl.window_rule({
  name = "gaming-steam-game-immediate",
  match = {
    class = "^(steam_app_.*|cs2)$",
  },
  immediate = true,
  workspace = 8,
})

hl.window_rule({
  name = "gaming-steam-game-fullscreen",
  match = {
    class = "^(steam_app_.*)$",
  },
  fullscreen = true,
  workspace = 8,
})

hl.window_rule({
  name = "gaming-retroarch-fullscreen",
  match = {
    class = "com.libretro.RetroArch",
  },
  fullscreen = true,
  opaque = true,
  idle_inhibit = "fullscreen",
})
