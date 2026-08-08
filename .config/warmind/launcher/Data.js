.pragma library

// Sentinel values for the search/state drills.
const fileCategory = "Files";
const ghCategory = "GitHub";
const favCategory = "Favourites";
const histCategory = "History";
const procCategory = "Processes";
const themeCategory = "Themes";
const clipboardCategory = "Clipboard";

// fd already respects .gitignore, the global ignore file, and skips
// hidden files by default. These excludes catch build dirs that
// aren't always gitignored.
const fdExcludes = [
    "node_modules", "target", "dist", "build", ".cache",
    ".venv", "__pycache__", ".tox", ".next", ".nuxt"
];

const imageExts = [
    "png", "jpg", "jpeg", "webp", "gif", "bmp", "ico", "avif", "svg"
];

const textExts = [
    "md", "txt", "qml", "lua", "toml", "sh", "bash", "zsh", "fish",
    "py", "js", "mjs", "cjs", "ts", "tsx", "jsx", "json", "jsonc",
    "yaml", "yml", "rs", "go", "c", "h", "cpp", "hpp", "cc", "hh",
    "html", "css", "scss", "conf", "ini", "cfg", "log", "csv", "xml",
    "rb", "java", "kt", "swift", "php", "sql", "vim", "el", "tex",
    "gitignore", "gitconfig", "dockerfile", "makefile", "env"
];

const fileIcons = {
    "png": "󰋩", "jpg": "󰋩", "jpeg": "󰋩", "webp": "󰋩", "gif": "󰋩",
    "bmp": "󰋩", "ico": "󰋩", "avif": "󰋩", "svg": "󰜡", "tiff": "󰋩",
    "mp4": "󰕧", "mkv": "󰕧", "webm": "󰕧", "mov": "󰕧", "avi": "󰕧",
    "m4v": "󰕧", "flv": "󰕧",
    "mp3": "󰝚", "flac": "󰝚", "ogg": "󰝚", "wav": "󰝚", "m4a": "󰝚",
    "opus": "󰝚", "aac": "󰝚",
    "pdf": "󰈦", "epub": "󰂺", "djvu": "󰈦",
    "doc": "󰈬", "docx": "󰈬", "odt": "󰈬", "rtf": "󰈬",
    "xls": "󰈛", "xlsx": "󰈛", "ods": "󰈛",
    "ppt": "󰈧", "pptx": "󰈧", "odp": "󰈧",
    "zip": "󰗄", "tar": "󰗄", "gz": "󰗄", "xz": "󰗄", "bz2": "󰗄",
    "7z": "󰗄", "rar": "󰗄", "zst": "󰗄",
    "md": "󰍔", "txt": "󰈙", "log": "󰦪", "csv": "󰈛",
    "json": "󰘦", "jsonc": "󰘦", "yaml": "󰈙", "yml": "󰈙",
    "toml": "󰈙", "xml": "󰗀", "ini": "󰒓", "cfg": "󰒓",
    "conf": "󰒓", "env": "󰒓",
    "sh": "󱆃", "bash": "󱆃", "zsh": "󱆃", "fish": "󰈺",
    "lua": "󰢱", "vim": "",
    "html": "󰌝", "css": "󰌜", "scss": "󰌜", "sass": "󰌜",
    "py": "󰌠", "js": "󰌞", "mjs": "󰌞", "cjs": "󰌞",
    "ts": "󰛦", "tsx": "󰜈", "jsx": "󰜈",
    "rs": "󱘗", "go": "󰟓", "java": "󰬷", "kt": "󱈙",
    "swift": "󰛥", "rb": "󰴭", "php": "󰌟",
    "c": "󰙱", "h": "󰙱", "cpp": "󰙲", "hpp": "󰙲", "cc": "󰙲", "hh": "󰙲",
    "qml": "󰢫", "sql": "󰆼", "el": "", "tex": "",
    // Dotless filenames: fileExt() returns the whole lowercased name.
    "gitignore": "", "gitconfig": "",
    "dockerfile": "󰡨", "makefile": "󰣪"
};

