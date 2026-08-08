import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property string query
    required property bool active
    property var allItems: []
    property var items: []
    property int selectedIndex: 0

    signal itemActivated(var item)

    function kbdHandle(event) {
        if (event.key === Qt.Key_Up) {
            selectedIndex = Math.max(0, selectedIndex - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            selectedIndex = Math.min(items.length - 1, selectedIndex + 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (items[selectedIndex]) activate(items[selectedIndex])
            event.accepted = true
        }
    }

    function activate(item) {
        if (!item) return
        var helper = (Quickshell.env("HOME") || "") + "/.config/warmind/launcher/bin/warmind-hypr"
        var workspaceName = item.workspaceName || ""
        var cmd = workspaceName
            ? helper + " workspace " + JSON.stringify(workspaceName)
                + " >/dev/null 2>&1; " + helper + " focus-address "
                + JSON.stringify(item.address)
            : helper + " focus-address " + JSON.stringify(item.address)
        switchProc.command = ["zsh", "-c", cmd]
        switchProc.running = false
        switchProc.running = true
        itemActivated(item)
    }

    onQueryChanged: _applyFilter()
    onActiveChanged: if (active) refresh()
    Component.onCompleted: if (active) refresh()

    Process {
        id: listProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var clients = JSON.parse(this.text)
                    root.allItems = clients.map(function(c) {
                        var wsName = c.workspace ? String(c.workspace.name || c.workspace.id || "?") : "?"
                        var title = c.title || c.initialTitle || c.class || "(untitled)"
                        var className = c.class || "unknown"
                        var tags = []
                        if (c.floating) tags.push("floating")
                        if (c.fullscreen) tags.push("fullscreen")
                        if (c.pinned) tags.push("pinned")
                        return {
                            address: c.address,
                            workspaceName: wsName,
                            title: title,
                            subtitle: "WS " + wsName + "  ·  " + className + (tags.length ? "  ·  " + tags.join(", ") : ""),
                            icon: "󱂬",
                            category: "Windows",
                            keywords: (title + " " + className + " " + wsName).toLowerCase(),
                            exec: "",
                            className: className
                        }
                    })
                    root._applyFilter()
                } catch (e) {
                    root.allItems = []
                    root.items = []
                    root.selectedIndex = 0
                }
            }
        }
    }

    function _applyFilter() {
        var previous = root.items[root.selectedIndex]
        var previousAddress = previous ? previous.address : ""
        var tokens = (root.query || "").toLowerCase().split(/\s+/).filter(function(t) { return t.length > 0 })
        root.items = root.allItems.filter(function(it) {
            if (tokens.length === 0) return true
            return tokens.every(function(t) { return it.keywords.includes(t) || (it.subtitle || "").toLowerCase().includes(t) })
        })

        if (root.items.length === 0) {
            root.selectedIndex = 0
            return
        }

        if (previousAddress) {
            for (var i = 0; i < root.items.length; i++) {
                if (root.items[i].address === previousAddress) {
                    root.selectedIndex = i
                    return
                }
            }
        }
        root.selectedIndex = Math.max(0, Math.min(root.selectedIndex, root.items.length - 1))
    }

    function refresh() {
        listProc.running = false
        listProc.running = true
    }

    Process { id: switchProc }
}
