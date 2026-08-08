import QtQuick
import QtQuick.Layouts

Item {
    id: pane

    required property var root
    required property var controller
    property bool compact: false

    width: parent ? parent.width : 0
    implicitHeight: mainRow.implicitHeight

    function eventTimeText(event) {
        if (!event) return "";
        let t = event.start_time || "";
        if (event.end_time && event.end_time !== "") t += " – " + event.end_time;
        return t;
    }

    RowLayout {
        id: mainRow
        width: parent.width
        spacing: pane.compact ? 16 : 20

        ColumnLayout {
            Layout.preferredWidth: pane.compact ? 360 : 410
            Layout.minimumWidth: pane.compact ? 360 : 410
            Layout.maximumWidth: pane.compact ? 360 : 410
            Layout.fillWidth: !pane.compact
            Layout.fillHeight: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 16
                spacing: 0

                Text {
                    text: pane.controller.monthLabel || "CALENDAR"
                    color: pane.root.ink
                    font.family: pane.root.mono
                    font.pixelSize: pane.compact ? 16 : 19
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    implicitWidth: 68
                    implicitHeight: 26
                    radius: 20
                    color: todayBtnHover.containsMouse ? Qt.rgba(pane.root.ink.r, pane.root.ink.g, pane.root.ink.b, 0.08) : Qt.rgba(pane.root.ink.r, pane.root.ink.g, pane.root.ink.b, 0.03)
                    border.color: pane.root.sep
                    border.width: 1
                    Layout.rightMargin: 8

                    Text {
                        anchors.centerIn: parent
                        text: "Today"
                        color: pane.root.inkDeep
                        font.family: pane.root.mono
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: todayBtnHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pane.controller.goToday()
                    }
                }

                CalendarChevron {
                    root: pane.root
                    text: "‹"
                    onTriggered: pane.controller.prevMonth()
                }
                CalendarChevron {
                    root: pane.root
                    text: "›"
                    onTriggered: pane.controller.nextMonth()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 6
                spacing: 2

                Repeater {
                    model: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: pane.compact ? 20 : 22
                        radius: pane.root.cornerRadius > 0 ? Math.max(6, pane.root.cornerRadius - 4) : 0
                        color: Qt.rgba(pane.root.ink.r, pane.root.ink.g, pane.root.ink.b, 0.035)

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: index >= 5 ? pane.root.seal : pane.root.inkDeep
                            opacity: index >= 5 ? 0.85 : 0.7
                            font.family: pane.root.mono
                            font.pixelSize: pane.compact ? 10 : 11
                            font.letterSpacing: 1.2
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Repeater {
                    model: pane.controller.weeks || []
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2

                        Repeater {
                            model: modelData
                            delegate: Item {
                                required property var modelData
                                property var day: modelData
                                readonly property bool isSelected: day.date === pane.controller.selectedDay
                                readonly property bool isToday: !!day.is_today
                                readonly property bool inMonth: !!day.in_month

                                Layout.fillWidth: true
                                implicitHeight: pane.compact ? 56 : 64

                                Rectangle {
                                    anchors.fill: parent
                                    radius: pane.root.cornerRadius > 0 ? Math.max(8, pane.root.cornerRadius - 2) : 0
                                    color: {
                                        if (isToday) return pane.root.seal;
                                        if (isSelected) return Qt.rgba(pane.root.ink.r, pane.root.ink.g, pane.root.ink.b, 0.10);
                                        if (cellHover.containsMouse) return Qt.rgba(pane.root.ink.r, pane.root.ink.g, pane.root.ink.b, 0.06);
                                        if (!inMonth) return "transparent";
                                        return Qt.rgba(pane.root.ink.r, pane.root.ink.g, pane.root.ink.b, 0.03);
                                    }
                                    border.color: isSelected ? pane.root.seal : "transparent"
                                    border.width: isSelected ? 1 : 0

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.topMargin: pane.compact ? 6 : 7
                                        anchors.leftMargin: 6
                                        anchors.rightMargin: 6
                                        anchors.bottomMargin: 5
                                        spacing: 4

                                        Text {
                                            text: day.date_num
                                            color: {
                                                if (isToday) return pane.root.paper;
                                                if (!inMonth) return pane.root.inkDeep;
                                                return pane.root.ink;
                                            }
                                            opacity: inMonth ? 1.0 : 0.35
                                            font.family: pane.root.mono
                                            font.pixelSize: pane.compact ? 11 : 12
                                            font.weight: isToday ? Font.Medium : Font.Normal
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Repeater {
                                                model: day.icons || []
                                                delegate: Text {
                                                    required property var modelData
                                                    text: modelData.icon
                                                    color: modelData.color
                                                    opacity: isToday ? 0.85 : (inMonth ? 1.0 : 0.4)
                                                    font.family: pane.root.mono
                                                    font.pixelSize: pane.compact ? 12 : 14
                                                }
                                            }

                                            Text {
                                                visible: (day.overflow || 0) > 0
                                                text: "+" + day.overflow
                                                color: isToday ? pane.root.paper : pane.root.inkDeep
                                                opacity: 0.8
                                                font.family: pane.root.mono
                                                font.pixelSize: 9
                                                Layout.leftMargin: 2
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: cellHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: inMonth
                                        cursorShape: inMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: pane.controller.selectDay(day.date)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            width: 1
            color: pane.root.sep
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            spacing: 0

            Text {
                text: pane.controller.selectedDayLabel || "SELECT A DAY"
                color: pane.root.ink
                font.family: pane.root.mono
                font.pixelSize: pane.compact ? 14 : 16
                font.weight: Font.Medium
                Layout.fillWidth: true
                Layout.bottomMargin: 10
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: pane.root.sep
                Layout.bottomMargin: 14
            }

            Text {
                visible: !!pane.controller.error
                text: pane.controller.error === "auth_required"
                      ? "GOOGLE CALENDAR AUTH REQUIRED"
                      : "CALENDAR BACKEND UNAVAILABLE"
                color: pane.root.seal
                font.family: pane.root.mono
                font.pixelSize: 11
                font.letterSpacing: 1.2
                Layout.bottomMargin: 10
            }

            Text {
                visible: !pane.controller.error && !pane.controller.calState.loading && (!pane.controller.selectedEvents || pane.controller.selectedEvents.length === 0)
                text: "No events"
                color: pane.root.inkDeep
                font.family: pane.root.mono
                font.pixelSize: 12
                font.italic: true
            }

            Text {
                visible: pane.controller.calState.loading
                text: "Loading…"
                color: pane.root.inkDeep
                font.family: pane.root.mono
                font.pixelSize: 12
                font.italic: true
            }

            ColumnLayout {
                visible: !pane.controller.calState.loading && pane.controller.selectedEvents && pane.controller.selectedEvents.length > 0
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: pane.controller.selectedEvents || []
                    delegate: RowLayout {
                        required property var modelData
                        property var event: modelData
                        Layout.fillWidth: true
                        Layout.bottomMargin: 16
                        spacing: 0

                        Text {
                            text: event.icon || "󰃭"
                            color: event.color || pane.root.seal
                            font.family: pane.root.mono
                            font.pixelSize: pane.compact ? 15 : 18
                            Layout.rightMargin: 12
                            Layout.preferredWidth: 22
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 3

                            Text {
                                text: event.title || "(No title)"
                                color: pane.root.ink
                                font.family: pane.root.mono
                                font.pixelSize: pane.compact ? 12 : 13
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                text: pane.eventTimeText(event)
                                color: pane.root.inkDeep
                                font.family: pane.root.mono
                                font.pixelSize: pane.compact ? 11 : 12
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
