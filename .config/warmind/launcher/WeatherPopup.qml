import QtQuick

CardWindow {
    id: weatherPopup
    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 360
    layerNamespace: "omarchy-weather"
    footer: "CLICK PLACE TO EDIT · R REFRESH · ESC"

    anchorEdge: weatherPopup.root.barEdge
    // Weather should open top-center of the invoking monitor/bar instance,
    // not at the trigger icon. Using the fullscreen popup window's own
    // width keeps the horizontal center stable even when the controller
    // opens the popup without a live icon-derived anchor.
    anchorBarX: weatherPopup.width / 2
    anchorBarY: weatherPopup.controller.anchorY

    onDismiss: weatherPopup.controller.close()
    onKeyPressed: function(event) {
        if (event.key === Qt.Key_Q) {
            weatherPopup.controller.close();
            event.accepted = true;
        } else if (event.key === Qt.Key_R) {
            weatherPopup.controller.refresh();
            event.accepted = true;
        }
    }

    Column {
        width: parent.width
        spacing: 12

        Item {
            width: parent.width
            height: 43

            Column {
                anchors.left: parent.left
                anchors.right: weatherRefresh.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: "WEATHER"
                    color: weatherPopup.root.ink
                    font.family: weatherPopup.root.mono
                    font.pixelSize: 19
                    font.letterSpacing: 4
                    font.weight: Font.Medium
                }
                Text {
                    id: weatherSubtitle
                    width: parent.width
                    elide: Text.ElideRight
                    text: {
                        const c = weatherPopup.controller;
                        const src = c.location === "" ? "AUTO" : "MANUAL";
                        if (c.unavailable) return src + "  ·  UNAVAILABLE";
                        if (!c.loaded) return src + "  ·  FETCHING…";
                        return c.place.toUpperCase() + "  ·  " + src + "  ·  " + c.updatedAt;
                    }
                    color: subMouse.containsMouse ? weatherPopup.root.seal : weatherPopup.root.inkDeep
                    font.family: weatherPopup.root.mono
                    font.pixelSize: 11
                    font.letterSpacing: 2
                    Behavior on color { ColorAnimation { duration: 140 } }

                    MouseArea {
                        id: subMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: weatherPopup.controller.editLocation()
                    }
                }
            }

            CalendarChevron {
                id: weatherRefresh
                root: weatherPopup.root
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: weatherPopup.root.icoRefresh
                restColor: weatherPopup.root.inkDeep
                font.pixelSize: 22
                onTriggered: weatherPopup.controller.refresh()
            }
        }

        Rectangle { width: parent.width; height: 1; color: weatherPopup.root.sep }

        Item {
            width: parent.width
            height: 86
            visible: weatherPopup.controller.loaded

            Text {
                id: heroGlyph
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: weatherPopup.controller.icon
                color: weatherPopup.root.seal
                font.family: weatherPopup.root.mono
                font.pixelSize: 56
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
                    elide: Text.ElideRight
                    text: weatherPopup.controller.fmtTemp(weatherPopup.controller.tempC) + "C"
                    color: weatherPopup.root.ink
                    font.family: weatherPopup.root.mono
                    font.pixelSize: 38
                    font.weight: Font.Light
                    font.letterSpacing: 2
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    text: weatherPopup.controller.desc.toUpperCase()
                    color: weatherPopup.root.inkDeep
                    font.family: weatherPopup.root.mono
                    font.pixelSize: 11
                    font.letterSpacing: 3
                }
            }
        }

        Text {
            width: parent.width
            height: 86
            visible: !weatherPopup.controller.loaded
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: weatherPopup.controller.unavailable ? "WTTR.IN UNREACHABLE" : "FETCHING…"
            color: weatherPopup.root.inkDeep
            font.family: weatherPopup.root.mono
            font.pixelSize: 11
            font.letterSpacing: 3
            opacity: 0.6
        }

        Grid {
            width: parent.width
            columns: 2
            rowSpacing: 4
            columnSpacing: 0
            visible: weatherPopup.controller.loaded

            Repeater {
                model: [
                    { label: "FEELS",    value: weatherPopup.controller.fmtTemp(weatherPopup.controller.feelsC) + "C" },
                    { label: "WIND",     value: weatherPopup.controller.windKmh + " KM/H " + weatherPopup.controller.windDir },
                    { label: "HUMIDITY", value: weatherPopup.controller.humidity + "%" },
                    { label: "UV INDEX", value: String(weatherPopup.controller.uv) }
                ]
                delegate: Item {
                    required property var modelData
                    width: parent.width / 2
                    height: 20
                    Text {
                        id: metricLabel
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: weatherPopup.root.inkDeep
                        font.family: weatherPopup.root.mono
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                    Text {
                        anchors.left: metricLabel.right
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                        text: modelData.value
                        color: weatherPopup.root.ink
                        font.family: weatherPopup.root.mono
                        font.pixelSize: 11
                        font.letterSpacing: 1
                        font.weight: Font.Medium
                    }
                }
            }
        }

        Rectangle {
            width: parent.width; height: 1; color: weatherPopup.root.sep
            visible: weatherPopup.controller.loaded
        }

        Item {
            width: parent.width
            height: 36
            visible: weatherPopup.controller.loaded

            Column {
                anchors.left: parent.left
                anchors.right: todayHiLo.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text {
                    text: "TODAY"
                    color: weatherPopup.root.inkDeep
                    font.family: weatherPopup.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: String.fromCodePoint(0xe34c) + " " + weatherPopup.controller.sunrise
                          + "   " + String.fromCodePoint(0xe34d) + " " + weatherPopup.controller.sunset
                    color: weatherPopup.root.inkDeep
                    font.family: weatherPopup.root.mono
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }
            }

            Row {
                id: todayHiLo
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Text {
                    text: "↑ " + weatherPopup.controller.fmtTemp(weatherPopup.controller.highC)
                    color: weatherPopup.root.seal
                    font.family: weatherPopup.root.mono
                    font.pixelSize: 13
                    font.letterSpacing: 1
                    font.weight: Font.Medium
                }
                Text {
                    text: "↓ " + weatherPopup.controller.fmtTemp(weatherPopup.controller.lowC)
                    color: weatherPopup.root.indigo
                    font.family: weatherPopup.root.mono
                    font.pixelSize: 13
                    font.letterSpacing: 1
                    font.weight: Font.Medium
                }
            }
        }

        Rectangle {
            width: parent.width; height: 1; color: weatherPopup.root.sep
            visible: weatherPopup.controller.loaded && weatherPopup.controller.forecast.length > 0
        }

        Text {
            visible: weatherPopup.controller.loaded && weatherPopup.controller.forecast.length > 0
            text: "FORECAST"
            color: weatherPopup.root.inkDeep
            font.family: weatherPopup.root.mono
            font.pixelSize: 10
            font.letterSpacing: 2
        }

        Repeater {
            model: weatherPopup.controller.forecast
            delegate: Item {
                required property var modelData
                width: parent.width
                height: 26

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.day
                    color: weatherPopup.root.ink
                    font.family: weatherPopup.root.mono
                    font.pixelSize: 11
                    font.letterSpacing: 3
                    font.weight: Font.Medium
                }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 60
                    anchors.verticalCenter: parent.verticalCenter
                    text: weatherPopup.controller.weatherGlyph(modelData.code, false)
                    color: weatherPopup.root.inkDeep
                    font.family: weatherPopup.root.mono
                    font.pixelSize: 18
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Text {
                        text: "↑ " + weatherPopup.controller.fmtTemp(modelData.high)
                        color: weatherPopup.root.seal
                        font.family: weatherPopup.root.mono
                        font.pixelSize: 12
                        font.letterSpacing: 1
                    }
                    Text {
                        text: "↓ " + weatherPopup.controller.fmtTemp(modelData.low)
                        color: weatherPopup.root.indigo
                        font.family: weatherPopup.root.mono
                        font.pixelSize: 12
                        font.letterSpacing: 1
                    }
                }
            }
        }
    }
}