// Synthetic rows at root level. Activating one sets the categoryFilter
// instead of executing a command. `target` matches against item.category;
// "App" is the bucket all .desktop entries land in. fileCategory and
// ghCategory route to their respective search drills.
const categoryNav = [
    { title: "Quick",   icon: "󱎫", category: "Browse", isCategory: true, target: "Quick",       keywords: "quick settings panel tray toggle popup weather screenshots videos brightness volume mute" },
    { title: "Apps",    icon: "󰀻", category: "Browse", isCategory: true, target: "App",         keywords: "apps applications launcher programs software desktop" },
    { title: "Files",   icon: "󰉋", category: "Browse", isCategory: true, target: fileCategory,  keywords: "files file search find folder browse path open image picture document text fd" },
    { title: "GitHub",  icon: "󰊤", category: "Browse", isCategory: true, target: ghCategory,    keywords: "github gh repo repository search code clone star issue pull request pr open source git" },
    { title: "History", icon: "󰋚", category: "Browse", isCategory: true, target: histCategory,    keywords: "history recent recents log past activity used opened" },
    { title: "Clipboard", icon: "󰅌", category: "Browse", isCategory: true, target: clipboardCategory, keywords: "clipboard clipse copy paste history recent text snippet selection wl-copy" },
    // { title: "Style",   icon: "󰏘", category: "Browse", isCategory: true, target: "Style",       keywords: "style theme appearance look font background corners waybar screensaver" },
    { title: "Setup",   icon: "󰒓", category: "Browse", isCategory: true, target: "Setup",       keywords: "setup config audio wifi bluetooth power monitors keybindings defaults dns security" },
    { title: "Install Package", icon: "󰣇", category: "Browse", keywords: "install add package aur yay fzf offline arch repo software", exec: "~/.config/warmind/launcher/bin/install-package-launcher.sh" },
    { title: "Update",  icon: "󰚰", category: "Browse", isCategory: true, target: "Update",      keywords: "update upgrade omarchy channel themes process hardware firmware password timezone time" },
    { title: "System",  icon: "󰐥", category: "Browse", isCategory: true, target: "System",      keywords: "system lock suspend hibernate logout restart reboot shutdown power" },
    // { title: "Toggle",  icon: "󰨚", category: "Browse", isCategory: true, target: "Toggle",      keywords: "toggle screensaver nightlight idle notifications bar layout gaps scaling sudo touchpad" },
    { title: "Capture", icon: "󰄀", category: "Browse", isCategory: true, target: "Capture",     keywords: "capture screenshot screenrecord ocr text extraction color picker" },
        { title: "Cams",    icon: "󰄄", category: "Browse", isCategory: true, target: "Cams",      keywords: "cameras cams nvr security monitor feeds rtsp surveillance video" },
    { title: "Learn",   icon: "󰂺", category: "Browse", isCategory: true, target: "Learn",       keywords: "learn docs manual help keybindings wiki cheatsheet" },
    { title: "Usage",   icon: "󰥔", category: "Browse", isCategory: true, target: "Usage",       keywords: "usage tokens credits billing ai llm models opencode grok openai chatgpt codex anthropic claude quota cost stats" },
    { title: "Processes", icon: "󰍛", category: "Browse", isCategory: true, target: procCategory,  keywords: "processes process kill task manager ps top htop activity cpu memory" },
    // { title: "Themes",    icon: "󰸌", category: "Browse", isCategory: true, target: themeCategory, keywords: "themes theme palette color swatch switcher dark light apply" },
    // Stage 2 — new search modes
    { title: "Windows",        icon: "󱂬", category: "Browse", isCategory: true, target: "Windows", keywords: "window switch focus open running apps hyprland" },
    { title: "Emoji & Symbols",icon: "󰞅", category: "Browse", isCategory: true, target: "Emoji",   keywords: "emoji symbol nerd font icon character unicode glyph picker copy" },
    { title: "Passwords",      icon: "", category: "Browse", isCategory: true, target: "Pass",    keywords: "pass password secret credential login autotype wtype store" }
];

