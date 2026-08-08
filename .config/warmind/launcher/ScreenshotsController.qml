import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: controller

    property bool active: false
    property int page: 0
    readonly property int perPage: 12
    property var files: []
    property int selected: -1
    property string copiedPath: ""

    function open() {
        controller.page = 0;
        controller.selected = 0;
        refresh();
        controller.active = true;
    }

    function close() {
        controller.active = false;
    }

    function toggle() {
        if (controller.active) controller.close();
        else controller.open();
    }

    function refresh() {
        screenshotProbe.running = false;
        screenshotProbe.running = true;
    }

    function moveSelection(delta) {
        if (controller.files.length === 0) return;
        const visible = controller.visibleFiles;
        const next = controller.selected + delta;
        if (next < 0 && controller.page > 0) {
            controller.page--;
            controller.selected = Math.min(
                controller.perPage - 1,
                controller.files.length - controller.page * controller.perPage - 1
            );
        } else if (next >= visible.length && controller.page < controller.pageCount - 1) {
            controller.page++;
            controller.selected = 0;
        } else if (next >= 0 && next < visible.length) {
            controller.selected = next;
        }
    }

    function moveRow(delta) {
        const visible = controller.visibleFiles;
        const next = controller.selected + delta * 4;
        if (next >= 0 && next < visible.length) controller.selected = next;
    }

    function pageBy(delta) {
        const next = controller.page + delta;
        if (next >= 0 && next < controller.pageCount) {
            controller.page = next;
            controller.selected = 0;
        }
    }

    function formatLabel(path) {
        const m = String(path).match(/screenshot-(\d{4}-\d{2}-\d{2})_(\d{2})-(\d{2})-\d{2}\.[A-Za-z0-9]+$/);
        if (m) return m[1] + " " + m[2] + ":" + m[3];
        const parts = String(path).split("/");
        return parts[parts.length - 1];
    }

    readonly property var visibleFiles: {
        if (!controller.active) return [];
        const start = controller.page * controller.perPage;
        return controller.files.slice(start, start + controller.perPage);
    }

    readonly property var selectedEntry:
        controller.selected >= 0 ? (controller.visibleFiles[controller.selected] || null) : null

    readonly property int pageCount: {
        if (controller.files.length === 0) return 1;
        return Math.ceil(controller.files.length / controller.perPage);
    }

    function openEntry(path) {
        if (!path) return;
        runCommand("swayimg " + JSON.stringify(path));
        controller.close();
    }

    function captureRegion() {
        runCommand("~/.local/bin/hypr_scripts/screenshot-notify.sh region file-clipboard");
        controller.close();
    }

    function copyToClipboard(path) {
        if (!path) return;
        shotCopier.command = ["sh", "-c", "wl-copy -t image/png < " + JSON.stringify(path)];
        shotCopier.running = false;
        shotCopier.running = true;
        controller.copiedPath = path;
        copiedReset.restart();
        if (controller.active) copiedDismiss.restart();
    }

    function runCommand(cmd) {
        runner.command = ["zsh", "-c", cmd];
        runner.running = false;
        runner.running = true;
    }

    Process { id: runner; running: false }

    Process {
        id: screenshotProbe
        running: false
        command: ["sh", "-c",
            "dir=\"" + Quickshell.env("HOME") + "/Pictures/Screenshots\"; "
            + "[ -d \"$dir\" ] || exit 0; "
            + "find \"$dir\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) "
            + "-printf '%T@ %p\\n' 2>/dev/null | sort -nr | cut -d' ' -f2- | head -60"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(s => s.length > 0);
                controller.files = lines.map(p => ({
                    path: p,
                    label: controller.formatLabel(p)
                }));
                if (controller.page >= controller.pageCount)
                    controller.page = 0;
                controller.selected = controller.visibleFiles.length > 0 ? 0 : -1;
            }
        }
    }

    Process { id: shotCopier; running: false }

    Timer {
        id: copiedReset
        interval: 1400
        repeat: false
        onTriggered: controller.copiedPath = ""
    }

    Timer {
        id: copiedDismiss
        interval: 260
        repeat: false
        onTriggered: controller.close()
    }
}
