import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: controller

    property bool active: false
    property bool ready: false
    property bool refreshing: false
    property bool stale: false
    property string lastError: ""

    property string email: ""
    property string planType: ""
    property real primaryPercent: 0
    property string primaryLabel: ""
    property string primaryResetsAt: ""
    property real secondaryPercent: 0
    property string secondaryLabel: ""
    property string secondaryResetsAt: ""
    property bool hasSecondary: false
    property real creditsBalance: 0
    property bool creditsUnlimited: false
    property bool hasCredits: false
    property int todayTokens: 0
    property var recentDays: []
    property real lifetimeTokens: 0
    property real peakDailyTokens: 0
    property int currentStreakDays: 0
    property int longestStreakDays: 0
    property string fetchedAt: ""

    readonly property string fetcherScriptPath: Quickshell.env("HOME")
        + "/.config/warmind/launcher/bin/codex-usage.py"

    function open() {
        controller.active = true;
        controller.refresh();
    }

    function close() {
        controller.active = false;
    }

    function toggle() {
        if (controller.active)
            controller.close();
        else
            controller.open();
    }

    function refresh() {
        if (fetcher.running)
            return;
        controller.refreshing = true;
        controller.lastError = "";
        fetcher.command = ["python3", controller.fetcherScriptPath];
        fetcher.running = false;
        fetcher.running = true;
    }

    function formatPercent(n) {
        if (n === null || n === undefined || isNaN(Number(n)))
            return "—";
        return Math.round(Number(n)) + "%";
    }

    function formatTokenCount(n) {
        const value = Number(n) || 0;
        if (value >= 1e9) return (value / 1e9).toFixed(1) + "B";
        if (value >= 1e6) return (value / 1e6).toFixed(1) + "M";
        if (value >= 1e3) return (value / 1e3).toFixed(1) + "K";
        return String(Math.round(value));
    }

    function planLabel() {
        const t = String(controller.planType || "").trim();
        if (!t.length) return "PLAN";
        return t.replace(/_/g, " ").toUpperCase();
    }

    function formatWhen(iso) {
        const value = String(iso || "");
        if (!value.length) return "—";
        const d = new Date(value);
        if (isNaN(d.getTime())) return value;
        const now = new Date();
        const sameYear = d.getFullYear() === now.getFullYear();
        const opts = sameYear
            ? { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" }
            : { year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" };
        try {
            return d.toLocaleString(undefined, opts);
        } catch (_) {
            return d.toISOString();
        }
    }

    function resetsInLabel(iso) {
        const value = String(iso || "");
        if (!value.length) return "";
        const end = new Date(value);
        if (isNaN(end.getTime())) return "";
        const ms = end.getTime() - Date.now();
        if (ms <= 0) return "RESET DUE";
        const mins = Math.floor(ms / 60000);
        if (mins < 60) return mins + "M LEFT";
        const hours = Math.floor(mins / 60);
        if (hours < 48) return hours + "H LEFT";
        const days = Math.floor(hours / 24);
        return days + "D LEFT";
    }

    function weekMaxTokens() {
        let max = 1;
        const days = controller.recentDays || [];
        for (let i = 0; i < days.length; i++) {
            const count = Number(days[i].tokens || 0);
            if (count > max) max = count;
        }
        return max;
    }

    function headlinePercent() {
        if (controller.primaryPercent !== null && controller.primaryPercent !== undefined
            && !isNaN(Number(controller.primaryPercent)))
            return Number(controller.primaryPercent);
        if (controller.hasSecondary)
            return Number(controller.secondaryPercent) || 0;
        return 0;
    }

    function applyUsage(content) {
        try {
            const data = JSON.parse(String(content || "{}"));
            controller.ready = data.ready === true;
            controller.stale = data.stale === true;
            controller.email = String(data.email || "");
            controller.planType = String(data.planType || "");
            controller.primaryPercent = data.primaryPercent === null || data.primaryPercent === undefined
                ? NaN : Number(data.primaryPercent);
            controller.primaryLabel = String(data.primaryLabel || "");
            controller.primaryResetsAt = String(data.primaryResetsAt || "");
            controller.secondaryPercent = data.secondaryPercent === null || data.secondaryPercent === undefined
                ? NaN : Number(data.secondaryPercent);
            controller.secondaryLabel = String(data.secondaryLabel || "");
            controller.secondaryResetsAt = String(data.secondaryResetsAt || "");
            controller.hasSecondary = data.secondaryPercent !== null && data.secondaryPercent !== undefined
                && !isNaN(Number(data.secondaryPercent));
            controller.creditsBalance = Number(data.creditsBalance || 0);
            controller.creditsUnlimited = data.creditsUnlimited === true;
            controller.hasCredits = data.hasCredits === true;
            controller.todayTokens = Math.max(0, Number(data.todayTokens || 0));
            controller.recentDays = Array.isArray(data.recentDays) ? data.recentDays : [];
            controller.lifetimeTokens = Math.max(0, Number(data.lifetimeTokens || 0));
            controller.peakDailyTokens = Math.max(0, Number(data.peakDailyTokens || 0));
            controller.currentStreakDays = Math.max(0, Number(data.currentStreakDays || 0));
            controller.longestStreakDays = Math.max(0, Number(data.longestStreakDays || 0));
            controller.fetchedAt = String(data.fetchedAt || "");
            controller.lastError = String(data.error || "");
            if (!controller.ready && !controller.lastError.length)
                controller.lastError = "Usage not available";
        } catch (e) {
            controller.ready = false;
            controller.stale = false;
            controller.lastError = "Failed to parse Codex usage";
        }
    }

    Timer {
        interval: 300000
        repeat: true
        running: controller.active
        onTriggered: controller.refresh()
    }

    Process {
        id: fetcher
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
                if (err.length > 0 && !controller.ready)
                    controller.lastError = err;
            }
        }
        onExited: function() {
            controller.refreshing = false;
        }
    }
}
