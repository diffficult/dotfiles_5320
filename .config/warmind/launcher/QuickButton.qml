import QtQuick

// Mono-caps action button used throughout the Quick detail panels.
// Compact, hover-shaded, optional left glyph + label, click signal.
// Use `selected: true` to render a persistent fill (e.g. for the
// currently-active power profile).
Item {
    id: btn
    required property var root

    property string label: ""
    property string glyph: ""
    property bool   selected: false
    // Bumps the horizontal padding for tighter button rows.
    property int    padH: 14
    property int    labelPixelSize: 10

    signal clicked()

    implicitWidth:  content.implicitWidth + padH * 2
    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: btn.root.cornerRadius
        color: btn.selected
               ? Qt.rgba(btn.root.seal.r, btn.root.seal.g, btn.root.seal.b, 0.20)
               : mouse.containsMouse
                  ? Qt.rgba(btn.root.ink.r, btn.root.ink.g, btn.root.ink.b, 0.10)
                  : Qt.rgba(btn.root.ink.r, btn.root.ink.g, btn.root.ink.b, 0.03)
        border.color: btn.selected ? btn.root.seal : btn.root.sep
        border.width: btn.selected ? 2 : 1
        Behavior on color        { ColorAnimation  { duration: 120 } }
        Behavior on border.color { ColorAnimation  { duration: 120 } }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8

        Text {
            visible: btn.root.showQuickButtonGlyphs && btn.glyph.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: btn.glyph
            color: btn.selected ? btn.root.seal : btn.root.ink
            font.family: btn.root.mono
            font.pixelSize: btn.root.quickButtonGlyphSize * btn.root.fontScale
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: btn.label
            color: btn.selected ? btn.root.seal : btn.root.ink
            font.family: btn.root.mono
            font.pixelSize: btn.labelPixelSize
            font.letterSpacing: 1.5
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
