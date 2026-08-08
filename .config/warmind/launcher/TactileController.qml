import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: controller

    property bool active: false
    property var screen: null
    property string windowAddress: ""
    property string windowTitle: ""
    property string monitorName: ""
    property int monitorX: 0
    property int monitorY: 0
    property int monitorWidth: 0
    property int monitorHeight: 0
    // Hyprland monitor `reserved` order is [left, top, right, bottom].
    property int reservedLeft: 0
    property int reservedTop: 0
    property int reservedRight: 0
    property int reservedBottom: 0
    property bool windowFloating: false
    property string firstKey: ""
    property string pendingApplyFirstKey: ""
    property string pendingApplySecondKey: ""
    property var previewKeys: []

    readonly property var letters: ["1", "2", "3", "4", "q", "w", "e", "r", "a", "s", "d", "f", "z", "x", "c", "v"]
    readonly property var keyMap: ({
        "1": { col: 0, row: 0, label: "1" }, "2": { col: 1, row: 0, label: "2" },
        "3": { col: 2, row: 0, label: "3" }, "4": { col: 3, row: 0, label: "4" },
        q: { col: 0, row: 1, label: "Q" }, w: { col: 1, row: 1, label: "W" },
        e: { col: 2, row: 1, label: "E" }, r: { col: 3, row: 1, label: "R" },
        a: { col: 0, row: 2, label: "A" }, s: { col: 1, row: 2, label: "S" },
        d: { col: 2, row: 2, label: "D" }, f: { col: 3, row: 2, label: "F" },
        z: { col: 0, row: 3, label: "Z" }, x: { col: 1, row: 3, label: "X" },
        c: { col: 2, row: 3, label: "C" }, v: { col: 3, row: 3, label: "V" }
    })
    readonly property int gap: 8
    readonly property int outerGap: 12
    readonly property int innerGap: 5
    readonly property int workX: reservedLeft + gap
    readonly property int workY: reservedTop + gap
    readonly property int workWidth: Math.max(320, monitorWidth - reservedLeft - reservedRight - gap * 2)
    readonly property int workHeight: Math.max(240, monitorHeight - reservedTop - reservedBottom - gap * 2)
    readonly property int workAbsX: monitorX + workX
    readonly property int workAbsY: monitorY + workY
    readonly property var cells: buildCells()

    function screenForName(name) {
        const screens = Quickshell.screens || [];
        for (let i = 0; i < screens.length; i++) {
            const current = screens[i];
            if (current && current.name === name) return current;
        }
        return screens.length > 0 ? screens[0] : null;
    }

    function spanStart(index, totalSize) {
        return Math.round(totalSize * index / 4);
    }

    function spanSize(index, totalSize) {
        return spanStart(index + 1, totalSize) - spanStart(index, totalSize);
    }

    function selectionInsets(minCol, maxCol, minRow, maxRow) {
        const innerHalfLow = Math.floor(innerGap / 2);
        const innerHalfHigh = innerGap - innerHalfLow;
        return {
            left: minCol === 0 ? outerGap : innerHalfLow,
            right: maxCol === 3 ? outerGap : innerHalfHigh,
            top: minRow === 0 ? 0 : innerHalfLow,
            bottom: maxRow === 3 ? outerGap : innerHalfHigh
        };
    }

    function buildCells() {
        const out = [];
        for (let i = 0; i < letters.length; i++) {
            const key = letters[i];
            const meta = keyMap[key];
            const baseX = workX + spanStart(meta.col, workWidth);
            const baseY = workY + spanStart(meta.row, workHeight);
            const baseWidth = spanSize(meta.col, workWidth);
            const baseHeight = spanSize(meta.row, workHeight);
            const insets = selectionInsets(meta.col, meta.col, meta.row, meta.row);
            out.push({
                key: key,
                label: meta.label,
                col: meta.col,
                row: meta.row,
                x: baseX + insets.left,
                y: baseY + insets.top,
                width: Math.max(40, baseWidth - insets.left - insets.right),
                height: Math.max(30, baseHeight - insets.top - insets.bottom)
            });
        }
        return out;
    }

    function keysBetween(a, b) {
        const first = keyMap[a];
        const second = keyMap[b];
        if (!first || !second) return [];
        const minCol = Math.min(first.col, second.col);
        const maxCol = Math.max(first.col, second.col);
        const minRow = Math.min(first.row, second.row);
        const maxRow = Math.max(first.row, second.row);
        const out = [];
        for (let i = 0; i < letters.length; i++) {
            const key = letters[i];
            const meta = keyMap[key];
            if (meta.col >= minCol && meta.col <= maxCol && meta.row >= minRow && meta.row <= maxRow)
                out.push(key);
        }
        return out;
    }

    function resetSelection() {
        applyPreviewTimer.stop();
        firstKey = "";
        pendingApplyFirstKey = "";
        pendingApplySecondKey = "";
        previewKeys = [];
    }

    function close() {
        active = false;
        resetSelection();
    }

    function toggle() {
        if (active) close();
        else open();
    }

    function open() {
        openProc.running = false;
        openProc.running = true;
    }

    function selectKey(key) {
        if (!(key in keyMap)) return;
        if (applyPreviewTimer.running) return;
        if (firstKey === "") {
            firstKey = key;
            previewKeys = [key];
            return;
        }
        previewKeys = keysBetween(firstKey, key);
        pendingApplyFirstKey = firstKey;
        pendingApplySecondKey = key;
        applyPreviewTimer.restart();
    }

    Timer {
        id: applyPreviewTimer
        interval: 140
        repeat: false
        onTriggered: controller.applySelection(controller.pendingApplyFirstKey, controller.pendingApplySecondKey)
    }

    function applySelection(firstSelectionKey, secondSelectionKey) {
        const first = keyMap[firstSelectionKey];
        const second = keyMap[secondSelectionKey];
        if (!first || !second || windowAddress.length === 0) {
            close();
            return;
        }
        const minCol = Math.min(first.col, second.col);
        const maxCol = Math.max(first.col, second.col);
        const minRow = Math.min(first.row, second.row);
        const maxRow = Math.max(first.row, second.row);
        const baseX = workAbsX + spanStart(minCol, workWidth);
        const baseY = workAbsY + spanStart(minRow, workHeight);
        const baseWidth = spanStart(maxCol + 1, workWidth) - spanStart(minCol, workWidth);
        const baseHeight = spanStart(maxRow + 1, workHeight) - spanStart(minRow, workHeight);
        const insets = selectionInsets(minCol, maxCol, minRow, maxRow);
        const x = baseX + insets.left;
        const y = baseY + insets.top;
        const width = Math.max(120, baseWidth - insets.left - insets.right);
        const height = Math.max(80, baseHeight - insets.top - insets.bottom);
        const target = "address:" + windowAddress;

        close();
        const prepLua = "local w = " + JSON.stringify(target) + "; "
            + "hl.dispatch(hl.dsp.window.fullscreen({ mode = 'fullscreen', action = 'unset', window = w })); "
            + "hl.dispatch(hl.dsp.window.fullscreen({ mode = 'maximized', action = 'unset', window = w })); "
            + (windowFloating ? "" : "hl.dispatch(hl.dsp.window.float({ action = 'set', window = w })); ");
        const geometryLua = "local w = " + JSON.stringify(target) + "; "
            + "hl.dispatch(hl.dsp.window.resize({ x = " + width + ", y = " + height + ", relative = false, window = w })); "
            + "hl.dispatch(hl.dsp.window.move({ x = " + x + ", y = " + y + ", relative = false, window = w }))";
        runCommand("hyprctl eval " + shellQuote(prepLua)
            + "; sleep 0.08; hyprctl eval " + shellQuote(geometryLua));
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function runCommand(cmd) {
        runner.command = ["bash", "-lc", cmd];
        runner.running = false;
        runner.running = true;
    }

    Process { id: runner; running: false }

    Process {
        id: openProc
        running: false
        command: ["bash", "-lc",
            "active=$(hyprctl activewindow -j 2>/dev/null);"
            + " addr=$(printf '%s' \"$active\" | jq -r '.address // \"\"');"
            + " title=$(printf '%s' \"$active\" | jq -r '(.title // .initialTitle // .class // \"\") | gsub(\"\\t|\\n|\\r\"; \" \" )');"
            + " monid=$(printf '%s' \"$active\" | jq -r '.monitor // empty');"
            + " floating=$(printf '%s' \"$active\" | jq -r '.floating // false');"
            + " hyprctl monitors -j 2>/dev/null | jq -r --arg addr \"$addr\" --arg title \"$title\" --arg monid \"$monid\" --arg floating \"$floating\" '"
            + " .[]"
            + " | select(((($monid | length) > 0) and ((.id | tostring) == $monid)) or ((($monid | length) == 0) and .focused == true))"
            + " | [$addr, $title, $floating, (.name // \"\"), (.x // 0), (.y // 0), (.width // 0), (.height // 0), (.reserved[0] // 0), (.reserved[1] // 0), (.reserved[2] // 0), (.reserved[3] // 0)] | @tsv' | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split("\t");
                if (parts.length < 12 || !(parts[0] || "").length) {
                    controller.close();
                    return;
                }
                controller.windowAddress = parts[0] || "";
                controller.windowTitle = parts[1] || "";
                controller.windowFloating = (parts[2] || "") === "true";
                controller.monitorName = parts[3] || "";
                controller.screen = controller.screenForName(controller.monitorName);
                controller.monitorX = parseInt(parts[4]) || 0;
                controller.monitorY = parseInt(parts[5]) || 0;
                controller.monitorWidth = parseInt(parts[6]) || 0;
                controller.monitorHeight = parseInt(parts[7]) || 0;
                controller.reservedLeft = parseInt(parts[8]) || 0;
                controller.reservedTop = parseInt(parts[9]) || 0;
                controller.reservedRight = parseInt(parts[10]) || 0;
                controller.reservedBottom = parseInt(parts[11]) || 0;
                controller.resetSelection();
                controller.active = controller.monitorWidth > 0 && controller.monitorHeight > 0;
            }
        }
    }
}
