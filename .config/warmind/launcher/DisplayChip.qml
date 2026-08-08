import QtQuick

// Pill-shaped click target used by presets and the action row.
Item {
    id: chip
    required property var root

    property string label: ""
    property bool selected: false
    signal activated()

    implicitWidth: chipText.implicitWidth + 18
    implicitHeight: 22

    Rectangle {
        anchors.fill: parent
        color: chipMouse.containsMouse
               ? Qt.rgba(chip.root.ink.r, chip.root.ink.g, chip.root.ink.b, 0.10)
               : Qt.rgba(chip.root.ink.r, chip.root.ink.g, chip.root.ink.b, 0.04)
        border.color: chip.selected ? chip.root.seal : chip.root.sep
        border.width: 1
        radius: chip.root.cornerRadius
        antialiasing: true
        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    Text {
        id: chipText
        anchors.centerIn: parent
        text: chip.label
        color: chip.selected ? chip.root.ink : chip.root.inkDeep
        font.family: chip.root.mono
        font.pixelSize: 10
        font.letterSpacing: 2
    }

    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.activated()
    }
}
