import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris

// Omarchy top bar. Owns the per-bar state, probes, and IPC; per-feature
// surfaces (Bar, *Popup, TooltipOverlay) and widgets (Module, Workspace,
// Bloom, …) read from `root` via `root: root` injection. Palette comes
// from the shared Theme; colours are re-exposed on root so sibling files
// keep their `root.paper` bindings.
Item {
    id: root

    required property var theme

    readonly property color paper:   theme.paper
    readonly property color ink:     theme.ink
    readonly property color inkDeep: theme.inkDeep
    readonly property color sumi:    theme.inkDeep
    readonly property color indigo:  theme.indigo
    readonly property color seal:    theme.seal
    readonly property color bg:      theme.bg
    readonly property color fg:      theme.fg
    readonly property color muted:   theme.muted
    readonly property color accent:  theme.accent
    readonly property color warn:    theme.warn
    readonly property color sep:     theme.sep
    readonly property color rowHi:   theme.rowHi
    readonly property color rowSel:  theme.rowSel

    readonly property string serif: theme.serif
    readonly property string mono:  theme.mono

    readonly property int  cornerRadius: theme.cornerRadius
    readonly property bool round:        theme.round

    // Wired in desktop/shell.qml to the sibling OmniMenu's toggle().
    signal paletteToggleRequested()

    // Kanji numerals 〇 一 二 ... 十.
    readonly property var kanjiNum: ["〇","一","二","三","四","五","六","七","八","九","十"]
    function indexKanji(n) { return n >= 0 && n <= 10 ? kanjiNum[n] : String(n); }

    // BMP Private Use Area icons; written via fromCodePoint so the source
    // stays ASCII-safe.
    readonly property string icoOmarchy: String.fromCodePoint(0xe900)
    readonly property string icoBtOn:    String.fromCodePoint(0xf294)
    readonly property string icoVol1:    String.fromCodePoint(0xf026)
    readonly property string icoVol2:    String.fromCodePoint(0xf027)
    readonly property string icoVol3:    String.fromCodePoint(0xf028)
    readonly property string icoMute:    String.fromCodePoint(0xeee8)
    readonly property string icoCamera:  String.fromCodePoint(0xf0100)
    readonly property string icoRefresh: String.fromCodePoint(0xf0450)
    readonly property string icoDisplay: String.fromCodePoint(0xf0379)
    readonly property string icoPower:   String.fromCodePoint(0xf0425)
    readonly property string icoFilm:    String.fromCodePoint(0xf0231)
    readonly property string icoSearch:  String.fromCodePoint(0xf0349)
    readonly property string icoUpdate:  String.fromCodePoint(0xf021)
    readonly property string icoPlug:    String.fromCodePoint(0xf06a5)
    readonly property string icoMusic:   String.fromCodePoint(0xf001)
    readonly property string icoPause:   String.fromCodePoint(0xf04c)

    readonly property int barHeight: 26

    // ---------- Edge ----------
    // Drives bar anchors, internal Row/Column flow, and where the toggle
    // arrow points.
    property string barEdge: "top"
    readonly property bool isHorizontal: barEdge === "top" || barEdge === "bottom"

    function cycleBarEdge() {
        const edges = ["top", "right", "bottom", "left"];
        root.barEdge = edges[(edges.indexOf(root.barEdge) + 1) % 4];
    }

    function edgeArrow() {
        return ({top: "↑", right: "→", bottom: "↓", left: "←"})[root.barEdge] || "?";
    }

    // ---------- Bar variant ----------
    // Which bar face is rendered. "zen" is the original 静 minimalist bar;
    // "hackerman" is the tactical/terminal readout (Mr. Robot / Jack Ryan
    // veins). Both surfaces are always instantiated below and gate on this
    // string via `visible`; an unmapped layer-surface reserves no exclusive
    // zone, so exactly one bar owns the edge at a time.
    //
    // Persisted to its own one-line state file (same scheme as Theme's
    // corner toggle) so the choice survives a relogin. Read once at startup
    // via cat — a FileView's initial load races property assignment in some
    // Quickshell builds and can clobber the value back to the default.
    readonly property var barVariants: ["zen", "hackerman"]
    readonly property string barVariantStatePath:
        Quickshell.env("HOME") + "/.local/state/quickshell-desktop/bar-variant"
    property string barVariant: "zen"

    function setBarVariant(name) {
        const want = root.barVariants.indexOf(name) !== -1 ? name : "zen";
        root.barVariant = want;
        barVariantWriter.command = ["zsh", "-c",
            "mkdir -p " + JSON.stringify(root.barVariantStatePath.replace(/\/[^/]+$/, ""))
            + " && printf '%s' " + JSON.stringify(want)
            + " > " + JSON.stringify(root.barVariantStatePath)];
        barVariantWriter.running = false;
        barVariantWriter.running = true;
    }
    function cycleBarVariant() {
        const i = root.barVariants.indexOf(root.barVariant);
        root.setBarVariant(root.barVariants[(i + 1) % root.barVariants.length]);
    }

    Process { id: barVariantWriter; running: false }
    Process {
        id: barVariantReader
        running: true
        command: ["cat", root.barVariantStatePath]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = this.text.trim();
                if (root.barVariants.indexOf(v) !== -1) root.barVariant = v;
            }
        }
        // Missing file -> keep the "zen" default.
        onExited: function(code) { if (code !== 0) root.barVariant = "zen"; }
    }

    // ---------- Tooltips ----------
    // A single overlay panel reads these and renders the label near the
    // hovered icon. Positions are bar-window-local; the overlay translates
    // them into its own (full-screen) coordinate space based on barEdge.
    property string tooltipText: ""
    property real   tooltipBarX: 0
    property real   tooltipBarY: 0
    property bool   tooltipShown: false

    function showTooltip(text, x, y) {
        if (!text) return;
        root.tooltipText  = text;
        root.tooltipBarX  = x;
        root.tooltipBarY  = y;
        root.tooltipShown = true;
    }

    function hideTooltip(text) {
        // Guard against a late-fired hide from a module the cursor has
        // already left for another tooltip-bearing module.
        if (!text || root.tooltipText === text) root.tooltipShown = false;
    }

    // ---------- Popup anchor ----------
    // Bar-window-local coordinates, the same coordinate space the tooltip
    // overlay consumes — both surfaces are full-edge PanelWindows so the
    // bar-local point translates 1:1.
    property real popupAnchorX: 0
    property real popupAnchorY: 0

    // Weather can still anchor from a dedicated bar item when a specific
    // trigger surface wants to hand the controller an explicit origin.
    property Item weatherAnchorItem: null

    function anchorPopupTo(item) {
        const p = item.mapToItem(null, item.width / 2, item.height / 2);
        root.popupAnchorX = p.x;
        root.popupAnchorY = p.y;
    }

    // ---------- State ----------
    property int activeWs: 1
    property var existingWs: [1, 2, 3, 4, 5]
    // +1 = user navigated to a higher-numbered workspace (rightward along
    // the bar), -1 = lower-numbered (leftward), 0 = no recent travel. The
    // active Workspace cell reads this to bias its kanji's entry offset.
    property int lastDirection: 0

    property int cpuVal: 0
    property int memVal: 0
    property int batVal: 0
    property string batState: "Unknown"
    // Instantaneous power draw in watts; magnitude only — direction is in batState.
    property real batPower: 0

    property string netIcon: "󰤯"
    property string netKind: "none"   // "eth" | "wifi" | "none"
    property string wifiSsid: ""
    property int    wifiSignal: 0

    WifiController {
        id: wifiController
    }
    property var wifi: wifiController

    BluetoothController {
        id: btController
    }
    property var bluetooth: btController

    AudioController {
        id: audioController
        host: root
    }
    property var audio: audioController
    property alias audioIcon: audioController.audioIcon
    property alias audioVol: audioController.audioVol
    property alias audioMuted: audioController.audioMuted

    PowerController {
        id: powerController
        host: root
    }
    property var power: powerController

    OsdController {
        id: osdController
    }
    property var osd: osdController


    property string hh: "--"
    property string mm: "--"
    property string dd: "--"
    property string mon: "---"

    ScreenshotsController {
        id: screenshotsController
    }
    property var screenshots: screenshotsController

    ClipboardController {
        id: clipboardController
    }
    property var clipboard: clipboardController

    VideosController {
        id: videosController
    }
    property var videos: videosController

    WeatherController {
        id: weatherController
        host: root
    }
    property var weather: weatherController

    CalendarController {
        id: calendarController
        host: root
    }
    property var calendar: calendarController

    DisplayController {
        id: displayController
        host: root
    }
    property var display: displayController

    ReminderController {
        id: reminderController
    }
    property var reminder: reminderController

    DropboxController {
        id: dropboxController
    }
    property var dropbox: dropboxController

    OpencodeUsageController {
        id: opencodeUsageController
    }
    property var opencodeUsage: opencodeUsageController

    GrokUsageController {
        id: grokUsageController
    }
    property var grokUsage: grokUsageController

    CodexUsageController {
        id: codexUsageController
    }
    property var codexUsage: codexUsageController

    TactileController {
        id: tactile
    }

    CamsController {
        id: camsController
    }
    property var cams: camsController

    // ---------- Weather controller ----------
    // Weather now lives in WeatherController.qml. It fetches wttr.in JSON,
    // backs both the popup and the quick tile summary, refreshes every
    // 30 minutes, and reads the optional manual location from:
    //   ~/.config/quickshell/weather-location
    // Empty/missing file falls back to wttr.in IP geolocation.
    // Wi-Fi signal-bars glyph from a 0-100% strength reading. Same ramp
    // the netProbe uses to drive the bar icon — shared so the Quick
    // panel rows render identical iconography.
    readonly property var _wifiBarsRamp: ["󰤯","󰤟","󰤢","󰤥","󰤨"]
    function wifiBarsGlyph(pct) {
        const idx = pct >= 80 ? 4 : pct >= 60 ? 3 : pct >= 40 ? 2 : pct >= 20 ? 1 : 0;
        return _wifiBarsRamp[idx];
    }

    // ---------- Generic launcher ----------
    Process { id: runner; running: false }
    function run(cmd) {
        runner.command = ["zsh", "-c", cmd];
        runner.running = false;
        runner.running = true;
    }

    // ---------- Telemetry (1 Hz) ----------
    Process {
        id: tel
        running: false
        command: ["bash", "-lc",
            "read _ a b c d _ < <(grep '^cpu ' /proc/stat); "
            + "sleep 0.15; "
            + "read _ e f g h _ < <(grep '^cpu ' /proc/stat); "
            + "du=$(( (e+f+g) - (a+b+c) )); dt=$(( (e+f+g+h) - (a+b+c+d) )); "
            + "cpu=$(( dt>0 ? du*100/dt : 0 )); "
            + "mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{m=$2}END{printf \"%d\",(t-m)*100/t}' /proc/meminfo); "
            + "bat=0; bst=Unknown; pwr=0; "
            + "if [ -d /sys/class/power_supply/BAT0 ]; then "
            + "  bat=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 0); "
            + "  bst=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo Unknown); "
            + "  pwr=$(cat /sys/class/power_supply/BAT0/power_now 2>/dev/null || echo 0); "
            + "elif [ -d /sys/class/power_supply/BAT1 ]; then "
            + "  bat=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 0); "
            + "  bst=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo Unknown); "
            + "  pwr=$(cat /sys/class/power_supply/BAT1/power_now 2>/dev/null || echo 0); "
            + "fi; "
            + "pwr=${pwr#-}; "  // some kernels prefix '-' on discharge; magnitude is enough, sign comes from $bst
            + "printf '%d|%d|%d|%s|%s|%s|%s|%s|%d' "
            + "  \"$cpu\" \"$mem\" \"$bat\" \"$bst\" "
            + "  \"$(date +%H)\" \"$(date +%M)\" \"$(date +%d)\" \"$(date +%b | tr a-z A-Z)\" \"$pwr\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.split("|");
                if (p.length === 9) {
                    root.cpuVal = parseInt(p[0]) || 0;
                    root.memVal = parseInt(p[1]) || 0;
                    root.batVal = parseInt(p[2]) || 0;
                    root.batState = p[3] || "Unknown";
                    root.hh = p[4]; root.mm = p[5];
                    root.dd = p[6]; root.mon = p[7];
                    root.batPower = (parseInt(p[8]) || 0) / 1e6;
                }
            }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { tel.running = false; tel.running = true; } }

    // ---------- Workspaces (2 Hz) ----------
    Process {
        id: wsProbe
        running: false
        command: ["bash", "-lc",
            "act=$(hyprctl activeworkspace -j 2>/dev/null | sed -n 's/.*\"id\": *\\([0-9]*\\).*/\\1/p' | head -1); "
            + "ids=$(hyprctl workspaces -j 2>/dev/null | tr ',' '\\n' | sed -n 's/.*\"id\": *\\([0-9]*\\).*/\\1/p' | sort -nu | paste -sd,); "
            + "printf '%s|%s' \"${act:-1}\" \"${ids:-1}\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.split("|");
                if (p.length === 2) {
                    const next = parseInt(p[0]) || 1;
                    // Set direction first; the Workspace delegates read it
                    // inside their onActiveChanged handlers, which fire as
                    // soon as we write activeWs below.
                    if (next > root.activeWs) root.lastDirection = 1;
                    else if (next < root.activeWs) root.lastDirection = -1;
                    root.activeWs = next;
                    const have = p[1].split(",").map(s => parseInt(s)).filter(n => !isNaN(n));
                    root.existingWs = [...new Set([...have, 1, 2, 3, 4, 5])].sort((a,b) => a-b).slice(0, 9);
                }
            }
        }
    }
    Timer { interval: 500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { wsProbe.running = false; wsProbe.running = true; } }

    // ---------- Network status ----------
    Process {
        id: netProbe
        running: false
        command: ["bash", "-lc",
            "type=none; "
            + "if ip -o addr show | grep -qE '^[0-9]+: (en|eth)[^ ]*.*inet '; then type=eth; fi; "
            + "if [ \"$type\" = none ]; then "
            + "  for w in $(iw dev 2>/dev/null | awk '/Interface/{print $2}'); do "
            + "    link=$(iw dev \"$w\" link 2>/dev/null); "
            + "    dbm=$(printf '%s\\n' \"$link\" | awk '/signal:/{print $2}'); "
            + "    if [ -n \"$dbm\" ]; then "
            + "      pct=$((2 * (dbm + 100))); "
            + "      [ $pct -lt 0 ] && pct=0; "
            + "      [ $pct -gt 100 ] && pct=100; "
            + "      ssid=$(printf '%s\\n' \"$link\" | sed -n 's/^[[:space:]]*SSID: //p'); "
            + "      type=\"wifi:$pct:$ssid\"; break; "
            + "    fi; "
            + "  done; "
            + "fi; printf '%s' \"$type\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim();
                if (t === "eth") {
                    root.netIcon = "󰀂"; root.netKind = "eth";
                    root.wifiSsid = ""; root.wifiSignal = 0;
                } else if (t.startsWith("wifi:")) {
                    // Split on the first two colons: signal pct, then SSID
                    // (which may itself contain colons, so a naive split
                    // would truncate networks like "Foo:Bar").
                    const rest = t.slice(5);
                    const c = rest.indexOf(":");
                    const sig = parseInt(c < 0 ? rest : rest.slice(0, c)) || 0;
                    const ssid = c < 0 ? "" : rest.slice(c + 1);
                    root.netIcon = root.wifiBarsGlyph(sig); root.netKind = "wifi";
                    root.wifiSignal = sig; root.wifiSsid = ssid;
                } else {
                    root.netIcon = "󰤮"; root.netKind = "none";
                    root.wifiSsid = ""; root.wifiSignal = 0;
                }
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { netProbe.running = false; netProbe.running = true; } }

    // ---------- Network burst detection ----------
    // Samples cumulative rx+tx bytes from /proc/net/dev once per second.
    // When the per-second delta crosses the threshold and the burst is
    // armed, emits netBurst() and disarms for `burstCooldown.interval` ms
    // so a sustained download doesn't keep retriggering — this should read
    // as a rare event, not a continuous activity light.
    signal netBurst()
    property real netPrevBytes: -1
    property bool burstArmed: false
    // First sample after startup seeds netPrevBytes; arm only after a
    // settling beat, otherwise the initial delta (counter vs 0) would
    // always fire.
    Timer { interval: 2500; running: true; repeat: false
        onTriggered: root.burstArmed = true }

    Process {
        id: netBurstProbe
        running: false
        // $2 is rx_bytes, $10 is tx_bytes per /proc/net/dev's column layout.
        // Skip loopback so localhost chatter doesn't count as "network".
        // Direct argv (no shell) — saves the per-poll login-shell startup.
        command: ["awk", "NR>2 && $1!~/^lo:/ {s+=$2+$10} END {print s+0}",
                  "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                const cur = parseFloat(this.text.trim());
                if (isNaN(cur)) return;
                if (root.netPrevBytes < 0) { root.netPrevBytes = cur; return; }
                const delta = cur - root.netPrevBytes;
                root.netPrevBytes = cur;
                // ~1.5 MB in a 1s sample window. Low enough that an active
                // download or stream paints the arc regularly, high enough
                // that idle browser chatter doesn't.
                if (root.burstArmed && delta > 1.5 * 1024 * 1024) {
                    root.burstArmed = false;
                    root.netBurst();
                    burstCooldown.restart();
                }
            }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { netBurstProbe.running = false; netBurstProbe.running = true; } }
    Timer { id: burstCooldown; interval: 2000; repeat: false
        onTriggered: root.burstArmed = true }

    // ---------- Idle dim ----------
    // Wayland ext-idle-notify-v1 via Quickshell. The compositor counts
    // pointer AND keyboard activity, so typing keeps the bar bright even
    // when the mouse hasn't moved. Once idle the rectangle eases to 0.7
    // opacity over 6s; the next input snaps it back over 60ms — slow
    // fade reads ambient, fast restore reads responsive.
    IdleMonitor {
        id: idleMonitor
        enabled: true
        timeout: 60
        respectInhibitors: true
    }
    readonly property bool isIdle: idleMonitor.isIdle

    // ---------- Battery icon helper ----------
    // "Not charging" covers plugged-in-but-topped-up laptops; "Full" is the
    // briefly-stable Charging→Full edge. Treat all three as AC-powered and
    // swap the battery ramp for a single plug glyph — once AC is in, the
    // % digit in the tooltip is the only number worth glancing at.
    function batteryIcon() {
        if (root.batState === "Charging"
            || root.batState === "Full"
            || root.batState === "Not charging") return root.icoPlug;
        const c = root.batVal;
        const r = ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"];
        return r[Math.min(9, Math.floor(c / 10))];
    }

    // ---------- Surfaces ----------
    // Both bar faces are instantiated; only the one matching barVariant maps
    // to the edge (the other is an unmapped, zero-exclusive-zone window).
    TooltipOverlay   { root: root }
    TactilePopup     { root: root; controller: tactile }
    CalendarPopup    { root: root; controller: calendar }
    ScreenshotsPopup { root: root; controller: screenshots }
    ClipboardPopup   { root: root; controller: clipboard }
    VideosPopup      { root: root; controller: videos }
    AudioPopup       { root: root; controller: audio }
    BluetoothPopup   { root: root; controller: bluetooth }
    NetworkPopup     { root: root; controller: wifi }
    PowerPopup       { root: root; controller: power }
    DisplayPopup     { root: root; controller: display }
    OsdOverlay       { root: root; controller: osd }
    ReminderPopup    { root: root; controller: reminder }
    DropboxPopup     { root: root; controller: dropbox }
    OpencodeUsagePopup { root: root; controller: opencodeUsage }
    GrokUsagePopup   { root: root; controller: grokUsage }
    CodexUsagePopup  { root: root; controller: codexUsage }
    WeatherPopup     { root: root; controller: weather }
    CamsPopup        { root: root; controller: cams }

    // ---------- IPC ----------
    IpcHandler {
        target: "tactile"
        function toggle(): void { tactile.toggle(); }
        function open(): void  { tactile.open(); }
        function close(): void { tactile.close(); }
    }

    // Lets external keybinds drive the screenshots popup. Wire up in
    // hyprland with e.g.:
    //   bind = SUPER, P, exec, qs ipc call screenshots toggle
    IpcHandler {
        target: "screenshots"
        function toggle(): void { screenshots.toggle(); }
        function open(): void { screenshots.open(); }
        function close(): void { screenshots.close(); }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { clipboard.toggle(); }
        function open(): void { clipboard.open(); }
        function close(): void { clipboard.close(); }
        function refresh(): void { clipboard.refresh(); }
    }

    // bind = SUPER, V, exec, qs ipc call videos toggle
    IpcHandler {
        target: "videos"
        function toggle(): void { videos.toggle(); }
        function open(): void { videos.open(); }
        function close(): void { videos.close(); }
    }

    // bind = SUPER, W, exec, qs ipc call weather toggle
    IpcHandler {
        target: "weather"
        function toggle(): void { weather.toggle(); }
        function open(): void    { weather.open(); }
        function close(): void   { weather.close(); }
        function refresh(): void { weather.refresh(); }
    }

    IpcHandler {
        target: "display"
        function toggle(): void { display.toggle(); }
        function open(): void { display.open(); }
        function close(): void { display.close(); }
        function refresh(): void { display.refreshAll(); }
    }

    IpcHandler {
        target: "osd"
        function flash(payloadJson: string): string {
            return osd.showPayload(payloadJson) ? "ok" : "invalid-json";
        }
        function volume(value: string): void {
            const pct = Math.max(0, Math.min(150, Math.round(Number(value) || 0)));
            osd.show("volume", "OUTPUT", pct, 150, pct + "%", true, 1800, pct <= 0);
        }
        function brightness(value: string): void {
            const pct = Math.max(0, Math.min(100, Math.round(Number(value) || 0)));
            osd.show("brightness", "BRIGHTNESS", pct, 100, pct + "%", true, 1800, false);
        }
        function status(text: string): void {
            osd.show("status", "STATUS", 0, 100, text, false, 1800, false);
        }
        function close(): void { osd.close(); }
        function ping(): string { return "ok"; }
    }

    IpcHandler {
        target: "audio"
        function toggle(): void { audio.toggle(); }
        function open(): void { audio.open(); }
        function close(): void { audio.close(); }
        function refresh(): void { audio.refreshAll(); }
    }

    IpcHandler {
        target: "bluetooth"
        function toggle(): void { bluetooth.toggle(); }
        function open(): void { bluetooth.open(); }
        function close(): void { bluetooth.close(); }
        function refresh(): void { bluetooth.refreshAll(); }
    }

    IpcHandler {
        target: "network"
        function toggle(): void { wifi.toggle(); }
        function open(): void { wifi.open(); }
        function close(): void { wifi.close(); }
        function refresh(): void { wifi.refresh(); }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { power.toggle(); }
        function open(): void { power.open(); }
        function close(): void { power.close(); }
        function refresh(): void { power.refresh(); }
    }

    IpcHandler {
        target: "dropbox"
        function toggle(): void { dropbox.toggle(); }
        function open(): void { dropbox.open(); }
        function close(): void { dropbox.close(); }
        function refresh(): void { dropbox.refresh(); }
    }

    IpcHandler {
        target: "opencode-usage"
        function toggle(): void { opencodeUsage.toggle(); }
        function open(): void { opencodeUsage.open(); }
        function close(): void { opencodeUsage.close(); }
        function refresh(): void { opencodeUsage.refresh(); }
    }

    IpcHandler {
        target: "grok-usage"
        function toggle(): void { grokUsage.toggle(); }
        function open(): void { grokUsage.open(); }
        function close(): void { grokUsage.close(); }
        function refresh(): void { grokUsage.refresh(); }
    }

    IpcHandler {
        target: "codex-usage"
        function toggle(): void { codexUsage.toggle(); }
        function open(): void { codexUsage.open(); }
        function close(): void { codexUsage.close(); }
        function refresh(): void { codexUsage.refresh(); }
    }

    IpcHandler {
        target: "reminder"
        function toggle(): void { reminder.toggle(); }
        function open(): void { reminder.open(); }
        function close(): void { reminder.close(); }
    }

    IpcHandler {
        target: "calendar"
        function toggle(): void { calendar.toggle(); }
        function open(): void { calendar.open(); }
        function close(): void { calendar.close(); }
        function refresh(): void { calendar.refresh(); }
    }

    // Bar face switch. Toggle from a keybind, or jump straight to one:
    //   bind = SUPER SHIFT, B, exec, qs -c desktop ipc call bar toggle
    // Also surfaced as a "Bar Style" row in the omni palette.

        IpcHandler {
            target: "cams"
            function toggle(): void { cams.toggle(); }
            function open(): void { cams.open(); }
            function close(): void { cams.close(); }
        }

    IpcHandler {
        target: "bar"
        function toggle(): void    { root.cycleBarVariant(); }
        function set(name: string): void { root.setBarVariant(name); }
        function zen(): void       { root.setBarVariant("zen"); }
        function hackerman(): void { root.setBarVariant("hackerman"); }
    }

    // ---------- MPRIS (now playing) ----------
    // Mpris.players is a live list of every player that has registered on
    // the bus. We don't bind to a single "active" one — instead the hidden
    // Repeater below subscribes to each player's signals, and on any track
    // or playback change we recompute which player to surface in the bar.
    // Preference: a playing player wins; otherwise the most-recently-seen
    // paused one with non-empty metadata; otherwise nothing.
    property MprisPlayer musicPlayer: null
    property string musicTitle: ""
    property string musicArtist: ""
    property bool   musicPlaying: false

    function refreshMusic() {
        const players = Mpris.players ? Mpris.players.values : [];
        let best = null;
        let bestRank = -1;
        for (let i = 0; i < players.length; i++) {
            const p = players[i];
            if (!p) continue;
            const hasTitle = !!(p.trackTitle && p.trackTitle.length > 0);
            // 2 = playing with title, 1 = paused with title, 0 = anything else.
            // Ties broken by list order, which roughly tracks bus registration.
            let rank = 0;
            if (hasTitle && p.isPlaying) rank = 2;
            else if (hasTitle) rank = 1;
            if (rank > bestRank) { best = p; bestRank = rank; }
        }
        root.musicPlayer  = best;
        root.musicTitle   = best ? (best.trackTitle  || "") : "";
        root.musicArtist  = best ? (best.trackArtist || "") : "";
        root.musicPlaying = best ? !!best.isPlaying : false;
    }

    function musicToggle() {
        if (root.musicPlayer && root.musicPlayer.canTogglePlaying) root.musicPlayer.togglePlaying();
    }
    function musicNext() {
        if (root.musicPlayer && root.musicPlayer.canGoNext) root.musicPlayer.next();
    }
    function musicPrev() {
        if (root.musicPlayer && root.musicPlayer.canGoPrevious) root.musicPlayer.previous();
    }

    Item {
        visible: false
        Repeater {
            model: Mpris.players
            delegate: Item {
                required property MprisPlayer modelData
                Connections {
                    target: modelData
                    function onPostTrackChanged()     { root.refreshMusic(); }
                    function onPlaybackStateChanged() { root.refreshMusic(); }
                }
                Component.onCompleted:   root.refreshMusic()
                Component.onDestruction: root.refreshMusic()
            }
        }
    }
}
