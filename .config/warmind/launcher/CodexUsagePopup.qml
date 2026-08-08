import QtQuick

CardWindow {
    id: usagePopup
    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 440
    layerNamespace: "warmind-codex-usage"
    title: "CODEX USAGE"
    readonly property bool authError: {
        const err = String(controller.lastError || "").toLowerCase();
        return err.indexOf("auth token") >= 0
            || err.indexOf("stale auth") >= 0
            || err.indexOf("pull auth") >= 0
            || err.indexOf("codex unavailable") >= 0;
    }
    subtitle: controller.refreshing ? "REFRESHING"
        : (!controller.ready && usagePopup.authError) ? "AUTH ERROR"
        : !controller.ready ? "NO DATA"
        : (controller.stale ? "~ " : "")
            + controller.formatPercent(controller.headlinePercent())
            + " · " + controller.planLabel()
    footer: usagePopup.authError
        ? "RUN: codex login · R RETRY · ESC CLOSE"
        : "R REFRESH · ESC CLOSE"

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
        height: 420
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
                text: (usagePopup.controller.stale ? "STALE · " : "")
                    + usagePopup.controller.lastError.toUpperCase()
                color: usagePopup.root.warn
                font.family: usagePopup.root.mono
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            Text {
                visible: usagePopup.authError
                width: parent.width
                text: usagePopup.controller.stale
                    ? "SHOWING CACHED USAGE. RE-AUTH MAY BE REQUIRED."
                    : "SIGN IN WITH `codex login` THEN PRESS R."
                color: usagePopup.root.inkDeep
                font.family: usagePopup.root.mono
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            Text {
                visible: !usagePopup.controller.ready && !usagePopup.controller.refreshing
                    && usagePopup.controller.lastError.length === 0
                width: parent.width
                text: "NO CODEX USAGE DATA. RUN `codex login` THEN OPEN AGAIN."
                color: usagePopup.root.inkDeep
                font.family: usagePopup.root.mono
                font.pixelSize: 12
                font.letterSpacing: 1
                wrapMode: Text.WordWrap
            }

            Rectangle {
                visible: usagePopup.controller.ready
                width: parent.width
                height: visible ? accountCol.implicitHeight + 22 : 0
                radius: usagePopup.root.cornerRadius
                color: usagePopup.root.rowHi
                border.color: usagePopup.root.sep
                border.width: 1

                Column {
                    id: accountCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 11
                    spacing: 6

                    Text {
                        text: "ACCOUNT"
                        color: usagePopup.root.ink
                        font.family: usagePopup.root.mono
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1
                    }
                    Text {
                        width: parent.width
                        text: usagePopup.controller.planLabel()
                            + (usagePopup.controller.email.length
                                ? "  ·  " + usagePopup.controller.email : "")
                        color: usagePopup.root.inkDeep
                        font.family: usagePopup.root.mono
                        font.pixelSize: 11
                        elide: Text.ElideMiddle
                    }
                    Text {
                        visible: usagePopup.controller.hasCredits || usagePopup.controller.creditsUnlimited
                        text: usagePopup.controller.creditsUnlimited
                            ? "CREDITS  UNLIMITED"
                            : "CREDITS  " + usagePopup.controller.creditsBalance
                        color: usagePopup.root.inkDeep
                        font.family: usagePopup.root.mono
                        font.pixelSize: 11
                    }
                    Text {
                        text: (usagePopup.controller.stale ? "CACHED  " : "FETCHED  ")
                            + usagePopup.controller.formatWhen(usagePopup.controller.fetchedAt)
                        color: usagePopup.root.inkDeep
                        font.family: usagePopup.root.mono
                        font.pixelSize: 10
                    }
                }
            }

            Rectangle {
                visible: usagePopup.controller.ready
                    && !isNaN(usagePopup.controller.primaryPercent)
                width: parent.width
                height: visible ? primaryCol.implicitHeight + 22 : 0
                radius: usagePopup.root.cornerRadius
                color: usagePopup.root.rowHi
                border.color: usagePopup.root.sep
                border.width: 1

                Column {
                    id: primaryCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 11
                    spacing: 8

                    Row {
                        width: parent.width
                        Text {
                            width: parent.width - pctLabel.width
                            text: (usagePopup.controller.primaryLabel || "PRIMARY").toUpperCase()
                            color: usagePopup.root.ink
                            font.family: usagePopup.root.mono
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1
                        }
                        Text {
                            id: pctLabel
                            text: usagePopup.controller.formatPercent(usagePopup.controller.primaryPercent)
                            color: usagePopup.root.ink
                            font.family: usagePopup.root.mono
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 10
                        radius: 2
                        color: usagePopup.root.sep
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.max(0, Math.min(1, (usagePopup.controller.primaryPercent || 0) / 100))
                            radius: 2
                            color: usagePopup.root.accent
                        }
                    }

                    Text {
                        visible: usagePopup.controller.primaryResetsAt.length > 0
                        text: "RESETS  " + usagePopup.controller.formatWhen(usagePopup.controller.primaryResetsAt)
                            + "  ·  " + usagePopup.controller.resetsInLabel(usagePopup.controller.primaryResetsAt)
                        color: usagePopup.root.inkDeep
                        font.family: usagePopup.root.mono
                        font.pixelSize: 10
                    }
                }
            }

            Rectangle {
                visible: usagePopup.controller.ready && usagePopup.controller.hasSecondary
                width: parent.width
                height: visible ? secondaryCol.implicitHeight + 22 : 0
                radius: usagePopup.root.cornerRadius
                color: usagePopup.root.rowHi
                border.color: usagePopup.root.sep
                border.width: 1

                Column {
                    id: secondaryCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 11
                    spacing: 8

                    Row {
                        width: parent.width
                        Text {
                            width: parent.width - pctLabel2.width
                            text: (usagePopup.controller.secondaryLabel || "SECONDARY").toUpperCase()
                            color: usagePopup.root.ink
                            font.family: usagePopup.root.mono
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1
                        }
                        Text {
                            id: pctLabel2
                            text: usagePopup.controller.formatPercent(usagePopup.controller.secondaryPercent)
                            color: usagePopup.root.ink
                            font.family: usagePopup.root.mono
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 10
                        radius: 2
                        color: usagePopup.root.sep
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.max(0, Math.min(1, (usagePopup.controller.secondaryPercent || 0) / 100))
                            radius: 2
                            color: usagePopup.root.accent
                        }
                    }

                    Text {
                        visible: usagePopup.controller.secondaryResetsAt.length > 0
                        text: "RESETS  " + usagePopup.controller.formatWhen(usagePopup.controller.secondaryResetsAt)
                            + "  ·  " + usagePopup.controller.resetsInLabel(usagePopup.controller.secondaryResetsAt)
                        color: usagePopup.root.inkDeep
                        font.family: usagePopup.root.mono
                        font.pixelSize: 10
                    }
                }
            }

            Rectangle {
                visible: usagePopup.controller.ready
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

                    Text {
                        text: "TODAY  " + usagePopup.controller.formatTokenCount(usagePopup.controller.todayTokens)
                        color: usagePopup.root.inkDeep
                        font.family: usagePopup.root.mono
                        font.pixelSize: 11
                    }

                    Repeater {
                        model: usagePopup.controller.recentDays
                        delegate: Row {
                            width: weekCol.width
                            spacing: 8
                            required property var modelData
                            readonly property real count: Number(modelData.tokens || 0)
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
                visible: usagePopup.controller.ready
                width: parent.width
                height: visible ? lifeCol.implicitHeight + 22 : 0
                radius: usagePopup.root.cornerRadius
                color: usagePopup.root.rowHi
                border.color: usagePopup.root.sep
                border.width: 1

                Column {
                    id: lifeCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 11
                    spacing: 6

                    Text {
                        text: "LIFETIME"
                        color: usagePopup.root.ink
                        font.family: usagePopup.root.mono
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1
                    }
                    Text {
                        text: "TOKENS  " + usagePopup.controller.formatTokenCount(usagePopup.controller.lifetimeTokens)
                        color: usagePopup.root.inkDeep
                        font.family: usagePopup.root.mono
                        font.pixelSize: 11
                    }
                    Text {
                        text: "PEAK DAY  " + usagePopup.controller.formatTokenCount(usagePopup.controller.peakDailyTokens)
                        color: usagePopup.root.inkDeep
                        font.family: usagePopup.root.mono
                        font.pixelSize: 11
                    }
                    Text {
                        text: "STREAK  " + usagePopup.controller.currentStreakDays
                            + "D  ·  BEST  " + usagePopup.controller.longestStreakDays + "D"
                        color: usagePopup.root.inkDeep
                        font.family: usagePopup.root.mono
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
