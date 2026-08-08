-- DaVinci Resolve window rules.

hl.window_rule({
  name = "davinci-resolve-dialog-float",
  match = {
    class = ".*[Rr]esolve.*",
    float = true,
  },
  stay_focused = true,
})
