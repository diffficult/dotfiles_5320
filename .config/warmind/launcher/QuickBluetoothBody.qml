import QtQuick

// Bluetooth detail — controller toggles plus rich device list.
// Keyboard: arrows / Tab move through header buttons and devices,
// Enter/Space activates.
Item {
    id: body
    required property var root
    required property var controller
    property var scroller: null
    width: parent ? parent.width : 0

    signal close()

    implicitHeight: col.implicitHeight + 8

    Component.onCompleted: if (body.controller) body.controller.refreshAll()

    property int kbdIndex: 0
    readonly property int _headerCount: 4
    readonly property var _visibleDevs: body.controller && body.controller.powered
                                        ? body.controller.devices
                                        : []
    readonly property int _kbdMax: _headerCount + _visibleDevs.length

    function kbdHandle(event) {
        const k = event.key;
        const n = body._kbdMax;
        if (n === 0) return false;
        if (k === Qt.Key_Up || k === Qt.Key_Left) {
            body.kbdIndex = Math.max(0, body.kbdIndex - 1);
            body._ensureVisible();
            return true;
        }
        if (k === Qt.Key_Down || k === Qt.Key_Right || k === Qt.Key_Tab) {
            body.kbdIndex = Math.min(n - 1, body.kbdIndex + 1);
            body._ensureVisible();
            return true;
        }
        if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            body._activateAt(body.kbdIndex);
            return true;
        }
        return false;
    }

    function _activateAt(i) {
        body.kbdIndex = i;
        body._ensureVisible();
        if (i === 0) { if (body.controller) body.controller.togglePower(); return; }
        if (i === 1) { if (body.controller) body.controller.toggleScan(); return; }
        if (i === 2) { if (body.controller) body.controller.togglePairable(); return; }
        if (i === 3) { if (body.controller) body.controller.toggleDiscoverable(); return; }
        const dev = body._visibleDevs[i - body._headerCount];
        if (!dev || !body.controller) return;
        if (dev.connected) body.controller.disconnect(dev.mac);
        else body.controller.connect(dev.mac);
    }

    function _ensureVisible() {
        if (!body.scroller || body.kbdIndex < body._headerCount) return;
        const item = devRepeater.itemAt(body.kbdIndex - body._headerCount);
        if (!item) return;
        const top = item.y;
        const bottom = item.y + item.height;
        if (top < body.scroller.contentY)
            body.scroller.contentY = top;
        else if (bottom > body.scroller.contentY + body.scroller.height)
            body.scroller.contentY = bottom - body.scroller.height;
    }

    function _batteryText(dev) {
        if (!dev || dev.battery === undefined || dev.battery < 0) return "";
        const pct = dev.battery;
        const glyph = pct >= 75 ? "󰁹"
                    : pct >= 50 ? "󰂀"
                    : pct >= 25 ? "󰁾"
                    : "󰁺";
        return glyph + " " + pct + "%";
    }

    function _batteryColor(dev) {
        const pct = dev && dev.battery !== undefined ? dev.battery : -1;
        if (pct < 0) return body.root.inkDeep;
        if (pct <= 25) return "#f7768e";
        if (pct <= 50) return "#e0af68";
        return "#9ece6a";
    }

    function _statusText(dev) {
        if (!dev) return "";
        const bits = [];
        if (dev.connected) bits.push("CONNECTED");
        else if (dev.paired) bits.push("PAIRED");
        if (dev.trusted) bits.push("TRUSTED");
        return bits.join("  ·  ");
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 6
        spacing: 10

        Column {
            width: parent.width
            spacing: 10

            Item {
                width: parent.width
                height: 28
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: !body.controller ? "—"
                          : !body.controller.powered ? "POWER OFF"
                          : (body.controller.devices.length + " DEVICES"
                             + (body.controller.count > 0
                                ? "  ·  " + body.controller.count + " CONN"
                                : "")
                             + (body.controller.scanning ? "  ·  SCANNING" : ""))
                    color: body.root.inkDeep
                    font.family: body.root.mono
                    font.pixelSize: 12
                    font.letterSpacing: 2
                }
            }

            Flow {
                width: parent.width
                spacing: 8

                QuickButton {
                    root: body.root
                    labelPixelSize: 14
                    label: body.controller && body.controller.powered ? "POWER OFF" : "POWER ON"
                    selected: body.kbdIndex === 0
                    onClicked: if (body.controller) body.controller.togglePower()
                }
                QuickButton {
                    root: body.root
                    labelPixelSize: 14
                    label: body.controller && body.controller.scanning ? "SCANNING" : "SCAN"
                    selected: body.kbdIndex === 1 || (body.controller && body.controller.scanning)
                    onClicked: if (body.controller) body.controller.toggleScan()
                }
                QuickButton {
                    root: body.root
                    labelPixelSize: 14
                    label: body.controller && body.controller.pairable ? "PAIRABLE" : "PAIR OFF"
                    selected: body.kbdIndex === 2 || (body.controller && body.controller.pairable)
                    onClicked: if (body.controller) body.controller.togglePairable()
                }
                QuickButton {
                    root: body.root
                    labelPixelSize: 14
                    label: body.controller && body.controller.discoverable ? "VISIBLE" : "HIDDEN"
                    selected: body.kbdIndex === 3 || (body.controller && body.controller.discoverable)
                    onClicked: if (body.controller) body.controller.toggleDiscoverable()
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: body.root.sep }

        Repeater {
            id: devRepeater
            model: body._visibleDevs
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool kbdFocused: body.kbdIndex === (index + body._headerCount)
                width: col.width
                height: 44
                radius: body.root.cornerRadius
                color: modelData.connected || kbdFocused
                       ? body.root.rowSel
                       : devMouse.containsMouse
                           ? body.root.rowHi
                           : "transparent"
                border.color: modelData.connected || kbdFocused ? body.root.seal : body.root.sep
                border.width: kbdFocused ? 2 : 1
                Behavior on color        { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }
                Behavior on border.width { NumberAnimation { duration: 120 } }

                Text {
                    id: devIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.glyph || (modelData.connected ? "󰂱" : (modelData.paired ? "󰂯" : "󰂲"))
                    color: modelData.connected ? body.root.seal : body.root.ink
                    font.family: body.root.mono
                    font.pixelSize: 21
                }

                Column {
                    anchors.left: devIcon.right
                    anchors.right: tag.left
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: modelData.name
                        elide: Text.ElideRight
                        color: modelData.connected ? body.root.ink : body.root.fg
                        font.family: body.root.mono
                        font.pixelSize: 15
                        font.weight: modelData.connected ? Font.Medium : Font.Normal
                    }
                    Row {
                        width: parent.width
                        spacing: 10
                        visible: statusText.text.length > 0 || batteryText.text.length > 0

                        Text {
                            id: statusText
                            text: body._statusText(modelData)
                            visible: text.length > 0
                            color: body.root.inkDeep
                            font.family: body.root.mono
                            font.pixelSize: 13
                            font.letterSpacing: 1.1
                            opacity: 0.85
                            elide: Text.ElideRight
                            width: parent.width - (batteryText.visible ? batteryText.implicitWidth + parent.spacing : 0)
                        }
                        Text {
                            id: batteryText
                            text: body._batteryText(modelData)
                            visible: text.length > 0
                            color: body._batteryColor(modelData)
                            font.family: body.root.mono
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            opacity: 0.95
                        }
                    }
                }

                Text {
                    id: tag
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.connected ? "DISCONNECT" : "CONNECT"
                    color: modelData.connected ? body.root.seal : body.root.inkDeep
                    font.family: body.root.mono
                    font.pixelSize: 13
                    font.letterSpacing: 1.5
                }
                MouseArea {
                    id: devMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: body._activateAt(index + body._headerCount)
                }
            }
        }

        Text {
            visible: body.controller && body.controller.powered && body.controller.devices.length === 0
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: body.controller && body.controller.scanning
                  ? "SCANNING — WAITING FOR DEVICES"
                  : "NO DEVICES — TAP SCAN"
            color: body.root.inkDeep
            font.family: body.root.mono
            font.pixelSize: 12
            font.letterSpacing: 2
            opacity: 0.6
        }
    }
}
