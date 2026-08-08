import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: controller

    required property var host

    property bool active: false
    property real warmthK: 6500
    property int brightnessPct: 100
    property real gammaPct: 100
    property string monitorName: "eDP-1"
    property string monitorRes: "2880x1800"
    property real monitorRate: 60.0
    property real monitorScale: 2.0
    readonly property var displayPresets: [
        { label: "DAY",     warmth: 6500, gamma: 100, bright: 100 },
        { label: "READING", warmth: 4500, gamma: 95,  bright: 60  },
        { label: "NIGHT",   warmth: 3000, gamma: 85,  bright: 30  },
        { label: "CANDLE",  warmth: 2000, gamma: 80,  bright: 15  }
    ]
    property int selectedPreset: 0
    property int displayRow: 0
    property bool sunsetReady: false
    property bool hyprsunsetAvailable: false
    property bool brightnessAvailable: false

    readonly property string ensureSunset:
        "pgrep -x hyprsunset >/dev/null"
        + " || { uwsm app -- hyprsunset --gamma_max 200 >/dev/null 2>&1 &"
        + "      for i in 1 2 3 4 5 6 7 8; do"
        + "        hyprctl hyprsunset identity >/dev/null 2>&1 && break;"
        + "        sleep 0.08;"
        + "      done; }; "

    function showOsd(kind, label, value, max, text, progress) {
        if (controller.host && controller.host.osd)
            controller.host.osd.show(kind, label, value, max, text, progress, 1800, false);
    }

    function sliderModels() {
        const out = [];
        if (controller.hyprsunsetAvailable)
            out.push({ label: "WARMTH", valKey: "warmthK", lo: 1000, hi: 6500, unit: "K", kind: "warmth" });
        if (controller.brightnessAvailable)
            out.push({ label: "BRIGHTNESS", valKey: "brightnessPct", lo: 1, hi: 100, unit: "%", kind: "brightness" });
        if (controller.hyprsunsetAvailable)
            out.push({ label: "GAMMA", valKey: "gammaPct", lo: 50, hi: 150, unit: "", kind: "gamma" });
        return out;
    }

    function presetRowIndex() { return controller.hyprsunsetAvailable ? controller.sliderModels().length : -1; }
    function editRowIndex() { return controller.sliderModels().length + (controller.hyprsunsetAvailable ? 1 : 0); }
    function blankRowIndex() { return controller.editRowIndex() + 1; }
    function resetRowIndex() { return controller.editRowIndex() + 2; }
    function maxRowIndex() { return controller.resetRowIndex(); }

    function statusText() {
        if (!controller.hyprsunsetAvailable && !controller.brightnessAvailable)
            return "Install hyprsunset/brightnessctl for display controls";
        const bits = [];
        if (controller.hyprsunsetAvailable) {
            bits.push(Math.round(controller.warmthK) + "K");
            bits.push("γ " + Math.round(controller.gammaPct));
        }
        if (controller.brightnessAvailable)
            bits.push("BR " + controller.brightnessPct + "%");
        bits.push(controller.monitorRate.toFixed(0) + "HZ");
        return bits.join("  ·  ");
    }

    function open() {
        controller.active = true;
        controller.refreshAll();
    }

    function close() {
        controller.active = false;
    }

    function toggle() {
        if (controller.active) controller.close();
        else controller.open();
    }

    function runSunset(verb) {
        const cmd = "hyprctl hyprsunset " + verb;
        if (controller.sunsetReady) controller.host.run(cmd);
        else {
            controller.host.run(controller.ensureSunset + cmd);
            controller.sunsetReady = true;
        }
    }

    function setWarmth(k) {
        if (!controller.hyprsunsetAvailable) return;
        k = Math.max(1000, Math.min(6500, Math.round(k / 50) * 50));
        controller.warmthK = k;
        controller.runSunset(k >= 6500 ? "identity" : "temperature " + k);
        controller.showOsd("warmth", "WARMTH", k, 6500, k + "K", true);
    }

    function setBrightness(pct) {
        if (!controller.brightnessAvailable) return;
        pct = Math.max(1, Math.min(100, Math.round(pct)));
        controller.brightnessPct = pct;
        controller.host.run("brightnessctl set " + pct + "%");
        controller.showOsd("brightness", "BRIGHTNESS", pct, 100, pct + "%", true);
    }

    function setGamma(pct) {
        if (!controller.hyprsunsetAvailable) return;
        pct = Math.max(50, Math.min(150, Math.round(pct)));
        controller.gammaPct = pct;
        controller.runSunset("gamma " + pct);
        controller.showOsd("gamma", "GAMMA", pct - 50, 100, pct + "%", true);
    }

    function applyPreset(p) {
        controller.warmthK = p.warmth;
        controller.gammaPct = p.gamma;
        controller.brightnessPct = p.bright;
        const cmds = [];
        if (controller.hyprsunsetAvailable) {
            cmds.push("hyprctl hyprsunset " + (p.warmth >= 6500 ? "identity" : "temperature " + p.warmth));
            cmds.push("hyprctl hyprsunset gamma " + p.gamma);
        }
        if (controller.brightnessAvailable)
            cmds.push("brightnessctl set " + p.bright + "%");
        if (!cmds.length) return;
        const prelude = controller.hyprsunsetAvailable && !controller.sunsetReady ? controller.ensureSunset : "";
        controller.host.run(prelude + cmds.join(" && "));
        if (controller.hyprsunsetAvailable) controller.sunsetReady = true;
        controller.showOsd("brightness", "DISPLAY", p.bright, 100, p.label, false);
    }

    function blankScreen() {
        controller.host.run("sleep 0.25 && ~/.config/warmind/launcher/bin/warmind-hypr dpms-off");
        controller.close();
    }

    function resetDisplay() {
        controller.warmthK = 6500;
        controller.gammaPct = 100;
        controller.brightnessPct = 100;
        const cmds = [];
        if (controller.hyprsunsetAvailable) {
            cmds.push("hyprctl hyprsunset identity");
            cmds.push("hyprctl hyprsunset gamma 100");
        }
        if (controller.brightnessAvailable)
            cmds.push("brightnessctl set 100%");
        if (!cmds.length) return;
        const prelude = controller.hyprsunsetAvailable && !controller.sunsetReady ? controller.ensureSunset : "";
        controller.host.run(prelude + cmds.join(" && "));
        if (controller.hyprsunsetAvailable) controller.sunsetReady = true;
        controller.showOsd("brightness", "DISPLAY", 100, 100, "RESET", false);
    }

    function openMonitorConfig() {
        controller.close();
        controller.host.run("~/.config/warmind/launcher/bin/setup-editor-launcher.sh 'Warmind Setup: Monitors' ~/.config/hypr/lua/core/monitors.lua");
    }

    function refreshAll() {
        displayProbe.running = false;
        displayProbe.running = true;
    }

    Process {
        id: displayProbe
        running: false
        command: ["bash", "-lc",
            "hs=0; command -v hyprsunset >/dev/null 2>&1 && hs=1;"
            + " bs=0; command -v brightnessctl >/dev/null 2>&1 && bs=1;"
            + " m=$(hyprctl monitors -j 2>/dev/null"
            + " | jq -r '.[0] | [.name,(\"\\(.width)x\\(.height)\"),(.refreshRate|tostring),(.scale|tostring)] | join(\"|\")' 2>/dev/null);"
            + " pct=100;"
            + " if [ \"$bs\" -eq 1 ]; then"
            + "   b=$(brightnessctl get 2>/dev/null || true);"
            + "   mb=$(brightnessctl max 2>/dev/null || true);"
            + "   if [ -n \"$b\" ] && [ -n \"$mb\" ] && [ \"$mb\" -gt 0 ]; then pct=$(( b * 100 / mb )); fi;"
            + " fi;"
            + " printf '%s|%d|%d|%d' \"$m\" \"$pct\" \"$hs\" \"$bs\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split("|");
                if (p.length < 7) return;
                controller.monitorName = p[0] || "eDP-1";
                controller.monitorRes = p[1] || "2880x1800";
                controller.monitorRate = parseFloat(p[2]) || 60.0;
                controller.monitorScale = parseFloat(p[3]) || 1.0;
                controller.brightnessPct = parseInt(p[4]) || 100;
                controller.hyprsunsetAvailable = parseInt(p[5]) === 1;
                controller.brightnessAvailable = parseInt(p[6]) === 1;
                controller.displayRow = Math.max(0, Math.min(controller.maxRowIndex(), controller.displayRow));
            }
        }
    }
}
