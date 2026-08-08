-- Communication app window rules.

hl.window_rule({
  name = "communication-tag-app",
  match = {
    class = "^(org.telegram.desktop|localsend|LocalSend|rustdesk|RustDesk|discord|vesktop|Keybase)$",
  },
  tag = "+communication",
})

hl.window_rule({
  name = "communication-keybase-workspace-8",
  match = {
    class = "^(Keybase)$",
  },
  workspace = 8,
})

hl.window_rule({
  name = "communication-workspace-9",
  match = {
    class = "^(org.telegram.desktop|localsend|LocalSend|vesktop)$",
  },
  workspace = 9,
})

hl.window_rule({
  name = "communication-keybase-float",
  match = {
    class = "^(Keybase)$",
  },
  float = true,
  center = true,
  size = "799 869",
})

hl.window_rule({
  name = "communication-telegram-no-border",
  match = {
    class = "^(org.telegram.desktop)$",
  },
  tag = "+no-border",
})

hl.window_rule({
  name = "communication-localsend-float",
  match = {
    class = "(Share|localsend|org\\.localsend\\.localsend_app)",
  },
  float = true,
  center = true,
  size = "800 650",
})

hl.window_rule({
  name = "communication-remote-chat-float",
  match = {
    class = "^(org.telegram.desktop|rustdesk|RustDesk)$",
  },
  float = true,
})

hl.window_rule({
  name = "communication-remote-desktop-tiling",
  match = {
    class = "^(?i)rustdesk$",
    title = ".*Remote Desktop.*",
  },
  float = false,
  border_size = 0,
})

hl.window_rule({
  name = "communication-discord-no-border",
  match = {
    class = "^(discord|vesktop)$",
  },
  tag = "+no-border",
  float = true,
  size = "1800 1100",
})