// Leaf actions — all commands must work without omarchy-* tools.
// `exec` is run verbatim via zsh -c.
const omarchyItems = [
    // ----- Quick -----
    // Quick popups currently kept visible in launcher rows.
    // Display is extracted/protected again but remains hidden by default
    // until a laptop-oriented exposure strategy is chosen.
    // { title: "Display",           icon: "󰍹", category: "Quick", keywords: "display monitor warmth gamma night light temperature dim screen",                    exec: "qs -c $HOME/.config/warmind/launcher ipc call display toggle" },
    { title: "Weather",           icon: "󰖐", category: "Quick", keywords: "weather forecast temperature wttr rain sun wind humidity uv sunrise sunset outdoor",  exec: "qs -c $HOME/.config/warmind/launcher ipc call weather toggle" },
    { title: "Calendar",          icon: "󰃭", category: "Quick", keywords: "calendar date month day today schedule planner agenda holidays google events",        exec: "qs -c $HOME/.config/warmind/launcher ipc call calendar toggle" },
    { title: "Screenshots",       icon: "󰄀", category: "Quick", keywords: "screenshots shots browse pictures captures images recent gallery",                     exec: "qs -c $HOME/.config/warmind/launcher ipc call screenshots toggle" },
    { title: "Videos",            icon: "󰟞", category: "Quick", keywords: "videos films clips recordings recent browse gallery library",                         exec: "qs -c $HOME/.config/warmind/launcher ipc call videos toggle" },
    { title: "Clipboard History", icon: "󰅌", category: "Action", keywords: "clipboard clipse history copy paste text image file recent",                       exec: "qs -c $HOME/.config/warmind/launcher ipc call clipboard open" },
    { title: "Reminder",          icon: "󰚥", category: "Action", keywords: "reminder alarm timer notify notification later minutes",                           exec: "qs -c $HOME/.config/warmind/launcher ipc call reminder open" },
    { title: "Mute Audio",        icon: "󰝟", category: "Quick", keywords: "mute audio unmute silence toggle volume sound speaker quick",                         exec: "wpctl set-mute @DEFAULT_SINK@ toggle" },
    { title: "Refresh Weather",   icon: "󰜉", category: "Quick", keywords: "weather refresh reload update wttr fetch",                                             exec: "qs -c $HOME/.config/warmind/launcher ipc call weather refresh" },
    { title: "Audio",             icon: "󰕾", category: "Action", keywords: "audio mixer pipewire pulse volume sink source microphone input device level",          exec: "qs -c $HOME/.config/warmind/launcher ipc call audio open" },
    { title: "Bluetooth",         icon: "󰂯", category: "Action", keywords: "bluetooth bt pair device headset speaker keyboard mouse scan connect",                      exec: "qs -c $HOME/.config/warmind/launcher ipc call bluetooth open" },
    { title: "Network",           icon: "󰖩", category: "Action", keywords: "network wifi wireless ethernet internet ssid signal scan connect",                          exec: "qs -c $HOME/.config/warmind/launcher ipc call network open" },
    { title: "Power",             icon: "󰁹", category: "Action", keywords: "power battery charge profile saver performance balanced laptop watts",                     exec: "qs -c $HOME/.config/warmind/launcher ipc call power open" },
    { title: "Dropbox",           icon: "󰇣", category: "Action", keywords: "dropbox cloud sync files folder storage",                                                   exec: "qs -c $HOME/.config/warmind/launcher ipc call dropbox open" },
    { title: "System Monitor",    icon: "󰍛", category: "Quick", keywords: "cpu memory process monitor btop top htop performance load activity",                  exec: "~/.config/warmind/launcher/bin/setup-terminal-launcher.sh 'Quick: System Monitor' btop" },

    // ----- Usage -----
    // AI/account usage panels. Future: Claude, etc.
    { title: "OpenCode Usage",    icon: "󰚩", category: "Usage", keywords: "opencode usage tokens models ai llm sessions stats anthropic openai claude",              exec: "qs -c $HOME/.config/warmind/launcher ipc call opencode-usage open" },
    { title: "Grok Usage",        icon: "󰚩", category: "Usage", keywords: "grok usage credits billing xai build account period weekly quota cost",                   exec: "qs -c $HOME/.config/warmind/launcher ipc call grok-usage open" },
    { title: "Codex Usage",       icon: "󰚩", category: "Usage", keywords: "codex usage openai chatgpt tokens rate limit daily weekly plan plus pro quota credits",   exec: "qs -c $HOME/.config/warmind/launcher ipc call codex-usage open" },

    // ----- Style -----
    { title: "Round Corners",    icon: "󰘇", category: "Style", keywords: "corners radius round soft rounded border edge shape popup",        exec: "qs -c $HOME/.config/warmind/launcher ipc call corners round" },
    { title: "Sharp Corners",    icon: "󰝣", category: "Style", keywords: "corners radius sharp square hard flat border edge shape popup",       exec: "qs -c $HOME/.config/warmind/launcher ipc call corners sharp" },
    { title: "Edit Waybar",      icon: "󰍜", category: "Style", keywords: "waybar config edit style modules bar",                                exec: "~/.config/warmind/launcher/bin/setup-editor-launcher.sh 'Style: Waybar Config' ~/.config/waybar/config.jsonc" },
    { title: "Edit Hyprland",    icon: "󰕮", category: "Style", keywords: "hyprland config edit window manager compositor border gaps lua",      exec: "~/.config/warmind/launcher/bin/setup-editor-launcher.sh 'Style: Hyprland Config' ~/.config/hypr/hyprland.lua" },

    // ----- Setup -----
    // { title: "Audio",             icon: "󰕾", category: "Setup", keywords: "audio sound speaker mixer pulse pipewire volume output input device pulsemixer", exec: "~/.config/warmind/launcher/bin/setup-terminal-launcher.sh 'Warmind Setup: Audio' pulsemixer" },
    // { title: "Wi-Fi",             icon: "󰖩", category: "Setup", keywords: "wifi wireless network internet nmcli connection",                                  exec: "~/.config/warmind/launcher/bin/setup-terminal-launcher.sh 'Warmind Setup: Wi-Fi' nmtui" },
    { title: "Bluetooth Power",   icon: "󰂯", category: "Setup", keywords: "bluetooth bt power on off toggle rfkill device headset speaker keyboard mouse",      exec: "~/.config/warmind/launcher/bin/bluetooth-power-toggle.sh" },
    { title: "Hyprland Config",   icon: "󰢨", category: "Setup", keywords: "hyprland config compositor window manager edit settings lua",                     exec: "~/.config/warmind/launcher/bin/setup-editor-launcher.sh 'Warmind Setup: Hyprland Config' ~/.config/hypr/hyprland.lua" },
    { title: "Hypridle Config",   icon: "󱎫", category: "Setup", keywords: "hypridle idle timeout lock screen blank afk",                                     exec: "~/.config/warmind/launcher/bin/setup-editor-launcher.sh 'Warmind Setup: Hypridle Config' ~/.config/hypr/hypridle.conf" },
    { title: "Hyprlock Config",   icon: "󰌾", category: "Setup", keywords: "hyprlock lock screen password security",                                          exec: "~/.config/warmind/launcher/bin/setup-editor-launcher.sh 'Warmind Setup: Hyprlock Config' ~/.config/hypr/hyprlock.conf" },
    { title: "Keybindings",       icon: "󰌌", category: "Setup", keywords: "keybindings shortcuts hotkeys keymap bindings input hypr lua",                   exec: "~/.config/warmind/launcher/bin/setup-editor-launcher.sh 'Warmind Setup: Keybindings' ~/.config/hypr/lua/core/keybindings.lua" },
    { title: "Waybar Config",     icon: "󰍜", category: "Setup", keywords: "waybar status bar config modules",                                                exec: "~/.config/warmind/launcher/bin/setup-editor-launcher.sh 'Warmind Setup: Waybar Config' ~/.config/waybar/config.jsonc" },
    { title: "Color Scheme",      icon: "󰸌", category: "Setup", isCategory: true, target: "ColorScheme", keywords: "color scheme theme palette accent tokyonight catppuccin live persistent" },
    { title: "Launcher Icons",    icon: "󰥻", category: "Setup", isCategory: true, target: "LauncherIcons", keywords: "launcher icons glyphs size preview toggle hide appearance live" },

    // ----- Install -----

    // ----- Remove -----
    { title: "Remove Package",   icon: "󰆴", category: "Remove",  keywords: "remove uninstall package pacman arch delete",                        exec: "~/.config/warmind/launcher/bin/setup-terminal-launcher.sh 'Remove Package' sudo pacman -Rns" },

    // ----- Update -----
    { title: "System Update",    icon: "󰦗", category: "Update",  keywords: "update upgrade system packages arch yay aur",                      exec: "~/.config/warmind/launcher/bin/system-update-launcher.sh" },
    // { title: "Update Firmware",  icon: "󰍛", category: "Update",  keywords: "firmware bios uefi fwupd update flash",                               exec: "foot -e sudo fwupdmgr update" },
    { title: "User Password",    icon: "󰷛", category: "Update",  keywords: "user password passwd security login change",                            exec: "~/.config/warmind/launcher/bin/user-password-launcher.sh" },
    { title: "Restart Audio",    icon: "󰜉", category: "Update",  keywords: "restart audio pipewire pipewire-pulse wireplumber pulse sound reload service", exec: "systemctl --user restart pipewire pipewire-pulse wireplumber" },
    { title: "Restart Waybar",   icon: "󰍜", category: "Update",  keywords: "restart waybar bar service reload",                                   exec: "pkill waybar; uwsm app -- waybar" },

    // ----- System -----
    { title: "Lock Screen",      icon: "󰌾", category: "System", keywords: "lock screen security hyprlock aerial video screensaver password", exec: "~/.local/bin/hypr_scripts/aerial-hyprlock.sh" },
    { title: "Logout",           icon: "󰍃", category: "System", keywords: "logout signout exit session end uwsm",                              exec: "uwsm stop", flushBookmarks: true },
    { title: "Restart",          icon: "󰜉", category: "System", keywords: "restart reboot reset power cycle",                                  exec: "systemctl reboot", flushBookmarks: true },
    { title: "Shutdown",         icon: "󰐥", category: "System", keywords: "shutdown poweroff off halt turn off",                               exec: "systemctl poweroff", flushBookmarks: true },

    // ----- Toggle -----
    { title: "Toggle Waybar",        icon: "󰍜", category: "Toggle", keywords: "toggle waybar top bar show hide visibility",                        exec: "pkill -SIGUSR1 waybar || uwsm app -- waybar" },
    { title: "Waybar Manager",       icon: "󰙨", category: "Toggle", keywords: "waybar manager tui config modules positions bar settings footclient",   exec: "footclient -a waybar-manager -T \"Waybar Manager\" $HOME/.local/bin/waybar_manager" },
    { title: "Toggle Notifications", icon: "󰂛", category: "Toggle", keywords: "toggle notifications silence mute dnd swaync",                       exec: "swaync-client -t" },

    // ----- Capture -----
    { title: "Screenshot Region",        icon: "󰄀", category: "Capture", keywords: "screenshot region area selection file clipboard grab snip",      exec: "~/.local/bin/hypr_scripts/screenshot-notify.sh region file-clipboard" },
    { title: "Screenshot Region Copy",   icon: "󰆒", category: "Capture", keywords: "screenshot region area selection clipboard copy grab snip",          exec: "~/.local/bin/hypr_scripts/screenshot-notify.sh region clipboard" },
    { title: "Screenshot Fullscreen",    icon: "󰹑", category: "Capture", keywords: "screenshot fullscreen full screen file clipboard capture image png", exec: "~/.local/bin/hypr_scripts/screenshot-notify.sh fullscreen file-clipboard" },
    { title: "Screenshot Fullscreen Copy", icon: "󰅍", category: "Capture", keywords: "screenshot fullscreen full screen clipboard copy capture",         exec: "~/.local/bin/hypr_scripts/screenshot-notify.sh fullscreen clipboard" },
    { title: "Color Picker",             icon: "󰃉", category: "Capture", keywords: "color picker hex rgb hyprpicker dropper sample eyedropper",         exec: "zsh -c 'pkill hyprpicker || hyprpicker -a'" },

    // ----- Learn -----
    { title: "Hyprland Wiki",  icon: "󱁉", category: "Learn", keywords: "hyprland wiki docs documentation help webapp brave",        exec: "$HOME/dev/mygits/warmind_helpers/bin/warmind-launch-webapp --browser=brave 'https://wiki.hypr.land/'" },
    { title: "Arch Wiki",      icon: "󰣇", category: "Learn", keywords: "arch wiki docs documentation help linux webapp brave",       exec: "$HOME/dev/mygits/warmind_helpers/bin/warmind-launch-webapp --browser=brave 'https://wiki.archlinux.org/'" },
    { title: "Quickshell Docs",icon: "󰢫", category: "Learn", keywords: "quickshell qml docs documentation api webapp brave",         exec: "$HOME/dev/mygits/warmind_helpers/bin/warmind-launch-webapp --browser=brave 'https://quickshell.outfoxxed.me/docs/'" }
];

