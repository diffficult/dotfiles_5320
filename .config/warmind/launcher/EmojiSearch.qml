import QtQuick
import Quickshell.Io

// Emoji + symbol picker with group/subgroup filtering.
//
// Query syntax:
//   @group   — restrict to groups containing "group" (e.g. @font → nerd-font,
//              @smileys → Smileys & Emotion, @git → gitmoji)
//   #sub     — restrict to subgroups containing "sub" (e.g. #fa → nf-fa,
//              #md → nf-md, #cod → nf-cod)
//   word     — filter name + keywords by the remaining tokens
//
// Examples:
//   @font             → all nerd-font icons
//   @font #fa         → Font Awesome icons only
//   @font #fa address → Font Awesome icons whose name contains "address"
//   smile             → any emoji/symbol with "smile" in name or keywords
//   @git improve      → gitmoji entries containing "improve"
//
// Enter       = copy char to clipboard via wl-copy
// Ctrl+Enter  = type char into focused window via wtype (palette closes first)
Item {
    id: root

    required property string query
    property var allItems: []
    property var items:    []
    property int selectedIndex: 0
    property bool loaded: false
    property string loadError: ""

    signal itemActivated(var item)

    // ── Query parsing ─────────────────────────────────────────────────
    // Returns { groupFilters: [], subFilters: [], textFilters: [] }
    function parseQuery(q) {
        var tokens = q.trim().toLowerCase().split(/\s+/).filter(function(t) { return t.length > 0 })
        var gf = [], sf = [], tf = []
        for (var i = 0; i < tokens.length; i++) {
            var t = tokens[i]
            if (t.charAt(0) === "@") gf.push(t.slice(1))
            else if (t.charAt(0) === "#") sf.push(t.slice(1))
            else tf.push(t)
        }
        return { groupFilters: gf, subFilters: sf, textFilters: tf }
    }

    // ── Keyboard ──────────────────────────────────────────────────────
    function kbdHandle(event) {
        if (event.key === Qt.Key_Up) {
            selectedIndex = Math.max(0, selectedIndex - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            selectedIndex = Math.min(items.length - 1, selectedIndex + 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            var it = items[selectedIndex]
            if (!it) return
            if (event.modifiers & Qt.ControlModifier)
                typeChar(it)
            else
                copyChar(it)
            event.accepted = true
        }
    }

    function copyChar(item) {
        copyProc.command = ["wl-copy", "--", item.char]
        copyProc.running = false
        copyProc.running = true
        itemActivated(item)
    }

    function typeChar(item) {
        itemActivated(item)   // closes palette so focus returns to target
        typeTimer.pendingChar = item.char
        typeTimer.start()
    }

    // ── Filtering ─────────────────────────────────────────────────────
    onQueryChanged: filterItems()

    function filterItems() {
        if (!loaded) return
        var parsed = parseQuery(query)
        var gf = parsed.groupFilters
        var sf = parsed.subFilters
        var tf = parsed.textFilters
        var hasFilter = gf.length > 0 || sf.length > 0 || tf.length > 0

        if (!hasFilter) {
            // Empty query: show first 300 (a mix of emoji then nerd-font)
            items = allItems.slice(0, 300)
            selectedIndex = 0
            return
        }

        var result = []
        for (var i = 0; i < allItems.length && result.length < 300; i++) {
            var it = allItems[i]

            // Group filter: all @tokens must match
            if (gf.length > 0) {
                var groupLow = it.group.toLowerCase()
                var gMatch = true
                for (var g = 0; g < gf.length; g++) {
                    if (groupLow.indexOf(gf[g]) < 0) { gMatch = false; break }
                }
                if (!gMatch) continue
            }

            // Subgroup filter: all #tokens must match
            if (sf.length > 0) {
                var subLow = it.subgroup.toLowerCase()
                var sMatch = true
                for (var s = 0; s < sf.length; s++) {
                    if (subLow.indexOf(sf[s]) < 0) { sMatch = false; break }
                }
                if (!sMatch) continue
            }

            // Text filter: all remaining tokens must appear in name+keywords
            if (tf.length > 0) {
                var hay = it.searchText
                var tMatch = true
                for (var t = 0; t < tf.length; t++) {
                    if (hay.indexOf(tf[t]) < 0) { tMatch = false; break }
                }
                if (!tMatch) continue
            }

            result.push(it)
        }
        items = result
        selectedIndex = 0
    }

    // ── Data loading ──────────────────────────────────────────────────
    Component.onCompleted: {
        if (!loaded) loadProc.running = true
    }

    Process {
        id: loadProc
        // Parse all 5 fields: char, group, subgroup, name, keywords
        command: [
            "python3", "-c",
            "import sys, json, os\n"
            + "path = os.path.expanduser('~/.local/share/data/rofi-emoji/all_emojis.txt')\n"
            + "try:\n"
            + "  with open(path, encoding='utf-8') as f:\n"
            + "    for line in f:\n"
            + "      line = line.rstrip('\\n')\n"
            + "      if not line: continue\n"
            + "      p = line.split('\\t')\n"
            + "      c  = p[0]\n"
            + "      g  = p[1] if len(p) > 1 else ''\n"
            + "      sg = p[2] if len(p) > 2 else ''\n"
            + "      n  = p[3] if len(p) > 3 else ''\n"
            + "      kw = p[4] if len(p) > 4 else ''\n"
            + "      print(json.dumps({'c':c,'g':g,'sg':sg,'n':n,'k':kw}))\n"
            + "except Exception as e:\n"
            + "  sys.stderr.write(str(e)+'\\n')\n"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n")
                var parsed = []
                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue
                    try {
                        var obj = JSON.parse(lines[i])
                        // Prefer source subgroup as the compact row badge:
                        // nf-fa → FA, nf-md → MD. Entries without a
                        // subgroup fall back to their dataset group.
                        var sourceLabel = obj.sg
                            ? obj.sg.replace(/^nf-/, "")
                            : (obj.g || "Emoji")
                        parsed.push({
                            char:       obj.c,
                            group:      obj.g,
                            subgroup:   obj.sg,
                            // Pre-lowercased search blob
                            searchText: (obj.n + " " + obj.k).toLowerCase(),
                            // Display
                            title:      obj.c + "  " + obj.n,
                            subtitle:   obj.g + (obj.sg ? " · " + obj.sg : ""),
                            icon:       "",
                            keywords:        obj.n + " " + obj.k,
                            category:        "Emoji",
                            displayCategory: sourceLabel,
                            exec:            ""
                        })
                    } catch(e) {}
                }
                root.allItems = parsed
                root.loaded = true
                root.loadError = parsed.length > 0 ? "" : "EMOJI DATA UNAVAILABLE"
                root.filterItems()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                var msg = (this.text || "").trim()
                if (msg.length > 0)
                    root.loadError = "EMOJI DATA UNAVAILABLE"
            }
        }
        onExited: (code) => {
            if (code !== 0 && root.loadError === "")
                root.loadError = "EMOJI DATA UNAVAILABLE"
        }
    }

    Process { id: copyProc }

    Timer {
        id: typeTimer
        property string pendingChar: ""
        interval: 600
        repeat: false
        onTriggered: {
            typeProc.command = ["wtype", "--", pendingChar]
            typeProc.running = false
            typeProc.running = true
        }
    }

    Process { id: typeProc }
}
