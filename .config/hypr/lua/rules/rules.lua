-- Core window rules - Migrated from sway/i3 config
-- Adapted for laptop eDP-1 1920x1080

-- ============================================================
-- SUPPRESS MAXIMIZE FOR ALL WINDOWS
-- ============================================================
hl.window_rule({
  match = { class = ".*" },
  suppress_event = "maximize",
})

-- ============================================================
-- NO FOCUS FOR BLANK XWAYLAND FLOATING WINDOWS
-- ============================================================
hl.window_rule({
  match = {
    class = "^$",
    title = "^$",
    xwayland = 1,
    float = 1,
    fullscreen = 0,
    pin = 0,
  },
  no_focus = true,
})

-- ============================================================
-- TAG-BASED RULES
-- ============================================================
hl.window_rule({
  name = "core-tag-no-border",
  match = { tag = "+no-border" },
  border_size = 0,
})

hl.window_rule({
  name = "core-tag-media-opaque",
  match = { tag = "+media" },
  opaque = true,
})

hl.window_rule({
  name = "core-tag-password-manager-security",
  match = { tag = "+password-manager" },
  no_screen_share = true,
})

-- ============================================================
-- WORKSPACE ASSIGNMENTS (from i3/sway assign rules)
-- ============================================================
hl.window_rule({ name = "ws-1-browser", match = { class = "^(?i)(google-chrome|chromium|firefox|zen-alpha|zen-beta|zen|Navigator)$" }, workspace = 1 })
hl.window_rule({ name = "ws-1-browser-title", match = { title = "^(?i)(google-chrome|chromium|firefox|zen-alpha|zen-beta|zen|Navigator)$" }, workspace = 1 })

hl.window_rule({ name = "ws-2-terminal", match = { class = "^(?i)(xfce4-terminal|foot|footclient|footclient-float|kitty)$" }, workspace = 2 })
hl.window_rule({ name = "ws-2-terminal-title", match = { title = "^(?i)(xfce4-terminal|foot|footclient|footclient-float|kitty)$" }, workspace = 2 })

hl.window_rule({ name = "ws-3-files", match = { class = "^(?i)(nautilus|nemo|thunar)$" }, workspace = 3 })
hl.window_rule({ name = "ws-3-files-title", match = { title = "^(?i)(nautilus|nemo|thunar)$" }, workspace = 3 })

hl.window_rule({ name = "ws-4-editor", match = { class = "^(?i)(subl|code-oss|.*zed.*)$" }, workspace = 4 })
hl.window_rule({ name = "ws-4-editor-title", match = { title = "^(?i)(subl|code-oss|.*zed.*)$" }, workspace = 4 })

hl.window_rule({ name = "ws-5-web", match = { class = "^(?i)(brave-browser|brave-origin|Keepass)$" }, workspace = 5 })
hl.window_rule({ name = "ws-5-web-title", match = { title = "^(?i)(brave-browser|brave-origin|Keepass)$" }, workspace = 5 })
hl.window_rule({ name = "ws-5-spotify", match = { class = "^(?i)Spotify$" }, workspace = 5 })

hl.window_rule({ name = "ws-6-office", match = { class = "^(?i)(libreoffice.*|gimp)$" }, workspace = 6 })

hl.window_rule({ name = "ws-7-media", match = { class = "^(?i)(mpv|gpicview|zathura)$" }, workspace = 7 })

hl.window_rule({ name = "ws-9-comm", match = { class = "^(?i)(telegramdesktop|localsend)$" }, workspace = 9 })

hl.window_rule({ name = "ws-10-tools", match = { class = "^(?i)(obsidian|virt-manager|rustdesk|protonvpn)$" }, workspace = 10 })

-- Spotify from i3
hl.window_rule({ name = "ws-5-spotify-class", match = { class = "^(?i)Spotify$" }, workspace = 5 })
hl.window_rule({ name = "ws-5-spotify-title", match = { title = "^(?i)Spotify$" }, workspace = 5 })

