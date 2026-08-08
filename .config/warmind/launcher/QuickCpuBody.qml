import QtQuick
import QtQuick.Layouts

// CPU detail — live CPU + memory bars with a BTOP launch button. btop
// is intentionally an external TUI (user choice); Enter fires it.
Item {
    id: body
    required property var root
    required property var nav
    width: parent ? parent.width : 0

    signal close()

    implicitHeight: col.implicitHeight + 8

    // Only one focusable thing (the BTOP button). Keep the contract so
    // OmniMenu's forwarder doesn't think the body refuses to handle keys.
    property int kbdIndex: 0
    readonly property int _kbdMax: 1

    function kbdHandle(event) {
        const k = event.key;
        if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            body._launch();
            return true;
        }
        return false;
    }
    function _launch() {
        if (body.nav) body.nav.run("footclient -a footclient-float -T 'CPU' -e btop");
        body.close();
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 6
        spacing: 10

        Repeater {
            model: [
                { label: "CPU", value: body.nav ? body.nav.cpuVal : 0, threshold: 80 },
                { label: "MEM", value: body.nav ? body.nav.memVal : 0, threshold: 80 }
            ]
            delegate: Item {
                required property var modelData
                width: col.width
                height: 26

                Text {
                    id: lbl
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    color: body.root.inkDeep
                    font.family: body.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
                Rectangle {
                    anchors.left: lbl.right
                    anchors.leftMargin: 12
                    anchors.right: valLbl.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    height: 6
                    radius: 3
                    color: Qt.rgba(body.root.ink.r, body.root.ink.g, body.root.ink.b, 0.10)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(1, modelData.value / 100))
                        radius: parent.radius
                        color: modelData.value > modelData.threshold
                               ? body.root.seal : body.root.ink
                        Behavior on width { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
                    }
                }
                Text {
                    id: valLbl
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(modelData.value) + "%"
                    color: body.root.ink
                    font.family: body.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                    font.weight: Font.Medium
                }
            }
        }

        Flow {
            width: parent.width
            spacing: 8
            QuickButton {
                root: body.root
                glyph: "󰍛"
                label: "BTOP"
                selected: body.kbdIndex === 0
                onClicked: body._launch()
            }
        }
    }
}
