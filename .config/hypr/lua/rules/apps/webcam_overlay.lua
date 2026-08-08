-- Webcam overlay window rules.

hl.window_rule({
  name = "webcam-overlay-float",
  match = {
    title = "WebcamOverlay",
  },
  float = true,
  pin = true,
  no_initial_focus = true,
  no_dim = true,
  move = "(monitor_w-window_w-40) (monitor_h-window_h-40)",
})
