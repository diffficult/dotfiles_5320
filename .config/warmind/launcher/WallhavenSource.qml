import QtQuick
import Quickshell
import Quickshell.Io

// Wallhaven.cc backend for the aether popup. Anonymous API, SFW only
// (purity=100, categories=100). Previews are driven by the cached
// thumbnail; applying fetches the full-resolution image (item.path)
// and hands that to aether --generate, so the desktop background is
// sharp even on hi-dpi panels. The preview palette and final theme
// may drift very slightly because they come from different scales of
// the same image, but the dominant colors are stable enough that the
// preview remains a faithful guide.
//
// Cache layout under cacheDir:
//   <id>.jpg              — thumbnail (preview only)
//   <id>.palette          — 16 lines of #hex (default "normal" mode)
//   <id>.material.palette — 16 lines of #hex (--extract-mode material)
// Palette caches are mode-keyed so toggling between normal and material
// doesn't blow away the other set — flipping back is instant. Full-res
// images land in ~/.local/share/aether/wallpapers/ and are reused on
// re-apply rather than re-fetched.
Item {
    id: source

    required property var navbar

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/quickshell-desktop/wallhaven"

    property var  items: []
    property int  page: 1
    property int  selectedIndex: -1
    property bool loading: false
    property string query: ""
    property bool active: false
    // When true, both extraction (preview swatches) and apply route
    // through `aether --extract-mode material`. Preview-matches-result
    // depends on both calls staying in lockstep.
    property bool material: false

    // Index up to which kickExtraction has already enqueued items. Lets
    // each appended page only enqueue its new tail rather than re-walking
    // the full accumulated list.
    property int extractedCount: 0

    // Captures the "append" intent for the in-flight probe so a refresh
    // racing a loadNextPage can't get its mode flipped under it.
    property bool _appendNext: false

    readonly property string url: {
        const q = source.query.trim();
        const base = "https://wallhaven.cc/api/v1/search"
                   + "?sorting=" + (q === "" ? "toplist" : "relevance")
                   + "&topRange=1M&purity=100&categories=100"
                   + "&page=" + source.page;
        return q === "" ? base : base + "&q=" + encodeURIComponent(q);
    }

    function loadPage(n, append) {
        source.page = Math.max(1, n);
        source._appendNext = !!append;
        source.loading = true;
        probe.running = false;
        probe.running = true;
    }

    function loadNextPage() {
        if (source.loading) return;
        source.loadPage(source.page + 1, true);
    }

    function refresh() {
        source.extractedCount = 0;
        source.loadPage(source.page, false);
    }

    function thumbPathFor(item)   { return item ? source.cacheDir + "/" + item.id + ".jpg" : ""; }
    function palettePathFor(item) {
        if (!item) return "";
        const suffix = source.material ? ".material.palette" : ".palette";
        return source.cacheDir + "/" + item.id + suffix;
    }

    // Re-extract for the new mode. Existing caches for the other mode
    // are left in place so flipping back doesn't repeat the work.
    onMaterialChanged: {
        source.extractedCount = 0;
        source.kickExtraction();
    }

    function moveSelection(delta) {
        const n = source.items.length;
        if (n === 0) { source.selectedIndex = -1; return; }
        const cur = source.selectedIndex < 0 ? 0 : source.selectedIndex;
        source.selectedIndex = Math.max(0, Math.min(n - 1, cur + delta));
    }

    function applyItem(item) {
        if (!item || !item.id || !item.path) return;
        const wallpaperDir = Quickshell.env("HOME") + "/.local/share/aether/wallpapers";
        // wallhaven's full-image URL ends in .jpg or .png; preserve the
        // original extension so swww/hyprpaper/etc. don't misidentify.
        const url = item.path;
        const ext = url.toLowerCase().endsWith(".png") ? ".png" : ".jpg";
        const dest = wallpaperDir + "/wallhaven-" + item.id + ext;
        const modeArg = source.material ? " --extract-mode material" : "";
        source.navbar.run(
            "mkdir -p " + JSON.stringify(wallpaperDir)
            + " && { [ -f " + JSON.stringify(dest) + " ]"
            + "       || curl -fsSL --max-time 60 -o " + JSON.stringify(dest) + " " + JSON.stringify(url) + "; }"
            + " && aether --generate " + JSON.stringify(dest) + modeArg
        );
    }

    Timer {
        id: queryDebounce
        interval: 300
        repeat: false
        onTriggered: {
            source.extractedCount = 0;
            source.loadPage(1, false);
        }
    }

    onQueryChanged: if (source.active) queryDebounce.restart()
    onActiveChanged: if (active && items.length === 0 && !loading) source.loadPage(1, false)

    Process {
        id: probe
        running: false
        command: ["curl", "-fsS", "--max-time", "15", source.url]
        stdout: StdioCollector {
            onStreamFinished: {
                source.loading = false;
                let arr = [];
                try {
                    const obj = JSON.parse(this.text);
                    arr = (obj.data || []).map(d => ({
                        id: d.id,
                        path: d.path,
                        thumb: (d.thumbs && d.thumbs.large) || "",
                        colors: d.colors || [],
                        resolution: d.resolution || "",
                        ratio: d.ratio || ""
                    })).filter(d => d.thumb && d.path);
                } catch (_) { arr = []; }

                if (source._appendNext) {
                    // Dedupe by id — wallhaven's toplist can return
                    // overlapping pages near the cutoff.
                    const seen = {};
                    for (const e of source.items) seen[e.id] = true;
                    source.items = source.items.concat(arr.filter(e => !seen[e.id]));
                } else {
                    source.items = arr;
                    source.selectedIndex = arr.length > 0 ? 0 : -1;
                    source.extractedCount = 0;
                }
                source._appendNext = false;
                source.kickExtraction();
            }
        }
    }

    // Spawn aether --extract-palette for items added since the last
    // call. Cache hits short-circuit before any network or aether call,
    // so re-visiting a page is instant. SUFFIX/MODE_ARG come in via the
    // environment so the script body stays mode-agnostic.
    function kickExtraction() {
        const items = source.items;
        if (items.length <= source.extractedCount) return;

        const suffix  = source.material ? ".material.palette" : ".palette";
        const modeArg = source.material ? "--extract-mode material" : "";

        const argv = ["bash", "-c",
            "CACHE=" + JSON.stringify(source.cacheDir) + ";"
            + " SUFFIX=" + JSON.stringify(suffix) + ";"
            + " MODE_ARG=" + JSON.stringify(modeArg) + ";"
            + " mkdir -p \"$CACHE\";"
            + " while [ $# -ge 2 ]; do"
            + "   id=$1; url=$2; shift 2;"
            + "   pal=\"$CACHE/$id$SUFFIX\";"
            + "   [ -f \"$pal\" ] && continue;"
            + "   thumb=\"$CACHE/$id.jpg\";"
            + "   [ -f \"$thumb\" ] || curl -fsSL --max-time 20 -o \"$thumb\" \"$url\" || continue;"
            + "   aether --extract-palette \"$thumb\" $MODE_ARG 2>/dev/null"
            + "     | awk '{print $2}' > \"$pal.tmp\""
            + "     && mv \"$pal.tmp\" \"$pal\";"
            + " done",
            "extract"];
        for (let i = source.extractedCount; i < items.length; i++) {
            const it = items[i];
            if (it && it.id && it.thumb) {
                argv.push(it.id);
                argv.push(it.thumb);
            }
        }
        source.extractedCount = items.length;
        if (argv.length <= 4) return;

        extractor.command = argv;
        extractor.running = false;
        extractor.running = true;
    }

    Process {
        id: extractor
        running: false
    }
}
