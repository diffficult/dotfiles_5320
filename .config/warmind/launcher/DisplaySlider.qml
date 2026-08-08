import QtQuick

// Click-to-set bar used in the display popup. No drag handler — pointer
// motion is coalesced through `commitTimer` so a swipe across the track
// emits at most one shell call every 60ms instead of one per frame.
Item {
    id: slider
    required property var root

    property string label: ""
    property real value: 0
    property real minV: 0
    property real maxV: 100
    property string unit: ""
    property bool selected: false

    signal commit(real v)
    signal focusRequested()

    readonly property real norm: maxV > minV
                                 ? Math.max(0, Math.min(1, (value - minV) / (maxV - minV)))
                                 : 0
    property real pendingValue: 0

    function valueFromX(x) {
        const ratio = Math.max(0, Math.min(1, x / track.width));
        return slider.minV + ratio * (slider.maxV - slider.minV);
    }

    implicitHeight: 30

    Timer {
        id: commitTimer
        interval: 60
        repeat: false
        onTriggered: slider.commit(slider.pendingValue)
    }

    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        text: slider.label
        color: slider.selected ? slider.root.seal : slider.root.inkDeep
        font.family: slider.root.mono
        font.pixelSize: 10
        font.letterSpacing: 2
        Behavior on color { ColorAnimation { duration: 140 } }
    }
    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        text: Math.round(slider.value) + slider.unit
        color: slider.selected ? slider.root.ink : slider.root.inkDeep
        font.family: slider.root.mono
        font.pixelSize: 10
        font.letterSpacing: 2
        font.weight: Font.Medium
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        height: 3
        color: Qt.rgba(slider.root.ink.r, slider.root.ink.g, slider.root.ink.b, 0.12)
        antialiasing: true

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * slider.norm
            color: slider.root.seal
            opacity: slider.selected ? 1.0 : 0.75
            antialiasing: true
            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 140 } }
        }

        // Thumb sits 4px above/below the track on the boundary.
        Rectangle {
            width: 2
            height: 11
            color: slider.root.seal
            antialiasing: true
            x: Math.max(0, Math.min(parent.width - width,
                        parent.width * slider.norm - width / 2))
            y: -4
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: (e) => {
                slider.focusRequested();
                slider.pendingValue = slider.valueFromX(e.x);
                slider.commit(slider.pendingValue);
            }
            onPositionChanged: (e) => {
                if (!pressed) return;
                slider.pendingValue = slider.valueFromX(e.x);
                commitTimer.restart();
            }
            onReleased: {
                commitTimer.stop();
                slider.commit(slider.pendingValue);
            }
        }
    }
}
