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
    property string copiedMode: ""

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
        videoProbe.running = false;
        videoProbe.running = true;
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
        const parts = String(path).split("/");
        return parts[parts.length - 1];
    }

    function formatDuration(secs) {
        const s = Math.max(0, Math.floor(Number(secs) || 0));
        if (s <= 0) return "";
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const ss = s % 60;
        const pad = (n) => String(n).padStart(2, "0");
        return h > 0 ? (h + ":" + pad(m) + ":" + pad(ss))
                     : (m + ":" + pad(ss));
    }

    function formatSize(bytes) {
        const b = Number(bytes) || 0;
        if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GB";
        if (b >= 1048576) return (b / 1048576).toFixed(0) + " MB";
        if (b >= 1024) return (b / 1024).toFixed(0) + " KB";
        return b + " B";
    }

    function formatMtime(secs) {
        if (!secs) return "";
        return Qt.formatDateTime(new Date(Number(secs) * 1000), "yyyy-MM-dd hh:mm");
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
        runCommand("mpv -- " + JSON.stringify(path));
        controller.close();
    }

    function openFolder() {
        runCommand("xdg-open " + JSON.stringify(Quickshell.env("HOME") + "/Videos"));
        controller.close();
    }

    function dragEntry(path) {
        if (!path) return;
        runCommand("dragon-drop -x -T -i -s 128 " + JSON.stringify(path));
        controller.close();
    }

    function _runCopy(cmd, path, mode) {
        vidCopier.command = ["sh", "-c", cmd];
        vidCopier.running = false;
        vidCopier.running = true;
        controller.copiedPath = path;
        controller.copiedMode = mode;
        copiedReset.restart();
        if (controller.active) copiedDismiss.restart();
    }

    function copyUri(path) {
        const uri = "file://" + encodeURI(path);
        controller._runCopy(
            "printf '%s\\r\\n' " + JSON.stringify(uri) + " | wl-copy -n --type text/uri-list",
            path,
            "file"
        );
    }

    function copyBytes(path) {
        controller._runCopy("wl-copy < " + JSON.stringify(path), path, "bytes");
    }

    function runCommand(cmd) {
        runner.command = ["bash", "-lc", cmd];
        runner.running = false;
        runner.running = true;
    }

    Process { id: runner; running: false }

    Process {
        id: videoProbe
        running: false
        command: ["bash", "-c",
            "CDIR=\"$HOME/.cache/quickshell-desktop/video-thumbs\"; "
          + "mkdir -p \"$CDIR\" 2>/dev/null; "
          + "PATHS=$(find \"$HOME/Videos\" -maxdepth 3 -type f "
              + "\\( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' "
              + "  -o -iname '*.mov' -o -iname '*.avi' -o -iname '*.m4v' \\) "
              + "-printf '%T@\\t%p\\n' 2>/dev/null | sort -rn | head -60 | cut -f2-); "
          + "printf '%s\\n' \"$PATHS\" | xargs -r -d '\\n' -P \"$(nproc 2>/dev/null || echo 4)\" -I{} "
              + "sh -c '"
                + "path=\"$1\"; cdir=\"$2\"; "
                + "key=$(printf %s \"$path\" | md5sum | cut -c1-32); "
                + "thumb=\"$cdir/$key.jpg\"; meta=\"$cdir/$key.meta\"; "
                + "if [ ! -f \"$thumb\" ] || [ \"$path\" -nt \"$thumb\" ]; then "
                  + "command -v ffmpeg >/dev/null 2>&1 && "
                  + "ffmpeg -y -ss 1 -i \"$path\" -frames:v 1 -vf scale=320:-1 -q:v 6 \"$thumb\" </dev/null >/dev/null 2>&1 || true; "
                + "fi; "
                + "if [ ! -f \"$meta\" ] || [ \"$path\" -nt \"$meta\" ]; then "
                  + "dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 \"$path\" 2>/dev/null | awk \"{printf \\\"%d\\\",\\$1+0}\"); "
                  + "printf %s \"${dur:-0}\" > \"$meta\"; "
                + "fi"
              + "' _ {} \"$CDIR\"; "
          + "printf '%s\\n' \"$PATHS\" | while IFS= read -r path; do "
              + "[ -z \"$path\" ] && continue; "
              + "key=$(printf %s \"$path\" | md5sum | cut -c1-32); "
              + "thumb=\"$CDIR/$key.jpg\"; "
              + "dur=$(cat \"$CDIR/$key.meta\" 2>/dev/null); "
              + "mtime=$(stat -c %Y \"$path\" 2>/dev/null); "
              + "size=$(stat -c %s \"$path\" 2>/dev/null); "
              + "printf '%s\\t%s\\t%s\\t%s\\t%s\\n' \"$path\" \"$thumb\" \"${dur:-0}\" \"${mtime:-0}\" \"${size:-0}\"; "
          + "done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(s => s.length > 0);
                controller.files = lines.map(line => {
                    const f = line.split("\t");
                    return {
                        path: f[0] || "",
                        thumb: f[1] || "",
                        duration: parseInt(f[2] || "0", 10),
                        mtime: parseInt(f[3] || "0", 10),
                        size: parseInt(f[4] || "0", 10),
                        label: controller.formatLabel(f[0] || "")
                    };
                });
                if (controller.page >= controller.pageCount)
                    controller.page = 0;
                controller.selected = controller.visibleFiles.length > 0 ? 0 : -1;
            }
        }
    }

    Process { id: vidCopier; running: false }

    Timer {
        id: copiedReset
        interval: 1400
        repeat: false
        onTriggered: { controller.copiedPath = ""; controller.copiedMode = ""; }
    }

    Timer {
        id: copiedDismiss
        interval: 260
        repeat: false
        onTriggered: controller.close()
    }
}
