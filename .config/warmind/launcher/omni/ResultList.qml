import QtQuick

// Vertical result list. Row delegate handles icon resolution (image
// fallback to glyph), title with drill-in chevron, favourite star, and
// category label. `list` is aliased so the parent's key handler can
// call positionViewAtIndex without reaching through child ids.
Item {
    id: rl

    required property var omni
    required property var bookmarks
    required property var processes
    required property var themes
    required property var ollamaChat

    property alias list: resultList

    ListView {
        id: resultList
        anchors.fill: parent
        model: rl.omni.filteredItems
        currentIndex: rl.omni.selectedIndex
        highlightFollowsCurrentItem: false
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 200
        // Snap pixel-perfect so the row outline doesn't shimmer during
        // arrow-key scroll.
        pixelAligned: true

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            width: ListView.view.width
            readonly property bool hasSubtitle: !!(row.modelData.subtitle && row.modelData.subtitle.length > 0)
            readonly property bool isPassDetail: row.modelData.category === "Pass" && (row.modelData.rowKind === "field" || row.modelData.rowKind === "header")
            readonly property bool isFileDetail: row.modelData.rowKind === "file"
            readonly property bool isTwoLine: row.hasSubtitle && (row.isPassDetail || row.isFileDetail)
            height: row.isTwoLine ? 58 : 42
            readonly property bool isSelected: rl.omni.selectedIndex === index

            Rectangle {
                anchors.fill: parent
                color: row.isSelected ? rl.omni.rowSel
                                      : rowMouse.containsMouse ? rl.omni.rowHi
                                                               : "transparent"
                Behavior on color { ColorAnimation { duration: 40 } }
            }
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 3
                color: rl.omni.seal
                visible: row.isSelected
            }

            // Icon slot: real-colour .desktop image when one resolves,
            // nerd-font glyph fallback otherwise. hasImageIcon flips
            // on Image.Ready so the swap happens in one frame, no
            // broken-icon flash.
            Item {
                id: iconText
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                readonly property int glyphSize: rl.omni.listGlyphSize
                readonly property int appSize: rl.omni.listAppIconSize
                readonly property int visibleBox: Math.max(rl.omni.showListGlyphs ? glyphSize : 0,
                                                           rl.omni.showListAppIcons ? appSize : 0)
                width: visibleBox > 0 ? visibleBox + 4 : 0
                height: visibleBox > 0 ? visibleBox + 4 : 0

                readonly property string iconUrl: rl.omni.resolveIconUrl(row.modelData.rawIcon, row.modelData.resolvedIcon)
                readonly property bool hasImageIcon: rl.omni.showListAppIcons && appImg.status === Image.Ready && iconUrl !== ""
                readonly property color tint: row.isSelected ? rl.omni.seal : rl.omni.inkDeep

                Text {
                    anchors.centerIn: parent
                    visible: rl.omni.showListGlyphs && !iconText.hasImageIcon
                    text: row.modelData.icon || "·"
                    color: iconText.tint
                    font.family: rl.omni.mono
                    font.pixelSize: rl.omni.listGlyphSize * rl.omni.fontScale
                }

                Image {
                    id: appImg
                    anchors.centerIn: parent
                    width: rl.omni.listAppIconSize
                    height: rl.omni.listAppIconSize
                    visible: iconText.hasImageIcon
                    source: iconText.iconUrl
                    sourceSize.width: rl.omni.listAppIconSize * 2
                    sourceSize.height: rl.omni.listAppIconSize * 2
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    cache: true
                    opacity: row.isSelected ? 1.0 : 0.96
                    Behavior on opacity { NumberAnimation { duration: 40 } }
                }
            }
            Text {
                id: titleText
                anchors.left: iconText.right
                anchors.leftMargin: 14
                anchors.top: row.isTwoLine ? parent.top : undefined
                anchors.topMargin: row.isTwoLine ? 8 : 0
                anchors.verticalCenter: row.isTwoLine ? undefined : parent.verticalCenter
                // Trailing chevron flags drill-in rows so you can tell
                // at a glance which Enters drill in vs. which Enters
                // execute.
                text: row.modelData.isCategory
                      ? row.modelData.title + "  ›"
                      : row.modelData.title
                color: row.isSelected ? rl.omni.ink : rl.omni.fg
                font.family: rl.omni.mono
                font.pixelSize: 15 * rl.omni.fontScale
                font.weight: row.isSelected ? Font.Medium : Font.Light
                font.letterSpacing: 1
                elide: Text.ElideRight
                width: row.width - iconText.width - catText.implicitWidth - 60
            }

            Text {
                id: subtitleText
                visible: row.isTwoLine
                anchors.left: titleText.left
                anchors.top: titleText.bottom
                anchors.topMargin: 2
                width: titleText.width
                text: row.modelData.subtitle || ""
                color: row.isSelected ? rl.omni.seal : rl.omni.inkDeep
                opacity: row.isSelected ? 0.98 : 0.78
                font.family: rl.omni.mono
                font.pixelSize: 12 * rl.omni.fontScale
                font.weight: Font.Light
                elide: Text.ElideRight
            }
            Text {
                id: starText
                anchors.right: catText.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                visible: rl.bookmarks.isFavourite(row.modelData)
                text: "󰓎"
                color: rl.omni.seal
                font.family: rl.omni.mono
                font.pixelSize: 13 * rl.omni.fontScale
            }
            Text {
                id: catText
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                // File rows show the dirname here, which shouldn't be
                // uppercased or letter-spaced. Cap the width so a deep
                // path doesn't push the title text off the row.
                readonly property string label: row.modelData.displayCategory
                                                || row.modelData.category
                                                || ""
                text: row.modelData.rawCategory
                      ? label
                      : label.toUpperCase()
                color: row.isSelected ? rl.omni.seal : rl.omni.inkDeep
                opacity: row.isSelected ? 0.98 : 0.74
                font.family: rl.omni.mono
                font.pixelSize: 12 * rl.omni.fontScale
                font.letterSpacing: row.modelData.rawCategory ? 0 : 2
                elide: Text.ElideLeft
                horizontalAlignment: Text.AlignRight
                width: row.modelData.rawCategory
                       ? Math.min(implicitWidth, row.width * 0.45)
                       : implicitWidth
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                // onPositionChanged fires only on actual cursor
                // movement; onEntered would also fire when rows shift
                // under a stationary cursor (after a query change,
                // drill-in, or rescore), stealing keyboard focus.
                onPositionChanged: rl.omni.selectedIndex = row.index
                onClicked: rl.omni.activate(row.modelData)
            }
        }

        Text {
            anchors.centerIn: parent
            visible: resultList.count === 0
            text: {
                const o = rl.omni;
                if (o.tldrMode) {
                    if (o.tldrTool.length === 0) return "TLDR COMMAND  ·  TYPE TOOL NAME";
                    if (o.tldrRunning) return "FETCHING TLDR…";
                    return "NO TLDR PAGE";
                }
                if (o.llmMode) {
                    const cmd = o.cmdMode;
                    if (o.chatPrompt.length === 0)
                        return cmd ? "$ SHELL TASK  ·  LOCAL AI"
                                   : "? QUESTION  ·  LOCAL AI";
                    if (o.chatStatus === "")    return "CHECKING OLLAMA…";
                    if (o.chatStatus !== "ok")  return "OLLAMA SETUP NEEDED";
                    if (!o.chatSubmitted)        return cmd ? "↵ TO GENERATE" : "↵ TO ASK";
                    if (o.chatRunning)           return "STREAMING…";
                    return cmd ? "READY  ·  EDIT TO REGENERATE"
                               : "READY  ·  EDIT TO ASK AGAIN";
                }
                if (o.clipboardMode) {
                    if (o.clipboardRunning) return "LOADING CLIPBOARD…";
                    return o.query.length === 0 ? "NO TEXT CLIPBOARD HISTORY" : "NO CLIPBOARD MATCH";
                }
                if (o.fileMode) {
                    if (o.fdRunning) return "SEARCHING FILES…";
                    if (o.query.length === 0) return "PROJECTS · DOWNLOADS · DOCUMENTS";
                    return "NO FILES MATCH";
                }
                if (o.ghMode) {
                    if (o.query.length === 0) {
                        return o.ghRunning ? "LOADING PRS…" : "NO OPEN PRS";
                    }
                    if (o.ghRunning) return "SEARCHING GITHUB…";
                    return "NO REPOS MATCH";
                }
                if (o.emojiMode) {
                    if (!o.emojiLoaded && o.emojiLoadError === "") return "LOADING EMOJI…";
                    if (o.emojiLoadError !== "") return o.emojiLoadError;
                    return "NO EMOJI MATCH";
                }
                    if (o.clipboardMode) {
                        if (o.clipboardRunning) return "LOADING HISTORY…";
                        return o.query.length === 0 ? "NO TEXT ENTRIES" : "NO CLIPBOARD MATCH";
                    }
                if (o.favMode)  return "NO FAVOURITES — CTRL+S TO STAR";
                if (o.histMode) return "NO HISTORY YET";
                if (o.procMode)  return rl.processes.running ? "LOADING…" : "NO PROCESSES";
                if (o.themeMode) return rl.themes.loaded ? "NO THEMES MATCH" : "LOADING THEMES…";
                return o.appsLoaded ? "NOTHING MATCHES" : "INDEXING APPS…";
            }
            color: rl.omni.inkDeep
            font.family: rl.omni.mono
            font.pixelSize: 13 * rl.omni.fontScale
            font.letterSpacing: 3
            opacity: 0.72
        }
    }
}
