import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: controller

    property bool active: false
    property bool ready: false
    property bool refreshing: false
    property bool hasLocalStats: false
    property string lastError: ""
    property string dbPath: "~/.local/share/opencode/opencode.db"

    property int todayPrompts: 0
    property int todaySessions: 0
    property int todayTotalTokens: 0
    property var todayTokensByModel: ({})
    property var recentDays: []
    property int totalPrompts: 0
    property int totalSessions: 0
    property var modelUsage: ({})

    readonly property string scannerScriptPath: Quickshell.env("HOME") + "/.config/warmind/launcher/bin/opencode-usage-scanner.py"

    function open() {
        controller.active = true;
        controller.refresh();
    }

    function close() {
        controller.active = false;
    }

    function toggle() {
        if (controller.active) controller.close();
        else controller.open();
    }

    function refresh() {
        if (scanner.running) return;
        controller.refreshing = true;
        controller.lastError = "";
        scanner.command = ["python3", controller.scannerScriptPath, controller.resolvePath(controller.dbPath)];
        scanner.running = false;
        scanner.running = true;
    }

    function resolvePath(path) {
        const value = String(path || "");
        if (value.startsWith("~"))
            return (Quickshell.env("HOME") || "") + value.substring(1);
        return value;
    }

    function formatTokenCount(n) {
        const value = Number(n) || 0;
        if (value >= 1e9) return (value / 1e9).toFixed(1) + "B";
        if (value >= 1e6) return (value / 1e6).toFixed(1) + "M";
        if (value >= 1e3) return (value / 1e3).toFixed(1) + "K";
        return String(Math.round(value));
    }

    function friendlyModelName(id) {
        const value = String(id || "");
        if (!value.length) return "Unknown";
        if (value.charAt(0) === "{") {
            try {
                const parsed = JSON.parse(value);
                const modelId = String(parsed.id || "");
                const provider = String(parsed.providerID || "");
                if (modelId && provider) return modelId + " (" + provider + ")";
                if (modelId) return modelId;
            } catch (_) {}
        }
        return value;
    }

    function modelEntries(map) {
        const source = map || ({});
        const out = [];
        for (const key in source) {
            if (!Object.prototype.hasOwnProperty.call(source, key)) continue;
            out.push({ modelId: key, value: source[key] });
        }
        out.sort(function(a, b) {
            const av = typeof a.value === "number" ? a.value : Number((a.value && a.value.inputTokens) || 0)
                + Number((a.value && a.value.outputTokens) || 0)
                + Number((a.value && a.value.cacheReadInputTokens) || 0)
                + Number((a.value && a.value.cacheCreationInputTokens) || 0);
            const bv = typeof b.value === "number" ? b.value : Number((b.value && b.value.inputTokens) || 0)
                + Number((b.value && b.value.outputTokens) || 0)
                + Number((b.value && b.value.cacheReadInputTokens) || 0)
                + Number((b.value && b.value.cacheCreationInputTokens) || 0);
            return bv - av;
        });
        return out;
    }

    function weekMaxTokens() {
        let max = 1;
        const days = controller.recentDays || [];
        for (let i = 0; i < days.length; i++) {
            const count = Number(days[i].messageCount || 0);
            if (count > max) max = count;
        }
        return max;
    }

    function applyUsage(content) {
        try {
            const data = JSON.parse(String(content || "{}"));
            controller.ready = data.ready === true;
            controller.hasLocalStats = data.hasLocalStats !== false && controller.ready;
            controller.todayPrompts = Math.max(0, Number(data.todayPrompts || 0));
            controller.todaySessions = Math.max(0, Number(data.todaySessions || 0));
            controller.todayTotalTokens = Math.max(0, Number(data.todayTotalTokens || 0));
            controller.todayTokensByModel = data.todayTokensByModel || ({});
            controller.recentDays = Array.isArray(data.recentDays) ? data.recentDays : [];
            controller.modelUsage = data.modelUsage || ({});
            controller.totalPrompts = Math.max(0, Number(data.totalPrompts || 0));
            controller.totalSessions = Math.max(0, Number(data.totalSessions || 0));
            if (!controller.ready)
                controller.lastError = "Scanner not ready";
            else
                controller.lastError = "";
        } catch (e) {
            controller.ready = false;
            controller.hasLocalStats = false;
            controller.lastError = "Failed to parse OpenCode usage";
        }
    }

    Timer {
        interval: 300000
        repeat: true
        running: controller.active
        onTriggered: controller.refresh()
    }

    Process {
        id: scanner
        running: false
        command: []
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: controller.applyUsage(text)
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: function() {
                const err = String(text || "").trim();
                if (err.length > 0)
                    controller.lastError = err;
            }
        }
        onExited: function() {
            controller.refreshing = false;
        }
    }
}
