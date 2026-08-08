import QtQuick

Item {
    id: body
    required property var root
    width: parent ? parent.width : 0

    readonly property int rowHeight: 92
    readonly property int rowGap: 12
    property int kbdIndex: 0

    readonly property var settingsModel: [
        {
            label: "APP ICONS",
            desc: "Desktop app images in the main result list",
            showProp: "showListAppIcons",
            sizeProp: "listAppIconSize",
            min: 12,
            max: 34,
            kind: "app",
            sampleGlyph: "󰀻",
            sampleText: "Firefox / Brave"
        },
        {
            label: "MENU GLYPHS",
            desc: "Category and action symbols in the result list",
            showProp: "showListGlyphs",
            sizeProp: "listGlyphSize",
            min: 12,
            max: 34,
            kind: "glyph",
            sampleGlyph: "󰚰",
            sampleText: "Update / System / Capture"
        },
        {
            label: "SEARCH GLYPH",
            desc: "The leading icon in the search input row",
            showProp: "showSearchGlyph",
            sizeProp: "searchGlyphSize",
            min: 12,
            max: 34,
            kind: "glyph",
            sampleGlyph: "󰍉",
            sampleText: "Search prompt"
        },
        {
            label: "QUICK TILE GLYPHS",
            desc: "Icons shown inside the 3x3 Quick tile grid",
            showProp: "showQuickTileGlyphs",
            sizeProp: "quickTileGlyphSize",
            min: 18,
            max: 44,
            kind: "glyph",
            sampleGlyph: "󰖩",
            sampleText: "Wi-Fi / Weather / CPU"
        },
        {
            label: "QUICK DETAIL GLYPHS",
            desc: "The large icon at the top of the expanded Quick panel",
            showProp: "showQuickDetailGlyphs",
            sizeProp: "quickDetailGlyphSize",
            min: 18,
            max: 48,
            kind: "glyph",
            sampleGlyph: "󰍛",
            sampleText: "Detail header"
        },
        {
            label: "QUICK BUTTON GLYPHS",
            desc: "Small symbols inside Quick action buttons",
            showProp: "showQuickButtonGlyphs",
            sizeProp: "quickButtonGlyphSize",
            min: 10,
            max: 28,
            kind: "glyph",
            sampleGlyph: "󰜉",
            sampleText: "Refresh / BTOP / Settings"
        }
    ]

    implicitHeight: flick.height

    function rowAt(index) {
        if (index < 0 || index >= body.settingsModel.length) return null;
        return body.settingsModel[index];
    }
    function getBool(name) { return !!body.root[name]; }
    function setBool(name, value) { body.root[name] = !!value; }
    function getSize(name) { return body.root[name]; }
    function setSize(name, value, minV, maxV) {
        body.root[name] = body.root.clampIconSize(value, minV, maxV);
    }
    function toggleCurrent() {
        const row = body.rowAt(body.kbdIndex);
        if (!row) return;
        body.setBool(row.showProp, !body.getBool(row.showProp));
    }
    function bumpCurrent(delta) {
        const row = body.rowAt(body.kbdIndex);
        if (!row) return;
        body.setSize(row.sizeProp, body.getSize(row.sizeProp) + delta, row.min, row.max);
    }
    function ensureVisible(index) {
        const rowTop = 88 + index * (body.rowHeight + body.rowGap);
        const rowBottom = rowTop + body.rowHeight;
        const maxY = Math.max(0, flick.contentHeight - flick.height);
        if (rowTop < flick.contentY) flick.contentY = Math.max(0, rowTop - 8);
        else if (rowBottom > flick.contentY + flick.height) flick.contentY = Math.min(maxY, rowBottom - flick.height + 8);
    }
    function select(index) {
        body.kbdIndex = Math.max(0, Math.min(body.settingsModel.length - 1, index));
        body.ensureVisible(body.kbdIndex);
    }
    function kbdHandle(event) {
        const k = event.key;
        if (k === Qt.Key_Up) {
            body.select(body.kbdIndex - 1);
            return true;
        }
        if (k === Qt.Key_Down || (k === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
            body.select(body.kbdIndex + 1);
            return true;
        }
        if (k === Qt.Key_Backtab || (k === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
            body.select(body.kbdIndex - 1);
            return true;
        }
        if (k === Qt.Key_Left) {
            body.bumpCurrent(-2);
            return true;
        }
        if (k === Qt.Key_Right) {
            body.bumpCurrent(+2);
            return true;
        }
        if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            body.toggleCurrent();
            return true;
        }
        return false;
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentCol.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentCol
            width: flick.width
            spacing: 12

            Text {
                width: parent.width
                text: "Preview and tune launcher icon groups live. Each row controls visibility and size for one icon family."
                wrapMode: Text.WordWrap
                color: body.root.ink
                font.family: body.root.mono
                font.pixelSize: 13 * body.root.fontScale
            }

            Text {
                width: parent.width
                text: "Keyboard: ↑/↓ select  ·  ←/→ resize  ·  ↵ toggle  ·  Esc back"
                wrapMode: Text.WordWrap
                color: body.root.seal
                opacity: 0.92
                font.family: body.root.mono
                font.pixelSize: 12 * body.root.fontScale
            }

            Repeater {
                model: body.settingsModel
                delegate: Rectangle {
                    id: rowCard
                    required property var modelData
                    required property int index

                    width: contentCol.width
                    height: body.rowHeight
                    radius: body.root.cornerRadius
                    color: body.kbdIndex === index
                           ? Qt.rgba(body.root.ink.r, body.root.ink.g, body.root.ink.b, 0.08)
                           : Qt.rgba(body.root.ink.r, body.root.ink.g, body.root.ink.b, 0.03)
                    border.color: body.kbdIndex === index ? body.root.seal : body.root.sep
                    border.width: body.kbdIndex === index ? 2 : 1

                    readonly property bool shown: body.getBool(modelData.showProp)
                    readonly property int sizeVal: body.getSize(modelData.sizeProp)

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: body.select(index)
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14

                        Rectangle {
                            width: 146
                            height: parent.height
                            radius: body.root.cornerRadius
                            color: Qt.rgba(body.root.paper.r, body.root.paper.g, body.root.paper.b, 0.04)
                            border.color: body.root.sep
                            border.width: 1

                            Item {
                                anchors.fill: parent
                                anchors.margins: 10

                                Rectangle {
                                    visible: modelData.kind === "app" && rowCard.shown
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: rowCard.sizeVal
                                    height: rowCard.sizeVal
                                    radius: Math.max(4, Math.round(rowCard.sizeVal / 5))
                                    color: Qt.rgba(body.root.seal.r, body.root.seal.g, body.root.seal.b, 0.16)
                                    border.color: body.root.seal
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "APP"
                                        color: body.root.seal
                                        font.family: body.root.mono
                                        font.pixelSize: Math.max(7, Math.round(rowCard.sizeVal * 0.34)) * body.root.fontScale
                                        font.weight: Font.Medium
                                    }
                                }

                                Text {
                                    visible: modelData.kind !== "app" && rowCard.shown
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.sampleGlyph
                                    color: body.root.seal
                                    font.family: body.root.mono
                                    font.pixelSize: rowCard.sizeVal * body.root.fontScale
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: rowCard.shown ? rowCard.sizeVal + 12 : 0
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: rowCard.shown ? modelData.sampleText : "Hidden"
                                    color: rowCard.shown ? body.root.ink : body.root.inkDeep
                                    opacity: rowCard.shown ? 1.0 : 0.75
                                    font.family: body.root.mono
                                    font.pixelSize: 11 * body.root.fontScale
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Column {
                            width: parent.width - 160
                            spacing: 7

                            Text {
                                text: modelData.label
                                color: body.root.ink
                                font.family: body.root.mono
                                font.pixelSize: 14 * body.root.fontScale
                                font.weight: Font.Medium
                                font.letterSpacing: 1.4
                            }

                            Text {
                                width: parent.width
                                text: modelData.desc
                                color: body.root.inkDeep
                                opacity: 0.84
                                wrapMode: Text.WordWrap
                                font.family: body.root.mono
                                font.pixelSize: 11 * body.root.fontScale
                            }

                            Row {
                                spacing: 8

                                Rectangle {
                                    width: 78
                                    height: 28
                                    radius: body.root.cornerRadius
                                    color: rowCard.shown
                                           ? Qt.rgba(body.root.seal.r, body.root.seal.g, body.root.seal.b, 0.18)
                                           : Qt.rgba(body.root.ink.r, body.root.ink.g, body.root.ink.b, 0.06)
                                    border.color: rowCard.shown ? body.root.seal : body.root.sep
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: rowCard.shown ? "ON" : "OFF"
                                        color: rowCard.shown ? body.root.seal : body.root.inkDeep
                                        font.family: body.root.mono
                                        font.pixelSize: 11 * body.root.fontScale
                                        font.weight: Font.Medium
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            body.select(index);
                                            body.toggleCurrent();
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: body.root.cornerRadius
                                    color: Qt.rgba(body.root.ink.r, body.root.ink.g, body.root.ink.b, 0.06)
                                    border.color: body.root.sep
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "−"
                                        color: body.root.ink
                                        font.family: body.root.mono
                                        font.pixelSize: 16 * body.root.fontScale
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            body.select(index);
                                            body.bumpCurrent(-2);
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 66
                                    height: 28
                                    radius: body.root.cornerRadius
                                    color: Qt.rgba(body.root.ink.r, body.root.ink.g, body.root.ink.b, 0.04)
                                    border.color: body.root.sep
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: rowCard.sizeVal + "px"
                                        color: body.root.ink
                                        font.family: body.root.mono
                                        font.pixelSize: 11 * body.root.fontScale
                                    }
                                }

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: body.root.cornerRadius
                                    color: Qt.rgba(body.root.ink.r, body.root.ink.g, body.root.ink.b, 0.06)
                                    border.color: body.root.sep
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        color: body.root.ink
                                        font.family: body.root.mono
                                        font.pixelSize: 16 * body.root.fontScale
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            body.select(index);
                                            body.bumpCurrent(+2);
                                        }
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Range " + modelData.min + "–" + modelData.max
                                    color: body.root.inkDeep
                                    opacity: 0.72
                                    font.family: body.root.mono
                                    font.pixelSize: 10 * body.root.fontScale
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
