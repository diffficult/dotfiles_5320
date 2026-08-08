import QtQuick

CardWindow {
    id: dropboxPopup
    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 500
    layerNamespace: "warmind-dropbox"
    property int kbdIndex: 0
    readonly property int primaryActions: controller.installed ? 1 : 0
    readonly property int directoryActions: controller.directoryAvailable ? 1 : 0
    readonly property int fileOffset: primaryActions + directoryActions
    readonly property int actionCount: fileOffset + controller.files.length
    title: "DROPBOX"
    subtitle: !controller.installed ? "NOT INSTALLED"
        : !controller.authenticated ? "LOGIN REQUIRED"
        : controller.running ? controller.statusText.toUpperCase() : "STOPPED"
    footer: actionCount > 0 ? "↑↓ ROW · ENTER ACTIVATE · R REFRESH · ESC CLOSE" : "R REFRESH · ESC CLOSE"

    anchorEdge: dropboxPopup.root.barEdge
    anchorBarX: dropboxPopup.root.popupAnchorX > 0
        ? dropboxPopup.root.popupAnchorX : dropboxPopup.width / 2
    anchorBarY: dropboxPopup.root.popupAnchorY

    headerRight: CalendarChevron {
        root: dropboxPopup.root
        text: dropboxPopup.root.icoRefresh
        restColor: dropboxPopup.root.inkDeep
        font.pixelSize: 22
        onTriggered: dropboxPopup.controller.refresh()
    }

    function activateSelection() {
        if (dropboxPopup.primaryActions && dropboxPopup.kbdIndex === 0) {
            if (!dropboxPopup.controller.authenticated) dropboxPopup.controller.login();
            else if (dropboxPopup.controller.running) dropboxPopup.controller.stopSync();
            else dropboxPopup.controller.startSync();
            return;
        }
        if (dropboxPopup.directoryActions && dropboxPopup.kbdIndex === dropboxPopup.primaryActions) {
            dropboxPopup.controller.openDirectory();
            return;
        }
        const fileIndex = dropboxPopup.kbdIndex - dropboxPopup.fileOffset;
        if (fileIndex >= 0 && fileIndex < dropboxPopup.controller.files.length)
            dropboxPopup.controller.openFile(dropboxPopup.controller.files[fileIndex]);
    }

    function fileGlyph(name) {
        const suffix = String(name || "").split(".").pop().toLowerCase();
        if (["jpg", "jpeg", "png", "gif", "webp", "avif", "heic", "svg"].indexOf(suffix) >= 0) return "󰋩";
        if (["mp4", "mov", "mkv", "webm", "avi", "m4v"].indexOf(suffix) >= 0) return "󰈫";
        if (["pdf", "txt", "md", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "odt", "csv"].indexOf(suffix) >= 0) return "󰈙";
        return "󰈔";
    }

    onDismiss: dropboxPopup.controller.close()
    onKeyPressed: function(event) {
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
            dropboxPopup.kbdIndex = Math.max(0, dropboxPopup.kbdIndex - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            dropboxPopup.kbdIndex = Math.min(Math.max(0, dropboxPopup.actionCount - 1), dropboxPopup.kbdIndex + 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            dropboxPopup.activateSelection();
            event.accepted = true;
        } else if (event.key === Qt.Key_R) {
            dropboxPopup.controller.refresh();
            event.accepted = true;
        } else if (event.key === Qt.Key_Q) {
            dropboxPopup.controller.close();
            event.accepted = true;
        }
    }

    Flickable {
        id: contentScroller
        width: parent.width
        height: 455
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
            id: contentColumn
            width: contentScroller.width
            spacing: 14

            Text {
                width: parent.width
                text: !dropboxPopup.controller.installed
                    ? "DROPBOX CLI IS NOT INSTALLED."
                    : !dropboxPopup.controller.authenticated
                        ? "START DROPBOX TO COMPLETE LOGIN FROM THE TRAY."
                        : dropboxPopup.controller.statusText.toUpperCase()
                color: dropboxPopup.root.inkDeep
                font.family: dropboxPopup.root.mono
                font.pixelSize: 12
                font.letterSpacing: 1
                wrapMode: Text.WordWrap
            }

            Text {
                visible: dropboxPopup.controller.actionStatus.length > 0 || dropboxPopup.controller.lastError.length > 0
                width: parent.width
                text: dropboxPopup.controller.actionStatus.length > 0
                    ? dropboxPopup.controller.actionStatus : dropboxPopup.controller.lastError
                color: dropboxPopup.controller.lastError.length > 0 ? dropboxPopup.root.warn : dropboxPopup.root.inkDeep
                font.family: dropboxPopup.root.mono
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            Rectangle {
                visible: dropboxPopup.controller.authenticated
                width: parent.width
                height: visible ? storageInfo.implicitHeight + 22 : 0
                radius: dropboxPopup.root.cornerRadius
                color: dropboxPopup.root.rowHi
                border.color: dropboxPopup.root.sep
                border.width: 1

                Column {
                    id: storageInfo
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 11
                    spacing: 4

                    Text {
                        text: "STORED  " + dropboxPopup.controller.usageText()
                        color: dropboxPopup.root.ink
                        font.family: dropboxPopup.root.mono
                        font.pixelSize: 11
                    }
                    Text {
                        text: dropboxPopup.controller.plan.length > 0
                            ? "PLAN  " + dropboxPopup.controller.plan.toUpperCase()
                            : "FOLDER  " + dropboxPopup.controller.directory
                        color: dropboxPopup.root.inkDeep
                        font.family: dropboxPopup.root.mono
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                    }
                }
            }

            Row {
                spacing: 8

                QuickButton {
                    visible: dropboxPopup.controller.installed
                    root: dropboxPopup.root
                    label: !dropboxPopup.controller.authenticated ? "LOGIN"
                        : dropboxPopup.controller.running ? "PAUSE SYNC" : "RESUME SYNC"
                    selected: dropboxPopup.kbdIndex === 0
                    onClicked: {
                        if (!dropboxPopup.controller.authenticated) dropboxPopup.controller.login();
                        else if (dropboxPopup.controller.running) dropboxPopup.controller.stopSync();
                        else dropboxPopup.controller.startSync();
                    }
                }
                QuickButton {
                    visible: dropboxPopup.controller.directoryAvailable
                    root: dropboxPopup.root
                    label: "OPEN FOLDER"
                    selected: dropboxPopup.kbdIndex === dropboxPopup.primaryActions
                    onClicked: dropboxPopup.controller.openDirectory()
                }
            }

            Column {
                visible: dropboxPopup.controller.authenticated
                width: parent.width
                spacing: 8

                Text {
                    text: "RECENT FILES"
                    color: dropboxPopup.root.inkDeep
                    font.family: dropboxPopup.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                }

                Text {
                    visible: dropboxPopup.controller.directoryAvailable && dropboxPopup.controller.files.length === 0
                    width: parent.width
                    text: "NO SYNCED FILES FOUND."
                    color: dropboxPopup.root.inkDeep
                    font.family: dropboxPopup.root.mono
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }

                Repeater {
                    model: dropboxPopup.controller.files
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool selected: dropboxPopup.kbdIndex === index + dropboxPopup.fileOffset

                        width: parent.width
                        height: 48
                        radius: dropboxPopup.root.cornerRadius
                        color: selected || fileMouse.containsMouse ? dropboxPopup.root.rowHi : "transparent"
                        border.color: selected ? dropboxPopup.root.seal : dropboxPopup.root.sep
                        border.width: selected ? 2 : 1

                        onSelectedChanged: {
                            if (!selected) return;
                            if (y < contentScroller.contentY)
                                contentScroller.contentY = y;
                            else if (y + height > contentScroller.contentY + contentScroller.height)
                                contentScroller.contentY = y + height - contentScroller.height;
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: dropboxPopup.fileGlyph(modelData.name)
                            color: dropboxPopup.root.inkDeep
                            font.family: dropboxPopup.root.mono
                            font.pixelSize: 16
                        }
                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 36
                            anchors.rightMargin: 10
                            spacing: 3

                            Text {
                                width: parent.width
                                text: modelData.name
                                color: dropboxPopup.root.ink
                                font.family: dropboxPopup.root.mono
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: dropboxPopup.controller.relativeTime(modelData.modifiedTs) + "  ·  " + modelData.folder
                                color: dropboxPopup.root.inkDeep
                                font.family: dropboxPopup.root.mono
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            id: fileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                dropboxPopup.kbdIndex = index + dropboxPopup.fileOffset;
                                dropboxPopup.controller.openFile(modelData);
                            }
                        }
                    }
                }
            }
        }
    }
}
