import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import "Data.js" as Data
import "omni" as Omni
import "omni/Tiles.js" as Tiles

// Omni-menu palette. Fuses installed apps (.desktop scan) with every
// `omarchy-menu` action, scored against title, category, and per-entry
// synonyms (so "wallpaper" finds Background, "reboot" finds Restart).
// Drill-down rows pivot the list to a category, fd file search, gh repo
// search, processes, or themes. Toggle via:
//   qs -c desktop ipc call palette toggle
//
// Source layout: this file is the entry and keeps all state (search
// index, scoring, mode flags, IPC, shortcuts, the keyboard handler,
// and the panel chrome). Visual subtrees live alongside in `omni/`:
//   omni/HeaderBar.qml       title + count + hint
//   omni/SearchInput.qml     prompt glyph + query text + caret
//   omni/QuickContainer.qml  quick-mode tile grid + detail panel
//   omni/ResultList.qml      ListView + row delegate
//   omni/PreviewPane.qml     preview header + body for all modes
//   omni/Footer.qml          exec line for the selected item
//   omni/Format.js           markdown formatters (tldr, chat)
//   omni/Tiles.js            quick-tile static data + dyn builder
Item {
    id: root

    required property var theme
    // Navbar instance handed in from shell.qml. Used by Quick mode to
    // bind live telemetry (battery, audio, network, bluetooth, weather,
    // …) into the tile grid. Optional so OmniMenu can still load without
    // a navbar (e.g. headless config); Quick tiles fall back to "—" then.
    // Named `navbar` to avoid colliding with the existing `nav: []`
    // category-row array further down.
    property var navbar: null

    readonly property color paper:   theme.paper
    readonly property color ink:     theme.ink
    readonly property color inkDeep: theme.inkDeep
    readonly property color sumi:    theme.inkDeep
    readonly property color indigo:  theme.indigo
    readonly property color seal:    theme.seal
    readonly property color bg:      theme.bg
    readonly property color fg:      theme.fg
    readonly property color muted:   theme.muted
    readonly property color sep:     theme.sep
    readonly property color rowHi:   theme.rowHi
    readonly property color rowSel:  theme.rowSel

    // Scoring weights and result cap. omarchy-menu has ~125 entries plus the
    // 12 nav rows plus ~80-200 .desktop apps, so the cap lets a quick
    // page-down still reach near-matches without overdrawing.
    readonly property int scPrefix: 100
    readonly property int scTitle:  60
    readonly property int scKw:     20
    readonly property int scCat:    10
    readonly property int maxResults: 250
    readonly property int listVisibleRows: 8
    readonly property int listRowHeight: 42
    readonly property int listHeight: listVisibleRows * listRowHeight

    readonly property string mono:  theme.mono
    readonly property string serif: theme.serif

    readonly property int cornerRadius: theme.cornerRadius

    // Sources that feed `allItems`. AppScan reads .desktop files;
    // NavbarApps probes the navbar shell for its IpcHandler widgets and
    // surfaces only the ones it actually exposes (so users on a
    // navbar-less setup see nothing instead of broken rows).
    AppScan { id: appScan }
    NavbarApps { id: navbarApps }
    Tuis { id: tuis }
    readonly property alias appsLoaded: appScan.loaded

    // ---------- Visibility / state ----------
    // Trailing underscore avoids shadowing Item.visible — read by the
    // PanelWindow's visibility binding below.
    property bool visible_: false
    property string query: ""
    property int queryCursorPos: 0
    property int selectedIndex: 0
    // Active drill-down. "" means root (category navigators + everything
    // searchable); any other value pins the list to that category. Set by
    // activating a category nav row; cleared by Esc / Backspace-on-empty.
    property string categoryFilter: ""
    property var categoryStack: []

    // File and GitHub search drills reuse the category machinery: the
    // Files/GitHub nav rows set categoryFilter to one of Data's sentinels,
    // filteredItems pivots to the matching results array, and goUp/Esc
    // unwind via the same path as any other category.
    readonly property bool fileMode: root.categoryFilter === Data.fileCategory
    readonly property bool ghMode:   root.categoryFilter === Data.ghCategory
    readonly property bool favMode:  root.categoryFilter === Data.favCategory
    readonly property bool histMode: root.categoryFilter === Data.histCategory
    readonly property bool procMode:  root.categoryFilter === Data.procCategory
    readonly property bool themeMode:  root.categoryFilter === Data.themeCategory
        readonly property bool clipboardMode: root.categoryFilter === Data.clipboardCategory
    // Stage 2 — new search modes
    readonly property bool windowMode: root.categoryFilter === "Windows"
    readonly property bool emojiMode:  root.categoryFilter === "Emoji"
    readonly property bool passMode:   root.categoryFilter === "Pass"
    readonly property bool launcherIconsMode: root.categoryFilter === "LauncherIcons"
    readonly property bool colorSchemeMode: root.categoryFilter === "ColorScheme"
    // Quick mode swaps the result list for a live-tile grid. Tiles bind
    // to nav telemetry for instantaneous state; clicking one drops an
    // expanded detail panel below the grid with that tile's adjustments.
    readonly property bool quickMode: root.categoryFilter === "Quick"
    // Query-shape modes. Each triggers off the query string directly,
    // so the user can pivot in from any drill without going back to
    // root.
    //   `tldr <name>` -> inline tldr preview
    //   `# <q>`       -> remote Ollama Linux/CLI help (llama3.2:3b)
    //   `? <q>`       -> remote Ollama general Q&A
    //   `$ <task>`    -> same model, but constrained to emit a shell
    //                    command for the described task
    readonly property bool tldrMode:
        root.query === "tldr" || root.query.substring(0, 5) === "tldr "
    readonly property bool keybindMode:
        root.query === "bind" || root.query.substring(0, 5) === "bind "
    readonly property bool linuxMode:   root.query.charAt(0) === "#"
    readonly property bool generalMode: root.query.charAt(0) === "?"
    readonly property bool cmdMode:     root.query.charAt(0) === "$"
    // LLM-backed modes share the single OllamaChat instance below,
    // differing only by system prompt + trigger prefix.
    readonly property bool llmMode:  root.linuxMode || root.generalMode || root.cmdMode
    // Live font multiplier — every `font.pixelSize` binding in this
    // file multiplies its base by this value. Ctrl++ / Ctrl+- nudge
    // it in 0.1 steps; Ctrl+= resets to 1.0. Clamped to keep the
    // panel usable at extremes.
    property real fontScale: 1.0
    property bool showListGlyphs: true
    property int listGlyphSize: 18
    property bool showListAppIcons: true
    property int listAppIconSize: 18
    property bool showSearchGlyph: true
    property int searchGlyphSize: 18
    property bool showQuickTileGlyphs: true
    property int quickTileGlyphSize: 28
    property bool showQuickDetailGlyphs: true
    property int quickDetailGlyphSize: 30
    property bool showQuickButtonGlyphs: true
    property int quickButtonGlyphSize: 13
    readonly property string iconSettingsPath: Quickshell.statePath("warmind/launcher/launcher-icons.json")
    property bool _iconSettingsHydrating: false
    property bool _iconSettingsLoaded: false

    function clampIconSize(value, minV, maxV) {
        return Math.max(minV, Math.min(maxV, Math.round(value)));
    }
    function iconSettingsSnapshot() {
        return {
            showListGlyphs: root.showListGlyphs,
            listGlyphSize: root.listGlyphSize,
            showListAppIcons: root.showListAppIcons,
            listAppIconSize: root.listAppIconSize,
            showSearchGlyph: root.showSearchGlyph,
            searchGlyphSize: root.searchGlyphSize,
            showQuickTileGlyphs: root.showQuickTileGlyphs,
            quickTileGlyphSize: root.quickTileGlyphSize,
            showQuickDetailGlyphs: root.showQuickDetailGlyphs,
            quickDetailGlyphSize: root.quickDetailGlyphSize,
            showQuickButtonGlyphs: root.showQuickButtonGlyphs,
            quickButtonGlyphSize: root.quickButtonGlyphSize
        };
    }
    function applyIconSettings(data) {
        if (!data || typeof data !== "object") return;
        root._iconSettingsHydrating = true;
        if (typeof data.showListGlyphs === "boolean") root.showListGlyphs = data.showListGlyphs;
        if (typeof data.listGlyphSize === "number") root.listGlyphSize = root.clampIconSize(data.listGlyphSize, 10, 48);
        if (typeof data.showListAppIcons === "boolean") root.showListAppIcons = data.showListAppIcons;
        if (typeof data.listAppIconSize === "number") root.listAppIconSize = root.clampIconSize(data.listAppIconSize, 10, 64);
        if (typeof data.showSearchGlyph === "boolean") root.showSearchGlyph = data.showSearchGlyph;
        if (typeof data.searchGlyphSize === "number") root.searchGlyphSize = root.clampIconSize(data.searchGlyphSize, 10, 48);
        if (typeof data.showQuickTileGlyphs === "boolean") root.showQuickTileGlyphs = data.showQuickTileGlyphs;
        if (typeof data.quickTileGlyphSize === "number") root.quickTileGlyphSize = root.clampIconSize(data.quickTileGlyphSize, 12, 72);
        if (typeof data.showQuickDetailGlyphs === "boolean") root.showQuickDetailGlyphs = data.showQuickDetailGlyphs;
        if (typeof data.quickDetailGlyphSize === "number") root.quickDetailGlyphSize = root.clampIconSize(data.quickDetailGlyphSize, 12, 80);
        if (typeof data.showQuickButtonGlyphs === "boolean") root.showQuickButtonGlyphs = data.showQuickButtonGlyphs;
        if (typeof data.quickButtonGlyphSize === "number") root.quickButtonGlyphSize = root.clampIconSize(data.quickButtonGlyphSize, 8, 40);
        root._iconSettingsHydrating = false;
        root._iconSettingsLoaded = true;
    }
    function scheduleIconSettingsSave() {
        if (root._iconSettingsHydrating || !root._iconSettingsLoaded) return;
        iconSettingsSaveDebounce.restart();
    }
    function bumpFontScale(delta) {
        const next = Math.max(0.7, Math.min(2.0, root.fontScale + delta));
        // Snap to one decimal so successive bumps don't drift on
        // floating-point round-off.
        root.fontScale = Math.round(next * 10) / 10;
    }

    onShowListGlyphsChanged: scheduleIconSettingsSave()
    onListGlyphSizeChanged: scheduleIconSettingsSave()
    onShowListAppIconsChanged: scheduleIconSettingsSave()
    onListAppIconSizeChanged: scheduleIconSettingsSave()
    onShowSearchGlyphChanged: scheduleIconSettingsSave()
    onSearchGlyphSizeChanged: scheduleIconSettingsSave()
    onShowQuickTileGlyphsChanged: scheduleIconSettingsSave()
    onQuickTileGlyphSizeChanged: scheduleIconSettingsSave()
    onShowQuickDetailGlyphsChanged: scheduleIconSettingsSave()
    onQuickDetailGlyphSizeChanged: scheduleIconSettingsSave()
    onShowQuickButtonGlyphsChanged: scheduleIconSettingsSave()
    onQuickButtonGlyphSizeChanged: scheduleIconSettingsSave()
    // null = no expansion; otherwise the tile object whose detail panel
    // is currently revealed under the grid.
    property var expandedTile: null
    // Single source of truth for "in Quick mode with a tile open" — the
    // grid column count, the compressed-tile flag, and the side-panel
    // visibility all key off it.
    readonly property bool quickExpanded: quickMode && expandedTile !== null
    readonly property int  quickGridCols: quickExpanded ? 1 : 3
    function expandTile(t) {
        if (!t) { root.expandedTile = null; return; }
        // Click same tile to collapse; click a different tile to swap.
        root.expandedTile = (root.expandedTile && root.expandedTile.key === t.key)
                            ? null : t;
    }
    function collapseTile() { root.expandedTile = null; }

    Bookmarks { id: bookmarks }

    Timer {
        id: iconSettingsSaveDebounce
        interval: 120
        repeat: false
        onTriggered: {
            const payload = JSON.stringify(root.iconSettingsSnapshot());
            iconSettingsSaveProc.command = [
                "sh", "-c",
                "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"",
                "sh", root.iconSettingsPath, payload
            ];
            iconSettingsSaveProc.running = false;
            iconSettingsSaveProc.running = true;
        }
    }

    Process { id: iconSettingsSaveProc; running: false; command: ["true"] }

    FileView {
        id: iconSettingsFile
        path: root.iconSettingsPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (path === "") return;
            try {
                const data = JSON.parse(iconSettingsFile.text());
                root.applyIconSettings(data);
            } catch (_) {
                root._iconSettingsLoaded = true;
            }
        }
    }

    // ---------- Quick tiles ----------
    // Split into a *static* base array (the Repeater's model) and a
    // *dynamic* dict of per-tile live data, indexed by tile.key. The
    // base never changes, so the Repeater's 12 delegates are built once
    // and never torn down — clicks and hover state survive across
    // navbar ticks. Dynamic fields (glyph/label/sub/tone) read out of
    // `quickTilesDyn` via the `tileDyn()` helper; when the dict swaps,
    // only the delegate's text/color bindings re-evaluate. Order
    // matches the Samsung-style quick panel — most glanced
    // (battery/audio/wifi/bt) first.
    readonly property var quickTilesBase: Tiles.base

    // Dynamic per-tile data — keyed by tile.key. Gated on `visible_`
    // so navbar ticks don't wake the rebuild while the palette is
    // closed (the previous snapshot keeps the Repeater happy when the
    // user re-opens, before this binding re-evaluates).
    property var _quickTilesDynCache: ({})
    readonly property var quickTilesDyn: {
        if (!root.visible_) return root._quickTilesDynCache;
        // No navbar yet (shell reload, hot-swap, or a tick before the
        // sibling Navbar wires up): return an empty snapshot but do NOT
        // store it, so the cached previous-good values survive the gap
        // and the close-fade never flashes blank tiles.
        if (!root.navbar) return ({});
        const dyn = Tiles.buildDyn(root.navbar);
        root._quickTilesDynCache = dyn;
        return dyn;
    }

    // Resolve the dynamic side of a base tile. Returns an empty object
    // (not undefined) so delegate bindings can chain `.glyph` / `.sub`
    // without an `?.` chain on every read.
    function tileDyn(t) { return (t && root.quickTilesDyn[t.key]) || ({}); }

    // No search field in quickMode — tiles are always the full set so
    // grid arithmetic (gridCols * row) stays predictable. Kept as a
    // separate property so non-quick code paths don't need to branch.
    readonly property var filteredQuickTiles: root.quickTilesBase

    // Same launch envelope as activate() so popup IPCs (qs ipc call …)
    // get fired off-process and quickshell can close immediately.
    function activateQuickTile(t) {
        if (!t || !t.action) return;
        runner.command = ["sh", "-c",
                          "setsid -f uwsm-app -- bash -c "
                          + JSON.stringify(t.action)
                          + " >/dev/null 2>&1"];
        runner.running = false;
        runner.running = true;
        root.close();
    }

    // Long-press / right-click hook. Stays open so a "refresh weather"
    // or "reset display" doesn't dismiss the panel mid-glance.
    function longQuickTile(t) {
        if (!t || !t.longAction) return;
        runner.command = ["sh", "-c",
                          "setsid -f uwsm-app -- bash -c "
                          + JSON.stringify(t.longAction)
                          + " >/dev/null 2>&1"];
        runner.running = false;
        runner.running = true;
    }

    // gh CLI-backed repo search + README preview.
    GhSearch {
        id: ghSearch
        query: root.query
        active: root.ghMode && !root.tldrMode && !root.llmMode
        selectedItem: root.filteredItems[root.selectedIndex] || null
    }
    readonly property alias ghReady:        ghSearch.ready
    readonly property alias ghItems:        ghSearch.items
    readonly property alias ghRunning:      ghSearch.running
    readonly property alias previewRepo:    ghSearch.previewRepo
    readonly property alias previewRepoUrl: ghSearch.previewRepoUrl
    readonly property alias previewReadme:  ghSearch.previewReadme

    readonly property string passLockedIcon: "󰌾"
    readonly property string passUnlockedIcon: "󰌿"
    readonly property string passCategoryIcon:
        passSearch.sessionUnlocked ? root.passUnlockedIcon : root.passLockedIcon

    readonly property string sectionIcon: {
        if (root.categoryFilter === "") return "";
        if (root.categoryFilter === "Pass") return root.passCategoryIcon;
        for (let i = 0; i < Data.categoryNav.length; i++) {
            if (Data.categoryNav[i].target === root.categoryFilter)
                return Data.categoryNav[i].icon;
        }
        for (let j = 0; j < root.allItems.length; j++) {
            const it = root.allItems[j];
            if (it.isCategory && it.target === root.categoryFilter)
                return it.icon || "";
        }
        return "";
    }

    // fd-backed file search + file preview. Aliases mirror the prior root
    // properties so the panel UI doesn't have to change wholesale.
    FileSearch {
        id: fileSearch
        query: root.query
        queryTokens: root.queryTokens
        active: root.fileMode && !root.tldrMode && !root.llmMode
        selectedItem: root.filteredItems[root.selectedIndex] || null
    }
    readonly property alias fileItems:    fileSearch.items
    readonly property alias fdRunning:    fileSearch.running
    readonly property alias previewPath:  fileSearch.previewPath
    readonly property alias previewText:  fileSearch.previewText
    readonly property alias previewMeta:  fileSearch.previewMeta
    readonly property alias previewKind:  fileSearch.previewKind

    Processes {
        id: processes
        active: root.procMode && !root.tldrMode && !root.llmMode
        selectedItem: root.filteredItems[root.selectedIndex] || null
    }
    readonly property alias procItems:    processes.items
    readonly property alias procRunning:  processes.running
    readonly property alias procPreviewText: processes.previewText
    readonly property alias procPreviewPid:  processes.previewPid

    Themes {
        id: themes
        active: root.themeMode && !root.tldrMode && !root.llmMode
    }

    // Stage 2 — new search mode components
    WindowSearch {
        id: windowSearch
        query: root.query
        active: root.windowMode
        onItemActivated: root.close()
    }
    EmojiSearch {
        id: emojiSearch
        query: root.query
        onItemActivated: root.close()
    }
    readonly property alias emojiLoaded: emojiSearch.loaded
    readonly property alias emojiLoadError: emojiSearch.loadError
        ClipboardHistory {
            id: clipboardHistory
            query: root.query
            active: root.clipboardMode && !root.tldrMode && !root.llmMode
            selectedItem: root.filteredItems[root.selectedIndex] || null
            onItemActivated: root.close()
        }
        readonly property alias clipboardItems: clipboardHistory.items
        readonly property alias clipboardRunning: clipboardHistory.running
        readonly property alias clipboardPreview: clipboardHistory.previewText
    PassSearch {
        id: passSearch
        query: root.query
        onItemActivated: root.close()
        onRequestQueryChange: function(value) { root.setQuery(value, value.length) }
    }
    readonly property alias themeItems:   themes.items
    readonly property alias themeLoaded:  themes.loaded

    // tldr-backed CLI help preview. Triggered by `$ <name>` in the query.
    TldrSearch {
        id: tldrSearch
        query: root.query
        active: root.tldrMode
    }
    readonly property alias tldrItems:    tldrSearch.items
    readonly property alias tldrRunning:  tldrSearch.running
    readonly property alias tldrPreview:  tldrSearch.previewText
    readonly property alias tldrTool:     tldrSearch.toolName

    // Hyprland keybindings explorer. Triggered by `bind <filter>`.
    KeybindSearch {
        id: keybindSearch
        query: root.query
        active: root.keybindMode
        palette: ({ ink: root.ink, inkDeep: root.inkDeep, indigo: root.indigo, seal: root.seal })
    }
    readonly property alias keybindItems:    keybindSearch.items
    readonly property alias keybindRunning:  keybindSearch.running
    readonly property alias keybindPreview:  keybindSearch.previewText
    readonly property alias keybindFilter:   keybindSearch.filterText

    // Remote-LLM preview. Triggered by `# <question>` (Linux),
    // `? <question>` (general), or `$ <task>` (command). The mode
    // property steers the system prompt and the placeholder copy;
    // everything else (probe, streaming, unload-on-leave) is shared.
    OllamaChat {
        id: ollamaChat
        query: root.query
        active: root.llmMode
        mode: root.cmdMode ? "command" : (root.generalMode ? "general" : "linux")
    }
    readonly property alias chatItems:          ollamaChat.items
    readonly property alias chatRunning:        ollamaChat.running
    readonly property alias chatPreview:        ollamaChat.previewText
    readonly property alias chatStatus:         ollamaChat.status
    readonly property alias chatPrompt:         ollamaChat.prompt
    readonly property alias chatSubmitted:      ollamaChat.submitted
    readonly property alias chatRequestError:   ollamaChat.requestError
    readonly property alias chatInvalidCommand: ollamaChat.invalidCommandResponse
    readonly property alias chatModel:          ollamaChat.model_

    readonly property bool previewActive: root.tldrMode || root.keybindMode || root.llmMode || root.fileMode || root.ghMode || root.procMode || root.themeMode || root.clipboardMode
    readonly property bool previewHasContent: {
        if (root.tldrMode) return root.tldrPreview !== "";
        if (root.keybindMode) return root.keybindPreview !== "";
            if (root.clipboardMode) return root.clipboardPreview !== "";
        if (root.llmMode) {
            // Probing: no content yet. Status != "ok": show the
            // install/start/pull hint as content. OK + not submitted:
            // empty (the placeholder hint shows). OK + submitted:
            // there's a streaming or completed answer.
            if (root.chatStatus === "") return false;
            if (root.chatStatus !== "ok") return true;
            if (!root.chatSubmitted) return false;
            return root.chatPreview !== "";
        }
        if (root.fileMode || root.ghMode)
            return root.previewPath !== "" || root.previewRepoUrl !== "";
        if (root.procMode) return processes.previewPid !== "";
        if (root.themeMode) {
            const it = root.filteredItems[root.selectedIndex];
            return !!(it && it.swatches && it.swatches.length > 0);
        }
        return false;
    }

    readonly property string homeDir: Quickshell.env("HOME")

    function clampCursor(pos) {
        return Math.max(0, Math.min(pos, root.query.length));
    }
    function protectedPrefixLength() {
        if (root.llmMode) return 1;
        if (root.keybindMode) return 4;
        return 0;
    }
    function setQuery(value, cursorPos) {
        root.query = value;
        root.queryCursorPos = root.clampCursor(cursorPos === undefined ? value.length : cursorPos);
        root.selectedIndex = 0;
    }
    function insertText(text) {
        const left = root.query.slice(0, root.queryCursorPos);
        const right = root.query.slice(root.queryCursorPos);
        root.setQuery(left + text + right, root.queryCursorPos + text.length);
    }
    function deleteBeforeCursor() {
        if (root.queryCursorPos <= 0) return false;
        const left = root.query.slice(0, root.queryCursorPos);
        const right = root.query.slice(root.queryCursorPos);
        root.setQuery(left.slice(0, -1) + right, root.queryCursorPos - 1);
        return true;
    }
    function deleteWordBeforeCursor() {
        const floor = root.protectedPrefixLength();
        if (root.queryCursorPos <= floor) return false;
        let i = root.queryCursorPos;
        while (i > floor && /\s/.test(root.query.charAt(i - 1))) i--;
        while (i > floor && !/\s/.test(root.query.charAt(i - 1))) i--;
        root.setQuery(root.query.slice(0, i) + root.query.slice(root.queryCursorPos), i);
        return true;
    }
    function deleteToPromptPrefix() {
        const floor = root.protectedPrefixLength();
        if (root.queryCursorPos <= floor) return false;
        root.setQuery(root.query.slice(0, floor) + root.query.slice(root.queryCursorPos), floor);
        return true;
    }
    function moveCursor(delta) {
        root.queryCursorPos = root.clampCursor(root.queryCursorPos + delta);
    }
    function moveCursorWord(dir) {
        const floor = root.protectedPrefixLength();
        let i = root.queryCursorPos;
        if (dir < 0) {
            while (i > floor && /\s/.test(root.query.charAt(i - 1))) i--;
            while (i > floor && !/\s/.test(root.query.charAt(i - 1))) i--;
        } else {
            const n = root.query.length;
            while (i < n && /\s/.test(root.query.charAt(i))) i++;
            while (i < n && !/\s/.test(root.query.charAt(i))) i++;
        }
        root.queryCursorPos = root.clampCursor(i);
    }
    onQueryChanged: root.queryCursorPos = root.clampCursor(root.queryCursorPos)

    function open() {
        root.setQuery("", 0);
        root.selectedIndex = 0;
        root.categoryFilter = "";
        root.categoryStack = [];
        passSearch.reset();
        appScan.refresh();
        root.visible_ = true;
        navbarApps.probe();
    }
    function close() {
        root.visible_ = false;
        passSearch.reset();
        // Cancel any in-flight stream and zero chat state so the next
        // session starts fresh. The ollama daemon itself is left
        // running — we don't manage its lifecycle, only our use of it.
        ollamaChat.clear();
    }
    function toggle() { if (root.visible_) close(); else open(); }
    function goUp() {
        // Step back one level. At root this is a no-op so the caller can
        // chain "goUp or close" without a branch.
        if (root.categoryFilter !== "") {
            root.categoryFilter = root.categoryStack.length > 0
                                ? root.categoryStack.pop()
                                : "";
            root.setQuery("", 0);
            root.selectedIndex = 0;
            return true;
        }
        return false;
    }

    // Entering or leaving file mode resets fd state. Other category drills
    // share the same handler — clearing both is a free no-op for other drills.
    onCategoryFilterChanged: {
        fileSearch.clear();
        ghSearch.clear();
        tldrSearch.clear();
        ollamaChat.clear();
        if (!root.passMode) passSearch.reset();
        // Processes/Themes own their own clear()-on-deactivate via their
        // `active` binding, so the shell doesn't have to nudge them when
        // the filter changes — they react automatically.
    }

    // ---------- Icon resolution ----------
    // `.desktop` Icon field is either an absolute path or an icon-theme
    // name. Quickshell's themed loader misses some valid icon names in the
    // current environment, so AppScan pre-resolves theme names to absolute
    // files via GTK when possible. Prefer that resolved path first, then
    // fall back to Quickshell.iconPath for names we couldn't map.
    function resolveIconUrl(raw, resolved) {
        if (resolved && resolved.charAt(0) === "/") return "file://" + resolved;
        if (!raw) return "";
        if (raw.charAt(0) === "/") return "file://" + raw;
        return Quickshell.iconPath(raw, "");
    }

    // ---------- Search index annotation ----------
    // Annotated indexes. Assigned in Component.onCompleted and in the
    // appScan handler so they stay plain `var` assignments rather than
    // re-evaluating bindings whose dependency graph would re-allocate the
    // 200+ entry array on unrelated property touches.
    property var omarchy: []
    property var nav: []
    readonly property var allItems: root.omarchy.concat(appScan.apps).concat(navbarApps.items).concat(tuis.items).concat(themes.items)

    // ---------- Launcher ----------
    // Matches omarchy's launch convention (see omarchy-launch-or-focus):
    //   setsid -f          fork into a new session, returning immediately
    //                      so quickshell's Process completes; the spawned
    //                      app fully detaches from quickshell's lifetime
    //   uwsm-app -- <cmd>  registers the spawn under a systemd-user scope
    //                      (omarchy convention; gives the app a managed
    //                      unit, proper cgroup, clean logout teardown)
    //   bash -c "<exec>"   lets exec lines with shell syntax (pipes,
    //                      ||, &&, redirects) work alongside plain
    //                      argv-style commands without a special case
    Process { id: runner; running: false }
    Process { id: clipboardProc; running: false }
    function copyTextToClipboard(text) {
        clipboardProc.command = ["wl-copy", "--", text];
        clipboardProc.running = false;
        clipboardProc.running = true;
    }
    function openFileParent(item) {
        if (!item || !item.path) return;
        const dir = Data.dirname(item.path);
        runner.command = ["sh", "-c",
                          "setsid -f uwsm-app -- bash -c "
                          + JSON.stringify(Data.openUrl(dir))
                          + " >/dev/null 2>&1"];
        runner.running = false;
        runner.running = true;
        root.close();
    }
    function launchCommand(cmd, flushStateFirst) {
        if (flushStateFirst) {
            runner.command = ["sh", "-c",
                "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\" && "
                + "setsid -f uwsm-app -- bash -c \"$3\" >/dev/null 2>&1",
                "sh", bookmarks.statePath, bookmarks.serializedState(), cmd];
        } else {
            runner.command = ["sh", "-c",
                "setsid -f uwsm-app -- bash -c " + JSON.stringify(cmd) + " >/dev/null 2>&1"];
        }
        runner.running = false;
        runner.running = true;
    }
    function activate(item) {
        if (!item) return;
        if (item.isCategory) {
            if (item.target === "Pass") passSearch.reset();
            // Cams opens its popup directly instead of drilling in.
            if (item.target === "Cams") {
                runner.command = ["sh", "-c",
                    "setsid -f uwsm-app -- qs -c $HOME/.config/warmind/launcher ipc call cams toggle >/dev/null 2>&1"];
                runner.running = false;
                runner.running = true;
                root.close();
                return;
            }
            if (root.categoryFilter !== "")
                root.categoryStack = root.categoryStack.concat([root.categoryFilter]);
            root.categoryFilter = item.target;
            root.setQuery("", 0);
            root.selectedIndex = 0;
            return;
        }
        // Process kill — refresh stays in-mode so you can chain kills.
        if (item.isProcess) {
            processes.killPid(item.pid, false);
            return;
        }
        // Theme apply — fire and forget; omarchy-theme-set rebuilds
        // configs and reloads all the live apps that listen for it.
        if (item.isTheme) {
            runner.command = ["sh", "-c",
                "setsid -f uwsm-app -- omarchy-theme-set \"$1\" >/dev/null 2>&1",
                "sh", item.themeName];
            runner.running = false;
            runner.running = true;
            root.close();
            return;
        }
        // tldr is inline-only: the right-hand preview is the UI.
        // Enter is a no-op here; users read/copy/scroll the preview
        // instead of spawning a separate terminal.
        // ollama chat → Enter behaviour depends on the readiness state:
        //   no-daemon  no-op; remote endpoint is unreachable
        //   no-model   no-op; remote endpoint lacks the configured model
        //   ok+!sub    submit the prompt; preview streams inline,
        //              panel stays open
        //   ok+sub     in `$` mode with a finished answer, copy the
        //              generated command to clipboard; otherwise no-op
        if (item.isLlm) {
            const status = ollamaChat.status;
            if (status === "no-daemon") {
                return;
            }
            if (status === "no-model") {
                return;
            }
            if (status === "ok" && (!ollamaChat.submitted
                || ollamaChat.requestError !== ""
                || ollamaChat.invalidCommandResponse)) {
                ollamaChat.submit();
                // Keep the panel open so the response streams in.
                return;
            }
            if (status === "ok" && root.cmdMode && ollamaChat.submitted
                && !ollamaChat.running && ollamaChat.previewText !== ""
                && ollamaChat.canCopyCommand()) {
                ollamaChat.copyCommandToClipboard();
                return;
            }
            // status === "ok" && submitted: stay open, no-op. User
            // can edit the prompt and the new submit fires on Enter.
            return;
        }
        if (item.isTldr) {
            return;
        }
        if (item.isKeybind) {
            return;
        }
        // Stage 2 — new mode item dispatch
        if (item.category === "Windows" && item.address) {
            windowSearch.activate(item);
            return;
        }
        if (item.category === "Emoji") {
            emojiSearch.copyChar(item);
            return;
        }
            if (item.category === "Clipboard") {
                clipboardHistory.activate(item);
                return;
            }
        if (item.category === "Pass") {
            passSearch.selectItem(item);
            return;
        }
        bookmarks.record(item);
        // TUI commands need a real terminal — fzf, sudo prompts, and bash
        // `read` fail when launched detached. `item.tui` holds the wrapper
        // command name (omarchy-launch-tui or omarchy-launch-floating-…).
        const cmd = item.tui ? item.tui + " " + item.exec : item.exec;
        root.launchCommand(cmd, !!item.flushBookmarks);
        root.close();
    }

    // ---------- Search ----------
    // Each query token must match somewhere in the item for the item to
    // qualify; scores stack so "thm dark" finds Theme even though neither
    // token is a prefix on its own. Uses precomputed lowercased fields
    // (`_t`/`_k`/`_c`) so a 200+ item × N-token scoring pass doesn't
    // re-lowercase the same strings on every keystroke.
    // Title-only score for the primary sort axis. When the typed query
    // hits the title, that's a strong "user wants THIS" signal and the
    // bucket competition (App vs omarchy vs theme) should happen here,
    // before keyword/category bonuses can flip the ranking.
    function primaryScore(item, tokens) {
        const title = item._t;
        let total = 0;
        for (let i = 0; i < tokens.length; i++) {
            const t = tokens[i];
            if (title.indexOf(t) === 0) total += root.scPrefix;
            else if (title.indexOf(t) >= 0) total += root.scTitle;
        }
        return total;
    }

    // Kind rank used as a tie-break after primaryScore+isCategory. Lower wins.
    // Categories chosen to satisfy "Apps before omarchy/navbar before
    // niche (TUIs, themes)" without source-tagging — the relevant
    // category strings are stable across sources.
    function kindRank(item) {
        const c = item.category;
        if (c === "App") return 1;
        if (c === "TUI") return 3;
        if (c === "THEME" || c === "ACTIVE") return 4;
        return 2;
    }

    function scoreItem(item, tokens) {
        const title = item._t;
        const kw = item._k;
        const cat = item._c;
        let total = 0;
        for (let i = 0; i < tokens.length; i++) {
            const t = tokens[i];
            let sub = 0;
            if (title.indexOf(t) === 0) sub += root.scPrefix;
            else if (title.indexOf(t) >= 0) sub += root.scTitle;
            if (kw.indexOf(t) >= 0) sub += root.scKw;
            if (cat.indexOf(t) >= 0) sub += root.scCat;
            if (sub === 0) return 0; // any token miss disqualifies
            total += sub;
        }
        return total;
    }

    function usageBonus(item) {
        const stats = bookmarks.usageStats(item);
        if (!stats) return 0;
        const count = Math.max(0, stats.count || 0);
        const lastUsed = Math.max(0, stats.lastUsed || 0);
        // Log scale so heavy use wins ties without drowning title quality
        // (prefix=100). Cap ~20 freq + ~10 recency ≈ rofi-like frecency.
        const freqBonus = Math.min(20, Math.floor((Math.log(count + 1) / Math.log(2)) * 5));
        const ageMs = Math.max(0, Date.now() - lastUsed);
        const hour = 60 * 60 * 1000;
        const day = 24 * hour;
        let recencyBonus = 0;
        if (ageMs < hour) recencyBonus = 10;
        else if (ageMs < day) recencyBonus = 8;
        else if (ageMs < 3 * day) recencyBonus = 6;
        else if (ageMs < 7 * day) recencyBonus = 4;
        else if (ageMs < 30 * day) recencyBonus = 2;
        return freqBonus + recencyBonus;
    }

    // Root-only category filter syntax: `@app yazi`, `@tui yazi`,
    // `@quick audio`, etc. We recognize only labels that actually exist
    // in the current general-search pool. Unknown @tokens remain ordinary
    // search text, and category drills keep their existing query behavior.
    function parseGeneralSearch(query) {
        const tokens = query.trim().toLowerCase().split(/\s+/)
            .filter(function(token) { return token.length > 0; });
        if (root.categoryFilter !== "")
            return { categories: [], textTokens: tokens };

        const known = {};
        const source = root.navRows.concat(root.allItems);
        for (let i = 0; i < source.length; ++i) {
            const category = (source[i].category || "").toLowerCase();
            if (category.length > 0) known[category] = true;
        }

        const categories = [];
        const textTokens = [];
        for (let j = 0; j < tokens.length; ++j) {
            const token = tokens[j];
            const candidate = token.charAt(0) === "@" ? token.slice(1) : "";
            if (candidate.length > 0 && known[candidate]) {
                if (categories.indexOf(candidate) < 0) categories.push(candidate);
            } else {
                textTokens.push(token);
            }
        }
        return { categories: categories, textTokens: textTokens };
    }
    readonly property var generalSearch: root.parseGeneralSearch(root.query)
    readonly property var generalCategoryFilters: root.generalSearch.categories
    readonly property var queryTokens: root.generalSearch.textTokens

    // Root drill-in rows. Pass gets a live icon override so the launcher
    // can reflect locked vs unlocked password-store state.
    readonly property var navRows: {
        const base = root.ghReady
            ? root.nav
            : root.nav.filter(it => it.target !== Data.ghCategory);
        return base.map(function(it) {
            return it.target === "Pass"
                ? Object.assign({}, it, { icon: root.passCategoryIcon })
                : it;
        });
    }

    readonly property var filteredItems: {
        // tldr mode owns the query entirely — its synthetic row is the
        // only thing the list should show, scoring doesn't apply.
        if (root.tldrMode) return root.tldrItems;
        // keybind mode — same one-row pivot, preview owns the UX.
        if (root.keybindMode) return root.keybindItems;
        // LLM modes are the other query-shape modes; same one-row
        // pivot for both chat (`?`) and command (`$`).
        if (root.llmMode) return root.chatItems;
        // File and GitHub modes are their own worlds: fd and gh already
        // did the filtering, so we just pass their results through.
        if (root.fileMode) return root.fileItems;
        if (root.ghMode)     return root.ghItems;
        if (root.windowMode) return windowSearch.items;
        if (root.emojiMode)  return emojiSearch.items;
            if (root.clipboardMode) return root.clipboardItems;
        if (root.passMode)   return passSearch.items;
        if (root.launcherIconsMode) return [];
        if (root.colorSchemeMode) return [];

        const tokens = root.queryTokens;
        const filter = root.categoryFilter;
        const cap = root.maxResults;

        // Favourites/history/proc/theme drill-ins draw from their
        // owning component; scoring still applies so typing inside the
        // drill filters live.
        let pool;
        if (root.favMode)        pool = bookmarks.favouriteItems;
        else if (root.histMode)  pool = bookmarks.historyItems;
        else if (root.procMode)  pool = root.procItems;
        else if (root.themeMode) pool = root.themeItems;
        else if (filter !== "")  pool = root.allItems.filter(it => it.category === filter);
        else {
            pool = root.navRows.concat(root.allItems);
            if (root.generalCategoryFilters.length > 0) {
                pool = pool.filter(function(item) {
                    return root.generalCategoryFilters.indexOf(
                        (item.category || "").toLowerCase()) >= 0;
                });
            }
        }

        // Empty query, default view: drill-ins first, then up to 5
        // favourites, then leaf actions/apps. TUIs and themes are
        // skipped from this view to keep the cold open scannable -
        // they stay in `allItems` so the scored branch below still
        // finds them when typed. Drill-in modes (fav/hist/proc/theme)
        // and category filters keep their existing pool unchanged.
        if (tokens.length === 0) {
            if (root.favMode || root.histMode || root.procMode
                || root.themeMode || filter !== ""
                || root.generalCategoryFilters.length > 0) {
                return pool.length <= cap ? pool : pool.slice(0, cap);
            }
            const favs = bookmarks.favouriteItems.slice(0, 5);
            const favKeys = {};
            for (let i = 0; i < favs.length; i++) {
                favKeys[Data.itemKey(favs[i])] = true;
            }
            const tail = [];
            for (let i = 0; i < root.allItems.length; i++) {
                const it = root.allItems[i];
                const c = it.category;
                if (c === "TUI" || c === "THEME" || c === "ACTIVE") continue;
                if (favKeys[Data.itemKey(it)]) continue;
                tail.push(it);
            }
            const out = root.navRows.concat(favs).concat(tail);
            return out.length <= cap ? out : out.slice(0, cap);
        }

        const scored = [];
        for (let i = 0; i < pool.length; i++) {
            const it = pool[i];
            const s = root.scoreItem(it, tokens);
            if (s > 0) {
                scored.push({
                    s: s,
                    p: root.primaryScore(it, tokens),
                    u: root.usageBonus(it),
                    item: it
                });
            }
        }
        scored.sort((a, b) => {
            // 1) Title match quality first (prefix > substring). Keyword-only
            // hits never outrank a real title hit, even with heavy use.
            if (b.p !== a.p) return b.p - a.p;
            // 2) Rofi-like frecency: among equal title quality, prefer items
            // used more often / more recently — including over category
            // drill-ins (so "ca" surfaces Camara 01 above Capture/Cams).
            if (b.u !== a.u) return b.u - a.u;
            // 3) Unused drill-ins still beat unused leaves on the same title
            // score (typed "setup" → Setup category before Setup leaves).
            const aCat = a.item.isCategory ? 0 : 1;
            const bCat = b.item.isCategory ? 0 : 1;
            if (aCat !== bCat) return aCat - bCat;
            // 4) Kind tie-break: App > omarchy/navbar > TUI > Theme.
            const ka = root.kindRank(a.item);
            const kb = root.kindRank(b.item);
            if (ka !== kb) return ka - kb;
            // 5) Full textual score (keywords/category), then alpha.
            if (b.s !== a.s) return b.s - a.s;
            return a.item.title.localeCompare(b.item.title);
        });
        const lim = Math.min(scored.length, cap);
        const out = new Array(lim);
        for (let j = 0; j < lim; j++) out[j] = scored[j].item;
        return out;
    }

    onFilteredItemsChanged: {
        root.selectedIndex = Math.max(0, Math.min(root.selectedIndex,
                                                  root.filteredItems.length - 1));
    }

    // ---------- Selection movement ----------
    // Single entry point for keyboard nav so arrow/Tab/Page bindings stay
    // one-liners. `wrap` toggles modulo behaviour vs. clamp — arrow + Tab
    // wrap, paging clamps (matches list-widget convention everywhere else).
    function moveSelection(delta, wrap) {
        const n = root.filteredItems.length;
        if (n === 0) return;
        let next = root.selectedIndex + delta;
        next = wrap ? ((next % n) + n) % n
                    : Math.max(0, Math.min(n - 1, next));
        root.selectedIndex = next;
        resultListInstance.list.positionViewAtIndex(next, ListView.Contain);
    }

    // Grid-aware step for Quick mode. `delta` may exceed ±1 (arrow Up/Down
    // moves by gridCols). Clamps rather than wraps so Up from the top row
    // doesn't jump to the last row of a partial bottom row.
    function moveQuickSelection(delta) {
        const n = root.filteredQuickTiles.length;
        if (n === 0) return;
        const next = Math.max(0, Math.min(n - 1, root.selectedIndex + delta));
        root.selectedIndex = next;
    }

    Component.onCompleted: {
        root.omarchy = Data.annotate(Data.omarchyItems);
        root.nav     = Data.annotate(Data.categoryNav);
        if (!root._iconSettingsLoaded) root._iconSettingsLoaded = true;
    }

    // ---------- IPC ----------
    IpcHandler {
        target: "palette"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
        function refresh(): void { appScan.refresh(); }
        // Open OmniMenu pre-pivoted to a drill-down category (e.g. "Quick").
        // Lets Hyprland bind a shortcut straight into a category without
        // exposing the visual grid as a separate surface.
        function openCategory(cat: string): void {
            root.open();
            root.expandedTile = null;
            if (cat === "Pass") passSearch.reset();
            root.categoryFilter = cat;
        }
        function openQuickTile(key: string): void {
            root.open();
            root.categoryFilter = "Quick";
            const tiles = root.quickTilesBase || [];
            let idx = -1;
            for (let i = 0; i < tiles.length; ++i) {
                if (tiles[i] && tiles[i].key === key) {
                    idx = i;
                    break;
                }
            }
            if (idx >= 0) {
                root.selectedIndex = idx;
                root.expandedTile = tiles[idx];
            } else {
                root.expandedTile = null;
            }
        }
    }

    // ---------- Global shortcuts ----------
    // Direct wlroots global-shortcut binding. Hyprland delivers the
    // keypress over its socket straight to this running shell, so
    // SUPER+SPACE no longer pays for a fresh `qs` client process (the
    // dominant ~50-150ms of perceived "boot" before any pixel changes).
    // Bind in Hyprland with:
    //   bind = SUPER, SPACE, global, quickshell:palette-toggle
    //   bind = ALT,   SPACE, global, quickshell:palette-quick
    GlobalShortcut {
        appid: "quickshell"
        name: "palette-toggle"
        description: "Toggle warmind launcher palette"
        onPressed: root.toggle()
    }
    GlobalShortcut {
        appid: "quickshell"
        name: "palette-quick"
        description: "Open warmind launcher pivoted to Quick"
        onPressed: { root.open(); root.categoryFilter = "Quick"; }
    }

    // ---------- Panel ----------
    PanelWindow {
        id: panel
        visible: root.visible_ || reveal > 0.001
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "warmind-launcher"
        WlrLayershell.keyboardFocus: root.visible_ ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        property real reveal: root.visible_ ? 1 : 0
        // Open and close are both instant: SUPER+SPACE paints the palette on
        // the very next frame, and dismissal drops it the same frame with no
        // fade or scale-out lag.

        // Outside-click dismiss.
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            // Card sits slightly above visual centre so the result list grows
            // downward without dragging the search field out of the eyeline.
            y: parent.height * 0.18
            // Wide in any preview-bearing mode (file, github, processes,
            // themes) so a ~520px preview pane fits next to the result
            // list. Quick mode gets a larger card so the 3x3 tile grid can
            // breathe and the expanded detail panel has more room.
            width: root.llmMode ? 820 : (root.previewActive ? 1040 : (root.quickMode ? 920 : (root.colorSchemeMode ? 980 : 680)))
            Behavior on width {
                NumberAnimation { duration: 60; easing.type: Easing.OutCubic }
            }
            // In search/list modes, keep a stable vertical budget so the
            // card doesn't collapse to a tiny implicit height before the
            // list has real content. Quick mode can still auto-size to its
            // tile/detail content because that's the intended behavior.
            height: root.quickMode
                ? Math.min(cardCol.implicitHeight + 54, parent.height * 0.82)
                : (root.colorSchemeMode
                    ? Math.min(parent.height * 0.84, 760)
                    : (root.llmMode
                        ? Math.min(parent.height * 0.84, Math.max(690, cardCol.implicitHeight + 54))
                        : Math.min(parent.height * 0.63,
                                   root.passMode && passSearch.view === "overview"
                                       ? 562
                                       : (root.previewActive ? 522 : 504))))
            color: root.bg
            border.color: root.sep
            border.width: 1
            radius: root.cornerRadius
            transformOrigin: Item.Center
            scale: panel.reveal

            // Swallow clicks so the underlying dismiss MouseArea doesn't fire.
            MouseArea { anchors.fill: parent }

            focus: root.visible_
            Keys.onPressed: function(event) {
                // hjkl → arrow translation (Vim-style nav). Only active
                // in quickMode, where there is no typing buffer and the
                // tile grid is the sole input surface. In the main omni
                // search h/j/k/l are letters first; remapping them — even
                // conditionally on empty query — surprised users who
                // expected to start typing immediately.
                const _hjklMap = {};
                _hjklMap[Qt.Key_H] = Qt.Key_Left;
                _hjklMap[Qt.Key_J] = Qt.Key_Down;
                _hjklMap[Qt.Key_K] = Qt.Key_Up;
                _hjklMap[Qt.Key_L] = Qt.Key_Right;
                const _wrap = (e) => {
                    if (_hjklMap[e.key] === undefined) return e;
                    if (!root.quickMode) return e;
                    return { key: _hjklMap[e.key], modifiers: e.modifiers, text: e.text };
                };
                const e2 = _wrap(event);

                // When a quick tile is expanded, give its body first crack
                // at the key so arrow/Tab/Enter drive the body's own focus
                // chain (volume slider, wi-fi list, bluetooth list, …)
                // instead of the tile grid. Bodies return true from
                // kbdHandle() to swallow the event; anything they leave
                // unhandled (e.g. Esc) bubbles to the cascade below.
                const bodyItem = root.quickExpanded
                                 ? quickContainer.bodyLoaderItem.item
                                 : (root.launcherIconsMode ? launcherIconsBodyInstance
                                    : (root.colorSchemeMode ? colorSchemeBodyInstance : null));
                if ((root.quickExpanded || root.launcherIconsMode || root.colorSchemeMode)
                    && bodyItem
                    && typeof bodyItem.kbdHandle === "function"
                    && bodyItem.kbdHandle(e2)) {
                    event.accepted = true;
                    return;
                }
                if (e2.key === Qt.Key_Escape) {
                    if (root.llmMode && ollamaChat.cancelRequest()) {
                        event.accepted = true;
                        return;
                    }
                    // In pass mode, let passSearch unwind its own local
                    // state (overview/unlocking → list) before the outer
                    // Esc cascade runs.
                    if (root.passMode && passSearch.goBack()) {
                        event.accepted = true;
                        return;
                    }
                    // Esc cascade: collapse the quick-tile detail panel
                    // first (if open), then clear the typed query, then
                    // unwind drill-down, then close. Each Esc undoes
                    // exactly one layer of state so the palette never
                    // exits with a half-typed query on screen.
                    if (root.quickExpanded) {
                        root.expandedTile = null;
                    } else if (root.query.length > 0) {
                        root.setQuery("", 0);
                        root.selectedIndex = 0;
                    } else if (!root.goUp()) {
                        root.close();
                    }
                    event.accepted = true;
                } else if (root.quickMode && e2.key === Qt.Key_Left) {
                    root.moveQuickSelection(-1);
                    event.accepted = true;
                } else if (root.quickMode && e2.key === Qt.Key_Right) {
                    root.moveQuickSelection(1);
                    event.accepted = true;
                } else if (root.quickMode && e2.key === Qt.Key_Up) {
                    root.moveQuickSelection(-root.quickGridCols);
                    event.accepted = true;
                } else if (root.quickMode && e2.key === Qt.Key_Down) {
                    root.moveQuickSelection(root.quickGridCols);
                    event.accepted = true;
                } else if (root.quickMode
                           && (e2.key === Qt.Key_Tab && !(e2.modifiers & Qt.ShiftModifier))) {
                    root.moveQuickSelection(1);
                    event.accepted = true;
                } else if (root.quickMode
                           && (e2.key === Qt.Key_Backtab
                               || (e2.key === Qt.Key_Tab && (e2.modifiers & Qt.ShiftModifier)))) {
                    root.moveQuickSelection(-1);
                    event.accepted = true;
                } else if (root.llmMode && root.previewHasContent
                           && (e2.key === Qt.Key_Up || e2.key === Qt.Key_Down
                               || e2.key === Qt.Key_PageUp || e2.key === Qt.Key_PageDown
                               || e2.key === Qt.Key_Home || e2.key === Qt.Key_End
                               || e2.key === Qt.Key_Tab || e2.key === Qt.Key_Backtab)) {
                    // chat / command mode: same scroll routing as
                    // tldr mode below.
                    // List nav is a no-op here (single synthetic row).
                    const f = previewPaneInstance.chatFlickable;
                    const max = Math.max(0, f.contentHeight - f.height);
                    const line = 18;
                    const page = Math.max(line, f.height * 0.9);
                    let dy = 0;
                    if (e2.key === Qt.Key_Up
                        || (e2.key === Qt.Key_Tab && (e2.modifiers & Qt.ShiftModifier))
                        || e2.key === Qt.Key_Backtab) dy = -line;
                    else if (e2.key === Qt.Key_Down
                             || (e2.key === Qt.Key_Tab && !(e2.modifiers & Qt.ShiftModifier))) dy = line;
                    else if (e2.key === Qt.Key_PageUp)   dy = -page;
                    else if (e2.key === Qt.Key_PageDown) dy = page;
                    else if (e2.key === Qt.Key_Home) { f.contentY = 0; event.accepted = true; return; }
                    else if (e2.key === Qt.Key_End)  { f.contentY = max; event.accepted = true; return; }
                    f.contentY = Math.max(0, Math.min(max, f.contentY + dy));
                    event.accepted = true;
                } else if (root.tldrMode && root.tldrPreview !== ""
                           && (e2.key === Qt.Key_Up || e2.key === Qt.Key_Down
                               || e2.key === Qt.Key_PageUp || e2.key === Qt.Key_PageDown
                               || e2.key === Qt.Key_Home || e2.key === Qt.Key_End
                               || e2.key === Qt.Key_Tab || e2.key === Qt.Key_Backtab)) {
                    // tldr mode has a single synthetic row, so list nav is
                    // a no-op. Route arrow/page/home/end (and Tab/Shift+Tab,
                    // which would otherwise wrap the same row to itself) to
                    // the preview Flickable instead.
                    const f = previewPaneInstance.tldrFlickable;
                    const max = Math.max(0, f.contentHeight - f.height);
                    const line = 18;
                    const page = Math.max(line, f.height * 0.9);
                    let dy = 0;
                    if (e2.key === Qt.Key_Up
                        || (e2.key === Qt.Key_Tab && (e2.modifiers & Qt.ShiftModifier))
                        || e2.key === Qt.Key_Backtab) dy = -line;
                    else if (e2.key === Qt.Key_Down
                             || (e2.key === Qt.Key_Tab && !(e2.modifiers & Qt.ShiftModifier))) dy = line;
                    else if (e2.key === Qt.Key_PageUp)   dy = -page;
                    else if (e2.key === Qt.Key_PageDown) dy = page;
                    else if (e2.key === Qt.Key_Home) { f.contentY = 0; event.accepted = true; return; }
                    else if (e2.key === Qt.Key_End)  { f.contentY = max; event.accepted = true; return; }
                    f.contentY = Math.max(0, Math.min(max, f.contentY + dy));
                    event.accepted = true;
                } else if (e2.key === Qt.Key_Down
                           || (e2.key === Qt.Key_Tab && !(e2.modifiers & Qt.ShiftModifier))) {
                    // Tab + Down step forward, Shift+Tab + Up step backward,
                    // both wrap. Paging clamps (see Key_PageDown). Matches
                    // launcher convention everywhere else.
                    root.moveSelection(1, true);
                    event.accepted = true;
                } else if (e2.key === Qt.Key_Up
                           || e2.key === Qt.Key_Backtab
                           || (e2.key === Qt.Key_Tab && (e2.modifiers & Qt.ShiftModifier))) {
                    root.moveSelection(-1, true);
                    event.accepted = true;
                } else if (e2.key === Qt.Key_PageDown) {
                    root.moveSelection(8, false);
                    event.accepted = true;
                } else if (e2.key === Qt.Key_PageUp) {
                    root.moveSelection(-8, false);
                    event.accepted = true;
                } else if (e2.key === Qt.Key_Home) {
                    root.selectedIndex = 0;
                    resultListInstance.list.positionViewAtIndex(0, ListView.Beginning);
                    event.accepted = true;
                } else if (e2.key === Qt.Key_End) {
                    root.selectedIndex = Math.max(0, root.filteredItems.length - 1);
                    resultListInstance.list.positionViewAtIndex(root.selectedIndex, ListView.End);
                    event.accepted = true;
                } else if (e2.key === Qt.Key_Return || e2.key === Qt.Key_Enter) {
                    if (root.quickMode) {
                        const t = root.filteredQuickTiles[root.selectedIndex];
                        if (t) root.expandTile(t);
                    } else {
                        const it = root.filteredItems[root.selectedIndex];
                        if (it) {
                            // Ctrl+Enter: mode-specific secondary action.
                            if (e2.modifiers & Qt.ControlModifier) {
                                if (root.fileMode && it.path) { root.openFileParent(it); event.accepted = true; return; }
                                if (root.emojiMode) { emojiSearch.typeChar(it); event.accepted = true; return; }
                                if (root.passMode)  { passSearch.activateSecondary(it); event.accepted = true; return; }
                            }
                            root.activate(it);
                        }
                    }
                    event.accepted = true;
                } else if ((e2.modifiers & Qt.ControlModifier) && e2.key === Qt.Key_A) {
                    root.queryCursorPos = root.protectedPrefixLength();
                    event.accepted = true;
                } else if ((e2.modifiers & Qt.ControlModifier) && e2.key === Qt.Key_E) {
                    root.queryCursorPos = root.query.length;
                    event.accepted = true;
                } else if ((e2.modifiers & Qt.ControlModifier) && e2.key === Qt.Key_U) {
                    if (root.deleteToPromptPrefix()) event.accepted = true;
                } else if ((e2.modifiers & Qt.ControlModifier) && e2.key === Qt.Key_W) {
                    if (root.deleteWordBeforeCursor()) event.accepted = true;
                } else if ((e2.modifiers & Qt.AltModifier) && e2.key === Qt.Key_B) {
                    root.moveCursorWord(-1);
                    event.accepted = true;
                } else if ((e2.modifiers & Qt.AltModifier) && e2.key === Qt.Key_F) {
                    root.moveCursorWord(1);
                    event.accepted = true;
                } else if (e2.key === Qt.Key_Backspace) {
                    // Backspace deletes before the logical cursor; once the
                    // query is empty it walks back up one level so the same
                    // key unwinds both the typed query and the breadcrumb.
                    if (root.query.length > 0) {
                        if (!root.deleteBeforeCursor() && root.query.length === 0) root.goUp();
                    } else root.goUp();
                    event.accepted = true;
                } else if (!root.quickMode && !root.launcherIconsMode
                           && !root.colorSchemeMode
                           && e2.modifiers === Qt.NoModifier
                           && e2.key === Qt.Key_Left) {
                    root.moveCursor(-1);
                    event.accepted = true;
                } else if (!root.quickMode && !root.launcherIconsMode
                           && !root.colorSchemeMode
                           && e2.modifiers === Qt.NoModifier
                           && e2.key === Qt.Key_Right) {
                    root.moveCursor(1);
                    event.accepted = true;
                } else if (e2.key === Qt.Key_S && (e2.modifiers & Qt.ControlModifier)) {
                    const it = root.filteredItems[root.selectedIndex];
                    if (it && !it.isCategory && !it.isTldr && !it.isLlm) bookmarks.toggleFavourite(it);
                    event.accepted = true;
                } else if ((e2.modifiers & Qt.ControlModifier)
                           && (e2.key === Qt.Key_Plus || e2.key === Qt.Key_Equal
                               || e2.key === Qt.Key_Minus)) {
                    // Ctrl++ / Ctrl+- nudge the warmind launcher font scale;
                    // Ctrl+= resets to default. Plus is reached via
                    // Shift+= on US layouts (Qt delivers Qt.Key_Plus),
                    // and via a dedicated key on numpads / EU layouts.
                    if (e2.key === Qt.Key_Plus) root.bumpFontScale(+0.1);
                    else if (e2.key === Qt.Key_Minus) root.bumpFontScale(-0.1);
                    else /* Key_Equal without Shift */ root.fontScale = 1.0;
                    event.accepted = true;
                } else if (e2.key === Qt.Key_C && (e2.modifiers & Qt.ControlModifier)
                           && root.fileMode) {
                    const it = root.filteredItems[root.selectedIndex];
                    if (it && it.path) {
                        root.copyTextToClipboard(it.path);
                        event.accepted = true;
                        return;
                    }
                } else if (e2.key === Qt.Key_C && (e2.modifiers & Qt.ControlModifier)
                           && root.llmMode && root.chatPreview !== "") {
                    // Ctrl+C: if the user dragged a selection in the
                    // rendered RichText edit, copy that (lossy — Qt
                    // strips inline `code` backticks during conversion,
                    // but it's what they asked for). With no selection,
                    // copy the full raw markdown from the hidden plain-
                    // text shadow so pasted commands keep their syntax.
                    if (previewPaneInstance.chatEdit.selectedText.length > 0) {
                        previewPaneInstance.chatEdit.copy();
                    } else {
                        previewPaneInstance.chatPlain.selectAll();
                        previewPaneInstance.chatPlain.copy();
                        previewPaneInstance.chatPlain.deselect();
                    }
                    event.accepted = true;
                } else if (e2.key === Qt.Key_C && (e2.modifiers & Qt.ControlModifier)
                           && root.tldrMode && root.tldrPreview !== "") {
                    // Ctrl+C in tldr mode: copy the active selection if
                    // there is one, otherwise copy the whole rendered
                    // preview. The TextEdit's `copy()` works without
                    // active focus, so the search input keeps keystrokes.
                    if (previewPaneInstance.tldrEdit.selectedText.length > 0) {
                        previewPaneInstance.tldrEdit.copy();
                    } else {
                        previewPaneInstance.tldrEdit.selectAll();
                        previewPaneInstance.tldrEdit.copy();
                        previewPaneInstance.tldrEdit.deselect();
                    }
                    event.accepted = true;
                } else if (root.keybindMode && root.keybindPreview !== ""
                           && (e2.key === Qt.Key_Up || e2.key === Qt.Key_Down
                               || e2.key === Qt.Key_PageUp || e2.key === Qt.Key_PageDown
                               || e2.key === Qt.Key_Home || e2.key === Qt.Key_End
                               || e2.key === Qt.Key_Tab || e2.key === Qt.Key_Backtab)) {
                    // keybind mode: route nav keys to the preview Flickable
                    // since the list has only one synthetic row.
                    const f = previewPaneInstance.keybindFlickable;
                    const max = Math.max(0, f.contentHeight - f.height);
                    const line = 18;
                    const page = Math.max(line, f.height * 0.9);
                    let dy = 0;
                    if (e2.key === Qt.Key_Up
                        || (e2.key === Qt.Key_Tab && (e2.modifiers & Qt.ShiftModifier))
                        || e2.key === Qt.Key_Backtab) dy = -line;
                    else if (e2.key === Qt.Key_Down
                             || (e2.key === Qt.Key_Tab && !(e2.modifiers & Qt.ShiftModifier))) dy = line;
                    else if (e2.key === Qt.Key_PageUp)   dy = -page;
                    else if (e2.key === Qt.Key_PageDown) dy = page;
                    else if (e2.key === Qt.Key_Home) { f.contentY = 0; event.accepted = true; return; }
                    else if (e2.key === Qt.Key_End)  { f.contentY = max; event.accepted = true; return; }
                    f.contentY = Math.max(0, Math.min(max, f.contentY + dy));
                    event.accepted = true;
                } else if (e2.key === Qt.Key_C && (e2.modifiers & Qt.ControlModifier)
                           && root.keybindMode && root.keybindPreview !== "") {
                    // Ctrl+C in keybind mode: copy selection or whole preview.
                    if (previewPaneInstance.keybindEdit.selectedText.length > 0) {
                        previewPaneInstance.keybindEdit.copy();
                    } else {
                        previewPaneInstance.keybindEdit.selectAll();
                        previewPaneInstance.keybindEdit.copy();
                        previewPaneInstance.keybindEdit.deselect();
                    }
                    event.accepted = true;
                } else if (!root.quickMode && !root.launcherIconsMode && !root.colorSchemeMode && event.text && event.text.length === 1) {
                    const ch = event.text;
                    // Printable range; lets letters, digits, and spaces in,
                    // keeps modifier-driven control codes out. Skipped in
                    // quickMode — there's no search field to feed.
                    if (ch.charCodeAt(0) >= 32 && ch.charCodeAt(0) !== 127) {
                        root.insertText(ch);
                        event.accepted = true;
                    }
                }
            }

            Column {
                id: cardCol
                anchors.fill: parent
                anchors.margins: 17
                spacing: 12

                Omni.HeaderBar {
                    id: headerBar
                    omni: root
                    processes: processes
                    themes: themes
                    bookmarks: bookmarks
                }

                Rectangle { width: parent.width; height: 1; color: root.sep }

                Omni.QuickContainer {
                    id: quickContainer
                    omni: root
                    panel: panel
                }

                Item {
                    id: passEntryHeader
                    visible: root.passMode && passSearch.view === "overview"
                    width: parent.width
                    height: visible ? 58 : 0

                    Column {
                        anchors.fill: parent
                        spacing: 2

                        Text {
                            text: passSearch.currentEntryTitle
                            color: root.ink
                            font.family: root.mono
                            font.pixelSize: 16 * root.fontScale
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: passSearch.currentEntrySubtitle || passSearch.currentEntry
                            color: root.inkDeep
                            opacity: 0.78
                            font.family: root.mono
                            font.pixelSize: 12 * root.fontScale
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: "↵ autotype entry  ·  field: ↵ type / Ctrl+↵ copy  ·  Esc back"
                            color: root.seal
                            opacity: 0.9
                            font.family: root.mono
                            font.pixelSize: 12 * root.fontScale
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }

                Omni.SearchInput { omni: root }

                Rectangle {
                    visible: !root.quickMode && !root.launcherIconsMode && !root.colorSchemeMode
                    width: parent.width
                    height: 1
                    color: root.sep
                }

                // Fixed row height in the delegate keeps positionViewAtIndex
                // honest under fast keyboard navigation; the wrapping Item's
                // clip prevents the bottom row bleeding into the footer
                // hairline mid-scroll.
                LauncherIconsBody {
                    id: launcherIconsBodyInstance
                    visible: root.launcherIconsMode
                    width: parent.width
                    height: visible ? root.listHeight : 0
                    root: root
                }

                ColorSchemeBody {
                    id: colorSchemeBodyInstance
                    visible: root.colorSchemeMode
                    width: parent.width
                    height: visible ? Math.max(560, card.height - 120) : 0
                    root: root
                }

                Item {
                    id: listArea
                    visible: !root.quickMode && !root.launcherIconsMode && !root.colorSchemeMode
                    width: parent.width
                    height: visible ? root.listHeight : 0
                    clip: true

                    // Most preview-bearing modes keep the list + preview split.
                    // LLM modes (`?` / `$`) are better as a single-column stack:
                    // search bar, model header, then full-width output.
                    readonly property bool singleColumnPreview: root.llmMode
                    readonly property real listFraction:
                        singleColumnPreview ? 0.0 : (root.previewActive ? 0.44 : 1.0)

                    Omni.ResultList {
                        id: resultListInstance
                        visible: !listArea.singleColumnPreview
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        // Follows card.width's Behavior animation — adding a
                        // second Behavior here would animate to a moving
                        // target and produce staggered motion.
                        width: visible ? parent.width * listArea.listFraction : 0
                        omni: root
                        bookmarks: bookmarks
                        processes: processes
                        themes: themes
                        ollamaChat: ollamaChat
                    }

                    Rectangle {
                        visible: root.previewActive && !listArea.singleColumnPreview
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: resultListInstance.right
                        width: 1
                        color: root.sep
                    }

                    Omni.PreviewPane {
                        id: previewPaneInstance
                        visible: root.previewActive
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: listArea.singleColumnPreview ? parent.left : resultListInstance.right
                        anchors.leftMargin: listArea.singleColumnPreview ? 0 : 13
                        anchors.right: parent.right
                        omni: root
                        ollamaChat: ollamaChat
                    }
                }


            }
        }
    }
}
