import QtQuick
import QtQuick.Layouts

// Audio detail — output and input controls plus device pickers.
// Device state comes from `wpctl`; the input meter uses PipeWire only while open.
Item {
    id: body

    required property var root
    required property var controller
    property int kbdIndex: 1
    readonly property var _sinks: body.controller ? body.controller.audioSinks : []
    readonly property var _sources: body.controller ? body.controller.audioSources : []
    readonly property int _sinkOffset: 2
    readonly property int _inputOffset: _sinkOffset + _sinks.length
    readonly property int _sourceOffset: _inputOffset + 2
    readonly property int _kbdMax: _sourceOffset + _sources.length

    signal close()

    function kbdHandle(event) {
        const k = event.key;
        const n = body._kbdMax;
        if (n === 0)
            return false;

        if (body.kbdIndex === 1 && (k === Qt.Key_Left || k === Qt.Key_Right)) {
            const delta = (k === Qt.Key_Left) ? -5 : 5;
            const cur = body.controller ? body.controller.audioVol : 0;
            if (body.controller)
                body.controller.setVolume(cur + delta);

            return true;
        }
        if (body.kbdIndex === body._inputOffset + 1 && (k === Qt.Key_Left || k === Qt.Key_Right)) {
            const delta = (k === Qt.Key_Left) ? -5 : 5;
            const cur = body.controller ? body.controller.inputVol : 0;
            if (body.controller)
                body.controller.setInputVolume(cur + delta);

            return true;
        }
        if (k === Qt.Key_Up || k === Qt.Key_Left) {
            body.kbdIndex = Math.max(0, body.kbdIndex - 1);
            return true;
        }
        if (k === Qt.Key_Down || k === Qt.Key_Right || k === Qt.Key_Tab) {
            body.kbdIndex = Math.min(n - 1, body.kbdIndex + 1);
            return true;
        }
        if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            if (body.kbdIndex === 0 || body.kbdIndex === 1) {
                if (body.controller)
                    body.controller.toggleMute();

                return true;
            }
            if (body.kbdIndex >= body._sinkOffset && body.kbdIndex < body._inputOffset) {
                const sink = body._sinks[body.kbdIndex - body._sinkOffset];
                if (sink && body.controller)
                    body.controller.setDefaultSink(sink.id);

                return true;
            }
            if (body.kbdIndex === body._inputOffset || body.kbdIndex === body._inputOffset + 1) {
                if (body.controller && body.controller.inputReady)
                    body.controller.toggleInputMute();

                return true;
            }
            const source = body._sources[body.kbdIndex - body._sourceOffset];
            if (source && body.controller)
                body.controller.setDefaultSource(source.id);

            return true;
        }
        return false;
    }

    width: parent ? parent.width : 0
    implicitHeight: col.implicitHeight + 8
    Component.onCompleted: {
        if (body.controller)
            body.controller.refreshAll();

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

            QuickButton {
                id: muteBtn

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                root: body.root
                glyph: body.controller ? body.controller.audioIcon : "󰕾"
                label: body.controller && body.controller.audioMuted ? "UNMUTE" : "MUTE"
                selected: body.kbdIndex === 0
                onClicked: {
                    if (body.controller)
                        body.controller.toggleMute();

                }
            }

            QuickSlider {
                anchors.left: muteBtn.right
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                root: body.root
                value: body.controller ? body.controller.audioVol : 0
                min: 0
                max: 150
                onCommitted: (v) => {
                    if (body.controller)
                        body.controller.setVolume(v);

                }
                label: body.controller && body.controller.audioMuted ? "MUTED" : (body.controller ? body.controller.audioVol + "%" : "—")
            }

        }

        Rectangle {
            visible: body.kbdIndex === 1
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 90
            anchors.rightMargin: 60
            height: 1
            color: body.root.seal
            opacity: 0.6
        }

        Item {
            visible: body._sinks.length > 0
            width: parent.width
            height: visible ? sinkCol.implicitHeight : 0

            Column {
                id: sinkCol

                width: parent.width
                spacing: 6

                Text {
                    text: "OUTPUT"
                    color: body.root.inkDeep
                    font.family: body.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }

                Column {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: body._sinks

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool kbdFocused: body.kbdIndex === (index + body._sinkOffset)

                            width: parent.width
                            height: 30
                            radius: body.root.cornerRadius
                            color: modelData.isDefault || kbdFocused ? body.root.rowSel : sinkMouse.containsMouse ? body.root.rowHi : "transparent"
                            border.color: modelData.isDefault || kbdFocused ? body.root.seal : body.root.sep
                            border.width: kbdFocused ? 2 : 1

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.isDefault ? "✓" : " "
                                color: body.root.seal
                                font.family: body.root.mono
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 26
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                elide: Text.ElideRight
                                color: modelData.isDefault ? body.root.ink : body.root.fg
                                font.family: body.root.mono
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: sinkMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    body.kbdIndex = index + body._sinkOffset;
                                    if (body.controller)
                                        body.controller.setDefaultSink(modelData.id);

                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }

                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 120
                                }

                            }

                            Behavior on border.width {
                                NumberAnimation {
                                    duration: 120
                                }

                            }

                        }

                    }

                }

            }

        }

        Item {
            visible: body._sources.length > 0
            width: parent.width
            height: visible ? inputCol.implicitHeight : 0

            Column {
                id: inputCol

                width: parent.width
                spacing: 8

                Text {
                    text: "INPUT"
                    color: body.root.inkDeep
                    font.family: body.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }

                Item {
                    width: parent.width
                    height: 28

                    QuickButton {
                        id: inputMuteBtn

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        root: body.root
                        glyph: body.controller ? body.controller.inputIcon : "󰍬"
                        label: body.controller && !body.controller.inputReady ? "SELECT INPUT" : body.controller && body.controller.inputMuted ? "UNMUTE MIC" : "MUTE MIC"
                        selected: body.kbdIndex === body._inputOffset
                        onClicked: {
                            if (body.controller && body.controller.inputReady)
                                body.controller.toggleInputMute();

                        }
                    }

                    QuickSlider {
                        anchors.left: inputMuteBtn.right
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12
                        root: body.root
                        value: body.controller ? body.controller.inputVol : 0
                        min: 0
                        max: 150
                        onCommitted: (v) => {
                            if (body.controller && body.controller.inputReady)
                                body.controller.setInputVolume(v);

                        }
                        label: body.controller && !body.controller.inputReady ? "—" : body.controller && body.controller.inputMuted ? "MUTED" : (body.controller ? body.controller.inputVol + "%" : "—")
                    }

                }

                Rectangle {
                    width: parent.width
                    height: 5
                    radius: 3
                    color: Qt.rgba(body.root.ink.r, body.root.ink.g, body.root.ink.b, 0.12)

                    Rectangle {
                        width: parent.width * (body.controller ? body.controller.inputPeak : 0)
                        height: parent.height
                        radius: parent.radius
                        color: body.root.seal

                        Behavior on width {
                            NumberAnimation {
                                duration: 70
                            }

                        }

                    }

                }

                Column {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: body._sources

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool kbdFocused: body.kbdIndex === (index + body._sourceOffset)

                            width: parent.width
                            height: 30
                            radius: body.root.cornerRadius
                            color: modelData.isDefault || kbdFocused ? body.root.rowSel : sourceMouse.containsMouse ? body.root.rowHi : "transparent"
                            border.color: modelData.isDefault || kbdFocused ? body.root.seal : body.root.sep
                            border.width: kbdFocused ? 2 : 1

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.isDefault ? "✓" : " "
                                color: body.root.seal
                                font.family: body.root.mono
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 26
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                elide: Text.ElideRight
                                color: modelData.isDefault ? body.root.ink : body.root.fg
                                font.family: body.root.mono
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: sourceMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    body.kbdIndex = index + body._sourceOffset;
                                    if (body.controller)
                                        body.controller.setDefaultSource(modelData.id);

                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }

                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 120
                                }

                            }

                            Behavior on border.width {
                                NumberAnimation {
                                    duration: 120
                                }

                            }

                        }

                    }

                }

            }

        }

    }

}
