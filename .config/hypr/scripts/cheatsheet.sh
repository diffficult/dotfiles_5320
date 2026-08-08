#!/usr/bin/env bash

set -euo pipefail

tmp_file=""

cleanup() {
  if [[ -n "${tmp_file}" && -f "${tmp_file}" ]]; then
    rm -f "${tmp_file}"
  fi
}

trap cleanup EXIT

accent="\e[38;5;45m"
header_color="\e[38;5;213m"
key_color="\e[38;5;122m"
desc_color="\e[38;5;255m"
muted="\e[38;5;245m"
reset="\e[0m"
bold="\e[1m"

cols=$(tput cols 2>/dev/null || printf '80')
if (( cols < 24 )); then
  cols=24
fi
pane_width=$((cols - 4))
if (( pane_width < 16 )); then
  pane_width=16
fi

make_line() {
  local len=$1 char=${2:-─} line
  printf -v line '%*s' "$len" ''
  printf '%s' "${line// /$char}"
}

pane_line=$(make_line "$pane_width")
key_col_width=$((pane_width / 3))
if (( key_col_width < 14 )); then
  key_col_width=14
fi
desc_col_width=$((pane_width - key_col_width - 5))
if (( desc_col_width < 24 )); then
  desc_col_width=24
  key_col_width=$((pane_width - desc_col_width - 5))
fi
if (( key_col_width < 12 )); then
  key_col_width=12
fi

print_header() {
  printf "%b┌%s┐%b\n" "$accent" "$pane_line" "$reset"
  printf "%b│ %b%-${pane_width}s%b│%b\n" "$accent" "$header_color$bold" "Hyprland Key Cheatsheet" "$accent" "$reset"
  printf "%b│ %b%-${pane_width}s%b│%b\n" "$accent" "$muted" "Inspired by Bubble Tea Layouts" "$accent" "$reset"
  printf "%b└%s┘%b\n\n" "$accent" "$pane_line" "$reset"
}

print_footer() {
  printf "%b└%s┘%b\n" "$accent" "$pane_line" "$reset"
  printf "%bTip:%b Press %bq%b to exit the cheatsheet.\n" "$muted" "$reset" "$bold" "$reset"
}

wrap_row() {
  local combo="$1"
  local text="$2"
  local first_line=1
  local line

  while IFS= read -r line; do
    if (( first_line )); then
      printf "%b│ %b%-${key_col_width}s %b│ %b%-${desc_col_width}s %b│%b\n" \
        "$accent" "$key_color" "$combo" "$accent" "$desc_color" "$line" "$accent" "$reset"
      first_line=0
    else
      printf "%b│ %b%-${key_col_width}s %b│ %b%-${desc_col_width}s %b│%b\n" \
        "$accent" "$key_color" "" "$accent" "$desc_color" "$line" "$accent" "$reset"
    fi
  done < <(printf '%s\n' "$text" | fold -s -w "$desc_col_width")
}

render_section() {
  local title="$1"
  printf "%b╭%s╮%b\n" "$accent" "$pane_line" "$reset"
  printf "%b│ %b%-${pane_width}s%b│%b\n" "$accent" "$header_color$bold" "$title" "$accent" "$reset"
  printf "%b├%s┤%b\n" "$accent" "$pane_line" "$reset"
  while IFS='|' read -r combo description; do
    [[ -z "${combo}${description}" ]] && continue
    wrap_row "$combo" "$description"
  done
  printf "%b╰%s╯%b\n\n" "$accent" "$pane_line" "$reset"
}

render_all() {
  print_header

  render_section "Workspaces & Navigation" <<'EOF'
SUPER+1..0|Switch to workspaces 1–10
SUPER+SHIFT+1..0|Move focused window to workspace
SUPER+minus|Toggle scratchpad workspace
SUPER+SHIFT+minus|Send window to scratchpad
SUPER+Tab|Jump to previous workspace
SUPER+SHIFT+Tab|Jump to next workspace
SUPER+O|ScrollOverview toggle
SUPER+E|ScrollOverview toggle
EOF

  render_section "Focus & Layout" <<'EOF'
SUPER+J/K/L/;|Focus left / down / up / right
SUPER+Arrow keys|Focus via arrow direction
SUPER+SHIFT+J/K/L/;|Move window left / down / up / right
SUPER+SHIFT+Arrow keys|Move window with arrows
SUPER+F|Toggle fullscreen
SUPER+SHIFT+space|Toggle floating for focused window
SUPER+space|Cycle focus between floating/tiling
SUPER+A|Toggle pseudo tiling (stacked)
SUPER+E|Toggle split orientation
EOF

  render_section "Launchers & Apps" <<'EOF'
SUPER+Return|Kitty terminal via uwsm app
SUPER+SHIFT+F|Nemo file manager
SUPER+G|Grok desktop client
SUPER+D|Rofi combi launcher
SUPER+P|rofi-pass password picker
SUPER+Y|Clipse clipboard manager (floating foot)
SUPER+period|Rofimoji picker (copy)
SUPER+C|Rofi calculator
SUPER+SHIFT+B|Rofi Bluetooth menu
SUPER+W|Walker / Zen Browser launcher
SUPER+comma|Hypr custom menu
SUPER+M|ncmpcpp music client (foot)
EOF

  render_section "Screenshots" <<'EOF'
SUPER+S|Region → save + clipboard
SUPER+CTRL+S|Region → clipboard only
SUPER+SHIFT+S|Fullscreen → save + clipboard
SUPER+CTRL+SHIFT+S|Fullscreen → clipboard only
EOF

  render_section "System & Utilities" <<'EOF'
SUPER+SHIFT+Q|Kill focused window
SUPER+SHIFT+C|Reload Hypr config
SUPER+SHIFT+R|Restart Hyprland session
SUPER+SHIFT+E|Rofi power menu
SUPER+CTRL+L|Hyprlock video screensaver
SUPER+CTRL+SHIFT+L|Hyprlock screenshot fallback
SUPER+CTRL+ALT+L|Emergency lock helper
SUPER+SHIFT+W|Random wallpaper on focused monitor
SUPER+COMMA|Hypr quick menu (scripts)
EOF

  render_section "Workspace Modes" <<'EOF'
SUPER+R|Enter resize mode (H/J/K/L or arrows)
SUPER+SHIFT+G|Enter gaps mode (O inner / I outer)
Return or Escape|Exit current submap
EOF

  render_section "Media & Volume" <<'EOF'
XF86AudioRaiseVolume|Increase sink volume by 5%
XF86AudioLowerVolume|Decrease sink volume by 5%
XF86AudioMute|Toggle sink mute
XF86AudioMicMute|Toggle microphone mute
EOF

  print_footer
}

main() {
  tmp_file=$(mktemp)
  render_all >"$tmp_file"
  less -R -F -X "$tmp_file"
}

main "$@"
