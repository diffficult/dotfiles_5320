import QtQuick

CardWindow {
    id: popup
    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 640
    layerNamespace: "warmind-clipboard"
    title: "CLIPBOARD"
    subtitle: controller.running ? "LOADING"
        : controller.filteredItems.length + " / " + controller.items.length + " ITEMS"
    footer: controller.selectedItem && controller.selectedItem.kind === "text"
        ? "ENTER COPY · CTRL+ENTER PASTE · R REFRESH · ESC CLOSE"
        : "ENTER COPY · O OPEN · R REFRESH · ESC CLOSE"

    headerRight: CalendarChevron {
        root: popup.root
        text: popup.root.icoRefresh
        restColor: popup.root.inkDeep
        font.pixelSize: 22
        onTriggered: popup.controller.refresh()
    }

    onDismiss: popup.controller.close()
    onKeyPressed: function(event) {
        const k = event.key;
        if (k === Qt.Key_Q) {
            popup.controller.close();
        } else if (k === Qt.Key_Down || k === Qt.Key_J) {
            popup.controller.move(1);
        } else if (k === Qt.Key_Up || k === Qt.Key_K) {
            popup.controller.move(-1);
        } else if (k === Qt.Key_R) {
            popup.controller.refresh();
        } else if (k === Qt.Key_O) {
            popup.controller.selectedOpen();
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            if (event.modifiers & Qt.ControlModifier) popup.controller.selectedPaste();
            else popup.controller.selectedCopy();
        } else {
            return;
        }
        event.accepted = true;
    }

    Row {
        width: parent.width
        height: 420
        spacing: 12

        Column {
            width: 274
            height: parent.height
            spacing: 8

            Rectangle {
                width: parent.width
                height: 36
                radius: popup.root.cornerRadius
                color: popup.root.rowHi
                border.color: popup.root.sep
                border.width: 1

                TextInput {
                    id: searchBox
                    anchors.fill: parent
                    anchors.leftMargin: 11
                    anchors.rightMargin: 11
                    verticalAlignment: TextInput.AlignVCenter
                    text: popup.controller.query
                    color: popup.root.ink
                    selectionColor: popup.root.indigo
                    selectedTextColor: popup.root.paper
                    font.family: popup.root.mono
                    font.pixelSize: 12
                    clip: true
                    focus: popup.revealed
                    activeFocusOnPress: true
                    onTextEdited: popup.controller.query = text
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                            popup.controller.move(1); event.accepted = true;
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                            popup.controller.move(-1); event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (event.modifiers & Qt.ControlModifier) popup.controller.selectedPaste();
                            else popup.controller.selectedCopy();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            popup.controller.close(); event.accepted = true;
                        }
                    }
                }

                Text {
                    anchors.left: searchBox.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchBox.text.length === 0
                    text: "FILTER HISTORY"
                    color: popup.root.inkDeep
                    opacity: 0.45
                    font.family: popup.root.mono
                    font.pixelSize: 11
                    font.letterSpacing: 1
                }
            }

            Flickable {
                width: parent.width
                height: parent.height - 44
                contentWidth: width
                contentHeight: listColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Column {
                    id: listColumn
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: popup.controller.filteredItems
                        delegate: Rectangle {
                            id: row
                            required property int index
                            required property var modelData
                            readonly property bool selected: popup.controller.selected === index
                            readonly property bool copied: popup.controller.copiedKey === modelData.key

                            width: listColumn.width
                            height: 58
                            radius: popup.root.cornerRadius
                            color: selected ? popup.root.rowSel : (mouse.containsMouse ? popup.root.rowHi : "transparent")
                            border.color: selected ? popup.root.seal : popup.root.sep
                            border.width: selected ? 1 : 0

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 9
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon
                                color: popup.root.accent
                                font.family: popup.root.mono
                                font.pixelSize: 18
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 40
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text {
                                    width: parent.width
                                    text: modelData.title
                                    color: popup.root.ink
                                    font.family: popup.root.mono
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }

                                Row {
                                    spacing: 8
                                    Text {
                                        text: modelData.kind.toUpperCase()
                                        color: popup.root.inkDeep
                                        font.family: popup.root.mono
                                        font.pixelSize: 9
                                        font.letterSpacing: 1
                                    }
                                    Text {
                                        visible: modelData.pinned
                                        text: "PINNED"
                                        color: popup.root.seal
                                        font.family: popup.root.mono
                                        font.pixelSize: 9
                                        font.letterSpacing: 1
                                    }
                                    Text {
                                        text: row.copied ? popup.controller.notice : modelData.relative
                                        color: row.copied ? popup.root.seal : popup.root.inkDeep
                                        font.family: popup.root.mono
                                        font.pixelSize: 9
                                        font.letterSpacing: 1
                                    }
                                }
                            }

                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onEntered: popup.controller.selected = row.index
                                onClicked: function(e) {
                                    popup.controller.selected = row.index;
                                    if (e.button === Qt.RightButton) popup.controller.openItem(row.modelData);
                                    else popup.controller.copyItem(row.modelData);
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: 1
            height: parent.height
            color: popup.root.sep
        }

        Rectangle {
            width: parent.width - 287
            height: parent.height
            radius: popup.root.cornerRadius
            color: popup.root.rowHi
            border.color: popup.root.sep
            border.width: 1

            property var item: popup.controller.selectedItem

            Text {
                anchors.centerIn: parent
                visible: !parent.item && !popup.controller.running
                text: popup.controller.lastError.length ? popup.controller.lastError.toUpperCase() : "NO CLIPBOARD ITEMS"
                color: popup.root.inkDeep
                font.family: popup.root.mono
                font.pixelSize: 12
                font.letterSpacing: 2
                opacity: 0.65
            }

            Image {
                anchors.fill: parent
                anchors.margins: 10
                visible: parent.item && parent.item.kind === "image"
                source: visible ? "file://" + parent.item.path : ""
                sourceSize.width: 1024
                sourceSize.height: 1024
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: 10
                visible: parent.item && parent.item.kind === "text"
                contentWidth: width
                contentHeight: textPreview.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                TextEdit {
                    id: textPreview
                    width: parent.width
                    text: parent.parent.item ? parent.parent.item.fullText : ""
                    color: popup.root.ink
                    font.family: popup.root.mono
                    font.pixelSize: 12
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText
                    readOnly: true
                    selectByMouse: true
                    persistentSelection: true
                    activeFocusOnPress: false
                    selectionColor: popup.root.indigo
                    selectedTextColor: popup.root.paper
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10
                visible: parent.item && parent.item.kind === "file"

                Text {
                    text: "FILE"
                    color: popup.root.ink
                    font.family: popup.root.mono
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 2
                }
                Text {
                    width: parent.width
                    text: parent.parent.item ? parent.parent.item.path : ""
                    color: popup.root.inkDeep
                    font.family: popup.root.mono
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
                Text {
                    text: "ENTER COPIES PATH · O OPENS"
                    color: popup.root.inkDeep
                    font.family: popup.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    opacity: 0.75
                }
            }
        }
    }
}
