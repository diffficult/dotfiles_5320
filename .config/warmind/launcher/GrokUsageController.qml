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

    property real percent: 0
    property string periodType: ""
    property string periodStart: ""
    property string periodEnd: ""
    property var products: []
    property real prepaidBalance: 0
    property real onDemandUsed: 0
    property real onDemandCap: 0
    property bool isUnifiedBillingUser: false
    property string fetchedAt: ""

    readonly property string fetcherScriptPath: Quickshell.env("HOME")
        + "/.config/warmind/launcher/bin/grok-usage.py"

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

    function periodLabel() {
        const t = String(controller.periodType || "");
        if (t.indexOf("WEEKLY") >= 0)
            return "WEEKLY";
        if (t.indexOf("MONTHLY") >= 0)
            return "MONTHLY";
        if (t.indexOf("DAILY") >= 0)
            return "DAILY";
        if (!t.length)
            return "PERIOD";
        return t.replace(/^USAGE_PERIOD_TYPE_/, "").replace(/_/g, " ");
    }

    function formatWhen(iso) {
        const value = String(iso || "");
        if (!value.length)
            return "—";
        const d = new Date(value);
        if (isNaN(d.getTime()))
            return value;
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

    function resetsInLabel() {
        const value = String(controller.periodEnd || "");
        if (!value.length)
            return "";
        const end = new Date(value);
        if (isNaN(end.getTime()))
            return "";
        const ms = end.getTime() - Date.now();
        if (ms <= 0)
            return "RESET DUE";
        const mins = Math.floor(ms / 60000);
        if (mins < 60)
            return mins + "M LEFT";
        const hours = Math.floor(mins / 60);
        if (hours < 48)
            return hours + "H LEFT";
        const days = Math.floor(hours / 24);
        return days + "D LEFT";
    }

    function barColor() {
        const p = Number(controller.percent) || 0;
        if (p >= 90)
            return controller._warnColor();
        if (p >= 70)
            return controller._accentColor();
        return controller._okColor();
    }

    // Fallback palette if parent theme not yet wired into helpers.
    function _warnColor() { return "#f38ba8"; }
    function _accentColor() { return "#fab387"; }
    function _okColor() { return "#a6e3a1"; }

    function productRows() {
        const list = controller.products || [];
        if (!Array.isArray(list))
            return [];
        return list;
    }

    function applyUsage(content) {
        try {
            const data = JSON.parse(String(content || "{}"));
            controller.ready = data.ready === true;
            controller.stale = data.stale === true;
            controller.percent = Math.max(0, Number(data.percent || 0));
            controller.periodType = String(data.periodType || "");
            controller.periodStart = String(data.periodStart || "");
            controller.periodEnd = String(data.periodEnd || "");
            controller.products = Array.isArray(data.products) ? data.products : [];
            controller.prepaidBalance = Number(data.prepaidBalance || 0);
            controller.onDemandUsed = Number(data.onDemandUsed || 0);
            controller.onDemandCap = Number(data.onDemandCap || 0);
            controller.isUnifiedBillingUser = data.isUnifiedBillingUser === true;
            controller.fetchedAt = String(data.fetchedAt || "");
            controller.lastError = String(data.error || "");
            if (!controller.ready && !controller.lastError.length)
                controller.lastError = "Usage not available";
        } catch (e) {
            controller.ready = false;
            controller.stale = false;
            controller.lastError = "Failed to parse Grok usage";
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
