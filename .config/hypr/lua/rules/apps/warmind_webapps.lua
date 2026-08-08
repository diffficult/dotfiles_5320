-- Warmind webapp window rules.

hl.window_rule({
  name = "chrome-webapp-grok",
  match = {
    class = "^(chrome|brave)-grok\\.com__-Default$",
  },
  float = true,
  center = true,
  size = "830 840",
  tag = "+chrome-webapp",
})

hl.window_rule({
  name = "chrome-webapp-chatgpt",
  match = {
    class = "^(chrome|brave)-chatgpt\\.com__-Default$",
  },
  float = true,
  center = true,
  size = "830 840",
  tag = "+chrome-webapp",
})

hl.window_rule({
  name = "chrome-webapp-gemini",
  match = {
    class = "^(chrome|brave)-gemini\\.google\\.com__-Default$",
  },
  float = true,
  center = true,
  size = "830 840",
  tag = "+chrome-webapp",
})

hl.window_rule({
  name = "warmind-webapp-word-web",
  match = {
    class = "^(chrome|brave)-word\\.cloud\\.microsoft__-Default$",
  },
  float = true,
  center = true,
  size = "830 840",
  tag = "+chrome-webapp",
})

hl.window_rule({
  name = "warmind-webapp-excel-web",
  match = {
    class = "^(chrome|brave)-excel\\.cloud\\.microsoft__-Default$",
  },
  float = true,
  center = true,
  size = "830 840",
  tag = "+chrome-webapp",
})
