import QtQuick

// Hover bloom: a soft accent-tinted halo that radiates from the cursor's
// entry point and fades inside the item rect. Single-beat sibling of
// clipboard-ripple. Clipped to the host bounds so neighbours don't get
// splashed.
Item {
    id: bloomRoot
    required property var root
    anchors.fill: parent
    clip: true

    property real ox: 0
    property real oy: 0
    property real haloR: 0
    property real haloO: 0

    function fire(x, y) {
        bloomRoot.ox = x;
        bloomRoot.oy = y;
        bloomAnim.restart();
    }

    Rectangle {
        width: bloomRoot.haloR * 2
        height: bloomRoot.haloR * 2
        radius: bloomRoot.haloR
        x: bloomRoot.ox - bloomRoot.haloR
        y: bloomRoot.oy - bloomRoot.haloR
        color: Qt.lighter(bloomRoot.root.accent, 1.35)
        opacity: bloomRoot.haloO
        antialiasing: true
    }

    SequentialAnimation {
        id: bloomAnim
        ScriptAction { script: { bloomRoot.haloR = 0; bloomRoot.haloO = 0; } }
        ParallelAnimation {
            NumberAnimation {
                target: bloomRoot; property: "haloR"
                from: 2; to: Math.max(bloomRoot.width, bloomRoot.height) * 0.9
                duration: 250
                easing.type: Easing.OutCubic
            }
            SequentialAnimation {
                NumberAnimation { target: bloomRoot; property: "haloO"; from: 0; to: 0.22; duration: 80; easing.type: Easing.OutQuad }
                NumberAnimation { target: bloomRoot; property: "haloO"; to: 0; duration: 170; easing.type: Easing.InCubic }
            }
        }
    }
}
