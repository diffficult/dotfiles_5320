import QtQuick

CardWindow {
    id: videosPopup
    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 566
    layerNamespace: "omarchy-videos"
    title: "VIDEOS"
    subtitle: videosPopup.controller.files.length === 0
              ? "NO RECENT VIDEOS"
              : "PAGE " + (videosPopup.controller.page + 1) + " / " + videosPopup.controller.pageCount
                + "  ·  " + videosPopup.controller.files.length + " TOTAL"

    headerRight: Row {
        spacing: 12
        CalendarChevron {
            root: videosPopup.root
            text: "‹"
            opacity: videosPopup.controller.page > 0 ? 1.0 : 0.3
            onTriggered: videosPopup.controller.pageBy(-1)
        }
        CalendarChevron {
            root: videosPopup.root
            text: videosPopup.root.icoRefresh
            restColor: videosPopup.root.inkDeep
            font.pixelSize: 24
            onTriggered: videosPopup.controller.refresh()
        }
        CalendarChevron {
            root: videosPopup.root
            text: "›"
            opacity: videosPopup.controller.page < videosPopup.controller.pageCount - 1 ? 1.0 : 0.3
            onTriggered: videosPopup.controller.pageBy(1)
        }
    }

    onDismiss: videosPopup.controller.close()
    onKeyPressed: function(event) {
        const r = videosPopup.controller;
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
            if (e) {
                if (event.modifiers & Qt.ShiftModifier) r.copyBytes(e.path);
                else r.copyUri(e.path);
            }
        } else {
            return;
        }
        event.accepted = true;
    }

    Column {
        id: vidCol
        width: parent.width
        spacing: 12

        Text {
            width: parent.width
            height: 248
            visible: videosPopup.controller.files.length === 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "~/Videos/*.mp4 · mkv · webm · mov · avi · m4v"
            color: videosPopup.root.inkDeep
            font.family: videosPopup.root.mono
            font.pixelSize: 11
            font.letterSpacing: 2
            opacity: 0.6
        }

        Grid {
            columns: 4
            rowSpacing: 6
            columnSpacing: 6
            width: parent.width
            visible: videosPopup.controller.files.length > 0

            Repeater {
                model: videosPopup.controller.perPage
                delegate: Item {
                    id: vidCell
                    required property int index
                    readonly property var entry: videosPopup.controller.visibleFiles[index] || null
                    readonly property bool filled: entry !== null
                    readonly property bool isSelected: filled && videosPopup.controller.selected === index
                    readonly property bool justCopied: filled && videosPopup.controller.copiedPath === entry.path

                    width: (vidCol.width - 18) / 4
                    height: width * 9 / 16

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(videosPopup.root.ink.r, videosPopup.root.ink.g, videosPopup.root.ink.b, vidCell.filled ? 0.04 : 0.02)
                        border.color: vidCell.isSelected ? videosPopup.root.seal : videosPopup.root.sep
                        border.width: 1
                        antialiasing: true
                    }

                    Image {
                        id: vidThumb
                        anchors.fill: parent
                        anchors.margins: 1
                        visible: vidCell.filled && status === Image.Ready
                        source: (vidCell.filled && videosPopup.controller.active && vidCell.entry.thumb)
                                ? "file://" + vidCell.entry.thumb : ""
                        sourceSize.width: 320
                        sourceSize.height: 180
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        clip: true
                        opacity: vidMouse.containsMouse || vidCell.isSelected ? 1.0 : 0.85
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: vidCell.filled && vidThumb.status !== Image.Ready
                        text: String.fromCodePoint(0xf040a)
                        color: videosPopup.root.inkDeep
                        font.family: videosPopup.root.mono
                        font.pixelSize: 28
                        opacity: 0.55
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 4
                        width: durLabel.implicitWidth + 8
                        height: durLabel.implicitHeight + 4
                        color: Qt.rgba(videosPopup.root.paper.r, videosPopup.root.paper.g, videosPopup.root.paper.b, 0.72)
                        visible: vidCell.filled && durLabel.text.length > 0
                        radius: videosPopup.root.cornerRadius

                        Text {
                            id: durLabel
                            anchors.centerIn: parent
                            text: vidCell.filled ? videosPopup.controller.formatDuration(vidCell.entry.duration) : ""
                            color: videosPopup.root.ink
                            font.family: videosPopup.root.mono
                            font.pixelSize: 9
                            font.letterSpacing: 1
                            font.weight: Font.Medium
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        color: "transparent"
                        border.color: videosPopup.root.seal
                        border.width: vidMouse.containsMouse && !vidCell.isSelected ? 1 : 0
                        visible: vidCell.filled
                        antialiasing: true
                        Behavior on border.width { NumberAnimation { duration: 120 } }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        color: Qt.rgba(videosPopup.root.seal.r, videosPopup.root.seal.g, videosPopup.root.seal.b, 0.28)
                        border.color: videosPopup.root.seal
                        border.width: 2
                        visible: opacity > 0.01
                        opacity: vidCell.justCopied ? 1 : 0
                        antialiasing: true
                        Behavior on opacity {
                            NumberAnimation {
                                duration: vidCell.justCopied ? 80 : 600
                                easing.type: vidCell.justCopied ? Easing.OutQuad : Easing.InCubic
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: videosPopup.controller.copiedMode === "bytes" ? "BYTES COPIED" : "FILE COPIED"
                            color: videosPopup.root.seal.hsvValue < 0.5 ? videosPopup.root.ink : videosPopup.root.paper
                            font.family: videosPopup.root.mono
                            font.pixelSize: 11
                            font.letterSpacing: 3
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: vidMouse
                        anchors.fill: parent
                        hoverEnabled: vidCell.filled
                        enabled: vidCell.filled
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                        property point pressPos: Qt.point(0, 0)
                        property bool dragInitiated: false

                        onEntered: videosPopup.controller.selected = vidCell.index
                        onPressed: (e) => {
                            pressPos = Qt.point(e.x, e.y);
                            dragInitiated = false;
                        }
                        onPositionChanged: (e) => {
                            if (!pressed || dragInitiated || !vidCell.filled) return;
                            if (!(e.buttons & Qt.LeftButton)) return;
                            const dx = e.x - pressPos.x;
                            const dy = e.y - pressPos.y;
                            if (dx * dx + dy * dy < 81) return;
                            dragInitiated = true;
                            videosPopup.controller.selected = vidCell.index;
                            videosPopup.controller.dragEntry(vidCell.entry.path);
                        }
                        onClicked: (e) => {
                            if (dragInitiated) return;
                            videosPopup.controller.selected = vidCell.index;
                            if (e.button === Qt.RightButton) {
                                videosPopup.controller.copyUri(vidCell.entry.path);
                            } else if (e.button === Qt.MiddleButton) {
                                videosPopup.controller.copyBytes(vidCell.entry.path);
                            } else {
                                videosPopup.controller.openEntry(vidCell.entry.path);
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: videosPopup.root.sep
            visible: videosPopup.controller.selectedEntry !== null
        }

        Item {
            width: parent.width
            height: 22
            visible: videosPopup.controller.selectedEntry !== null

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.55
                elide: Text.ElideMiddle
                text: videosPopup.controller.selectedEntry ? videosPopup.controller.selectedEntry.label : ""
                color: videosPopup.root.ink
                font.family: videosPopup.root.mono
                font.pixelSize: 11
                font.letterSpacing: 2
            }

            Text {
                readonly property bool copied: videosPopup.controller.copiedPath !== ""
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (copied) {
                        return videosPopup.controller.copiedMode === "bytes"
                            ? "VIDEO BYTES ON CLIPBOARD"
                            : "FILE ON CLIPBOARD";
                    }
                    if (!videosPopup.controller.selectedEntry) return "";
                    const e = videosPopup.controller.selectedEntry;
                    const bits = [];
                    const d = videosPopup.controller.formatDuration(e.duration); if (d) bits.push(d);
                    const s = videosPopup.controller.formatSize(e.size);         if (s) bits.push(s);
                    const t = videosPopup.controller.formatMtime(e.mtime);       if (t) bits.push(t);
                    return bits.join("  ·  ");
                }
                color: copied ? videosPopup.root.seal : videosPopup.root.inkDeep
                font.family: videosPopup.root.mono
                font.pixelSize: 11
                font.letterSpacing: 2
                opacity: copied ? 1.0 : 0.7
                Behavior on color { ColorAnimation { duration: 180 } }
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }
        }
    }
}
