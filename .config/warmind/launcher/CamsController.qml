import QtQuick
import Quickshell
import Quickshell.Io

// Camera monitor controller. Manages up to 4 RTSP feeds from a 16-channel
// NVR, positioned in a quadrant of the active monitor/workspace.
//
// Based on the original select_cams_hypr.sh pattern:
//   - single generated bash script does everything
//   - reads focused monitor geometry at runtime
//   - positions with absolute coordinates via hyprctl
//   - no per-window movetoworkspace (avoids recentering)
Item {
    id: controller

    property bool active: false
    property bool isRunning: false
    property var selectedCams: []
    property string targetMonitor: "DP-1"
    property string corner: "top-left"
    property string workspace: ""
    property int maxFeeds: 4

    readonly property string camPrefix: "Colegio Cam"
    readonly property string rtspBase: "rtsp://admin:888888@192.168.3.30:554/cam/realmonitor?channel=%1&subtype=0"
    readonly property string mpvOpts: "--no-keepaspect-window --video-aspect-override=16:9 --no-resume-playback --no-border"

    readonly property int regionWidthPct: 40
    readonly property int regionHeightPct: 50
    readonly property int marginX: 4
    readonly property int marginY: 4

    signal launched()
    signal closed()

    Component.onCompleted: refreshRunning()

    // ── Public API ───────────────────────────────────────────

    function toggle() {
        if (active) close();
        else open();
    }

    function open() {
        refreshRunning();
        active = true;
    }

    function close() {
        active = false;
    }

    function refreshRunning() {
        checkProc.running = false;
        checkProc.running = true;
    }

    function closeAll() {
        closeProc.running = false;
        closeProc.running = true;
    }

    function launch(camIds, monitor, corner, workspace) {
        controller.selectedCams = camIds;
        controller.targetMonitor = monitor || "DP-1";
        controller.corner = corner || "top-left";
        controller.workspace = workspace || "";

        const script = controller.buildFullScript();
        runner.command = ["bash", "-lc", script];
        runner.running = false;
        runner.running = true;
    }

    // ── Script generator ──────────────────────────────────────

    function buildFullScript() {
        const ws = controller.workspace;
        const ids = controller.selectedCams.slice(0, controller.maxFeeds);
        const numFeeds = ids.length;

        let s = "#!/bin/bash\n";
        s += "set -e\n\n";

        // 1. Optional workspace switch
        if (ws.length > 0) {
            s += "# Switch to workspace " + ws + "\n";
            s += "HYPR=\"$HOME/.config/warmind/launcher/bin/warmind-hypr\"\n";
            s += "\"$HYPR\" workspace " + ws + "\n";
            s += "sleep 0.5\n\n";
        } else {
            s += "HYPR=\"$HOME/.config/warmind/launcher/bin/warmind-hypr\"\n";
        }

        // 2. Read focused monitor geometry
        s += "# Read focused monitor geometry\n";
        s += "read MON_W MON_H MON_X MON_Y RESERVED_TOP <<< \"\$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | \"\\(.width) \\(.height) \\(.x) \\(.y) \\(.reserved[1])\"')\"\n";
        s += "REGION_W=$(( MON_W * " + controller.regionWidthPct + " / 100 ))\n";
        s += "REGION_H=$(( MON_H * " + controller.regionHeightPct + " / 100 ))\n";

        // 3. Calculate region origin based on corner
        s += "\n# Calculate region origin\n";
        switch (controller.corner) {
            case "top-left":
                s += "REGION_X=$(( MON_X + " + controller.marginX + " ))\n";
                s += "REGION_Y=$(( MON_Y + RESERVED_TOP + " + controller.marginY + " ))\n";
                break;
            case "top-right":
                s += "REGION_X=$(( MON_X + MON_W - REGION_W - " + controller.marginX + " ))\n";
                s += "REGION_Y=$(( MON_Y + RESERVED_TOP + " + controller.marginY + " ))\n";
                break;
            case "bottom-left":
                s += "REGION_X=$(( MON_X + " + controller.marginX + " ))\n";
                s += "REGION_Y=$(( MON_Y + MON_H - REGION_H - " + controller.marginY + " ))\n";
                break;
            case "bottom-right":
                s += "REGION_X=$(( MON_X + MON_W - REGION_W - " + controller.marginX + " ))\n";
                s += "REGION_Y=$(( MON_Y + MON_H - REGION_H - " + controller.marginY + " ))\n";
                break;
            default:
                s += "REGION_X=$(( MON_X + " + controller.marginX + " ))\n";
                s += "REGION_Y=$(( MON_Y + RESERVED_TOP + " + controller.marginY + " ))\n";
        }

        // 4. Calculate per-window geometry
        s += "\n# Calculate window geometry\n";
        if (numFeeds === 1) {
            s += "W0=$REGION_W\n";
            s += "H0=$REGION_H\n";
            s += "X0=$REGION_X\n";
            s += "Y0=$REGION_Y\n";
        } else if (numFeeds === 2) {
            s += "HALF_W=$(( REGION_W / 2 ))\n";
            s += "W0=$HALF_W\n";
            s += "H0=$REGION_H\n";
            s += "X0=$REGION_X\n";
            s += "Y0=$REGION_Y\n";
            s += "W1=$(( REGION_W - HALF_W ))\n";
            s += "H1=$REGION_H\n";
            s += "X1=$(( REGION_X + HALF_W ))\n";
            s += "Y1=$REGION_Y\n";
        } else {
            s += "HALF_W=$(( REGION_W / 2 ))\n";
            s += "HALF_H=$(( REGION_H / 2 ))\n";
            s += "W0=$HALF_W\n";
            s += "H0=$HALF_H\n";
            s += "X0=$REGION_X\n";
            s += "Y0=$REGION_Y\n";
            s += "W1=$(( REGION_W - HALF_W ))\n";
            s += "H1=$HALF_H\n";
            s += "X1=$(( REGION_X + HALF_W ))\n";
            s += "Y1=$REGION_Y\n";
            s += "W2=$HALF_W\n";
            s += "H2=$(( REGION_H - HALF_H ))\n";
            s += "X2=$REGION_X\n";
            s += "Y2=$(( REGION_Y + HALF_H ))\n";
            s += "W3=$(( REGION_W - HALF_W ))\n";
            s += "H3=$(( REGION_H - HALF_H ))\n";
            s += "X3=$(( REGION_X + HALF_W ))\n";
            s += "Y3=$(( REGION_Y + HALF_H ))\n";
        }

        // 5. Launch and position each feed
        s += "\n# Launch feeds\n";
        for (let i = 0; i < numFeeds; i++) {
            const camId = ids[i];
            const url = controller.rtspBase.arg(camId);
            const title = controller.camPrefix + " " + camId;

            s += "\n# --- Camera " + camId + " ---\n";
            s += "setsid mpv " + controller.mpvOpts + " --title=" + shQuote(title) + " " + shQuote(url) + " >/dev/null 2>&1 &\n";
        }
        s += "sleep 0.5\n";

        // 6. Wait for windows and position
        for (let i = 0; i < numFeeds; i++) {
            const camId = ids[i];
            const title = controller.camPrefix + " " + camId;

            s += "\n# Position camera " + camId + "\n";
            s += "for j in $(seq 1 50); do\n";
            s += "  if hyprctl clients -j | jq -e --arg t " + shQuote(title) + " '.[] | select(.title==\$t)' >/dev/null 2>&1; then\n";
            s += "    break\n";
            s += "  fi\n";
            s += "  sleep 0.2\n";
            s += "done\n";

            s += "\"$HYPR\" place \"\$W" + i + "\" \"\$H" + i + "\" \"\$X" + i + "\" \"\$Y" + i
                + "\" " + shQuote("title:^(" + title + ")$") + "\n";
        }

        s += "\nexit 0\n";
        return s;
    }

    function shQuote(s) {
        return '"' + s.replace(/"/g, '\\"') + '"';
    }

    function esc(s) {
        return s.replace(/"/g, '\\"');
    }

    // ── Processes ─────────────────────────────────────────────

    Process {
        id: runner
        running: false
        onRunningChanged: {
            if (!runner.running) controller.launched();
        }
    }

    Process {
        id: checkProc
        running: false
        command: ["bash", "-lc",
            "cnt=$(hyprctl clients -j | jq -r '.[].title' | grep -c '^" + controller.camPrefix + "');"
            + " echo \"$cnt\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const cnt = parseInt(this.text.trim() || "0", 10);
                controller.isRunning = cnt > 0;
            }
        }
    }

    Process {
        id: closeProc
        running: false
        command: ["bash", "-lc",
            "HYPR=\"$HOME/.config/warmind/launcher/bin/warmind-hypr\";"
            + " while hyprctl clients -j | jq -r '.[].title' | grep -q '^" + controller.camPrefix + "'; do"
            + " \"$HYPR\" close 'title:^" + controller.camPrefix + "' 2>/dev/null;"
            + " sleep 0.1;"
            + " done"]
        onRunningChanged: {
            if (!closeProc.running) controller.closed();
        }
    }
}
