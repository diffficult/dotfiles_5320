import QtQuick

// Hover-reactive glyph used for the calendar's prev/today/next controls.
// Hit area expands -7px around the glyph so the click target is fat.
Text {
    id: chevron
    required property var root

    property color restColor: root.ink
    property color hotColor:  root.seal
    signal triggered()

    color: chevronMouse.containsMouse ? hotColor : restColor
    font.family: root.mono
    font.pixelSize: 24
    Behavior on color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: chevronMouse
        anchors.fill: parent
        anchors.margins: -7
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chevron.triggered()
    }
}