// Pre-lowercases `title`/`keywords`/`category` onto `_t`/`_k`/`_c` so the
// per-keystroke scoring loop doesn't re-lowercase the same strings on
// every character.
function annotate(items) {
    const out = new Array(items.length);
    for (let i = 0; i < items.length; i++) {
        const it = items[i];
        out[i] = Object.assign({}, it, {
            _t: (it.title || "").toLowerCase(),
            _k: (it.keywords || "").toLowerCase(),
            _c: (it.category || "").toLowerCase()
        });
    }
    return out;
}

function basename(p) {
    const s = p.lastIndexOf("/");
    return s >= 0 ? p.substring(s + 1) : p;
}
function dirname(p) {
    const s = p.lastIndexOf("/");
    return s >= 0 ? p.substring(0, s) : "";
}
function tildify(p, homeDir) {
    return (homeDir && p.indexOf(homeDir) === 0)
        ? "~" + p.substring(homeDir.length)
        : p;
}
function fileExt(path) {
    const name = basename(path);
    const dot = name.lastIndexOf(".");
    if (dot <= 0) return name.toLowerCase(); // dotless name (Makefile)
    return name.substring(dot + 1).toLowerCase();
}
function fileIcon(path) {
    return fileIcons[fileExt(path)] || "";
}
function openUrl(url) {
    return "xdg-open " + JSON.stringify(url);
}
function formatStars(n) {
    if (n >= 1000000) return (n / 1000000).toFixed(1) + "m";
    if (n >= 1000)    return (n / 1000).toFixed(1) + "k";
    return "" + n;
}

// Stable identity per item — path wins (files, repos, PRs), exec next
// (apps, omarchy actions), title+category last (synthetic rows).
function itemKey(item) {
    if (!item) return "";
    return item.path || item.exec || (item.title + "|" + item.category);
}
