-- Terminal window rules.

hl.window_rule({
  match = {
    class = "^(Alacritty|kitty|com.mitchellh.ghostty|dev.warp.Warp)$",
  },
  tag = "+terminal",
})

hl.window_rule({
  name = "terminal-warp-float",
  match = {
    class = "^(dev.warp.Warp)$",
  },
  float = true,
  center = true,
  size = "(monitor_w*0.62) (monitor_h*0.69)",
})

hl.window_rule({
  name = "terminal-sudo-passwordless-float",
  match = {
    class = "^(warmind\\.sudo\\.passwordless)$",
  },
  float = true,
  center = true,
  size = "728 788",
})

hl.window_rule({
  name = "terminal-bnatxtgen-float",
  match = {
    class = "^(BNATXTGen)$",
  },
  float = true,
  center = true,
  size = "1331 1045",
})

hl.window_rule({
  name = "terminal-yazi-float",
  match = {
    initial_class = "^(yazi)$",
    initial_title = "^(Yazi)$",
  },
  float = true,
  center = true,
  size = "1360 780",
})
