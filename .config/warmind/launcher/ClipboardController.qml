import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: controller

    property bool active: false
    property bool running: loadProc.running
    property string query: ""
    property string lastError: ""
    property var items: []
    property int selected: 0
    property string notice: ""
    property string copiedKey: ""
    property int _gen: 0

    readonly property string historyPath: Quickshell.env("HOME") + "/.config/clipse/clipboard_history.json"
    readonly property int maxItems: 80

    readonly property var filteredItems: {
        const q = String(controller.query || "").trim().toLowerCase();
        if (!q.length) return controller.items;
        const tokens = q.split(/\s+/).filter(function(t) { return t.length > 0; });
        return controller.items.filter(function(item) {
            const hay = String(item.searchText || "");
            return tokens.every(function(t) { return hay.indexOf(t) >= 0; });
        });
    }

    readonly property var selectedItem: {
        const rows = controller.filteredItems;
        if (!rows || rows.length === 0) return null;
        const idx = Math.max(0, Math.min(controller.selected, rows.length - 1));
        return rows[idx] || null;
    }

    onFilteredItemsChanged: {
        if (controller.selected >= controller.filteredItems.length)
            controller.selected = Math.max(0, controller.filteredItems.length - 1);
    }

    function open() {
        controller.active = true;
        controller.query = "";
        controller.selected = 0;
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
        controller._gen += 1;
        controller.lastError = "";
        loadProc.gen = controller._gen;
        loadProc.running = false;
        loadProc.running = true;
    }

    function move(delta) {
        const len = controller.filteredItems.length;
        if (len <= 0) return;
        controller.selected = Math.max(0, Math.min(len - 1, controller.selected + delta));
    }

    function typeIcon(kind) {
        if (kind === "image") return "󰋩";
        if (kind === "file") return "󰈔";
        return "󰅌";
    }

    function extension(path) {
        const p = String(path || "").toLowerCase();
        const dot = p.lastIndexOf(".");
        return dot >= 0 ? p.substring(dot + 1) : "";
    }

    function hasRealFilePath(path) {
        if (path === null || path === undefined) return false;
        const text = String(path).trim();
        return text.length > 0 && text.toLowerCase() !== "null";
    }

    function isImagePath(path) {
        const ext = controller.extension(path);
        return ["png", "jpg", "jpeg", "webp", "gif", "bmp", "avif"].indexOf(ext) >= 0;
    }

    function isImageMarker(value) {
        const text = String(value || "").trim();
        const lower = text.toLowerCase();
        return text.indexOf("📷 ") === 0
            || lower.indexOf("<img") >= 0
            || lower.indexOf("data:image/") >= 0
            || (lower.indexOf("content-type") >= 0 && lower.indexOf("image/") >= 0);
    }

    function basename(path) {
        const p = String(path || "");
        const idx = p.lastIndexOf("/");
        return idx >= 0 ? p.substring(idx + 1) : p;
    }

    function firstTextLine(text) {
        const lines = String(text || "").split(/\r?\n/);
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].replace(/\s+/g, " ").trim();
            if (line.length > 0)
                return line.length > 92 ? line.substring(0, 92) + "..." : line;
        }
        return "(empty)";
    }

    function relativeTime(recorded) {
        const value = String(recorded || "");
        const m = value.match(/^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})/);
        if (!m) return value;
        const d = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]), Number(m[4]), Number(m[5]), Number(m[6]));
        const ms = Date.now() - d.getTime();
        if (ms < 0) return value;
        const min = Math.floor(ms / 60000);
        if (min < 1) return "now";
        if (min < 60) return min + "m ago";
        const h = Math.floor(min / 60);
        if (h < 24) return h + "h ago";
        const days = Math.floor(h / 24);
        if (days < 7) return days + "d ago";
        return value.substring(0, 10);
    }

    function kindFor(entry) {
        if (!entry) return "unknown";
        const path = entry.filePath;
        if (controller.hasRealFilePath(path))
            return controller.isImagePath(path) || controller.isImageMarker(entry.value) ? "image" : "file";
        return typeof entry.value === "string" ? "text" : "unknown";
    }

    function buildItems(history) {
        const out = [];
        for (let i = 0; i < history.length && out.length < controller.maxItems; i++) {
            const entry = history[i];
            if (!entry || typeof entry !== "object") continue;
            const kind = controller.kindFor(entry);
            if (kind === "unknown") continue;
            const path = controller.hasRealFilePath(entry.filePath) ? String(entry.filePath) : "";
            const text = String(entry.value || "");
            const title = kind === "text" ? controller.firstTextLine(text) : controller.basename(path || text);
            const recorded = String(entry.recorded || "");
            const key = kind + "|" + (path || text) + "|" + recorded;
            out.push({
                key: key,
                title: title,
                value: text,
                fullText: text,
                path: path,
                kind: kind,
                icon: controller.typeIcon(kind),
                recorded: recorded,
                relative: controller.relativeTime(recorded),
                pinned: entry.pinned === true,
                searchText: (title + " " + text + " " + path + " " + kind).toLowerCase()
            });
        }
        return out;
    }

    function copyItem(item) {
        if (!item) return;
        if (item.kind === "image" && item.path.length > 0) {
            const mime = controller.extension(item.path) === "webp" ? "image/webp"
                : controller.extension(item.path) === "jpg" || controller.extension(item.path) === "jpeg" ? "image/jpeg"
                : "image/png";
            copyProc.command = ["sh", "-c", "wl-copy -t \"$1\" < \"$2\"", "sh", mime, item.path];
        } else if (item.kind === "file" && item.path.length > 0) {
            copyProc.command = ["wl-copy", "--", item.path];
        } else {
            copyProc.command = ["wl-copy", "--", item.fullText || ""];
        }
        copyProc.running = false;
        copyProc.running = true;
        controller.copiedKey = item.key;
        controller.notice = item.kind === "image" ? "IMAGE COPIED" : item.kind === "file" ? "PATH COPIED" : "TEXT COPIED";
        noticeReset.restart();
    }

    function pasteItem(item) {
        if (!item) return;
        controller.copyItem(item);
        pasteTimer.restart();
    }

    function openItem(item) {
        if (!item || !item.path.length) return;
        openProc.command = ["xdg-open", item.path];
        openProc.running = false;
        openProc.running = true;
        controller.notice = "OPENED";
        noticeReset.restart();
    }

    function selectedCopy() { controller.copyItem(controller.selectedItem); }
    function selectedPaste() { controller.pasteItem(controller.selectedItem); }
    function selectedOpen() { controller.openItem(controller.selectedItem); }

    Process {
        id: loadProc
        running: false
        command: ["sh", "-c", "cat \"$1\"", "sh", controller.historyPath]
        property int gen: 0
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (loadProc.gen !== controller._gen) return;
                try {
                    const parsed = JSON.parse(this.text || "{}");
                    const history = Array.isArray(parsed.clipboardHistory)
                        ? parsed.clipboardHistory
                        : (Array.isArray(parsed) ? parsed : []);
                    controller.items = controller.buildItems(history);
                    controller.selected = controller.filteredItems.length > 0 ? 0 : -1;
                    controller.lastError = "";
                } catch (e) {
                    controller.items = [];
                    controller.selected = -1;
                    controller.lastError = "Failed to parse Clipse history";
                }
            }
        }
        onExited: function(code) {
            if (loadProc.gen !== controller._gen) return;
            if (code !== 0) {
                controller.items = [];
                controller.selected = -1;
                controller.lastError = "Clipse history unavailable";
            }
        }
    }

    Process { id: copyProc; running: false }
    Process { id: openProc; running: false }
    Process { id: pasteProc; running: false }

    Timer {
        id: pasteTimer
        interval: 80
        repeat: false
        onTriggered: {
            pasteProc.command = ["sh", "-c", "command -v wtype >/dev/null 2>&1 && wtype -M ctrl -P v -p v -m ctrl || true"];
            pasteProc.running = false;
            pasteProc.running = true;
            controller.close();
        }
    }

    Timer {
        id: noticeReset
        interval: 1200
        repeat: false
        onTriggered: {
            controller.notice = "";
            controller.copiedKey = "";
        }
    }
}