-- ============================================================
-- FLOATING RULES
-- ============================================================
hl.window_rule({ name = "float-pavucontrol", match = { class = "^(?i)pavucontrol$" }, float = true })
hl.window_rule({ name = "float-qt5ct", match = { class = "^(?i)qt5ct$" }, float = true })
hl.window_rule({ name = "float-gsimplecal", match = { class = "^(?i)gsimplecal$" }, float = true })
hl.window_rule({ name = "float-file-roller", match = { class = "^(?i)file-roller$" }, float = true })
hl.window_rule({ name = "float-whatsie", match = { class = "^(?i)whatsie$" }, float = true })
hl.window_rule({ name = "float-steam", match = { class = "^(?i)steam$" }, float = true })
hl.window_rule({ name = "float-mpv", match = { class = "^(?i)mpv$" }, float = true })
hl.window_rule({ name = "float-virt-manager", match = { class = "^(?i)virt-manager$" }, float = true })
hl.window_rule({ name = "float-nautilus", match = { class = "^(?i)nautilus$" }, float = true })
hl.window_rule({ name = "float-nemo", match = { class = "^(?i)nemo$" }, float = true })
hl.window_rule({ name = "float-seahorse", match = { class = "^(?i)seahorse$" }, float = true })
hl.window_rule({ name = "float-protonvpn", match = { class = "^(?i)protonvpn$" }, float = true })
hl.window_rule({ name = "float-rustdesk", match = { class = "^(?i)rustdesk$" }, float = true })
hl.window_rule({ name = "float-localsend", match = { class = "^(?i)localsend$" }, float = true })
hl.window_rule({ name = "float-blueman", match = { class = "^(?i)blueman-manager$" }, float = true })
hl.window_rule({ name = "float-drawn-st", match = { class = "^(drawn-st)$" }, float = true })
hl.window_rule({ name = "float-st", match = { class = "^(st)$", title = "^(st)$" }, float = true })
hl.window_rule({ name = "float-floating-update", match = { class = "^(floating_update)$" }, float = true })
hl.window_rule({ name = "float-footclient-float", match = { class = "^(footclient-float.*)$" }, float = true, center = true })

-- Dialog / pop-up types
hl.window_rule({ name = "float-dialog-title", match = { title = "^(pop-up|task_dialog|bubble|dialog|menu|Preferences)$" }, float = true })
hl.window_rule({ name = "float-file-dialog", match = { title = "^(Open File|Save File|Save As|Open Document)$" }, float = true, center = true, border_size = 0 })
hl.window_rule({ name = "float-about", match = { title = "^(About ).*$" }, float = true })
hl.window_rule({ name = "float-file-progress", match = { class = "^(file_progress)$" }, float = true })
hl.window_rule({ name = "float-generic-dialog", match = { class = "^(.*-picker|.*-dialog|.*-preferences)$" }, float = true })
hl.window_rule({ name = "float-zenity", match = { class = "^(zenity)$" }, float = true })

-- eww
hl.window_rule({ name = "float-eww", match = { class = "^(eww-calendar)$" }, float = true, border_size = 0 })
hl.window_rule({ name = "float-eww-title", match = { class = "^(eww)$", title = "^(calendar)$" }, float = true, border_size = 0 })

-- Firefox pop-up
hl.window_rule({ name = "float-firefox-popup", match = { class = "^(?i)firefox$", title = "^(?i)(pop-up|dialog)$" }, float = true })

-- ============================================================
-- FLOAT + SIZE + CENTER (1920x1080 safe sizes)
-- ============================================================
hl.window_rule({ name = "size-blueman", match = { class = "^(?i)blueman-manager$" }, float = true, center = true, size = "600 680" })
hl.window_rule({ name = "size-nsxiv", match = { class = "^(?i)nsxiv$" }, float = true, center = true, size = "1200 700" })
hl.window_rule({ name = "size-qt5ct", match = { class = "^(?i)qt5ct$" }, float = true, center = true, size = "600 680" })
hl.window_rule({ name = "size-warmind-webapp", match = { class = "^(warmind\\.install\\.webapp)$" }, float = true, center = true, size = "646 486" })
hl.window_rule({ name = "size-warmind-tui", match = { class = "^(warmind\\.install\\.tui)$" }, float = true, center = true, size = "646 486" })
hl.window_rule({ name = "size-steam", match = { class = "^(?i)steam$" }, float = true, center = true, size = "960 640" })

-- Brave webapps - resized for 1920x1080
hl.window_rule({ name = "size-brave-sheets", match = { class = "^brave-sheets\\.google\\.com-Default$" }, float = true, center = true, size = "1200 900", border_size = 0 })
hl.window_rule({ name = "size-brave-docs", match = { class = "^brave-docs\\.google\\.com__-Default$" }, float = true, center = true, size = "1200 900", border_size = 0 })
hl.window_rule({ name = "size-brave-powerpoint", match = { class = "^(?i)(Brave-browser|Brave-origin)$", title = "^(?i)powerpoint\\.cloud\\.microsoft$" }, float = true, center = true, size = "1200 900", border_size = 0 })

-- Warmind windows - resized for 1920x1080
hl.window_rule({ name = "warmind-system-update", match = { title = "^(Warmind System Update)$" }, float = true, center = true, size = "1100 820" })
hl.window_rule({ name = "warmind-user-password", match = { title = "^(Warmind User Password)$" }, float = true, center = true, size = "900 520" })
hl.window_rule({ name = "warmind-install-package", match = { title = "^(Warmind Install Package)$" }, float = true, center = true, size = "1200 850" })
hl.window_rule({ name = "warmind-setup-terminal", match = { title = "^Warmind Setup: .*$" }, float = true, center = true, size = "1180 820" })
hl.window_rule({ name = "warmind-setup-bluetooth", match = { title = "^(Warmind Setup: Bluetooth)$" }, float = true, center = true, size = "860 720" })
hl.window_rule({ name = "warmind-setup-audio", match = { class = "^org\\.pulseaudio\\.pavucontrol$" }, float = true, center = true, size = "1100 760" })

