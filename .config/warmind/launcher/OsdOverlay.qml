import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: overlay

    required property var root
    required property var controller

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "warmind-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    property real reveal: controller.active ? 1 : 0
    visible: reveal > 0.001

    Behavior on reveal {
        NumberAnimation {
            duration: overlay.controller.active ? 130 : 170
            easing.type: overlay.controller.active ? Easing.OutCubic : Easing.InCubic
        }
    }

    TextMetrics {
        id: textMetrics
        font.family: overlay.root.mono
        font.pixelSize: 15
        font.weight: Font.Medium
        text: overlay.controller.text || overlay.controller.label
    }

    TextMetrics {
        id: labelMetrics
        font.family: overlay.root.mono
        font.pixelSize: 10
        font.letterSpacing: 1.2
        text: overlay.controller.label
    }

    Rectangle {
        id: card

        readonly property int pad: 16
        readonly property int gap: 14
        readonly property int barWidth: 190
        readonly property int valueWidth: 56
        readonly property int messageWidth: Math.min(300, Math.ceil(textMetrics.advanceWidth))
        readonly property int progressWidth: Math.max(34 + gap + barWidth + gap + valueWidth, Math.min(360, Math.ceil(labelMetrics.advanceWidth)))

        width: pad * 2 + (overlay.controller.progress ? progressWidth : 34 + gap + messageWidth)
        height: overlay.controller.progress ? 78 : 68
        radius: overlay.root.cornerRadius
        color: overlay.root.bg
        border.color: overlay.root.sep
        border.width: 1
        opacity: overlay.reveal

        x: {
            const gap = 18;
            if (overlay.root.barEdge === "left") return overlay.root.barHeight + gap;
            if (overlay.root.barEdge === "right") return parent.width - overlay.root.barHeight - width - gap;
            return Math.round((parent.width - width) / 2);
        }
        y: {
            const gap = 42;
            if (overlay.root.barEdge === "top") return overlay.root.barHeight + gap;
            if (overlay.root.barEdge === "bottom") return parent.height - overlay.root.barHeight - height - gap;
            return Math.round(parent.height - height - 72);
        }

        transform: Scale {
            origin.x: card.width / 2
            origin.y: card.height / 2
            xScale: 0.96 + overlay.reveal * 0.04
            yScale: 0.96 + overlay.reveal * 0.04
        }

        Item {
            anchors.fill: parent
            anchors.margins: card.pad

            Column {
                visible: overlay.controller.progress
                anchors.centerIn: parent
                width: parent.width
                spacing: 6

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: card.gap

                    Text {
                        width: 34
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: overlay.controller.glyph
                        color: overlay.root.ink
                        font.family: overlay.root.mono
                        font.pixelSize: 26
                    }

                    Rectangle {
                        width: card.barWidth
                        height: 7
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(overlay.root.ink.r, overlay.root.ink.g, overlay.root.ink.b, 0.16)

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, overlay.controller.value / overlay.controller.max))
                            height: parent.height
                            radius: parent.radius
                            color: overlay.root.seal

                            Behavior on width { NumberAnimation { duration: 70 } }
                        }
                    }

                    Text {
                        width: card.valueWidth
                        anchors.verticalCenter: parent.verticalCenter
                        text: overlay.controller.text
                        color: overlay.root.ink
                        font.family: overlay.root.mono
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }
                }

                Text {
                    visible: overlay.controller.label.length > 0
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: overlay.controller.label
                    color: overlay.root.inkDeep
                    font.family: overlay.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 1.2
                    elide: Text.ElideRight
                }
            }

            Row {
                visible: !overlay.controller.progress
                anchors.centerIn: parent
                spacing: card.gap

                Text {
                    width: 34
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: overlay.controller.glyph
                    color: overlay.root.ink
                    font.family: overlay.root.mono
                    font.pixelSize: 26
                }

                Text {
                    width: card.messageWidth
                    anchors.verticalCenter: parent.verticalCenter
                    text: overlay.controller.text
                    color: overlay.root.ink
                    font.family: overlay.root.mono
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }
        }
    }
}
