import QtQuick

// Stub — Aether blueprint system not available on this machine.
Item {
    id: body
    required property var root
    required property var nav
    width: parent ? parent.width : 0

    signal close()

    implicitHeight: 80

    function kbdHandle(event) { return false }

    Text {
        anchors.centerIn: parent
        text: "Not available on this system"
        color: body.root ? body.root.sumi : "#585b70"
        font.family: body.root ? body.root.mono : "monospace"
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
    }
}
