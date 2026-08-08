import QtQuick
import Quickshell
import Quickshell.Io

// Clipse-backed clipboard history drill.
//
// Reads ~/.config/clipse/clipboard_history.json on activation, keeps the
// newest 20 text entries, filters them by the launcher query, shows the
// selected item's full text in the preview pane, and restores the entry
// with wl-copy on activation.
Item {
    id: root

    required property string query
    required property bool active
    required property var selectedItem

    readonly property string historyPath: Quickshell.env("HOME") + "/.config/clipse/clipboard_history.json"

    property var allItems: []
    property var items: []
    property string previewText: selectedItem ? (selectedItem.fullText || "") : ""
    property int _gen: 0

    readonly property bool running: loadProc.running

    signal itemActivated(var item)

    function clear() {
        root.allItems = []
        root.items = []
        root._gen += 1
        loadProc.running = false
    }

    function hasRealFilePath(filePath) {
        if (filePath === null || filePath === undefined) return false
        var text = String(filePath).trim().toLowerCase()
        return text !== "" && text !== "null"
    }

    function isImageMarker(value) {
        var text = (value || "").trim()
        if (text.length === 0) return true
        var lower = text.toLowerCase()
        if (text.indexOf("📷 ") === 0) return true
        if (lower.indexOf("<img") >= 0) return true
        if (lower.indexOf("data:image/") >= 0) return true
        if (lower.indexOf("content-type") >= 0 && lower.indexOf("image/") >= 0) return true
        return false
    }

    function isTextEntry(entry) {
        if (!entry || typeof entry.value !== "string") return false
        if (hasRealFilePath(entry.filePath)) return false
        if (isImageMarker(entry.value)) return false
        return true
    }

    function displayTitle(text) {
        var lines = (text || "").split(/\r?\n/)
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].replace(/\s+/g, " ").trim()
            if (line.length > 0)
                return line.length > 88 ? line.substring(0, 88) + "…" : line
        }
        return "(empty)"
    }

    function buildItems(history) {
        var out = []
        for (var i = 0; i < history.length && out.length < 20; i++) {
            var entry = history[i]
            if (!isTextEntry(entry)) continue
            var text = entry.value || ""
            out.push({
                title: displayTitle(text),
                subtitle: entry.recorded || "",
                icon: "󰅌",
                category: "Clipboard",
                keywords: text,
                searchText: text.toLowerCase(),
                fullText: text,
                recorded: entry.recorded || "",
                rawCategory: true,
                rowKind: "clipboard"
            })
        }
        return out
    }

    function filterItems() {
        var tokens = (root.query || "").toLowerCase().split(/\s+/).filter(function(t) { return t.length > 0 })
        if (tokens.length === 0) {
            root.items = root.allItems
            return
        }
        root.items = root.allItems.filter(function(it) {
            return tokens.every(function(t) { return it.searchText.indexOf(t) >= 0 })
        })
    }

    function activate(item) {
        if (!item) return
        copyProc.command = ["wl-copy", "--", item.fullText || ""]
        copyProc.running = false
        copyProc.running = true
        itemActivated(item)
    }

    onQueryChanged: filterItems()

    onActiveChanged: {
        if (!root.active) {
            root.clear()
            return
        }
        root._gen += 1
        loadProc.gen = root._gen
        loadProc.running = false
        loadProc.running = true
    }

    Process {
        id: loadProc
        running: false
        command: ["sh", "-c", "cat \"$1\"", "sh", root.historyPath]
        property int gen: 0
        stdout: StdioCollector {
            onStreamFinished: {
                if (loadProc.gen !== root._gen) return
                try {
                    var parsed = JSON.parse(this.text || "{}")
                    var history = Array.isArray(parsed.clipboardHistory)
                        ? parsed.clipboardHistory
                        : []
                    root.allItems = root.buildItems(history)
                    root.filterItems()
                } catch (_) {
                    root.allItems = []
                    root.items = []
                }
            }
        }
        onExited: function(code) {
            if (loadProc.gen !== root._gen) return
            if (code !== 0) {
                root.allItems = []
                root.items = []
            }
        }
    }

    Process { id: copyProc }
}
