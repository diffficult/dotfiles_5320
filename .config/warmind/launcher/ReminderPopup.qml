import QtQuick

CardWindow {
    id: reminderPopup

    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 500
    layerNamespace: "warmind-reminder"
    title: "REMINDER"
    subtitle: controller.reminders.length > 0 ? controller.reminders.length + " ACTIVE · " + (controller.step === "delay" ? "CHOOSE A DELAY" : controller.minutes + " MINUTES") : (controller.step === "delay" ? "CHOOSE A DELAY" : controller.minutes + " MINUTES")
    footer: controller.step === "delay" ? "TYPE MINUTES  ·  ENTER CONTINUE  ·  R REFRESH  ·  ESC CLOSE" : "ENTER SCHEDULE  ·  R REFRESH  ·  ESC CLOSE"
    anchorEdge: reminderPopup.root.barEdge
    anchorBarX: reminderPopup.root.popupAnchorX > 0 ? reminderPopup.root.popupAnchorX : reminderPopup.width / 2
    anchorBarY: reminderPopup.root.popupAnchorY
    onDismiss: reminderPopup.controller.close()
    onRevealedChanged: {
        if (!revealed)
            return ;

        reminderPopup.controller.refreshTimers();
        Qt.callLater(function() {
            if (reminderPopup.controller.step === "delay")
                delayInput.forceActiveFocus();
            else
                messageInput.forceActiveFocus();
        });
    }
    onKeyPressed: function(event) {
        if (event.key === Qt.Key_R) {
            reminderPopup.controller.refreshTimers();
            event.accepted = true;
            return ;
        }
        if (event.key === Qt.Key_Q) {
            reminderPopup.controller.close();
            event.accepted = true;
        }
    }
    Component.onCompleted: Qt.callLater(function() {
        delayInput.forceActiveFocus();
    })

    Connections {
        function onStepChanged() {
            Qt.callLater(function() {
                if (!reminderPopup.revealed)
                    return ;

                if (reminderPopup.controller.step === "delay")
                    delayInput.forceActiveFocus();
                else
                    messageInput.forceActiveFocus();
            });
        }

        target: reminderPopup.controller
    }

    Column {
        width: parent.width
        spacing: 14

        Column {
            visible: reminderPopup.controller.reminders.length > 0
            width: parent.width
            spacing: 8

            Text {
                text: "ACTIVE REMINDERS"
                color: reminderPopup.root.inkDeep
                font.family: reminderPopup.root.mono
                font.pixelSize: 10
                font.letterSpacing: 1.5
            }

            Item {
                width: parent.width
                height: Math.min(174, reminderList.implicitHeight)

                Flickable {
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: reminderList.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height

                    Column {
                        id: reminderList

                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: reminderPopup.controller.reminders

                            delegate: Rectangle {
                                required property var modelData

                                width: reminderList.width
                                height: 52
                                radius: reminderPopup.root.cornerRadius
                                color: reminderPopup.root.rowHi
                                border.color: reminderPopup.root.sep
                                border.width: 1

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 9
                                    spacing: 3

                                    Text {
                                        width: parent.width
                                        text: modelData.message
                                        color: reminderPopup.root.ink
                                        font.family: reminderPopup.root.mono
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "AT " + reminderPopup.controller.formatTime(modelData.at) + "  ·  " + reminderPopup.controller.formatRemaining(modelData.at)
                                        color: reminderPopup.root.inkDeep
                                        font.family: reminderPopup.root.mono
                                        font.pixelSize: 10
                                        font.letterSpacing: 1
                                    }

                                }

                            }

                        }

                    }

                }

            }

        }

        Item {
            width: parent.width
            height: reminderPopup.controller.step === "delay" ? delayBody.implicitHeight : messageBody.implicitHeight

            Column {
                id: delayBody

                width: parent.width
                visible: reminderPopup.controller.step === "delay"
                spacing: 10

                Text {
                    text: "QUICK DELAYS"
                    color: reminderPopup.root.inkDeep
                    font.family: reminderPopup.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                }

                Row {
                    spacing: 7

                    Repeater {
                        model: reminderPopup.controller.presets

                        delegate: QuickButton {
                            required property int modelData

                            root: reminderPopup.root
                            label: modelData + "M"
                            onClicked: reminderPopup.controller.chooseDelay(modelData)
                        }

                    }

                }

                Text {
                    text: "OR ENTER MINUTES"
                    color: reminderPopup.root.inkDeep
                    font.family: reminderPopup.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                }

                Rectangle {
                    width: parent.width
                    height: 42
                    radius: reminderPopup.root.cornerRadius
                    color: reminderPopup.root.rowHi
                    border.color: delayInput.activeFocus ? reminderPopup.root.seal : reminderPopup.root.sep
                    border.width: delayInput.activeFocus ? 2 : 1

                    TextInput {
                        id: delayInput

                        anchors.fill: parent
                        anchors.margins: 11
                        color: reminderPopup.root.ink
                        font.family: reminderPopup.root.mono
                        font.pixelSize: 15
                        inputMethodHints: Qt.ImhDigitsOnly
                        selectByMouse: true
                        text: reminderPopup.controller.minutes
                        onTextEdited: {
                            reminderPopup.controller.minutes = text;
                            reminderPopup.controller.errorText = "";
                        }
                        Keys.onReturnPressed: function(event) {
                            reminderPopup.controller.chooseDelay(delayInput.text);
                            event.accepted = true;
                        }
                        Keys.onEnterPressed: function(event) {
                            reminderPopup.controller.chooseDelay(delayInput.text);
                            event.accepted = true;
                        }
                    }

                    Text {
                        anchors.fill: parent
                        anchors.margins: 11
                        visible: !delayInput.text
                        text: "MINUTES"
                        color: reminderPopup.root.muted
                        font.family: reminderPopup.root.mono
                        font.pixelSize: 15
                        verticalAlignment: Text.AlignVCenter
                    }

                }

            }

            Column {
                id: messageBody

                width: parent.width
                visible: reminderPopup.controller.step === "message"
                spacing: 10

                Text {
                    text: "WHAT SHOULD WE REMIND YOU?"
                    color: reminderPopup.root.inkDeep
                    font.family: reminderPopup.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                }

                Rectangle {
                    width: parent.width
                    height: 72
                    radius: reminderPopup.root.cornerRadius
                    color: reminderPopup.root.rowHi
                    border.color: messageInput.activeFocus ? reminderPopup.root.seal : reminderPopup.root.sep
                    border.width: messageInput.activeFocus ? 2 : 1

                    TextInput {
                        id: messageInput

                        anchors.fill: parent
                        anchors.margins: 11
                        color: reminderPopup.root.ink
                        font.family: reminderPopup.root.mono
                        font.pixelSize: 14
                        selectByMouse: true
                        text: reminderPopup.controller.message
                        onTextChanged: reminderPopup.controller.message = text
                        Keys.onReturnPressed: function(event) {
                            reminderPopup.controller.schedule();
                            event.accepted = true;
                        }
                        Keys.onEnterPressed: function(event) {
                            reminderPopup.controller.schedule();
                            event.accepted = true;
                        }
                    }

                    Text {
                        anchors.fill: parent
                        anchors.margins: 11
                        visible: !messageInput.text
                        text: "OPTIONAL MESSAGE"
                        color: reminderPopup.root.muted
                        font.family: reminderPopup.root.mono
                        font.pixelSize: 14
                    }

                }

                Row {
                    spacing: 8

                    QuickButton {
                        root: reminderPopup.root
                        label: "BACK"
                        onClicked: reminderPopup.controller.backToDelay()
                    }

                    QuickButton {
                        root: reminderPopup.root
                        label: "SCHEDULE"
                        selected: true
                        onClicked: reminderPopup.controller.schedule()
                    }

                }

            }

        }

        Text {
            visible: reminderPopup.controller.errorText.length > 0
            width: parent.width
            text: reminderPopup.controller.errorText
            color: reminderPopup.root.warn
            font.family: reminderPopup.root.mono
            font.pixelSize: 10
            font.letterSpacing: 1
            wrapMode: Text.WordWrap
        }

    }

}
