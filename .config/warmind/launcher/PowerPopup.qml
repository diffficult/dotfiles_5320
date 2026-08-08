import QtQuick

CardWindow {
    id: powerPopup
    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 620
    layerNamespace: "warmind-power"
    title: "POWER"
    subtitle: powerPopup.hasBattery
        ? powerPopup.batteryPercent + "% · " + powerPopup.batteryStateText
        : "NO BATTERY"
    footer: "↑↓ ROW · ENTER ACTIVATE · R REFRESH · ESC CLOSE"

    anchorEdge: powerPopup.root.barEdge
    anchorBarX: powerPopup.root.popupAnchorX > 0
        ? powerPopup.root.popupAnchorX : powerPopup.width / 2
    anchorBarY: powerPopup.root.popupAnchorY

    headerRight: CalendarChevron {
        root: powerPopup.root
        text: powerPopup.root.icoRefresh
        restColor: powerPopup.root.inkDeep
        font.pixelSize: 22
        onTriggered: powerPopup.controller.refresh()
    }

    readonly property var bd: powerPopup.controller ? powerPopup.controller.batteryDetail || {} : {}
    readonly property bool hasBattery: bd.percentage !== undefined && bd.percentage !== ""
    readonly property int batteryPercent: hasBattery ? parseInt(bd.percentage, 10) || 0 : 0
    readonly property string batteryState: (bd.state || "").toLowerCase()
    readonly property string batteryStateText: {
        if (batteryState === "holding") return "HOLDING";
        if (batteryState === "charging") return "CHARGING";
        if (batteryState === "fully-charged") return "FULLY CHARGED";
        if (batteryState === "discharging") return "DISCHARGING";
        return (bd.state || "").toUpperCase();
    }
    readonly property real batteryFraction: hasBattery ? Math.max(0, Math.min(1, batteryPercent / 100)) : 0
    readonly property bool charging: batteryState === "charging" && !holding
    readonly property bool holding: batteryState === "holding"
    readonly property bool profileActive: controller && controller.powerProfiles.length > 0

    property int kbdIndex: 0
    readonly property int _kbdMax: profileActive ? controller.powerProfiles.length : 0

    function profileGlyph(p) {
        if (p === "performance") return "󱐌";
        if (p === "power-saver") return "󰌪";
        return "󰊚";
    }

    function batteryIcon() {
        if (!powerPopup.root) return "󰁹";
        if (holding) return "󰂀";
        if (batteryState === "charging") return "󰂄";
        if (batteryState === "fully-charged") return "󰂅";
        const r = ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"];
        return r[Math.min(9, Math.floor(batteryPercent / 10))];
    }

    function barColor() {
        if (batteryPercent <= 10) return powerPopup.root.seal;
        if (batteryPercent <= 20) return powerPopup.root.indigo;
        return powerPopup.root.ink;
    }

    function detailValue(key, fallback) {
        const v = powerPopup.bd[key];
        return v !== undefined && v !== "" ? v : (fallback || "—");
    }

    function handleKey(event) {
        const k = event.key;
        if (k === Qt.Key_R) { powerPopup.controller.refresh(); return true; }
        if (k === Qt.Key_Q) { powerPopup.controller.close(); return true; }
        if (!powerPopup.profileActive) return false;
        const n = powerPopup._kbdMax;
        if (k === Qt.Key_Left || k === Qt.Key_Up) {
            powerPopup.kbdIndex = (powerPopup.kbdIndex - 1 + n) % n;
            return true;
        }
        if (k === Qt.Key_Right || k === Qt.Key_Down || k === Qt.Key_Tab) {
            powerPopup.kbdIndex = (powerPopup.kbdIndex + 1) % n;
            return true;
        }
        if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            const name = powerPopup.controller.powerProfiles[powerPopup.kbdIndex];
            if (name) powerPopup.controller.setPowerProfile(name);
            return true;
        }
        return false;
    }

    onDismiss: powerPopup.controller.close()
    onKeyPressed: function(event) {
        if (powerPopup.handleKey(event)) event.accepted = true;
    }

    Component.onCompleted: powerPopup.controller.refresh()

    component SectionLabel: Text {
        color: powerPopup.root.inkDeep
        font.family: powerPopup.root.mono
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 1.4
    }

    component StatLabel: Text {
        color: powerPopup.root.inkDeep
        font.family: powerPopup.root.mono
        font.pixelSize: 11
    }

    component StatValue: Text {
        color: powerPopup.root.ink
        font.family: powerPopup.root.mono
        font.pixelSize: 11
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
    }

    component StatRow: Row {
        required property string label
        required property string value
        width: parent.width
        spacing: 8
        StatLabel { text: parent.label }
        Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2); height: 1 }
        StatValue { text: parent.value }
    }

    component ProfilePill: Rectangle {
        id: pill
        required property string name
        required property int index
        readonly property bool selected: powerPopup.controller && powerPopup.controller.powerProfile === pill.name
        readonly property bool focused: powerPopup.kbdIndex === index
        width: parent.cellWidth
        height: 42
        radius: powerPopup.root.cornerRadius
        color: selected || focused ? powerPopup.root.rowSel : pillMouse.containsMouse ? powerPopup.root.rowHi : "transparent"
        border.color: selected || focused ? powerPopup.root.seal : powerPopup.root.sep
        border.width: focused ? 2 : 1
        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
            anchors.centerIn: parent
            spacing: 7
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: powerPopup.profileGlyph(pill.name)
                color: selected ? powerPopup.root.seal : powerPopup.root.ink
                font.family: powerPopup.root.mono
                font.pixelSize: 16
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.name.charAt(0).toUpperCase() + pill.name.slice(1)
                color: selected ? powerPopup.root.ink : powerPopup.root.fg
                font.family: powerPopup.root.mono
                font.pixelSize: 11
            }
        }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                powerPopup.kbdIndex = pill.index;
                powerPopup.controller.setPowerProfile(pill.name);
            }
        }
    }

    Flickable {
        id: powerScroller
        width: parent.width
        height: Math.min(560, Math.max(180, powerBody.implicitHeight))
        contentWidth: width
        contentHeight: powerBody.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
            id: powerBody
            width: powerScroller.width
            spacing: 16

            Item {
                visible: powerPopup.hasBattery
                width: parent.width
                height: 78

                Text {
                    id: heroIcon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: powerPopup.batteryIcon()
                    color: powerPopup.root.ink
                    font.family: powerPopup.root.mono
                    font.pixelSize: 44
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Column {
                    anchors.left: heroIcon.right
                    anchors.leftMargin: 16
                    anchors.right: heroPercent.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Text {
                        width: parent.width
                        text: "Battery"
                        color: powerPopup.root.ink
                        font.family: powerPopup.root.mono
                        font.pixelSize: 19
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: powerPopup.batteryStateText
                        color: powerPopup.root.inkDeep
                        font.family: powerPopup.root.mono
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2
                        elide: Text.ElideRight
                    }
                }

                Text {
                    id: heroPercent
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: powerPopup.batteryPercent + "%"
                    color: powerPopup.root.ink
                    font.family: powerPopup.root.mono
                    font.pixelSize: 40
                    font.bold: true
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Item {
                visible: powerPopup.hasBattery
                width: parent.width
                height: 8

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(powerPopup.root.ink.r, powerPopup.root.ink.g, powerPopup.root.ink.b, 0.12)
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(parent.height, parent.width * powerPopup.batteryFraction)
                    height: parent.height
                    radius: height / 2
                    color: powerPopup.barColor()
                    Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 220 } }
                    SequentialAnimation on opacity {
                        running: powerPopup.charging && powerPopup.hasBattery
                        loops: Animation.Infinite
                        alwaysRunToEnd: true
                        NumberAnimation { from: 1.0; to: 0.55; duration: 950; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.55; to: 1.0; duration: 950; easing.type: Easing.InOutSine }
                    }
                }
            }

            Grid {
                visible: powerPopup.hasBattery
                width: parent.width
                columns: 2
                columnSpacing: 28
                rowSpacing: 10

                StatRow {
                    label: powerPopup.holding ? "Charge limit" : (powerPopup.batteryState === "discharging" ? "Time left" : "Time to full")
                    value: powerPopup.holding ? powerPopup.detailValue("threshold") : powerPopup.detailValue("time")
                }
                StatRow {
                    label: "Rate"
                    value: powerPopup.detailValue("rate")
                }
                StatRow {
                    label: "Battery size"
                    value: powerPopup.detailValue("size")
                }
                StatRow {
                    label: "Charge cycles"
                    value: powerPopup.detailValue("cycles")
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: powerPopup.root.sep
            }

            Column {
                width: parent.width
                spacing: 10

                SectionLabel { text: "POWER PROFILE" }

                Row {
                    visible: powerPopup.profileActive
                    width: parent.width
                    spacing: 10
                    readonly property real cellWidth: (width - spacing * (powerPopup.controller.powerProfiles.length - 1)) / powerPopup.controller.powerProfiles.length

                    Repeater {
                        model: powerPopup.controller ? powerPopup.controller.powerProfiles : []
                        delegate: ProfilePill {
                            required property string modelData
                            required property int index
                            name: modelData
                            index: index
                        }
                    }
                }

                Text {
                    visible: !powerPopup.profileActive
                    width: parent.width
                    text: "NO POWER PROFILES"
                    color: powerPopup.root.inkDeep
                    font.family: powerPopup.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
            }
        }
    }
}
