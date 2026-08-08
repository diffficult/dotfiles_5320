-- Password manager window rules.

hl.window_rule({
  name = "password-manager-tag-app",
  match = {
    class = "^(1[p|P]assword|Bitwarden|Keepass|keepassx2|keepassxc)$",
  },
  tag = "+password-manager",
  no_screen_share = true,
})

hl.window_rule({
  name = "password-manager-workspace-5",
  match = {
    class = "^(1[p|P]assword|Bitwarden|Keepass|keepassx2|keepassxc|Brave-browser|brave-browser)$",
  },
  workspace = 5,
})
