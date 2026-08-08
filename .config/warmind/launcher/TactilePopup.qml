import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: tactilePopup
    required property var root
    required property var controller

    color: "transparent"
    visible: controller.active
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "warmind-tactile"
    WlrLayershell.keyboardFocus: controller.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    screen: controller.screen

    function keyToken(event) {
        const txt = (event.text || "").toLowerCase();
        if (txt.length === 1 && controller.letters.indexOf(txt) >= 0) return txt;
        return "";
    }

    Item {
        anchors.fill: parent
        focus: controller.active

        Keys.onPressed: function(event) {
            const token = tactilePopup.keyToken(event);
            if (event.key === Qt.Key_Escape) {
                controller.close();
            } else if (event.key === Qt.Key_Backspace) {
                controller.resetSelection();
            } else if (token.length > 0) {
                controller.selectKey(token);
            } else {
                return;
            }
            event.accepted = true;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: controller.close()
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.18)
        }
    }

    Rectangle {
        id: frame
        x: controller.workX
        y: controller.workY
        width: controller.workWidth
        height: controller.workHeight
        color: Qt.rgba(root.bg.r, root.bg.g, root.bg.b, 0.18)
        border.color: Qt.rgba(root.seal.r, root.seal.g, root.seal.b, 0.80)
        border.width: 2
        radius: root.cornerRadius + 4

        Text {
            id: titleText
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 14
            anchors.topMargin: 10
            width: parent.width - 28
            text: (controller.windowTitle || "ACTIVE WINDOW").toUpperCase()
            color: root.ink
            font.family: root.mono
            font.pixelSize: 16
            font.letterSpacing: 3
            elide: Text.ElideRight
        }

        Text {
            anchors.left: parent.left
            anchors.top: titleText.bottom
            anchors.topMargin: 4
            anchors.leftMargin: 14
            width: parent.width - 28
            text: controller.firstKey === ""
                  ? ("SELECT FIRST CORNER  ·  " + (controller.monitorName || "MONITOR"))
                  : ("SELECT SECOND CORNER FROM " + controller.keyMap[controller.firstKey].label + "  ·  " + (controller.monitorName || "MONITOR"))
            color: root.inkDeep
            font.family: root.mono
            font.pixelSize: 10
            font.letterSpacing: 2
            elide: Text.ElideRight
        }

        Repeater {
            model: controller.cells
            delegate: Rectangle {
                required property var modelData
                readonly property bool selected: controller.previewKeys.indexOf(modelData.key) >= 0
                x: modelData.x - controller.workX
                y: modelData.y - controller.workY
                width: modelData.width
                height: modelData.height
                color: selected
                       ? Qt.rgba(root.seal.r, root.seal.g, root.seal.b, controller.firstKey === modelData.key ? 0.34 : 0.24)
                       : Qt.rgba(root.paper.r, root.paper.g, root.paper.b, 0.06)
                border.color: selected ? root.seal : Qt.rgba(root.sep.r, root.sep.g, root.sep.b, 0.95)
                border.width: selected ? 2 : 1

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: parent.selected ? root.paper : root.ink
                    font.family: root.mono
                    font.pixelSize: 24
                    font.weight: Font.Medium
                    opacity: parent.selected ? 1.0 : 0.85
                }
            }
        }
    }

    Text {
        anchors.horizontalCenter: frame.horizontalCenter
        anchors.top: frame.bottom
        anchors.topMargin: 10
        text: controller.firstKey === ""
              ? "PRESS TWO KEYS TO DEFINE THE RECTANGLE  ·  ESC CLOSE"
              : "SECOND KEY APPLIES  ·  BACKSPACE RESETS  ·  ESC CLOSE"
        color: root.inkDeep
        font.family: root.mono
        font.pixelSize: 10
        font.letterSpacing: 2
        opacity: 0.9
    }
}
