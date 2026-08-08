import QtQuick

CardWindow {
    id: screenshotsPopup
    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 566
    layerNamespace: "omarchy-screenshots"
    title: "SCREENSHOTS"
    subtitle: screenshotsPopup.controller.files.length === 0
              ? "NO RECENT CAPTURES"
              : "PAGE " + (screenshotsPopup.controller.page + 1) + " / " + screenshotsPopup.controller.pageCount
                + "  ·  " + screenshotsPopup.controller.files.length + " TOTAL"

    headerRight: Row {
        spacing: 12
        CalendarChevron {
            root: screenshotsPopup.root
            text: "‹"
            opacity: screenshotsPopup.controller.page > 0 ? 1.0 : 0.3
            onTriggered: screenshotsPopup.controller.pageBy(-1)
        }
        CalendarChevron {
            root: screenshotsPopup.root
            text: screenshotsPopup.root.icoRefresh
            restColor: screenshotsPopup.root.inkDeep
            font.pixelSize: 24
            onTriggered: screenshotsPopup.controller.refresh()
        }
        CalendarChevron {
            root: screenshotsPopup.root
            text: "›"
            opacity: screenshotsPopup.controller.page < screenshotsPopup.controller.pageCount - 1 ? 1.0 : 0.3
            onTriggered: screenshotsPopup.controller.pageBy(1)
        }
    }

    onDismiss: screenshotsPopup.controller.close()
    onKeyPressed: function(event) {
        const r = screenshotsPopup.controller;
        const k = event.key;
        if (k === Qt.Key_Q) {
            r.close();
        } else if (k === Qt.Key_Right || k === Qt.Key_L || k === Qt.Key_Tab) {
            r.moveSelection(1);
        } else if (k === Qt.Key_Left || k === Qt.Key_H || k === Qt.Key_Backtab) {
            r.moveSelection(-1);
        } else if (k === Qt.Key_Down || k === Qt.Key_J) {
            r.moveRow(1);
        } else if (k === Qt.Key_Up || k === Qt.Key_K) {
            r.moveRow(-1);
        } else if (k === Qt.Key_N) {
            r.pageBy(1);
        } else if (k === Qt.Key_P) {
            r.pageBy(-1);
        } else if (k === Qt.Key_O || k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            const e = r.selectedEntry;
            if (e) r.openEntry(e.path);
        } else if (k === Qt.Key_C) {
            const e = r.selectedEntry;
            if (e) r.copyToClipboard(e.path);
        } else {
            return;
        }
        event.accepted = true;
    }

    Column {
        id: shotCol
        width: parent.width
        spacing: 12

        Text {
            width: parent.width
            height: 248
            visible: screenshotsPopup.controller.files.length === 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "~/Pictures/Screenshots/*.{png,jpg,jpeg,webp}"
            color: screenshotsPopup.root.inkDeep
            font.family: screenshotsPopup.root.mono
            font.pixelSize: 11
            font.letterSpacing: 2
            opacity: 0.6
        }

        Grid {
            columns: 4
            rowSpacing: 6
            columnSpacing: 6
            width: parent.width
            visible: screenshotsPopup.controller.files.length > 0

            Repeater {
                model: screenshotsPopup.controller.perPage
                delegate: Item {
                    id: shotCell
                    required property int index
                    readonly property var entry: screenshotsPopup.controller.visibleFiles[index] || null
                    readonly property bool filled: entry !== null
                    readonly property bool isSelected: filled && screenshotsPopup.controller.selected === index
                    readonly property bool justCopied: filled && screenshotsPopup.controller.copiedPath === entry.path

                    width: (shotCol.width - 18) / 4
                    height: width * 9 / 16

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(screenshotsPopup.root.ink.r, screenshotsPopup.root.ink.g, screenshotsPopup.root.ink.b, shotCell.filled ? 0.04 : 0.02)
                        border.color: shotCell.isSelected ? screenshotsPopup.root.seal : screenshotsPopup.root.sep
                        border.width: 1
                        antialiasing: true
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        visible: shotCell.filled
                        source: (shotCell.filled && screenshotsPopup.controller.active)
                                ? "file://" + shotCell.entry.path : ""
                        sourceSize.width: 256
                        sourceSize.height: 144
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        clip: true
                        opacity: shotMouse.containsMouse || shotCell.isSelected ? 1.0 : 0.85
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        color: "transparent"
                        border.color: screenshotsPopup.root.seal
                        border.width: shotMouse.containsMouse && !shotCell.isSelected ? 1 : 0
                        visible: shotCell.filled
                        antialiasing: true
                        Behavior on border.width { NumberAnimation { duration: 120 } }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        color: Qt.rgba(screenshotsPopup.root.seal.r, screenshotsPopup.root.seal.g, screenshotsPopup.root.seal.b, 0.28)
                        border.color: screenshotsPopup.root.seal
                        border.width: 2
                        visible: opacity > 0.01
                        opacity: shotCell.justCopied ? 1 : 0
                        antialiasing: true
                        Behavior on opacity {
                            NumberAnimation {
                                duration: shotCell.justCopied ? 80 : 600
                                easing.type: shotCell.justCopied ? Easing.OutQuad : Easing.InCubic
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "COPIED"
                            color: screenshotsPopup.root.seal.hsvValue < 0.5 ? screenshotsPopup.root.ink : screenshotsPopup.root.paper
                            font.family: screenshotsPopup.root.mono
                            font.pixelSize: 11
                            font.letterSpacing: 3
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: shotMouse
                        anchors.fill: parent
                        hoverEnabled: shotCell.filled
                        enabled: shotCell.filled
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onEntered: screenshotsPopup.controller.selected = shotCell.index
                        onClicked: (e) => {
                            screenshotsPopup.controller.selected = shotCell.index;
                            if (e.button === Qt.RightButton) {
                                screenshotsPopup.controller.copyToClipboard(shotCell.entry.path);
                            } else {
                                screenshotsPopup.controller.openEntry(shotCell.entry.path);
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: screenshotsPopup.root.sep
            visible: screenshotsPopup.controller.selectedEntry !== null
        }

        Item {
            width: parent.width
            height: 22
            visible: screenshotsPopup.controller.selectedEntry !== null

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: screenshotsPopup.controller.selectedEntry ? screenshotsPopup.controller.selectedEntry.label : ""
                color: screenshotsPopup.root.ink
                font.family: screenshotsPopup.root.mono
                font.pixelSize: 11
                font.letterSpacing: 2
            }

            Text {
                readonly property bool copied: screenshotsPopup.controller.copiedPath !== ""
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: copied ? "COPIED TO CLIPBOARD" : "RIGHT-CLICK TO COPY"
                color: copied ? screenshotsPopup.root.seal : screenshotsPopup.root.inkDeep
                font.family: screenshotsPopup.root.mono
                font.pixelSize: 11
                font.letterSpacing: 2
                opacity: copied ? 1.0 : 0.7
                Behavior on color { ColorAnimation { duration: 180 } }
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }
        }
    }
}
