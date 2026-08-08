import QtQuick

// Weather detail — mirrors WeatherPopup's body inline. Mostly read-only;
// keyboard shortcuts: R = refresh, E = edit location file, Enter on the
// default focus also refreshes.
Item {
    id: body
    required property var root
    required property var controller
    width: parent ? parent.width : 0

    signal close()

    implicitHeight: col.implicitHeight + 8

    property int kbdIndex: 0
    readonly property int _kbdMax: 2

    function kbdHandle(event) {
        const k = event.key;
        if (k === Qt.Key_R) {
            if (body.controller) body.controller.refresh();
            return true;
        }
        if (k === Qt.Key_E) {
            if (body.controller) body.controller.editLocation();
            body.close();
            return true;
        }
        if (k === Qt.Key_Left || k === Qt.Key_Up) {
            body.kbdIndex = Math.max(0, body.kbdIndex - 1);
            return true;
        }
        if (k === Qt.Key_Right || k === Qt.Key_Down || k === Qt.Key_Tab) {
            body.kbdIndex = Math.min(body._kbdMax - 1, body.kbdIndex + 1);
            return true;
        }
        if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            if (body.kbdIndex === 0) { if (body.controller) body.controller.refresh(); return true; }
            if (body.kbdIndex === 1) { if (body.controller) body.controller.editLocation(); body.close(); return true; }
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

        Item {
            width: parent.width
            height: 22
            Text {
                id: placeLabel
                anchors.left: parent.left
                anchors.right: refreshBtn.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: {
                    if (!body.controller) return "";
                    const src = body.controller.location === "" ? "AUTO" : "MANUAL";
                    if (body.controller.unavailable) return src + "  ·  UNAVAILABLE";
                    if (!body.controller.loaded) return src + "  ·  FETCHING…";
                    return body.controller.place.toUpperCase() + "  ·  " + src + "  ·  " + body.controller.updatedAt;
                }
                color: placeMouse.containsMouse || body.kbdIndex === 1
                       ? body.root.seal : body.root.inkDeep
                font.family: body.root.mono
                font.pixelSize: 10
                font.letterSpacing: 2
                Behavior on color { ColorAnimation { duration: 140 } }
                MouseArea {
                    id: placeMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (body.controller) body.controller.editLocation();
                        body.close();
                    }
                }
            }
            CalendarChevron {
                id: refreshBtn
                root: body.root
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: body.root.icoRefresh
                restColor: body.kbdIndex === 0 ? body.root.seal : body.root.inkDeep
                font.pixelSize: 18
                onTriggered: if (body.controller) body.controller.refresh()
            }
        }

        Item {
            visible: body.controller && body.controller.loaded
            width: parent.width
            height: visible ? 80 : 0

            Text {
                id: heroGlyph
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: body.controller ? body.controller.icon : ""
                color: body.root.seal
                font.family: body.root.mono
                font.pixelSize: 52
            }
            Column {
                anchors.left: heroGlyph.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    text: body.controller ? body.controller.fmtTemp(body.controller.tempC) + "C" : ""
                    color: body.root.ink
                    font.family: body.root.mono
                    font.pixelSize: 34
                    font.weight: Font.Light
                    font.letterSpacing: 2
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    text: body.controller ? body.controller.desc.toUpperCase() : ""
                    color: body.root.inkDeep
                    font.family: body.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 3
                }
            }
        }

        Text {
            visible: body.controller && !body.controller.loaded
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: body.controller && body.controller.unavailable ? "WTTR.IN UNREACHABLE" : "FETCHING…"
            color: body.root.inkDeep
            font.family: body.root.mono
            font.pixelSize: 11
            font.letterSpacing: 3
            opacity: 0.6
        }

        Grid {
            visible: body.controller && body.controller.loaded
            width: parent.width
            columns: 4
            rowSpacing: 4
            columnSpacing: 8
            Repeater {
                model: body.controller && body.controller.loaded ? [
                    { label: "FEELS",    value: body.controller.fmtTemp(body.controller.feelsC) + "C" },
                    { label: "WIND",     value: body.controller.windKmh + " " + body.controller.windDir },
                    { label: "HUMIDITY", value: body.controller.humidity + "%" },
                    { label: "UV",       value: String(body.controller.uv) }
                ] : []
                delegate: Item {
                    required property var modelData
                    width: (parent.width - 24) / 4
                    height: 20
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: body.root.inkDeep
                        font.family: body.root.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1.5
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.value
                        color: body.root.ink
                        font.family: body.root.mono
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                }
            }
        }

        Rectangle {
            visible: body.controller && body.controller.loaded
            width: parent.width; height: 1; color: body.root.sep
        }

        Item {
            visible: body.controller && body.controller.loaded
            width: parent.width
            height: visible ? 28 : 0
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: body.controller
                      ? String.fromCodePoint(0xe34c) + " " + body.controller.sunrise
                        + "   " + String.fromCodePoint(0xe34d) + " " + body.controller.sunset
                      : ""
                color: body.root.inkDeep
                font.family: body.root.mono
                font.pixelSize: 10
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Text {
                    text: body.controller ? "↑ " + body.controller.fmtTemp(body.controller.highC) : ""
                    color: body.root.seal
                    font.family: body.root.mono
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
                Text {
                    text: body.controller ? "↓ " + body.controller.fmtTemp(body.controller.lowC) : ""
                    color: body.root.indigo
                    font.family: body.root.mono
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }
        }

        Repeater {
            model: body.controller ? body.controller.forecast : []
            delegate: Item {
                required property var modelData
                width: col.width
                height: 22

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.day
                    color: body.root.ink
                    font.family: body.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 3
                    font.weight: Font.Medium
                }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 56
                    anchors.verticalCenter: parent.verticalCenter
                    text: body.controller ? body.controller.weatherGlyph(modelData.code, false) : ""
                    color: body.root.inkDeep
                    font.family: body.root.mono
                    font.pixelSize: 16
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Text {
                        text: body.controller ? "↑ " + body.controller.fmtTemp(modelData.high) : ""
                        color: body.root.seal
                        font.family: body.root.mono
                        font.pixelSize: 11
                    }
                    Text {
                        text: body.controller ? "↓ " + body.controller.fmtTemp(modelData.low) : ""
                        color: body.root.indigo
                        font.family: body.root.mono
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
