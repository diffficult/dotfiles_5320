-- Picture-in-picture window rules.

hl.window_rule({
  name = "pip-picture-in-picture-float",
  match = {
    title = "^(Picture.?in.?[Pp]icture)",
  },
  float = true,
  size = "1210 679",
  keep_aspect_ratio = true,
  move = "14 747",
})