-- Brave learning windows - resized for 1920x1080
hl.window_rule({ name = "warmind-learn-hyprland", match = { class = "^brave-wiki\\.hypr\\.land__-Default$" }, float = true, center = true, size = "1200 900", tag = "+chrome-webapp" })
hl.window_rule({ name = "warmind-learn-arch", match = { class = "^brave-wiki\\.archlinux\\.org__-Default$" }, float = true, center = true, size = "1200 900", tag = "+chrome-webapp" })
hl.window_rule({ name = "warmind-learn-quickshell", match = { class = "^brave-quickshell\\.outfoxxed\\.me__docs-Default$" }, float = true, center = true, size = "1200 900", tag = "+chrome-webapp" })

-- ============================================================
-- NO BORDER RULES
-- ============================================================
hl.window_rule({ name = "noborder-sublime", match = { class = "^(?i)(sublime_text|subl)$" }, border_size = 0 })
hl.window_rule({ name = "noborder-firefox", match = { class = "^(?i)(firefox|chrome|chromium|zen|Navigator)$" }, border_size = 0 })
hl.window_rule({ name = "noborder-discord", match = { class = "^(?i)discord$" }, border_size = 0 })
hl.window_rule({ name = "noborder-zathura", match = { class = "^(?i)zathura$" }, border_size = 0 })
hl.window_rule({ name = "noborder-gpicview", match = { class = "^(?i)gpicview$" }, border_size = 0 })
hl.window_rule({ name = "noborder-telegram", match = { class = "^(?i)telegramdesktop$" }, border_size = 0 })
hl.window_rule({ name = "noborder-drawn-st", match = { class = "^(drawn-st)$" }, border_size = 0 })
hl.window_rule({ name = "noborder-steam", match = { class = "^(?i)steam$" }, border_size = 0 })
hl.window_rule({ name = "noborder-zenity", match = { class = "^(zenity)$" }, border_size = 0 })
hl.window_rule({ name = "noborder-footclient-float", match = { class = "^(footclient-float.*)$" }, border_size = 0 })
hl.window_rule({ name = "noborder-st", match = { class = "^(st)$", title = "^(st)$" }, border_size = 0 })
hl.window_rule({ name = "noborder-floating-update", match = { class = "^(floating_update)$" }, border_size = 0 })

-- ============================================================
-- SPECIAL RULES
-- ============================================================
-- gsimplecal position at mouse
hl.window_rule({ name = "gsimplecal-pos", match = { class = "^(?i)gsimplecal$" }, float = true })

-- nemo preview
hl.window_rule({ name = "nemo-preview", match = { class = "^(?i)nemo-preview-start$" }, float = true, border_size = 4 })

-- pavucontrol scratchpad
hl.window_rule({ name = "pavucontrol-scratch", match = { class = "^(?i)pavucontrol$" }, workspace = "special" })

-- pidgin floating max (approximated)
hl.window_rule({ name = "pidgin-float", match = { class = "^(?i)pidgin$" }, float = true, size = "600 800" })

-- ============================================================
-- FOOTCLIENT SPECIAL SIZES
-- ============================================================
hl.window_rule({ name = "foot-cpu", match = { title = "^(CPU.*)$" }, size = "900 720" })
hl.window_rule({ name = "foot-weather", match = { title = "^(Weather.*)$" }, size = "774 600" })
hl.window_rule({ name = "foot-yay", match = { title = "^(yay.*)$" }, size = "800 760" })

-- ============================================================
-- WAYBAR MANAGER / WIDGET FLOATS
-- ============================================================
hl.window_rule({ name = "waybar-manager", match = { class = "^(waybar-manager)$" }, float = true, size = "800 600", center = true })
hl.window_rule({ name = "waybar-widgets", match = { class = "^(floating-waybar-(cpu|weather|pacman|calendar))$" }, float = true, center = true })

-- ============================================================
-- BRAVE INSTANCE-SPECIFIC RULES (from i3)
-- ============================================================
hl.window_rule({ name = "brave-gemini", match = { class = "^(?i)Brave-origin$", title = "^(?i).*gemini\\.google\\.com.*$" }, float = false })
hl.window_rule({ name = "brave-grok", match = { class = "^(?i)Brave-origin$", title = "^(?i).*grok\\.com.*$" }, float = false })
hl.window_rule({ name = "brave-word", match = { class = "^(?i)Brave-origin$", title = "^(?i).*word\\.cloud\\.microsoft.*$" }, float = false })
hl.window_rule({ name = "brave-chatgpt", match = { class = "^(?i)Brave-origin$", title = "^(?i).*chatgpt\\.com.*$" }, float = false })
hl.window_rule({ name = "brave-excel", match = { class = "^(?i)Brave-origin$", title = "^(?i).*excel\\.cloud\\.microsoft.*$" }, float = false })

-- Note: i3/sway "focus" directive has no direct equivalent in Hyprland Lua.
-- Comprobante windows will focus normally when clicked or activated.
