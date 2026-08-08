import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Mission-Control-style workspace overview with real per-workspace thumbnails.
//
// Wayland forbids a layer-shell client from screencapping arbitrary surfaces.
// Workaround: a background daemon tails Hyprland's event socket and, on every
// workspace / window change (debounced 400ms), shells out to `grim` to grab
// each monitor's currently-visible workspace into:
//
//     ~/.cache/quickshell/expose/ws-<id>.png   (~900x500, ~50KB)
//
// Workspaces visited at least once during the session show as real pixels;
// never-visited workspaces fall back to a schematic class-name view. The
// active-window outline is drawn on top of the thumbnail in every case.
//
// Bind in Hyprland:
//   bind = SUPER, grave, exec, qs -c expose ipc call expose toggle
ShellRoot {
    id: root

    // ---- palette (Catppuccin Mocha, static) ----
    readonly property color paper:   "#1e1e2e"
    readonly property color ink:     "#cdd6f4"
    readonly property color inkDeep: "#a6adc8"
    readonly property color sumi:    "#585b70"
    readonly property color indigo:  "#89b4fa"
    readonly property color seal:    "#f38ba8"
    readonly property color wash:    Qt.lighter(paper, 1.18)
    readonly property string serif:  "serif"
    readonly property string mono:   "JetBrainsMono Nerd Font"

    // ---- kanji (matches Workspace.qml in the desktop module) ----
    readonly property var kanjiNum: ["〇","一","二","三","四","五","六","七","八","九","十"]
    function kanji(n) { return n >= 0 && n <= 10 ? kanjiNum[n] : String(n); }

    // ---- state ----
    property bool open: false
    property bool everOpened: false
    property var monitors: []
    property var workspaces: []
    property var clients: []
    property var monitorsByName: ({})
    property int selectedIndex: 0
    property int cols: 1
    property int thumbTick: 0  // bumped after every capture to force Image reloads
    property var availableThumbs: ({})  // { wsId: true } for ws-N.png files that exist
    property real revealPhase: 0  // 0..1, drives the stagger reveal of tiles

    function hasThumb(wsId) { return root.availableThumbs[wsId] === true; }

    onOpenChanged: {
        if (root.open) {
            root.everOpened = true;
            revealPhase = 0;
            revealAnim.restart();
        } else {
            revealAnim.stop();
            revealPhase = 0;
            if (root.everOpened) Qt.quit();
        }
    }
    NumberAnimation {
        id: revealAnim
        target: root
        property: "revealPhase"
        from: 0; to: 1
        // ~30ms per tile, with a floor so single-workspace setups still animate.
        duration: 220 + Math.max(0, root.workspaces.length - 1) * 26
        easing.type: Easing.OutCubic
    }

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/quickshell/expose"

    function thumbPathFor(wsId) { return root.cacheDir + "/ws-" + wsId + ".png"; }

    function reloadData() { dataLoad.running = false; dataLoad.running = true; }
    function toggle() {
        if (root.open) { root.open = false; }
        else {
            reloadData();
            captureVisible();
        }
    }

    IpcHandler {
        target: "expose"
        function show(): void { root.reloadData(); root.captureVisible(); }
        function hide(): void { root.open = false; }
        function toggle(): void { root.toggle(); }
        function capture(): void { root.captureVisible(); }
    }

    // ---- ensure cache dir exists at startup and seed availableThumbs ----
    Process {
        running: true
        command: ["bash", "-lc",
              "d=\"$HOME/.cache/quickshell/expose\"; "
            + "mkdir -p \"$d\"; "
            + "ids=$(ls \"$d\"/ws-*.png 2>/dev/null | sed -n 's#.*/ws-\\([0-9]\\+\\)\\.png#\\1#p' | sort -n | tr '\\n' ' '); "
            + "echo \"OK $ids\""]
        stdout: SplitParser {
            onRead: function(line) {
                if (!line.startsWith("OK")) return;
                const parts = line.trim().split(/\s+/);
                const next = {};
                for (let i = 1; i < parts.length; i++) {
                    const n = parseInt(parts[i]);
                    if (!isNaN(n)) next[n] = true;
                }
                root.availableThumbs = next;
            }
        }
    }

    // ---- data source ----
    Process {
        id: dataLoad
        running: false
        command: ["bash", "-lc",
              "printf '%s' '{\"monitors\":'; hyprctl -j monitors; "
            + "printf '%s' ',\"workspaces\":'; hyprctl -j workspaces; "
            + "printf '%s' ',\"clients\":'; hyprctl -j clients; "
            + "printf '}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(this.text);
                    root.monitors = o.monitors || [];
                    const byName = {};
                    for (let i = 0; i < root.monitors.length; i++) {
                        byName[root.monitors[i].name] = root.monitors[i];
                    }
                    root.monitorsByName = byName;

                    const ws = (o.workspaces || []).filter(w => w && w.id > 0);
                    ws.sort((a, b) => a.id - b.id);
                    root.workspaces = ws;
                    root.clients = o.clients || [];

                    // Default selection: currently focused workspace.
                    let sel = 0;
                    for (let i = 0; i < ws.length; i++) {
                        const m = root.monitorsByName[ws[i].monitor];
                        if (m && m.focused && m.activeWorkspace && m.activeWorkspace.id === ws[i].id) {
                            sel = i; break;
                        }
                    }
                    root.selectedIndex = sel;
                    root.open = true;
                } catch (e) {
                    console.warn("expose: parse error", e, this.text.slice(0, 200));
                }
            }
        }
    }

    Process { id: runner; running: false }
    readonly property string hyprHelper: (Quickshell.env("HOME") || "") + "/.config/warmind/launcher/bin/warmind-hypr"
    function runHelper(args) {
        runner.command = [root.hyprHelper].concat(args);
        runner.running = false;
        runner.running = true;
    }
    function workspaceIdForAddress(addr) {
        for (let i = 0; i < clients.length; i++) {
            const c = clients[i];
            if (c.address === addr && c.workspace && c.workspace.id)
                return c.workspace.id;
        }
        return 0;
    }
    function jumpWorkspace(wsId) {
        root.open = false;
        root.runHelper(["workspace", String(wsId)]);
    }
    function focusWindow(addr) {
        const wsId = root.workspaceIdForAddress(addr);
        root.open = false;
        if (wsId > 0) {
            runner.command = ["bash", "-lc",
                  root.hyprHelper + " workspace " + String(wsId)
                + " >/dev/null 2>&1; sleep 0.05; "
                + root.hyprHelper + " focus-address " + JSON.stringify(addr)];
            runner.running = false;
            runner.running = true;
        } else {
            root.runHelper(["focus-address", addr]);
        }
    }
    function jumpSelected() { const ws = root.workspaces[root.selectedIndex]; if (ws) root.jumpWorkspace(ws.id); }

    function clientsInWorkspace(wsId) {
        const out = [];
        for (let i = 0; i < clients.length; i++) {
            const c = clients[i];
            if (c.workspace && c.workspace.id === wsId) out.push(c);
        }
        return out;
    }
    function activeAddrFor(wsId) {
        let best = null;
        for (let i = 0; i < clients.length; i++) {
            const c = clients[i];
            if (c.workspace && c.workspace.id === wsId) {
                if (best === null || c.focusHistoryID < best.focusHistoryID) best = c;
            }
        }
        return best ? best.address : null;
    }

    // ---- capture daemon ----
    // Captures each monitor's currently-active workspace via grim. Called on
    // a debounce after Hyprland events, and once on every expose open. The
    // cache path is hardcoded in Python so we don't have to rely on
    // Process.environment.
    Process {
        id: captureProc
        running: false
        command: ["bash", "-lc",
              "command -v grim >/dev/null 2>&1 || { echo 'expose: grim not installed, thumbnails disabled' >&2; exit 0; }; "
            + "mkdir -p \"$HOME/.cache/quickshell/expose\"; "
            + "hyprctl -j monitors | "
            + "python3 -c '\n"
            + "import json,sys,subprocess,os\n"
            + "out=os.path.expanduser(\"~/.cache/quickshell/expose\")\n"
            + "ms=json.load(sys.stdin)\n"
            + "for m in ms:\n"
            + "    aw=m.get(\"activeWorkspace\") or {}\n"
            + "    wid=aw.get(\"id\")\n"
            + "    if not wid or wid<=0: continue\n"
            + "    dst=f\"{out}/ws-{wid}.png\"\n"
            + "    tmp=dst+\".tmp\"\n"
            + "    r=subprocess.run([\"grim\",\"-o\",m[\"name\"],\"-s\",\"0.35\",tmp],\n"
            + "                     stderr=subprocess.DEVNULL)\n"
            + "    if r.returncode==0 and os.path.exists(tmp):\n"
            + "        os.replace(tmp,dst)\n"
            + "    else:\n"
            + "        try: os.unlink(tmp)\n"
            + "        except FileNotFoundError: pass\n"
            + "ids=sorted(int(f[3:-4]) for f in os.listdir(out) if f.startswith(\"ws-\") and f.endswith(\".png\"))\n"
            + "print(\"OK\",*ids,flush=True)\n"
            + "'"]
        stdout: SplitParser {
            onRead: function(line) {
                if (!line.startsWith("OK")) return;
                const parts = line.split(" ");
                const next = {};
                for (let i = 1; i < parts.length; i++) {
                    const n = parseInt(parts[i]);
                    if (!isNaN(n)) next[n] = true;
                }
                root.availableThumbs = next;
            }
        }
        onExited: function(code) { root.thumbTick = root.thumbTick + 1; }
    }

    function captureVisible() { captureProc.running = false; captureProc.running = true; }

    // ---- debounced trigger from socket2 events ----
    Timer {
        id: captureDebounce
        interval: 400
        repeat: false
        onTriggered: root.captureVisible()
    }

    Process {
        id: hyprEvents
        running: true
        command: ["python3", "-u", "-c",
              "import os,socket,sys\n"
            + "p=os.environ['XDG_RUNTIME_DIR']+'/hypr/'+os.environ['HYPRLAND_INSTANCE_SIGNATURE']+'/.socket2.sock'\n"
            + "s=socket.socket(socket.AF_UNIX); s.connect(p)\n"
            + "f=s.makefile('r')\n"
            + "for ln in f:\n"
            + "    sys.stdout.write(ln); sys.stdout.flush()\n"]
        stdout: SplitParser {
            onRead: function(line) {
                const ix = line.indexOf(">>");
                if (ix < 0) return;
                const name = line.substring(0, ix);
                // Events that change *what* is on screen on some monitor.
                if (name === "workspace" || name === "workspacev2"
                    || name === "focusedmon"
                    || name === "openwindow" || name === "closewindow"
                    || name === "movewindow" || name === "movewindowv2"
                    || name === "changefloatingmode"
                    || name === "fullscreen") {
                    captureDebounce.restart();
                }
            }
        }
        onRunningChanged: if (!running) eventsRevive.start()
    }
    Timer { id: eventsRevive; interval: 3000; onTriggered: hyprEvents.running = true }

    // ---- prime the cache at startup ----
    Timer {
        interval: 800
        running: true
        repeat: false
        onTriggered: root.captureVisible()
    }

    // ---- surface ----
    // Single fullscreen layer-shell surface. Hyprland places it on the
    // currently-focused monitor, which is also the monitor the user pressed
    // the keybind on. The grid still shows every workspace across every
    // monitor; click a tile to jump even to one on another output.
    PanelWindow {
        id: panel
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "qs-expose"
        visible: root.open

            // ---- dim backdrop ----
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(root.paper.r, root.paper.g, root.paper.b, 0.94)
                opacity: root.open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.open = false
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                }
            }

            // ---- faded kanji watermark, clipped at the corner like an ink-margin stamp ----
            Text {
                text: "観"
                color: root.ink
                opacity: root.open ? 0.035 : 0
                Behavior on opacity { NumberAnimation { duration: 600 } }
                font.family: root.serif
                font.pixelSize: Math.min(parent.width, parent.height) * 0.85
                font.weight: Font.Light
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: -Math.min(parent.width, parent.height) * 0.18
                anchors.bottomMargin: -Math.min(parent.width, parent.height) * 0.22
            }
            // Vertical sumi reading-line on the far left edge — a single
            // hairline gutter, like the edge of a calligraphy scroll.
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: 38
                width: 1
                color: root.sumi
                opacity: root.open ? 0.10 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.rightMargin: 38
                width: 1
                color: root.sumi
                opacity: root.open ? 0.10 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }

            // ---- keyboard ----
            Item {
                anchors.fill: parent
                focus: root.open
                Keys.onPressed: function(e) {
                    if (!root.open) return;
                    if (e.key === Qt.Key_Escape || e.key === Qt.Key_Q) {
                        root.open = false; e.accepted = true; return;
                    }
                    const n = root.workspaces.length;
                    if (n === 0) return;
                    if (e.key === Qt.Key_Right || e.key === Qt.Key_L
                        || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier))) {
                        root.selectedIndex = (root.selectedIndex + 1) % n; e.accepted = true; return;
                    }
                    if (e.key === Qt.Key_Left || e.key === Qt.Key_H
                        || (e.key === Qt.Key_Tab && (e.modifiers & Qt.ShiftModifier))) {
                        root.selectedIndex = (root.selectedIndex - 1 + n) % n; e.accepted = true; return;
                    }
                    if (e.key === Qt.Key_Down || e.key === Qt.Key_J) {
                        root.selectedIndex = Math.min(n - 1, root.selectedIndex + root.cols); e.accepted = true; return;
                    }
                    if (e.key === Qt.Key_Up || e.key === Qt.Key_K) {
                        root.selectedIndex = Math.max(0, root.selectedIndex - root.cols); e.accepted = true; return;
                    }
                    if (e.key === Qt.Key_Home) { root.selectedIndex = 0; e.accepted = true; return; }
                    if (e.key === Qt.Key_End)  { root.selectedIndex = n - 1; e.accepted = true; return; }
                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
                        root.jumpSelected(); e.accepted = true; return;
                    }
                    if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) {
                        const i = e.key - Qt.Key_1;
                        if (i < n) { root.selectedIndex = i; root.jumpSelected(); }
                        e.accepted = true; return;
                    }
                }
            }

            // ---- title block ----
            // 概観 (gaikan) — "overview" — set large in serif, with a
            // brush-stroke divider beneath punctuated by a vermilion hanko
            // dot, then a tiny romaji caption with the workspace count.
            Item {
                id: titleBlock
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 38
                width: Math.min(520, parent.width - 200)
                height: 84
                opacity: root.open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 260 } }

                Text {
                    id: titleKanji
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    text: "概観"
                    color: root.ink
                    opacity: 0.92
                    font.family: root.serif
                    font.pixelSize: 32
                    font.letterSpacing: 14
                    font.weight: Font.Light
                }

                // Brush-stroke divider: two short hairlines tapered toward a
                // central vermilion dot. Reads like a sumi-e flick from each
                // side meeting at a hanko stamp.
                Item {
                    id: divider
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: titleKanji.bottom
                    anchors.topMargin: 10
                    width: 260; height: 8

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: (parent.width - dot.width) / 2 - 10
                        height: 1
                        color: root.sumi
                        opacity: 0.42
                    }
                    Rectangle {
                        id: dot
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6; height: 6; radius: 3
                        color: root.seal
                        rotation: -8
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.85; to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.0; to: 0.85; duration: 1400; easing.type: Easing.InOutSine }
                        }
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: (parent.width - dot.width) / 2 - 10
                        height: 1
                        color: root.sumi
                        opacity: 0.42
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: divider.bottom
                    anchors.topMargin: 9
                    text: "exposé · " + root.kanji(root.workspaces.length) + " · "
                        + root.workspaces.length + (root.workspaces.length === 1 ? " workspace" : " workspaces")
                    color: root.sumi
                    opacity: 0.65
                    font.family: root.serif
                    font.pixelSize: 11
                    font.italic: true
                    font.letterSpacing: 4
                }
            }

            // ---- grid ----
            Item {
                id: grid
                anchors.fill: parent
                anchors.topMargin: 166
                anchors.bottomMargin: 100
                anchors.leftMargin: 92
                anchors.rightMargin: 92

                readonly property int n: root.workspaces.length

                readonly property int cols: {
                    if (n <= 1) return 1;
                    const aspect = width / Math.max(1, height);
                    const target = Math.max(1, Math.round(Math.sqrt(n * aspect * 0.55)));
                    return Math.max(1, Math.min(n, target));
                }
                readonly property int rows: Math.max(1, Math.ceil(n / cols))
                readonly property real gapX: 30
                readonly property real gapY: 34
                readonly property real cellW: cols > 0 ? (width  - (cols - 1) * gapX) / cols : width
                readonly property real cellH: rows > 0 ? (height - (rows - 1) * gapY) / rows : height

                onColsChanged: root.cols = cols
                Component.onCompleted: root.cols = cols

                Repeater {
                    model: root.workspaces
                    delegate: WorkspaceTile {
                        id: wt
                        required property var modelData
                        required property int index

                        shell: root
                        ws: modelData
                        mon: root.monitorsByName[modelData.monitor] || null
                        wsClients: root.clientsInWorkspace(modelData.id)
                        activeAddr: root.activeAddrFor(modelData.id) || ""
                        focused: root.selectedIndex === index
                        current: {
                            const m = root.monitorsByName[modelData.monitor];
                            return m && m.activeWorkspace && m.activeWorkspace.id === modelData.id;
                        }
                        thumbPath: root.thumbPathFor(modelData.id)
                        thumbTick: root.thumbTick
                        thumbExists: root.availableThumbs[modelData.id] === true
                        wsIndex: index

                        width: grid.cellW
                        height: grid.cellH
                        x: (index % grid.cols) * (grid.cellW + grid.gapX)
                        y: Math.floor(index / grid.cols) * (grid.cellH + grid.gapY)
                        Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                        // Stagger reveal: each tile fades + scales in once
                        // its index falls below the current `revealPhase`.
                        readonly property real revealAt: root.workspaces.length > 0
                            ? wt.index / root.workspaces.length : 0
                        readonly property bool revealed: root.revealPhase > wt.revealAt
                        opacity: revealed ? 1 : 0
                        scale: revealed ? (focused ? 1.015 : 1.0) : 0.94
                        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on scale   { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                        onJump: function(wsId) { root.jumpWorkspace(wsId); }
                        onFocusWindow: function(addr) { root.focusWindow(addr); }
                        onHovered: function(idx) { root.selectedIndex = idx; }
                    }
                }
            }

            // ---- footer ----
            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 34
                height: 26
                opacity: root.open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 260 } }

                // Hairline rule above the keybind row, indented at the gutters.
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 120
                    anchors.rightMargin: 120
                    anchors.top: parent.top
                    height: 1
                    color: root.sumi
                    opacity: 0.18
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    spacing: 16

                    Repeater {
                        model: [
                            { k: "← →",  v: "move" },
                            { k: "↵",    v: "jump" },
                            { k: "1-9",  v: "direct" },
                            { k: "esc",  v: "close" }
                        ]
                        delegate: Row {
                            required property var modelData
                            required property int index
                            spacing: 16

                            // Pipe separator before every chip except the first.
                            Rectangle {
                                visible: index > 0
                                width: 1; height: 10
                                color: root.sumi
                                opacity: 0.32
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Row {
                                spacing: 7
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    text: modelData.k
                                    color: root.ink
                                    opacity: 0.72
                                    font.family: root.mono
                                    font.pixelSize: 11
                                    font.letterSpacing: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: modelData.v
                                    color: root.sumi
                                    opacity: 0.7
                                    font.family: root.mono
                                    font.pixelSize: 10
                                    font.italic: true
                                    font.letterSpacing: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
