-- Development app window rules.

hl.window_rule({
  name = "development-tag-app",
  match = {
    class = "^(code|Code|code-oss|Subl|subl|Sublime_text|.*zed.*|jetbrains-.*|Marker|t3code)$",
  },
  tag = "+development +no-border",
})

hl.window_rule({
  name = "development-workspace-4",
  match = {
    class = "^(code|Code|code-oss|Subl|subl|Sublime_text|.*zed.*|Marker|t3code)$",
  },
  workspace = 4,
})

hl.window_rule({
  name = "development-marker-workspace-4-fixed",
  match = {
    class = "^(Marker)$",
  },
  float = true,
  size = "1255 1378",
  move = "1290 55",
})

hl.window_rule({
  name = "development-t3code-float",
  match = {
    class = "^(t3code)$",
  },
  float = true,
  center = true,
  size = "1270 1286",
})

hl.window_rule({
  name = "development-opencode-float-center",
  match = {
    initial_class = "^(ai\\.opencode\\.desktop)$",
    initial_title = "^(OpenCode)$",
  },
  float = true,
  center = true,
})

hl.window_rule({
  name = "development-claude-float-center",
  match = {
    initial_class = "^(Claude)$",
    title = "^(Claude)$",
  },
  float = true,
  center = true,
})

hl.window_rule({
  name = "development-jetbrains-splash-float",
  match = {
    class = "^(jetbrains-.*)$",
    title = "^(splash)$",
    float = true,
  },
  center = true,
  no_initial_focus = true,
  decorate = true,
})

hl.window_rule({
  name = "development-jetbrains-popup-float",
  match = {
    class = "^(jetbrains-.*)",
    title = "^()$",
    float = true,
  },
  center = true,
  stay_focused = true,
  decorate = true,
  size = "(monitor_w*0.5) (monitor_h*0.5)",
})

hl.window_rule({
  name = "development-jetbrains-no-follow-mouse",
  match = {
    class = "^(jetbrains-.*)$",
  },
  no_follow_mouse = true,
})

hl.window_rule({
  name = "development-jetbrains-autocomplete",
  match = {
    class = "^(jetbrains-.*)$",
    title = "^(win.*)$",
    float = true,
  },
  no_initial_focus = true,
})
