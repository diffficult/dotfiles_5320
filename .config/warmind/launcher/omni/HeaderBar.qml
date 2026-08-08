import QtQuick

// Top section of the launcher card: category-aware title on the left,
// live stats on the right.
Item {
    id: header

    required property var omni
    property var processes: null
    property var themes:    null
    property var bookmarks: null

    width: parent ? parent.width : 0
    height: Math.max(34, title.implicitHeight + 6)

    function countApps(items) {
        let n = 0;
        for (let i = 0; i < items.length; i++) {
            if (items[i] && items[i].category === "App") n++;
        }
        return n;
    }

    function countActions(items) {
        let n = 0;
        for (let i = 0; i < items.length; i++) {
            const it = items[i];
            if (it && !it.isCategory && it.category !== "App") n++;
        }
        return n;
    }

    Text {
        id: title
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: header.omni.categoryFilter === ""
              ? ""
              : "  ›  " + header.omni.sectionIcon + "  " + header.omni.categoryFilter.toUpperCase()
        color: header.omni.ink
        font.family: header.omni.mono
        font.pixelSize: 21 * header.omni.fontScale
        font.letterSpacing: 2
        font.weight: Font.Medium
    }

    Text {
        id: stats
        anchors.right: parent.right
        anchors.baseline: title.baseline
        text: {
            const o = header.omni;
            if (!o.appsLoaded) return "LOADING APPS…";
            if (o.launcherIconsMode) {
                return "LIVE PREVIEW  ·  ↵ TOGGLE  ·  ←/→ SIZE  ·  ESC BACK";
            }
            if (o.colorSchemeMode) {
                return "LIVE THEME  ·  TAB SWITCHES SECTION  ·  ←/→ CHANGE  ·  ESC BACK";
            }
            if (o.fileMode) {
                if (o.fdRunning) return "SEARCHING FILES…";
                const total = o.filteredItems.length;
                if (o.query.length === 0) {
                    return total === 0
                        ? "PROJECTS  ·  DOWNLOADS  ·  DOCUMENTS"
                        : total + " FILE" + (total === 1 ? "" : "S") + "  ·  PRIORITY SCOPES";
                }
                return total === 0
                    ? "NO FILES MATCH"
                    : total + " FILE" + (total === 1 ? "" : "S") + "  ·  FD + FZF";
            }
            if (o.ghMode) {
                const total = o.filteredItems.length;
                if (o.query.length === 0) {
                    if (o.ghRunning && total === 0) return "LOADING PRS…";
                    return total === 0
                        ? "NO OPEN PRS"
                        : total + " OPEN PR" + (total === 1 ? "" : "S");
                }
                if (o.ghRunning) return "SEARCHING GITHUB…";
                return total === 0
                    ? "NO REPOS MATCH"
                    : total + " REPO" + (total === 1 ? "" : "S");
            }
            if (o.favMode) {
                const total = o.filteredItems.length;
                return total === 0
                    ? "NO FAVOURITES YET  ·  CTRL+S TO STAR"
                    : total + " FAVOURITE" + (total === 1 ? "" : "S");
            }
            if (o.histMode) {
                const total = o.filteredItems.length;
                return total === 0
                    ? "NO HISTORY YET"
                    : total + " RECENT" + (total === 1 ? "" : "S");
            }
            if (o.procMode) {
                const total = o.filteredItems.length;
                if (header.processes && header.processes.running && total === 0) return "LOADING PROCESSES…";
                return total === 0
                    ? "NO PROCESSES"
                    : total + " PROCESS" + (total === 1 ? "" : "ES");
            }
            if (o.themeMode) {
                const total = o.filteredItems.length;
                if (header.themes && !header.themes.loaded && total === 0) return "LOADING THEMES…";
                return total === 0
                    ? "NO THEMES FOUND"
                    : total + " THEME" + (total === 1 ? "" : "S");
            }
            const total = o.filteredItems.length;
            const totalApps = header.countApps(o.allItems);
            if (o.query.length === 0) {
                return totalApps + " APPS  ·  " + header.countActions(o.allItems) + " ACTIONS";
            }
            const matchedApps = header.countApps(o.filteredItems);
            return total === 0
                ? "NO MATCHES"
                : matchedApps + " APPS  ·  " + total + " MATCH" + (total === 1 ? "" : "ES");
        }
        color: header.omni.inkDeep
        font.family: header.omni.mono
        font.pixelSize: 13 * header.omni.fontScale
        font.letterSpacing: 2
        horizontalAlignment: Text.AlignRight
        width: Math.max(0, parent.width - title.width - 18)
    }
}
