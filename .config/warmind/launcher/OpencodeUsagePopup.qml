import QtQuick

CardWindow {
    id: usagePopup
    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 520
    layerNamespace: "warmind-opencode-usage"
    title: "OPENCODE USAGE"
    subtitle: controller.refreshing ? "REFRESHING"
        : !controller.hasLocalStats ? "NO DATA"
        : controller.formatTokenCount(controller.todayTotalTokens) + " TODAY"
    footer: "R REFRESH · ESC CLOSE"

    anchorEdge: usagePopup.root.barEdge
    anchorBarX: usagePopup.root.popupAnchorX > 0
        ? usagePopup.root.popupAnchorX : usagePopup.width / 2
    anchorBarY: usagePopup.root.popupAnchorY

    headerRight: CalendarChevron {
        root: usagePopup.root
        text: usagePopup.root.icoRefresh
        restColor: usagePopup.root.inkDeep
        font.pixelSize: 22
        onTriggered: usagePopup.controller.refresh()
    }

    onDismiss: usagePopup.controller.close()
    onKeyPressed: function(event) {
        if (event.key === Qt.Key_R) {
            usagePopup.controller.refresh();
            event.accepted = true;
        } else if (event.key === Qt.Key_Q) {
            usagePopup.controller.close();
            event.accepted = true;
        }
    }

    Flickable {
        id: contentScroller
        width: parent.width
        height: 470
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
            id: contentColumn
            width: contentScroller.width
            spacing: 14

            Text {
                visible: usagePopup.controller.lastError.length > 0
                width: parent.width
                text: usagePopup.controller.lastError
                color: usagePopup.root.warn
                font.family: usagePopup.root.mono
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            Text {
                visible: !usagePopup.controller.hasLocalStats && !usagePopup.controller.refreshing
                width: parent.width
                text: "NO USAGE DATA YET. START AN OPENCODE SESSION TO SEE STATS."
                color: usagePopup.root.inkDeep
                font.family: usagePopup.root.mono
                font.pixelSize: 12
                font.letterSpacing: 1
                wrapMode: Text.WordWrap
            }

            Rectangle {
                visible: usagePopup.controller.hasLocalStats
                width: parent.width
                height: visible ? todayCol.implicitHeight + 22 : 0
                radius: usagePopup.root.cornerRadius
                color: usagePopup.root.rowHi
                border.color: usagePopup.root.sep
                border.width: 1

                Column {
                    id: todayCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 11
                    spacing: 8

                    Text {
                        text: "TODAY"
                        color: usagePopup.root.ink
                        font.family: usagePopup.root.mono
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1
                    }

                    Row {
                        spacing: 24
                        Column {
                            spacing: 2
                            Text {
                                text: String(usagePopup.controller.todaySessions)
                                color: usagePopup.root.ink
                                font.family: usagePopup.root.mono
                                font.pixelSize: 20
                                font.bold: true
                            }
                            Text {
                                text: "SESSIONS"
                                color: usagePopup.root.inkDeep
                                font.family: usagePopup.root.mono
                                font.pixelSize: 10
                            }
                        }
                        Column {
                            spacing: 2
                            Text {
                                text: usagePopup.controller.formatTokenCount(usagePopup.controller.todayTotalTokens)
                                color: usagePopup.root.ink
                                font.family: usagePopup.root.mono
                                font.pixelSize: 20
                                font.bold: true
                            }
                            Text {
                                text: "TOKENS"
                                color: usagePopup.root.inkDeep
                                font.family: usagePopup.root.mono
                                font.pixelSize: 10
                            }
                        }
                    }

                    Repeater {
                        model: usagePopup.controller.modelEntries(usagePopup.controller.todayTokensByModel)
                        delegate: Row {
                            width: todayCol.width
                            spacing: 8
                            required property var modelData

                            Text {
                                width: parent.width - countLabel.width - 8
                                text: usagePopup.controller.friendlyModelName(modelData.modelId)
                                color: usagePopup.root.inkDeep
                                font.family: usagePopup.root.mono
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                            Text {
                                id: countLabel
                                text: usagePopup.controller.formatTokenCount(modelData.value)
                                color: usagePopup.root.ink
                                font.family: usagePopup.root.mono
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: usagePopup.controller.hasLocalStats && usagePopup.controller.recentDays.some(function(d) {
                    return Number(d.messageCount || 0) > 0;
                })
                width: parent.width
                height: visible ? weekCol.implicitHeight + 22 : 0
                radius: usagePopup.root.cornerRadius
                color: usagePopup.root.rowHi
                border.color: usagePopup.root.sep
                border.width: 1

                Column {
                    id: weekCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 11
                    spacing: 8

                    Text {
                        text: "LAST 7 DAYS"
                        color: usagePopup.root.ink
                        font.family: usagePopup.root.mono
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1
                    }

                    Repeater {
                        model: usagePopup.controller.recentDays
                        delegate: Row {
                            width: weekCol.width
                            spacing: 8
                            required property var modelData
                            readonly property real count: Number(modelData.messageCount || 0)
                            readonly property real maxCount: usagePopup.controller.weekMaxTokens()

                            Text {
                                width: 52
                                text: {
                                    const d = String(modelData.date || "");
                                    if (!d.length) return "";
                                    const dt = new Date(d + "T00:00:00");
                                    const names = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
                                    return names[dt.getDay()];
                                }
                                color: usagePopup.root.inkDeep
                                font.family: usagePopup.root.mono
                                font.pixelSize: 10
                            }

                            Rectangle {
                                width: parent.width - 52 - 56 - 16
                                height: 10
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 2
                                color: usagePopup.root.sep

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: parent.width * (count / maxCount)
                                    radius: 2
                                    color: usagePopup.root.accent
                                }
                            }

                            Text {
                                width: 56
                                horizontalAlignment: Text.AlignRight
                                text: usagePopup.controller.formatTokenCount(count)
                                color: usagePopup.root.ink
                                font.family: usagePopup.root.mono
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: usagePopup.controller.hasLocalStats
                    && Object.keys(usagePopup.controller.modelUsage || ({})).length > 0
                width: parent.width
                height: visible ? allTimeCol.implicitHeight + 22 : 0
                radius: usagePopup.root.cornerRadius
                color: usagePopup.root.rowHi
                border.color: usagePopup.root.sep
                border.width: 1

                Column {
                    id: allTimeCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 11
                    spacing: 10

                    Text {
                        text: "ALL-TIME"
                        color: usagePopup.root.ink
                        font.family: usagePopup.root.mono
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1
                    }

                    Text {
                        text: String(usagePopup.controller.totalSessions) + " SESSIONS"
                        color: usagePopup.root.inkDeep
                        font.family: usagePopup.root.mono
                        font.pixelSize: 11
                    }

                    Repeater {
                        model: usagePopup.controller.modelEntries(usagePopup.controller.modelUsage)
                        delegate: Column {
                            width: allTimeCol.width
                            spacing: 3
                            required property var modelData

                            Text {
                                width: parent.width
                                text: usagePopup.controller.friendlyModelName(modelData.modelId)
                                color: usagePopup.root.ink
                                font.family: usagePopup.root.mono
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: "IN  " + usagePopup.controller.formatTokenCount(modelData.value.inputTokens || 0)
                                    + "   OUT  " + usagePopup.controller.formatTokenCount(modelData.value.outputTokens || 0)
                                    + "   CACHE R  " + usagePopup.controller.formatTokenCount(modelData.value.cacheReadInputTokens || 0)
                                    + "   CACHE W  " + usagePopup.controller.formatTokenCount(modelData.value.cacheCreationInputTokens || 0)
                                color: usagePopup.root.inkDeep
                                font.family: usagePopup.root.mono
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }
}
