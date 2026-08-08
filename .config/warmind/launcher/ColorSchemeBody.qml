import QtQuick

Item {
    id: body
    required property var root
    width: parent ? parent.width : 0

    property int focusSection: 0   // 0 schemes, 1 accents
    property int schemeIndex: 0
    property int accentIndex: 0

    readonly property var schemeKeys: body.root.theme.schemeKeys
    readonly property var accentEntries: body.root.theme.accentEntries()

    function syncFromTheme() {
        const schemes = body.schemeKeys || [];
        let si = schemes.indexOf(body.root.theme.schemeKey);
        if (si < 0) si = 0;
        body.schemeIndex = si;

        const accents = body.accentEntries || [];
        let ai = 0;
        for (let i = 0; i < accents.length; i++) {
            if (accents[i].key === body.root.theme.accentKey) {
                ai = i;
                break;
            }
        }
        body.accentIndex = Math.max(0, Math.min(ai, Math.max(0, accents.length - 1)));
    }
    function selectScheme(index) {
        const schemes = body.schemeKeys || [];
        if (schemes.length === 0) return;
        const next = Math.max(0, Math.min(index, schemes.length - 1));
        body.root.theme.selectScheme(schemes[next]);
        body.syncFromTheme();
    }
    function selectAccent(index) {
        const accents = body.accentEntries || [];
        if (accents.length === 0) return;
        const next = Math.max(0, Math.min(index, accents.length - 1));
        body.root.theme.selectAccent(accents[next].key);
        body.syncFromTheme();
    }
    function kbdHandle(event) {
        const key = event.key;
        if (key === Qt.Key_Up || key === Qt.Key_Down || key === Qt.Key_Tab || key === Qt.Key_Backtab) {
            body.focusSection = body.focusSection === 0 ? 1 : 0;
            return true;
        }
        if (key === Qt.Key_Left) {
            if (body.focusSection === 0) body.selectScheme(body.schemeIndex - 1);
            else body.selectAccent(body.accentIndex - 1);
            return true;
        }
        if (key === Qt.Key_Right) {
            if (body.focusSection === 0) body.selectScheme(body.schemeIndex + 1);
            else body.selectAccent(body.accentIndex + 1);
            return true;
        }
        if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space) {
            if (body.focusSection === 0) body.selectScheme(body.schemeIndex);
            else body.selectAccent(body.accentIndex);
            return true;
        }
        return false;
    }

    Component.onCompleted: syncFromTheme()

    Connections {
        target: body.root.theme
        function onSchemeKeyChanged() { body.syncFromTheme(); }
        function onAccentKeyChanged() { body.syncFromTheme(); }
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
            spacing: 16

            Text {
                width: parent.width
                text: "Switch the launcher palette live. Choose a scheme family/variant first, then pick an accent color. Changes are saved automatically."
                wrapMode: Text.WordWrap
                color: body.root.ink
                font.family: body.root.mono
                font.pixelSize: 13 * body.root.fontScale
            }

            Text {
                width: parent.width
                text: "Keyboard: Tab/↑/↓ switch section  ·  ←/→ change  ·  ↵ apply  ·  Esc back"
                wrapMode: Text.WordWrap
                color: body.root.seal
                opacity: 0.92
                font.family: body.root.mono
                font.pixelSize: 12 * body.root.fontScale
            }

            Column {
                width: parent.width
                spacing: 10

                Text {
                    text: "SCHEMES"
                    color: body.focusSection === 0 ? body.root.seal : body.root.inkDeep
                    font.family: body.root.mono
                    font.pixelSize: 13 * body.root.fontScale
                    font.weight: Font.Medium
                    font.letterSpacing: 2
                }

                Flow {
                    width: parent.width
                    spacing: 12

                    Repeater {
                        model: body.schemeKeys
                        delegate: Rectangle {
                            required property string modelData
                            required property int index
                            readonly property var scheme: body.root.theme.schemeData(modelData)
                            readonly property bool selected: body.root.theme.schemeKey === modelData
                            readonly property bool kbdSelected: body.focusSection === 0 && body.schemeIndex === index

                            width: Math.floor((contentCol.width - 24) / 3)
                            height: 120
                            radius: body.root.cornerRadius
                            color: selected
                                   ? Qt.rgba(body.root.seal.r, body.root.seal.g, body.root.seal.b, 0.12)
                                   : Qt.rgba(body.root.ink.r, body.root.ink.g, body.root.ink.b, 0.03)
                            border.color: kbdSelected ? body.root.seal : (selected ? body.root.indigo : body.root.sep)
                            border.width: (selected || kbdSelected) ? 2 : 1

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    body.focusSection = 0;
                                    body.selectScheme(index);
                                }
                            }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                Text {
                                    text: scheme.label
                                    color: body.root.ink
                                    font.family: body.root.mono
                                    font.pixelSize: 13 * body.root.fontScale
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Row {
                                    spacing: 8
                                    Repeater {
                                        model: [scheme.paper, scheme.bgHigh, scheme.inkDeep, body.root.theme.schemeData(modelData).accents[body.root.theme.defaultAccentForScheme(modelData)]]
                                        delegate: Rectangle {
                                            required property string modelData
                                            width: 22
                                            height: 22
                                            radius: 6
                                            color: modelData
                                            border.color: Qt.rgba(0, 0, 0, 0.22)
                                            border.width: 1
                                        }
                                    }
                                }

                                Text {
                                    text: scheme.family.toUpperCase() + (selected ? "  ·  ACTIVE" : "")
                                    color: selected ? body.root.seal : body.root.inkDeep
                                    opacity: 0.9
                                    font.family: body.root.mono
                                    font.pixelSize: 11 * body.root.fontScale
                                    font.letterSpacing: 1
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 10

                Text {
                    text: "ACCENT"
                    color: body.focusSection === 1 ? body.root.seal : body.root.inkDeep
                    font.family: body.root.mono
                    font.pixelSize: 13 * body.root.fontScale
                    font.weight: Font.Medium
                    font.letterSpacing: 2
                }

                Flow {
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: body.accentEntries
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool selected: body.root.theme.accentKey === modelData.key
                            readonly property bool kbdSelected: body.focusSection === 1 && body.accentIndex === index

                            width: 128
                            height: 42
                            radius: body.root.cornerRadius
                            color: selected
                                   ? Qt.rgba(body.root.seal.r, body.root.seal.g, body.root.seal.b, 0.12)
                                   : Qt.rgba(body.root.ink.r, body.root.ink.g, body.root.ink.b, 0.03)
                            border.color: kbdSelected ? body.root.seal : (selected ? body.root.indigo : body.root.sep)
                            border.width: (selected || kbdSelected) ? 2 : 1

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    body.focusSection = 1;
                                    body.selectAccent(index);
                                }
                            }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: modelData.color
                                    border.color: Qt.rgba(0, 0, 0, 0.24)
                                    border.width: 1
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    color: body.root.ink
                                    font.family: body.root.mono
                                    font.pixelSize: 12 * body.root.fontScale
                                    elide: Text.ElideRight
                                    width: parent.width - 44
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                implicitHeight: previewCol.implicitHeight + 24
                radius: body.root.cornerRadius
                color: body.root.bg
                border.color: body.root.sep
                border.width: 1

                Column {
                    id: previewCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text {
                        text: "LIVE PREVIEW"
                        color: body.root.ink
                        font.family: body.root.mono
                        font.pixelSize: 13 * body.root.fontScale
                        font.weight: Font.Medium
                        font.letterSpacing: 2
                    }

                    Rectangle {
                        width: parent.width
                        height: 48
                        radius: body.root.cornerRadius
                        color: body.root.rowSel
                        border.color: body.root.sep
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 12

                            Text {
                                text: "󰚰"
                                color: body.root.seal
                                font.family: body.root.mono
                                font.pixelSize: 18 * body.root.fontScale
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Selected launcher row"
                                color: body.root.ink
                                font.family: body.root.mono
                                font.pixelSize: 13 * body.root.fontScale
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 12

                        Rectangle {
                            width: (parent.width - 12) / 2
                            height: 92
                            radius: body.root.cornerRadius
                            color: Qt.rgba(body.root.ink.r, body.root.ink.g, body.root.ink.b, 0.04)
                            border.color: body.root.sep
                            border.width: 1

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                Text {
                                    text: "󰖩  Quick Tile"
                                    color: body.root.seal
                                    font.family: body.root.mono
                                    font.pixelSize: 16 * body.root.fontScale
                                }
                                Text {
                                    text: "Accent, borders, and text weights update live."
                                    color: body.root.inkDeep
                                    font.family: body.root.mono
                                    font.pixelSize: 11 * body.root.fontScale
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width - 12) / 2
                            height: 92
                            radius: body.root.cornerRadius
                            color: Qt.rgba(body.root.ink.r, body.root.ink.g, body.root.ink.b, 0.04)
                            border.color: body.root.sep
                            border.width: 1

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                Text {
                                    text: "Current: " + body.root.theme.schemeLabel(body.root.theme.schemeKey)
                                    color: body.root.ink
                                    font.family: body.root.mono
                                    font.pixelSize: 12 * body.root.fontScale
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: "Accent: " + ((body.accentEntries[body.accentIndex] && body.accentEntries[body.accentIndex].label) || "—")
                                    color: body.root.seal
                                    font.family: body.root.mono
                                    font.pixelSize: 12 * body.root.fontScale
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
