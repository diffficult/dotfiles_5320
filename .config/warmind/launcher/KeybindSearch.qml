import QtQuick
import Quickshell.Io

// Hyprland keybindings explorer. Triggered by a `bind ` query prefix
// in the omni-menu. Parses `hyprctl binds -j` once on first activation,
// then filters the cached list by the query text. The right-hand
// preview pane shows the matching binds as a scrollable RichText list.
//
// Enter is a no-op; the UX is read/search/scroll in the preview.
Item {
    id: keybindSearch

    required property string query
    required property bool active

    property var items: []
    property string previewText: ""
    property string filterText: ""
    property var allBinds: []
    property int _gen: 0

    readonly property bool running: probeProc.running

    function clear() {
        keybindSearch.items = [];
        keybindSearch.previewText = "";
        keybindSearch.filterText = "";
        keybindSearch._gen += 1;
        probeProc.running = false;
    }

    // Accept "bind" exactly (cold pivot) or "bind <filter>".
    function parseQuery(q) {
        if (q !== "bind" && q.substring(0, 5) !== "bind ") return null;
        return q.substring(4).trim();
    }

    // Decode Hyprland modmask to human-readable modifiers.
    //   1 = Shift, 4 = Ctrl, 8 = Alt, 64 = Super
    function modMaskName(mask) {
        const mods = [];
        if (mask & 64) mods.push("SUPER");
        if (mask & 8)  mods.push("ALT");
        if (mask & 4)  mods.push("CTRL");
        if (mask & 1)  mods.push("SHIFT");
        return mods.join("+");
    }

    // Human-readable description inferred from dispatcher + arg.
    // Falls back to the raw command when no pattern matches.
    function describeBind(dispatcher, arg) {
        const a = arg || "";
        const d = dispatcher || "";
        // Workspace navigation
        if (d === "workspace")       return "Switch to workspace " + a;
        if (d === "movetoworkspace") return "Move window to workspace " + a;
        if (d === "togglespecialworkspace") return "Toggle special workspace";
        // Window focus / movement
        if (d === "movefocus") {
            const dir = { l: "left", r: "right", u: "up", d: "down",
                          left: "left", right: "right", up: "up", down: "down" }[a] || a;
            return "Focus window " + dir;
        }
        if (d === "movewindow") {
            const dir = { l: "left", r: "right", u: "up", d: "down",
                          left: "left", right: "right", up: "up", down: "down" }[a] || a;
            return "Move window " + dir;
        }
        if (d === "resizeactive")    return "Resize window";
        if (d === "centerwindow")    return "Center window";
        if (d === "cyclenext")       return "Cycle windows";
        if (d === "killactive")      return "Close active window";
        if (d === "fullscreen")      return "Toggle fullscreen";
        if (d === "togglefloating")  return "Toggle floating";
        if (d === "pin")             return "Pin window";
        // Layout
        if (d === "layoutmsg")       return "Layout: " + a;
        // Mouse
        if (d === "mouse" && a === "mouse:272") return "Drag to move window";
        if (d === "mouse" && a === "mouse:273") return "Drag to resize window";
        if (d === "mouse")           return "Mouse action";
        // Submaps (legacy hyprlang + Lua manager)
        if (d === "submap") {
            if (a === "reset") return "Exit submap";
            if (a === "resize") return "Enter resize submap";
            if (a === "gaps" || a === "gaps_outer" || a === "gaps_inner") return "Enter gaps submap";
            return "Enter submap: " + a;
        }
        // Lua config manager callbacks (arg is often a numeric handle)
        if (d === "__lua")           return "Lua bind";
        // Exec commands — pattern-match the arg string
        if (d === "exec") {
            if (a.includes("tactile toggle"))         return "Toggle Tactile grid";
            if (a.includes("palette openCategory Emoji")) return "Open Emoji picker";
            if (a.includes("palette openCategory Pass"))    return "Open Password search";
            if (a.includes("palette openCategory"))   return "Open launcher category";
            if (a.includes("palette toggle"))         return "Open launcher";
            if (a.includes("expose-toggle"))          return "Toggle Expose overview";
            if (a.includes("hyprctl reload"))           return "Reload Hyprland config";
            if (a.includes("hyprctl keyword general:gaps_in") || a.includes("gaps_in")) return "Set inner gaps";
            if (a.includes("hyprctl keyword general:gaps_out") || a.includes("gaps_out")) return "Set outer gaps";
            if (a.includes("hyprctl keyword general:border_size") || a.includes("border_size")) return "Toggle borders";
            if (a.includes("warmind-hypr exit"))        return "Logout (Hyprland exit)";
            if (a.includes("warmind-hypr dpms-off"))    return "Blank displays";
            if (a.includes("warmind-hypr dpms-on") || a.includes("wlopm --on")) return "Wake displays";
            if (a.includes("warmind-audio-key.sh raise")) return "Raise volume";
            if (a.includes("warmind-audio-key.sh lower")) return "Lower volume";
            if (a.includes("warmind-audio-key.sh mute")) return "Toggle mute";
            if (a.includes("warmind-audio-key.sh mic-mute")) return "Toggle mic mute";
            if (a.includes("warmind-media-key.sh play-pause")) return "Play / Pause";
            if (a.includes("warmind-media-key.sh next")) return "Next track";
            if (a.includes("warmind-media-key.sh previous")) return "Previous track";
            if (a.includes("pkill -x waycal"))        return "Close calendar popup";
            if (a.includes("wpctl set-volume"))         return "Adjust volume";
            if (a.includes("wpctl set-mute"))           return "Toggle mute";
            if (a.includes("playerctl next"))          return "Next track";
            if (a.includes("playerctl previous"))        return "Previous track";
            if (a.includes("playerctl play-pause"))    return "Play / Pause";
            if (a.includes("nemo"))                     return "Open file manager";
            if (a.includes("kitty"))                    return "Open terminal (kitty)";
            if (a.includes("zen-browser"))              return "Open browser";
            if (a.includes("ncmpcpp"))                  return "Open music player";
            if (a.includes("rofi-bluetooth"))           return "Open Bluetooth menu";
            if (a.includes("rofi-power-menu"))          return "Open power menu";
            if (a.includes("hypr-menu"))                return "Open Hypr menu";
            if (a.includes("screenshot-notify.sh") && a.includes("fullscreen")) return "Screenshot fullscreen";
            if (a.includes("screenshot-notify.sh") && a.includes("region"))    return "Screenshot region";
            if (a.includes("aerial-hyprlock.sh"))        return "Lock screen";
            if (a.includes("emergency-lock.sh"))        return "Emergency lock";
            if (a.includes("lock-fallback.sh"))         return "Lock screen (fallback)";
            if (a.includes("calendar_daemon.py --prev")) return "Calendar previous month";
            if (a.includes("calendar_daemon.py --next")) return "Calendar next month";
            if (a.includes("calendar_daemon.py --init")) return "Calendar today";
            if (a.includes("enter-submap gaps"))        return "Enter gaps submap";
            if (a.includes("enter-submap resize"))       return "Enter resize submap";
            if (a.includes("show-cheatsheet.sh"))       return "Show keybinding cheatsheet";
            if (a.includes("screenrecord-menu.sh"))      return "Open screen recording menu";
            if (a.includes("voxtype record toggle"))    return "Toggle voice typing";
            if (a.includes("voxtype record cancel"))     return "Cancel voice typing";
            if (a.includes("skwd wall toggle"))          return "Toggle wallpaper";
            if (a.includes("footclient") && a.includes("clipse")) return "Open clipboard history";
            if (a.includes("footclient"))                return "Open terminal";
            if (a.includes("wlopm --off"))              return "Blank displays";
            if (a.includes("gtk-launch Grok"))           return "Open Grok";
            if (a.includes("clipse"))                    return "Open clipboard history";
            if (a.includes("clipboard-ripple"))         return "Clipboard ripple demo";
            // Generic exec fallback
            const base = a.split("/").pop().split(" ")[0];
            return "Run: " + base;
        }
        return d + (a ? " " + a : "");
    }

    // Turn one JSON bind into a display object.
    function formatBind(b) {
        const mod = keybindSearch.modMaskName(b.modmask || 0);
        const key = b.key || "";
        const combo = mod ? (mod + " + " + key) : key;
        const dispatcher = b.dispatcher || "";
        const arg = b.arg || "";
        const desc = keybindSearch.describeBind(dispatcher, arg);
        return { combo, dispatcher, arg, desc };
    }

    // Build RichText HTML for the preview pane.
    // One line per bind: combo + brief description.
    function buildPreview(binds, filter) {
        const f = filter.toLowerCase();
        const filtered = binds.filter(function(b) {
            if (!f) return true;
            return b.combo.toLowerCase().includes(f)
                || b.desc.toLowerCase().includes(f)
                || b.dispatcher.toLowerCase().includes(f)
                || b.arg.toLowerCase().includes(f);
        });

        if (filtered.length === 0)
            return "<i>No keybindings match</i>";

        const lines = [];
        const pal = keybindSearch.palette;
        const indigo = pal.indigo;
        const inkDeep = pal.inkDeep;
        const seal = pal.seal;

        for (let i = 0; i < filtered.length; i++) {
            const b = filtered[i];
            lines.push('<span style="color:' + indigo + '"><b>' + esc(b.combo) + '</b></span>'
                       + '<span style="color:' + inkDeep + '">  →  ' + esc(b.desc) + '</span>');
        }
        return lines.join("<br>");
    }

    function esc(s) {
        return s.replace(/&/g, "&amp;")
                .replace(/</g, "&lt;")
                .replace(/>/g, "&gt;");
    }

    // Recompute preview whenever the query changes while active.
    onQueryChanged: { if (keybindSearch.active) keybindSearch.refresh(); }

    onActiveChanged: {
        if (!keybindSearch.active) { keybindSearch.clear(); return; }
        // Load binds on first activation if we haven't yet.
        if (keybindSearch.allBinds.length === 0) {
            keybindSearch._gen += 1;
            probeProc.gen = keybindSearch._gen;
            probeProc.running = false;
            probeProc.running = true;
        } else {
            keybindSearch.refresh();
        }
    }

    function refresh() {
        const parsed = keybindSearch.parseQuery(keybindSearch.query);
        keybindSearch.filterText = parsed || "";
        keybindSearch.previewText = keybindSearch.buildPreview(
            keybindSearch.allBinds, keybindSearch.filterText);
        keybindSearch.items = [{
            title: "Keybindings",
            comment: keybindSearch.filterText || "all binds",
            keywords: "",
            category: "keybind",
            icon: "󰌌",
            rawCategory: true,
            isKeybind: true
        }];
    }

    // Expose the palette so the formatter can use live colours.
    property var palette: ({ ink: "#c0caf5", inkDeep: "#565f89",
                            indigo: "#7aa2f7", seal: "#a9b1d6" })

    Process {
        id: probeProc
        running: false
        command: ["hyprctl", "binds", "-j"]
        property int gen: 0
        stdout: StdioCollector {
            onStreamFinished: {
                if (probeProc.gen !== keybindSearch._gen) return;
                const text = this.text.trim();
                if (text.length === 0) {
                    keybindSearch.allBinds = [];
                    keybindSearch.previewText = "<i>Could not read binds</i>";
                    keybindSearch.refresh();
                    return;
                }
                try {
                    const data = JSON.parse(text);
                    const binds = [];
                    for (let i = 0; i < data.length; i++) {
                        binds.push(keybindSearch.formatBind(data[i]));
                    }
                    keybindSearch.allBinds = binds;
                    keybindSearch.refresh();
                } catch (e) {
                    keybindSearch.allBinds = [];
                    keybindSearch.previewText = "<i>Error parsing binds</i>";
                    keybindSearch.refresh();
                }
            }
        }
    }
}
