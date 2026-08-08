import QtQuick

// Display detail — driven by DisplayController.
// Supports warmth/gamma when hyprsunset exists and brightness when
// brightnessctl is available on the target machine.
Item {
    id: body
    required property var root
    required property var controller
    width: parent ? parent.width : 0

    signal close()

    implicitHeight: col.implicitHeight + 8

    Component.onCompleted: {
        if (body.controller) body.controller.refreshAll();
    }

    function kbdHandle(event) {
        if (!body.controller) return false;
        const r = body.controller;
        const k = event.key;
        if (k === Qt.Key_Up) {
            r.displayRow = Math.max(0, r.displayRow - 1);
            return true;
        }
        if (k === Qt.Key_Down || k === Qt.Key_Tab) {
            r.displayRow = Math.min(r.maxRowIndex(), r.displayRow + 1);
            return true;
        }
        if (k === Qt.Key_Left) {
            const sliders = r.sliderModels();
            const row = r.displayRow;
            if (sliders[row]) {
                if (sliders[row].kind === "warmth") r.setWarmth(r.warmthK - 250);
                else if (sliders[row].kind === "brightness") r.setBrightness(r.brightnessPct - 5);
                else if (sliders[row].kind === "gamma") r.setGamma(r.gammaPct - 5);
                return true;
            }
            if (r.hyprsunsetAvailable && row === r.presetRowIndex()) {
                const n = r.displayPresets.length;
                r.selectedPreset = (r.selectedPreset - 1 + n) % n;
                return true;
            }
        }
        if (k === Qt.Key_Right) {
            const sliders = r.sliderModels();
            const row = r.displayRow;
            if (sliders[row]) {
                if (sliders[row].kind === "warmth") r.setWarmth(r.warmthK + 250);
                else if (sliders[row].kind === "brightness") r.setBrightness(r.brightnessPct + 5);
                else if (sliders[row].kind === "gamma") r.setGamma(r.gammaPct + 5);
                return true;
            }
            if (r.hyprsunsetAvailable && row === r.presetRowIndex()) {
                r.selectedPreset = (r.selectedPreset + 1) % r.displayPresets.length;
                return true;
            }
        }
        if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            if (r.displayRow === r.presetRowIndex() && r.hyprsunsetAvailable) {
                r.applyPreset(r.displayPresets[r.selectedPreset]);
            } else if (r.displayRow === r.editRowIndex()) {
                r.openMonitorConfig();
                body.close();
            } else if (r.displayRow === r.blankRowIndex()) {
                r.blankScreen();
                body.close();
            } else if (r.displayRow === r.resetRowIndex()) {
                r.resetDisplay();
            }
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
        spacing: 10

        Text {
            text: body.controller ? body.controller.statusText() : ""
            color: body.root.inkDeep
            font.family: body.root.mono
            font.pixelSize: 10
            font.letterSpacing: 2
        }

        Repeater {
            model: body.controller ? body.controller.sliderModels() : []
            delegate: DisplaySlider {
                required property var modelData
                required property int index
                root: body.root
                width: col.width
                label: modelData.label
                value: body.controller ? body.controller[modelData.valKey] : 0
                minV: modelData.lo
                maxV: modelData.hi
                unit: modelData.unit
                selected: body.controller && body.controller.displayRow === index
                onCommit: function(v) {
                    if (!body.controller) return;
                    if (modelData.kind === "warmth") body.controller.setWarmth(v);
                    else if (modelData.kind === "brightness") body.controller.setBrightness(v);
                    else body.controller.setGamma(v);
                }
                onFocusRequested: if (body.controller) body.controller.displayRow = index
            }
        }

        Rectangle { width: parent.width; height: 1; color: body.root.sep }

        Item {
            visible: body.controller && body.controller.hyprsunsetAvailable
            width: parent.width
            height: visible ? 38 : 0
            Text {
                anchors.left: parent.left
                anchors.top: parent.top
                text: "PRESETS"
                color: body.controller && body.controller.displayRow === body.controller.presetRowIndex() ? body.root.seal : body.root.inkDeep
                font.family: body.root.mono
                font.pixelSize: 10
                font.letterSpacing: 2
                Behavior on color { ColorAnimation { duration: 140 } }
            }
            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                spacing: 6
                Repeater {
                    model: body.controller ? body.controller.displayPresets : []
                    delegate: DisplayChip {
                        required property var modelData
                        required property int index
                        root: body.root
                        label: modelData.label
                        selected: body.controller && body.controller.selectedPreset === index
                        onActivated: {
                            if (!body.controller) return;
                            body.controller.selectedPreset = index;
                            body.controller.displayRow = body.controller.presetRowIndex();
                            body.controller.applyPreset(modelData);
                        }
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: body.root.sep }

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: body.controller
                  ? "MONITOR · " + body.controller.monitorName + " · " + body.controller.monitorRes
                    + " · ×" + body.controller.monitorScale.toFixed(2)
                  : ""
            color: body.root.inkDeep
            font.family: body.root.mono
            font.pixelSize: 10
            font.letterSpacing: 2
        }

        Item {
            width: parent.width
            height: 28
            DisplayChip {
                root: body.root
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                label: "EDIT MONITORS"
                selected: body.controller && body.controller.displayRow === body.controller.editRowIndex()
                onActivated: {
                    if (!body.controller) return;
                    body.controller.displayRow = body.controller.editRowIndex();
                    body.controller.openMonitorConfig();
                    body.close();
                }
            }
            DisplayChip {
                root: body.root
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                label: (body.root ? body.root.icoPower : "") + " BLANK"
                selected: body.controller && body.controller.displayRow === body.controller.blankRowIndex()
                onActivated: {
                    if (!body.controller) return;
                    body.controller.displayRow = body.controller.blankRowIndex();
                    body.controller.blankScreen();
                    body.close();
                }
            }
            DisplayChip {
                root: body.root
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                label: "RESET"
                selected: body.controller && body.controller.displayRow === body.controller.resetRowIndex()
                onActivated: {
                    if (!body.controller) return;
                    body.controller.displayRow = body.controller.resetRowIndex();
                    body.controller.resetDisplay();
                }
            }
        }
    }
}
