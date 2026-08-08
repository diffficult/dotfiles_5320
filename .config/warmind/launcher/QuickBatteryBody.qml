import QtQuick
import QtQuick.Layouts

// Battery detail — capacity bar + state line + power-profile selector
// when powerprofilesctl is installed. Keyboard: arrows / Tab cycle the
// available profiles, Enter sets the focused one.
Item {
    id: body
    required property var root
    required property var nav
    required property var powerController
    width: parent ? parent.width : 0

    signal close()

    implicitHeight: col.implicitHeight + 8

    Component.onCompleted: if (body.powerController) body.powerController.refreshPowerProfile()

    readonly property bool hasProfile: powerController && powerController.powerProfile.length > 0
                                       && powerController.powerProfiles.length > 0
    property int kbdIndex: 0
    readonly property int _kbdMax: hasProfile ? body.powerController.powerProfiles.length : 0

    function _profileGlyph(p) {
        if (p === "performance") return "󱐌";
        if (p === "power-saver") return "󰌪";
        return "󰊚";
    }

    function kbdHandle(event) {
        if (!body.hasProfile) return false;
        const k = event.key;
        const n = body.powerController.powerProfiles.length;
        if (k === Qt.Key_Left || k === Qt.Key_Up) {
            body.kbdIndex = (body.kbdIndex - 1 + n) % n;
            return true;
        }
        if (k === Qt.Key_Right || k === Qt.Key_Down || k === Qt.Key_Tab) {
            body.kbdIndex = (body.kbdIndex + 1) % n;
            return true;
        }
        if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            const name = body.powerController.powerProfiles[body.kbdIndex];
            if (name) body.powerController.setPowerProfile(name);
            return true;
        }
        return false;
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 6
        spacing: 12

        Item {
            width: parent.width
            height: 28
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 10
                radius: 5
                color: Qt.rgba(body.root.ink.r, body.root.ink.g, body.root.ink.b, 0.10)
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.max(0, Math.min(1,
                        (body.nav ? body.nav.batVal : 0) / 100))
                    radius: parent.radius
                    color: body.nav && body.nav.batVal <= 10
                           ? body.root.seal
                           : (body.nav && body.nav.batVal <= 20
                              ? body.root.indigo
                              : body.root.ink)
                    Behavior on width { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation  { duration: 180 } }
                }
            }
        }

        Text {
            width: parent.width
            text: body.nav
                  ? body.nav.batVal + "%"
                    + "  ·  " + body.nav.batState.toUpperCase()
                    + (body.nav.batPower >= 0.05
                        ? "  ·  " + body.nav.batPower.toFixed(1) + "W"
                        : "")
                  : "—"
            color: body.root.inkDeep
            font.family: body.root.mono
            font.pixelSize: 10
            font.letterSpacing: 2
        }

        Item {
            visible: body.hasProfile
            width: parent.width
            height: visible ? profileCol.implicitHeight : 0

            Column {
                id: profileCol
                width: parent.width
                spacing: 6

                Text {
                    text: "POWER PROFILE"
                    color: body.root.inkDeep
                    font.family: body.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
                Flow {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: body.powerController ? body.powerController.powerProfiles : []
                        delegate: QuickButton {
                            required property string modelData
                            required property int index
                            root: body.root
                            glyph: body._profileGlyph(modelData)
                            label: modelData.toUpperCase()
                            selected: (body.powerController && body.powerController.powerProfile === modelData)
                                      || body.kbdIndex === index
                            onClicked: if (body.powerController) body.powerController.setPowerProfile(modelData)
                        }
                    }
                }
            }
        }
    }
}
