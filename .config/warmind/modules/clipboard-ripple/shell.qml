import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Every time the Wayland selection changes, a soft accent-tinted halo blooms
// outward from the cursor and fades. Tiny "the system saw that" feedback —
// overlay layer, click-through, themed off the omarchy palette.
ShellRoot {
    id: root

    // Catppuccin Mocha accent, static
    readonly property color accent: "#89b4fa"

    // wl-paste --watch always fires once at startup with whatever's already in
    // the clipboard. Suppress that phantom so logging in doesn't ripple at
    // mouse-park position.
    property bool armed: false

    Timer { interval: 1200; running: true; onTriggered: root.armed = true }

    // ---------- Clipboard event source ----------
    // wl-paste --watch invokes the inner command on every selection change,
    // piping the clipboard payload to its stdin. We discard the payload and
    // emit a sentinel line; wl-paste forwards the inner stdout, which arrives
    // here line-by-line via SplitParser. Auto-revives 3s after death so the
    // ripple survives wl-paste restarts (e.g. wlroots reload).
    Process {
        id: watcher
        running: true
        command: ["bash", "-lc",
            "exec wl-paste --watch bash -c 'cat >/dev/null; echo P'"]
        stdout: SplitParser {
            onRead: function(line) {
                if (line !== "P") return;
                if (!root.armed) return;
                posQuery.running = false;
                posQuery.running = true;
            }
        }
        onRunningChanged: if (!running) reviveTimer.start()
    }
    Timer { id: reviveTimer; interval: 3000; onTriggered: watcher.running = true }

    // ---------- Resolve cursor + focused monitor ----------
    Process {
        id: posQuery
        running: false
        command: ["python3", "-c",
            "import json, subprocess as s\n"
          + "ms = json.loads(s.check_output(['hyprctl','-j','monitors']))\n"
          + "cp = s.check_output(['hyprctl','cursorpos']).decode().strip()\n"
          + "cx, cy = [int(float(v.strip())) for v in cp.split(',')[:2]]\n"
          + "focused = ms[0] if ms else None\n"
          + "for mon in ms:\n"
          + "    if mon.get('focused'):\n"
          + "        focused = mon\n"
          + "        break\n"
          + "chosen = None\n"
          + "for mon in ms:\n"
          + "    mx = int(mon.get('x', 0)); my = int(mon.get('y', 0))\n"
          + "    mw = int(mon.get('width', 0)); mh = int(mon.get('height', 0))\n"
          + "    if cx >= mx and cx < mx + mw and cy >= my and cy < my + mh:\n"
          + "        chosen = mon\n"
          + "        break\n"
          + "if chosen is None:\n"
          + "    chosen = focused\n"
          + "if chosen is None:\n"
          + "    raise SystemExit(0)\n"
          + "print(f'{cx},{cy}|{int(chosen.get(\"x\",0))} {int(chosen.get(\"y\",0))}')\n"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("|");
                if (parts.length !== 2) return;
                const cm = parts[0].split(",").map(s => parseInt(s.trim()));
                const mm = parts[1].trim().split(/\s+/).map(s => parseInt(s));
                if (cm.length < 2 || mm.length < 2) return;
                if (cm.some(isNaN) || mm.some(isNaN)) return;
                stage.fire(cm[0] - mm[0], cm[1] - mm[1]);
            }
        }
    }

    // Manual trigger for testing or shell-side hooks:
    //   qs -p ~/.config/warmind/modules/clipboard-ripple/shell.qml ipc call ripple poke
    IpcHandler {
        target: "ripple"
        function poke(): void { posQuery.running = false; posQuery.running = true; }
    }

    PanelWindow {
        id: surface
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "clipboard-ripple"
        mask: Region {}  // fully click-through

        Item {
            id: stage
            anchors.fill: parent

            property real ox: width / 2
            property real oy: height / 2

            // Outer halo: soft tinted disc radiating outward.
            property real haloR: 0
            property real haloO: 0

            // Inner pulse: brighter dot that beats twice at the centre while
            // the halo expands. Gives the effect a "two-tick heartbeat"
            // rhythm rather than a single fade.
            property real coreR: 0
            property real coreO: 0

            function fire(x, y) {
                stage.ox = x;
                stage.oy = y;
                anim.restart();
            }

            Rectangle {
                width: stage.haloR * 2
                height: stage.haloR * 2
                radius: stage.haloR
                x: stage.ox - stage.haloR
                y: stage.oy - stage.haloR
                color: Qt.lighter(root.accent, 1.35)
                opacity: stage.haloO
                antialiasing: true
            }

            Rectangle {
                width: stage.coreR * 2
                height: stage.coreR * 2
                radius: stage.coreR
                x: stage.ox - stage.coreR
                y: stage.oy - stage.coreR
                color: Qt.lighter(root.accent, 1.6)
                opacity: stage.coreO
                antialiasing: true
            }

            SequentialAnimation {
                id: anim
                ScriptAction { script: {
                    stage.haloR = 0; stage.haloO = 0;
                    stage.coreR = 0; stage.coreO = 0;
                }}
                ParallelAnimation {
                    // Outer halo — smaller, gentler.
                    ParallelAnimation {
                        NumberAnimation {
                            target: stage; property: "haloR"
                            from: 6; to: 42
                            duration: 520
                            easing.type: Easing.OutCubic
                        }
                        SequentialAnimation {
                            NumberAnimation { target: stage; property: "haloO"; from: 0; to: 0.55; duration: 90; easing.type: Easing.OutQuad }
                            PauseAnimation { duration: 80 }
                            NumberAnimation { target: stage; property: "haloO"; to: 0; duration: 360; easing.type: Easing.InCubic }
                        }
                    }

                    // Inner pulse — two quick beats, then fade.
                    SequentialAnimation {
                        // beat 1
                        ParallelAnimation {
                            NumberAnimation { target: stage; property: "coreR"; from: 2; to: 7; duration: 140; easing.type: Easing.OutQuad }
                            NumberAnimation { target: stage; property: "coreO"; from: 0; to: 0.95; duration: 80 }
                        }
                        NumberAnimation { target: stage; property: "coreR"; to: 3; duration: 110; easing.type: Easing.InQuad }
                        // beat 2 (slightly weaker)
                        ParallelAnimation {
                            NumberAnimation { target: stage; property: "coreR"; to: 6; duration: 130; easing.type: Easing.OutQuad }
                            NumberAnimation { target: stage; property: "coreO"; to: 0.75; duration: 130 }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: stage; property: "coreR"; to: 0; duration: 220; easing.type: Easing.InCubic }
                            NumberAnimation { target: stage; property: "coreO"; to: 0; duration: 220; easing.type: Easing.InCubic }
                        }
                    }
                }
            }
        }
    }
}
