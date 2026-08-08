import QtQuick
import QtQuick.Layouts
import ".."

// Quick-mode container: tile grid on the left, optional detail panel
// on the right when a tile is expanded. The grid compresses to a
// 64px column when something is expanded so the panel gets the wider
// right half. `bodyLoaderItem` is aliased so the OmniMenu key handler
// can give the active body first crack at arrow/Enter/Esc.
Item {
    id: qc

    required property var omni
    required property var panel

    property alias bodyLoaderItem: bodyLoader

    visible: omni.quickMode
    width: parent ? parent.width : 0
    height: visible
        ? Math.max(quickGrid.height,
                   detailPanel.visible ? detailPanel.height : 0)
        : 0

    Item {
        id: quickGrid
        visible: qc.omni.quickMode
        // Expanded: compress to a narrow column on the left edge so
        // the detail panel gets the wider right half.
        readonly property bool colMode: qc.omni.quickExpanded
        anchors.top: parent.top
        anchors.left: parent.left
        width: colMode ? 80 : parent.width
        readonly property int tileH: colMode ? 52 : 114
        readonly property int spacing: colMode ? 6 : 14
        readonly property int rows: visible
            ? Math.ceil(qc.omni.filteredQuickTiles.length / qc.omni.quickGridCols)
            : 0
        height: visible
            ? (rows * tileH + Math.max(0, rows - 1) * spacing)
            : 0

        Grid {
            anchors.fill: parent
            columns: qc.omni.quickGridCols
            rowSpacing: quickGrid.spacing
            columnSpacing: quickGrid.spacing

            Repeater {
                model: qc.omni.filteredQuickTiles
                delegate: Item {
                    id: tileSlot
                    required property var modelData
                    required property int index
                    readonly property bool selected: qc.omni.selectedIndex === index
                    width: (quickGrid.width - (qc.omni.quickGridCols - 1) * quickGrid.spacing)
                           / qc.omni.quickGridCols
                    height: quickGrid.tileH

                    Rectangle {
                        anchors.fill: parent
                        radius: qc.omni.cornerRadius
                        color: tileSlot.selected
                               ? Qt.rgba(qc.omni.ink.r, qc.omni.ink.g, qc.omni.ink.b, 0.08)
                               : tileMouse.containsMouse
                                    ? Qt.rgba(qc.omni.ink.r, qc.omni.ink.g, qc.omni.ink.b, 0.05)
                                    : Qt.rgba(qc.omni.ink.r, qc.omni.ink.g, qc.omni.ink.b, 0.03)
                        border.color: tileSlot.selected ? qc.omni.seal : qc.omni.sep
                        border.width: tileSlot.selected ? 2 : 1
                        Behavior on color        { ColorAnimation  { duration: 50 } }
                        Behavior on border.color { ColorAnimation  { duration: 50 } }
                        Behavior on border.width { NumberAnimation { duration: 50 } }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: quickGrid.colMode ? 5 : 12
                        spacing: quickGrid.colMode ? 1 : 5

                        Text {
                            readonly property var dyn: qc.omni.tileDyn(tileSlot.modelData)
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: qc.omni.showQuickTileGlyphs
                            text: dyn.glyph || ""
                            color: dyn.tone || qc.omni.ink
                            font.family: qc.omni.mono
                            font.pixelSize: (quickGrid.colMode ? Math.max(14, qc.omni.quickTileGlyphSize - 10)
                                                               : qc.omni.quickTileGlyphSize) * qc.omni.fontScale
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: qc.omni.tileDyn(tileSlot.modelData).label || ""
                            color: qc.omni.ink
                            font.family: qc.omni.mono
                            font.pixelSize: (quickGrid.colMode ? 11 : 14) * qc.omni.fontScale
                            font.letterSpacing: quickGrid.colMode ? 0.8 : 1.4
                            font.weight: Font.Medium
                        }
                        // Sub-label is redundant in colMode - the detail
                        // panel header above shows the same live value.
                        // Hiding it lets the column fit all 12 tiles
                        // inside the card's vertical budget.
                        Text {
                            visible: !quickGrid.colMode
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: qc.omni.tileDyn(tileSlot.modelData).sub || ""
                            color: qc.omni.inkDeep
                            font.family: qc.omni.mono
                            font.pixelSize: 12 * qc.omni.fontScale
                            font.letterSpacing: 1
                            opacity: 0.85
                        }
                    }

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPositionChanged: qc.omni.selectedIndex = tileSlot.index
                        onClicked: (e) => {
                            qc.omni.selectedIndex = tileSlot.index;
                            if (e.button === Qt.RightButton) {
                                // Right-click still runs the long action
                                // (mute toggle, refresh, reset) without
                                // opening the detail panel.
                                qc.omni.longQuickTile(tileSlot.modelData);
                            } else {
                                qc.omni.expandTile(tileSlot.modelData);
                            }
                        }
                    }
                }
            }
        }
    }

    // Vertical separator between the compressed tile column (left)
    // and the detail panel (right). Anchored to the grid's right
    // edge so it tracks the column's width.
    Rectangle {
        id: quickMidSep
        visible: qc.omni.quickExpanded
        anchors.left: quickGrid.right
        anchors.leftMargin: 16
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: qc.omni.sep
    }

    // ---------- Quick tile detail panel ----------
    // Drops beside the tile column when a tile is clicked. Each tile
    // gets a small adjustment surface here - sliders for audio +
    // display, action buttons for everything else. The whole panel
    // collapses to height 0 when no tile is expanded so the card
    // auto-shrinks back to its grid-only footprint.
    Item {
        id: detailPanel
        visible: qc.omni.quickExpanded
        anchors.left: quickMidSep.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.top: parent.top
        // Cap the panel so the card never extends past its budget.
        // Body content beyond this height scrolls inside `bodyScroll`
        // below instead of pushing the card off-screen.
        readonly property real _maxHeight: qc.panel.height * 0.55
        readonly property real _wantHeight: detailHeader.implicitHeight + bodyLoader.implicitContentHeight + 18
        height: visible ? Math.min(_wantHeight, _maxHeight) : 0
        clip: true
        Behavior on height {
            NumberAnimation { duration: 60; easing.type: Easing.OutCubic }
        }

        readonly property var t: qc.omni.expandedTile
        readonly property string tKey: t ? t.key : ""
        // Forward to the OmniMenu root under a non-conflicting name.
        // Inside the Component children below, an expression like
        // `root: root` would self-bind to the body's own `root`
        // property (still undefined at the moment of evaluation)
        // rather than reach the outer id. `omni` lets us reference
        // the OmniMenu root unambiguously from within those
        // Component templates.
        readonly property var omni: qc.omni

        // Per-tile body Components - instantiated by the Loader below
        // based on `tKey`. Each body owns its own controls (sliders,
        // lists) and may emit `close` to dismiss OmniMenu after an
        // action that takes focus away.
        Component { id: batteryBodyComp;     QuickBatteryBody     { root: detailPanel.omni; nav: detailPanel.omni.navbar; powerController: detailPanel.omni.navbar ? detailPanel.omni.navbar.power : null } }
        Component { id: audioBodyComp;       QuickAudioBody       { root: detailPanel.omni; controller: detailPanel.omni.navbar ? detailPanel.omni.navbar.audio : null } }
        Component { id: wifiBodyComp;        QuickWifiBody        { root: detailPanel.omni; nav: detailPanel.omni.navbar; controller: detailPanel.omni.navbar ? detailPanel.omni.navbar.wifi : null } }
        Component { id: btBodyComp;          QuickBluetoothBody   { root: detailPanel.omni; controller: detailPanel.omni.navbar ? detailPanel.omni.navbar.bluetooth : null } }
        Component { id: weatherBodyComp;     QuickWeatherBody     { root: detailPanel.omni; controller: detailPanel.omni.navbar ? detailPanel.omni.navbar.weather : null } }
        Component { id: calendarBodyComp;    QuickCalendarBody    { root: detailPanel.omni; controller: detailPanel.omni.navbar ? detailPanel.omni.navbar.calendar : null } }
        Component { id: cpuBodyComp;         QuickCpuBody         { root: detailPanel.omni; nav: detailPanel.omni.navbar } }
        Component { id: screenshotsBodyComp; QuickScreenshotsBody { root: detailPanel.omni; controller: detailPanel.omni.navbar ? detailPanel.omni.navbar.screenshots : null } }
        Component { id: videosBodyComp;      QuickVideosBody      { root: detailPanel.omni; controller: detailPanel.omni.navbar ? detailPanel.omni.navbar.videos : null } }
        Component { id: powerBodyComp;       QuickPowerBody       { root: detailPanel.omni; nav: detailPanel.omni.navbar; controller: detailPanel.omni.navbar ? detailPanel.omni.navbar.power : null } }

        // Header (always visible at the top of the panel)
        RowLayout {
            id: detailHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 6
            spacing: 12
            Text {
                readonly property var dyn: qc.omni.tileDyn(detailPanel.t)
                visible: qc.omni.showQuickDetailGlyphs
                text: dyn.glyph || ""
                color: dyn.tone || qc.omni.ink
                font.family: qc.omni.mono
                font.pixelSize: qc.omni.quickDetailGlyphSize * qc.omni.fontScale
                Layout.alignment: Qt.AlignVCenter
            }
            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                Text {
                    text: qc.omni.tileDyn(detailPanel.t).label || ""
                    color: qc.omni.ink
                    font.family: qc.omni.mono
                    font.pixelSize: 17 * qc.omni.fontScale
                    font.letterSpacing: 2
                    font.weight: Font.Medium
                }
                Text {
                    text: qc.omni.tileDyn(detailPanel.t).sub || ""
                    color: qc.omni.inkDeep
                    font.family: qc.omni.mono
                    font.pixelSize: 14 * qc.omni.fontScale
                    font.letterSpacing: 1
                    opacity: 0.85
                }
            }
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 22; height: 22; radius: 11
                color: closeMouse.containsMouse
                       ? Qt.rgba(qc.omni.ink.r, qc.omni.ink.g, qc.omni.ink.b, 0.08)
                       : "transparent"
                border.color: qc.omni.sep
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: qc.omni.inkDeep
                    font.family: qc.omni.mono
                    font.pixelSize: 18 * qc.omni.fontScale
                }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: qc.omni.collapseTile()
                }
            }
        }

        // Scrollable body region: takes whatever vertical space is
        // left after the header. When the body content exceeds the
        // available space the user can flick / scroll inside this
        // clipped region instead of having content fall off the card.
        Flickable {
            id: bodyScroll
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: detailHeader.bottom
            anchors.bottom: parent.bottom
            anchors.topMargin: 10
            contentWidth: width
            contentHeight: bodyLoader.implicitContentHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            WheelHandler {
                enabled: bodyScroll.contentHeight > bodyScroll.height
                onWheel: (event) => {
                    const max = Math.max(0, bodyScroll.contentHeight - bodyScroll.height);
                    bodyScroll.contentY = Math.max(0, Math.min(max,
                        bodyScroll.contentY - event.angleDelta.y * 0.5));
                }
            }

            Loader {
                id: bodyLoader
                width: bodyScroll.width
                active: detailPanel.visible
                // Exposed so detailPanel.height can clamp to
                // panel-budget while still picking the shorter of
                // "content" / "available".
                readonly property real implicitContentHeight: item ? item.implicitHeight : 0
                sourceComponent: {
                    switch (detailPanel.tKey) {
                        case "battery":     return batteryBodyComp;
                        case "audio":       return audioBodyComp;
                        case "network":     return wifiBodyComp;
                        case "bluetooth":   return btBodyComp;
                        case "weather":     return weatherBodyComp;
                        case "calendar":    return calendarBodyComp;
                        case "cpu":         return cpuBodyComp;
                        case "screenshots": return screenshotsBodyComp;
                        case "videos":      return videosBodyComp;
                        case "power":       return powerBodyComp;
                    }
                    return null;
                }
                onLoaded: {
                    if (item && item.close)
                        item.close.connect(function() { qc.omni.close(); });
                    if (item && ("scroller" in item))
                        item.scroller = bodyScroll;
                    bodyScroll.contentY = 0;
                }
            }

            // Slim scroll indicator on the right edge - only visible
            // while overflow exists. Tracks the viewport position so
            // the user has a hint that more content is below.
            Rectangle {
                visible: bodyScroll.contentHeight > bodyScroll.height
                anchors.right: parent.right
                anchors.rightMargin: 2
                width: 3
                radius: 1.5
                color: qc.omni.seal
                opacity: 0.55
                y: bodyScroll.contentHeight > 0
                   ? (bodyScroll.contentY / bodyScroll.contentHeight) * bodyScroll.height
                   : 0
                height: bodyScroll.contentHeight > 0
                        ? Math.max(20, (bodyScroll.height / bodyScroll.contentHeight) * bodyScroll.height)
                        : 0
            }
        }
    }
}
