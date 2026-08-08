import QtQuick
import Quickshell.Io

// Two-mode picker — local aether blueprints, or wallhaven.cc browse
// with thumbnail-driven palette extraction.
CardWindow {
    id: aetherPopup
    required property var root

    property string mode: "blueprints"
    readonly property bool wallhavenMode: mode === "wallhaven"

    WallhavenSource {
        id: wallhaven
        navbar: aetherPopup.root
        active: aetherPopup.wallhavenMode && aetherPopup.revealed
    }

    theme: root
    revealed: root.aetherVisible
    cardWidth: wallhavenMode ? 580 : 460
    layerNamespace: "omarchy-aether"

    title: "AETHER"
    subtitle: {
        const r = aetherPopup.root;
        if (aetherPopup.wallhavenMode) {
            if (wallhaven.loading && wallhaven.items.length === 0) return "WALLHAVEN  ·  LOADING…";
            const n = wallhaven.items.length;
            if (n === 0) return "WALLHAVEN  ·  NO RESULTS";
            const tag = wallhaven.query === "" ? "TOPLIST" : "“" + wallhaven.query + "”";
            return "WALLHAVEN  ·  " + tag + "  ·  " + n + " LOADED" + (wallhaven.loading ? "  ·  +" : "");
        }
        if (r.aetherLoading) return "BLUEPRINTS  ·  LOADING…";
        const total = r.aetherBlueprints.length;
        if (total === 0) return "BLUEPRINTS  ·  NONE";
        const shown = r.aetherFiltered.length;
        if (r.aetherQuery === "") return "BLUEPRINTS  ·  " + total + " SAVED";
        return shown === 0
            ? "BLUEPRINTS  ·  NO MATCHES"
            : "BLUEPRINTS  ·  " + shown + " / " + total + " MATCH" + (shown === 1 ? "" : "ES");
    }
    footer: aetherPopup.wallhavenMode
            ? "SCROLL FOR MORE  ·  ↵ APPLY  ·  ^M MATERIAL  ·  TAB MODE  ·  ESC"
            : "TAB SWITCHES MODE  ·  ↵ APPLY  ·  ESC CLOSE"

    headerRight: CalendarChevron {
        visible: aetherPopup.wallhavenMode
        root: aetherPopup.root
        text: aetherPopup.root.icoRefresh
        restColor: aetherPopup.root.inkDeep
        font.pixelSize: 22
        onTriggered: wallhaven.refresh()
    }

    onDismiss: aetherPopup.root.aetherVisible = false

    onKeyPressed: function(event) {
        const r = aetherPopup.root;
        const k = event.key;
        const mods = event.modifiers;

        // Plain Tab toggles modes; Shift+Tab is reserved for backward
        // list nav in blueprint mode.
        if (k === Qt.Key_Tab && !(mods & Qt.ShiftModifier) && !aetherPopup.wallhavenMode && r.aetherQuery.length === 0) {
            aetherPopup.mode = "wallhaven";
            event.accepted = true;
            return;
        }

        if (aetherPopup.wallhavenMode) {
            const followSel = () => wallhavenGrid.positionViewAtIndex(wallhaven.selectedIndex, GridView.Contain);
            // Toggle the material extraction mode. Ctrl is required so
            // plain "m" still types into the search query.
            if (k === Qt.Key_M && (mods & Qt.ControlModifier)) {
                wallhaven.material = !wallhaven.material;
                event.accepted = true;
                return;
            }
            if (k === Qt.Key_Right) {
                wallhaven.moveSelection(1); followSel();
            } else if (k === Qt.Key_Left) {
                wallhaven.moveSelection(-1); followSel();
            } else if (k === Qt.Key_Down) {
                wallhaven.moveSelection(4); followSel();
            } else if (k === Qt.Key_Up) {
                wallhaven.moveSelection(-4); followSel();
            } else if (k === Qt.Key_Home) {
                wallhavenGrid.positionViewAtBeginning();
                if (wallhaven.items.length > 0) wallhaven.selectedIndex = 0;
            } else if (k === Qt.Key_End) {
                wallhavenGrid.positionViewAtEnd();
                if (wallhaven.items.length > 0) wallhaven.selectedIndex = wallhaven.items.length - 1;
            } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                const it = wallhaven.items[wallhaven.selectedIndex];
                if (it) {
                    wallhaven.applyItem(it);
                    r.aetherVisible = false;
                }
            } else if (k === Qt.Key_Backspace) {
                if (wallhaven.query.length > 0) {
                    wallhaven.query = wallhaven.query.slice(0, -1);
                } else {
                    aetherPopup.mode = "blueprints";
                }
            } else if (event.text && event.text.length === 1) {
                const ch = event.text;
                if (ch.charCodeAt(0) >= 32 && ch.charCodeAt(0) !== 127) {
                    wallhaven.query += ch;
                } else {
                    return;
                }
            } else {
                return;
            }
            event.accepted = true;
            return;
        }

        if (k === Qt.Key_Down
            || (k === Qt.Key_Tab && !(mods & Qt.ShiftModifier))) {
            r.moveAetherSelection(1, true);
            aetherList.positionViewAtIndex(r.selectedAether, ListView.Contain);
        } else if (k === Qt.Key_Up
                   || k === Qt.Key_Backtab
                   || (k === Qt.Key_Tab && (mods & Qt.ShiftModifier))) {
            r.moveAetherSelection(-1, true);
            aetherList.positionViewAtIndex(r.selectedAether, ListView.Contain);
        } else if (k === Qt.Key_PageDown) {
            r.moveAetherSelection(8, false);
            aetherList.positionViewAtIndex(r.selectedAether, ListView.Contain);
        } else if (k === Qt.Key_PageUp) {
            r.moveAetherSelection(-8, false);
            aetherList.positionViewAtIndex(r.selectedAether, ListView.Contain);
        } else if (k === Qt.Key_Home) {
            if (r.aetherFiltered.length > 0) {
                r.selectedAether = 0;
                aetherList.positionViewAtIndex(0, ListView.Beginning);
            }
        } else if (k === Qt.Key_End) {
            const n = r.aetherFiltered.length;
            if (n > 0) {
                r.selectedAether = n - 1;
                aetherList.positionViewAtIndex(n - 1, ListView.End);
            }
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            const e = r.aetherFiltered[r.selectedAether];
            if (e) r.applyAetherBlueprint(e.name);
        } else if (k === Qt.Key_Backspace) {
            if (r.aetherQuery.length > 0)
                r.aetherQuery = r.aetherQuery.slice(0, -1);
        } else if (event.text && event.text.length === 1) {
            const ch = event.text;
            if (ch.charCodeAt(0) >= 32 && ch.charCodeAt(0) !== 127) {
                r.aetherQuery += ch;
            } else {
                return;
            }
        } else {
            return;
        }
        event.accepted = true;
    }

    // ---------- Body ----------
    Column {
        width: parent.width
        spacing: 12

        // Mode switch chips. Material toggle hangs off the right edge,
        // only meaningful in wallhaven mode so we hide it elsewhere.
        Item {
            width: parent.width
            height: 22
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                DisplayChip {
                    root: aetherPopup.root
                    label: "BLUEPRINTS"
                    selected: !aetherPopup.wallhavenMode
                    onActivated: aetherPopup.mode = "blueprints"
                }
                DisplayChip {
                    root: aetherPopup.root
                    label: "WALLHAVEN"
                    selected: aetherPopup.wallhavenMode
                    onActivated: aetherPopup.mode = "wallhaven"
                }
            }
            DisplayChip {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                root: aetherPopup.root
                label: "MATERIAL"
                visible: aetherPopup.wallhavenMode
                selected: wallhaven.material
                onActivated: wallhaven.material = !wallhaven.material
            }
        }

        Rectangle { width: parent.width; height: 1; color: aetherPopup.root.sep }

        // Search row — feeds the active mode's query.
        Item {
            width: parent.width
            height: 28

            Text {
                id: aetherSearchGlyph
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: aetherPopup.root.icoSearch
                color: aetherPopup.root.seal
                font.family: aetherPopup.root.mono
                font.pixelSize: 14
            }

            Text {
                id: aetherQueryText
                anchors.left: aetherSearchGlyph.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                readonly property string activeQuery: aetherPopup.wallhavenMode
                    ? wallhaven.query : aetherPopup.root.aetherQuery
                text: activeQuery.length === 0
                      ? (aetherPopup.wallhavenMode
                            ? "Search wallhaven (empty = toplist)…"
                            : "Filter blueprints…")
                      : activeQuery
                color: activeQuery.length === 0 ? aetherPopup.root.inkDeep : aetherPopup.root.ink
                opacity: activeQuery.length === 0 ? 0.5 : 1.0
                font.family: aetherPopup.root.mono
                font.pixelSize: 12
                font.letterSpacing: 1
            }

            Rectangle {
                width: 2
                height: 14
                color: aetherPopup.root.seal
                anchors.verticalCenter: parent.verticalCenter
                x: aetherQueryText.activeQuery.length === 0
                   ? aetherSearchGlyph.x + aetherSearchGlyph.width + 10
                   : aetherQueryText.x + aetherQueryText.contentWidth + 2
                visible: aetherPopup.root.aetherVisible
                SequentialAnimation on opacity {
                    running: aetherPopup.root.aetherVisible
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 0.2; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.2; to: 1; duration: 600; easing.type: Easing.InOutSine }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: aetherPopup.root.sep }

        // ---------- Blueprints list ----------
        ListView {
            id: aetherList
            width: parent.width
            height: 360
            visible: !aetherPopup.wallhavenMode
            clip: true
            model: aetherPopup.root.aetherFiltered
            spacing: 0
            currentIndex: aetherPopup.root.selectedAether
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: aeRow
                required property var modelData
                required property int index
                width: aetherList.width
                height: 34

                readonly property bool selected: aetherPopup.root.selectedAether === aeRow.index

                Rectangle {
                    anchors.fill: parent
                    color: rowMouse.containsMouse
                           ? Qt.rgba(aetherPopup.root.ink.r, aetherPopup.root.ink.g, aetherPopup.root.ink.b, 0.10)
                           : (aeRow.selected
                              ? Qt.rgba(aetherPopup.root.ink.r, aetherPopup.root.ink.g, aetherPopup.root.ink.b, 0.04)
                              : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Rectangle {
                    visible: aeRow.selected
                    width: 2
                    height: parent.height - 10
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: aetherPopup.root.seal
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 175
                    elide: Text.ElideRight
                    text: aeRow.modelData.name
                    color: aeRow.selected ? aetherPopup.root.ink : aetherPopup.root.inkDeep
                    font.family: aetherPopup.root.mono
                    font.pixelSize: 11
                    font.letterSpacing: 1
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 190
                    anchors.verticalCenter: parent.verticalCenter
                    text: aeRow.modelData.lightMode ? "L" : "D"
                    color: aetherPopup.root.inkDeep
                    font.family: aetherPopup.root.mono
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    opacity: 0.7
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Repeater {
                        model: (aeRow.modelData.colors || []).slice(0, 8)
                        delegate: Rectangle {
                            required property var modelData
                            width: 14
                            height: 14
                            color: modelData
                            border.color: Qt.rgba(0, 0, 0, 0.25)
                            border.width: 1
                        }
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: aetherPopup.root.selectedAether = aeRow.index
                    onClicked: aetherPopup.root.applyAetherBlueprint(aeRow.modelData.name)
                }
            }
        }

        // ---------- Wallhaven grid (scrollable) ----------
        GridView {
            id: wallhavenGrid
            width: parent.width
            height: 360
            visible: aetherPopup.wallhavenMode
            clip: true
            cellWidth: width / 4
            cellHeight: cellWidth * 9 / 16 + 4
            model: wallhaven.items
            currentIndex: wallhaven.selectedIndex
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: cellHeight * 2

            // Flickable's built-in wheel maps too small for a grid.
            WheelHandler {
                target: null
                onWheel: function(event) {
                    const grid = wallhavenGrid;
                    const step = grid.cellHeight * 1.5;
                    const dy = event.angleDelta.y > 0 ? -step : step;
                    const max = Math.max(0, grid.contentHeight - grid.height);
                    grid.contentY = Math.max(0, Math.min(max, grid.contentY + dy));
                    event.accepted = true;
                }
            }

            // !loading guards an in-flight page; items.length > 0 keeps
            // the cold-open from firing (atYEnd is true on an empty list).
            onAtYEndChanged: {
                if (atYEnd && !wallhaven.loading && wallhaven.items.length > 0) {
                    wallhaven.loadNextPage();
                }
            }

            delegate: Item {
                id: whCell
                required property var modelData
                required property int index
                readonly property bool isSelected: wallhaven.selectedIndex === whCell.index
                property var extractedPalette: []

                width: wallhavenGrid.cellWidth
                height: wallhavenGrid.cellHeight

                // watchChanges only while rendering and not yet loaded
                // — keeps inotify slots from leaking across scrolls.
                FileView {
                    path: wallhaven.palettePathFor(whCell.modelData)
                    watchChanges: aetherPopup.wallhavenMode
                                  && aetherPopup.revealed
                                  && whCell.extractedPalette.length === 0
                    onFileChanged: reload()
                    onLoaded: {
                        const lines = text().split("\n");
                        const out = [];
                        for (let i = 0; i < lines.length; i++) {
                            const s = lines[i].trim();
                            if (s.length > 0 && s.charAt(0) === "#") out.push(s);
                        }
                        whCell.extractedPalette = out;
                    }
                }

                // Switching modes points the FileView at a different
                // cache file; clear the cached palette so watchChanges
                // re-arms and swatches refresh once the new file lands.
                Connections {
                    target: wallhaven
                    function onMaterialChanged() { whCell.extractedPalette = []; }
                }

                Rectangle {
                    id: whImageBox
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 3
                    height: parent.height - 12
                    color: Qt.rgba(aetherPopup.root.ink.r, aetherPopup.root.ink.g, aetherPopup.root.ink.b, 0.04)
                    border.color: whCell.isSelected ? aetherPopup.root.seal : aetherPopup.root.sep
                    border.width: 1
                    antialiasing: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: aetherPopup.revealed ? whCell.modelData.thumb : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 256
                        sourceSize.height: 144
                        asynchronous: true
                        cache: true
                        clip: true
                        opacity: whMouse.containsMouse || whCell.isSelected ? 1.0 : 0.85
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }
                }

                Row {
                    anchors.top: whImageBox.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 3
                    anchors.rightMargin: 3
                    anchors.topMargin: 1
                    spacing: 0
                    Repeater {
                        model: whCell.extractedPalette.slice(0, 8)
                        delegate: Rectangle {
                            required property var modelData
                            width: (whCell.width - 6) / 8
                            height: 8
                            color: modelData
                        }
                    }
                }

                MouseArea {
                    id: whMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: wallhaven.selectedIndex = whCell.index
                    onClicked: {
                        wallhaven.applyItem(whCell.modelData);
                        aetherPopup.root.aetherVisible = false;
                    }
                }
            }
        }

        Text {
            width: parent.width
            visible: aetherPopup.wallhavenMode && wallhaven.items.length === 0
            horizontalAlignment: Text.AlignHCenter
            text: wallhaven.loading ? "FETCHING WALLHAVEN…"
                                    : "NO RESULTS — TRY A DIFFERENT QUERY"
            color: aetherPopup.root.inkDeep
            font.family: aetherPopup.root.mono
            font.pixelSize: 11
            font.letterSpacing: 2
            opacity: 0.6
            padding: 60
        }

        Rectangle {
            width: parent.width
            height: 1
            color: aetherPopup.root.sep
            visible: !aetherPopup.wallhavenMode
        }

        // ---------- Blueprint-only actions ----------
        Item {
            width: parent.width
            height: 26
            visible: !aetherPopup.wallhavenMode
            DisplayChip {
                root: aetherPopup.root
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                label: "OPEN GUI"
                onActivated: {
                    aetherPopup.root.run("aether");
                    aetherPopup.root.aetherVisible = false;
                }
            }
            DisplayChip {
                root: aetherPopup.root
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                label: "RANDOM REGEN"
                onActivated: {
                    aetherPopup.root.run("sh -c 'aether --generate \"$(aether --random-wallpaper)\"'");
                    aetherPopup.root.aetherVisible = false;
                }
            }
        }
    }
}
