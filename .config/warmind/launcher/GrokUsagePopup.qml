import QtQuick

CardWindow {
    id: usagePopup
    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 420
    layerNamespace: "warmind-grok-usage"
    title: "GROK USAGE"
    readonly property bool authError: {
        const err = String(controller.lastError || "").toLowerCase();
        return err.indexOf("auth token") >= 0
            || err.indexOf("refresh auth") >= 0
            || err.indexOf("pull auth") >= 0;
    }
    subtitle: controller.refreshing ? "REFRESHING"
        : (!controller.ready && usagePopup.authError) ? "AUTH ERROR"
        : !controller.ready ? "NO DATA"
        : (controller.stale ? "~ " : "")
            + controller.formatPercent(controller.percent)
            + " · " + controller.periodLabel()
    footer: usagePopup.authError
        ? "RUN: grok login · R RETRY · ESC CLOSE"
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
        height: 360
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
                    : "SIGN IN WITH `grok login` THEN PRESS R."
                color: usagePopup.root.inkDeep
                font.family: usagePopup.root.mono
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            Text {
                visible: !usagePopup.controller.ready && !usagePopup.controller.refreshing
                    && usagePopup.controller.lastError.length === 0
                width: parent.width
                text: "NO BILLING DATA. RUN `grok login` THEN OPEN AGAIN."
                color: usagePopup.root.inkDeep
                font.family: usagePopup.root.mono
                font.pixelSize: 12
                font.letterSpacing: 1
                wrapMode: Text.WordWrap
            }

            // ── Credit bar ────────────────────────────────────────────
            Rectangle {
                visible: usagePopup.controller.ready
                width: parent.width
                height: visible ? creditCol.implicitHeight + 22 : 0
                radius: usagePopup.root.cornerRadius
                color: usagePopup.root.rowHi
                border.color: usagePopup.root.sep
                border.width: 1

                Column {
                    id: creditCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 11
                    spacing: 10

                    Row {
                        width: parent.width
                        Text {
                            width: parent.width - resetLabel.width
                            text: "ACCOUNT CREDITS"
                            color: usagePopup.root.ink
                            font.family: usagePopup.root.mono
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1
                        }
                        Text {
                            id: resetLabel
                            text: usagePopup.controller.resetsInLabel()
                            color: usagePopup.root.inkDeep
                            font.family: usagePopup.root.mono
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Text {
                        text: usagePopup.controller.formatPercent(usagePopup.controller.percent)
                        color: usagePopup.root.ink
                        font.family: usagePopup.root.mono
                        font.pixelSize: 32
                        font.bold: true
                    }

                    // Progress track
                    Rectangle {
                        width: parent.width
                        height: 12
                        radius: 3
                        color: usagePopup.root.sep

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.min(1, Math.max(0,
                                (Number(usagePopup.controller.percent) || 0) / 100))
                            radius: 3
                            color: {
                                const p = Number(usagePopup.controller.percent) || 0;
                                if (p >= 90)
                                    return usagePopup.root.warn;
                                if (p >= 70)
                                    return usagePopup.root.accent;
                                return usagePopup.root.accent;
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: "RESETS  " + usagePopup.controller.formatWhen(usagePopup.controller.periodEnd)
                        color: usagePopup.root.inkDeep
                        font.family: usagePopup.root.mono
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        visible: usagePopup.controller.fetchedAt.length > 0
                        width: parent.width
                        text: (usagePopup.controller.stale ? "CACHED  " : "FETCHED  ")
                            + usagePopup.controller.formatWhen(usagePopup.controller.fetchedAt)
                        color: usagePopup.root.inkDeep
                        font.family: usagePopup.root.mono
                        font.pixelSize: 10
                    }
                }
            }

            // ── Per-product split ─────────────────────────────────────
            Rectangle {
                visible: usagePopup.controller.ready
                    && usagePopup.controller.productRows().length > 0
                width: parent.width
                height: visible ? productCol.implicitHeight + 22 : 0
                radius: usagePopup.root.cornerRadius
                color: usagePopup.root.rowHi
                border.color: usagePopup.root.sep
                border.width: 1

                Column {
                    id: productCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 11
                    spacing: 10

                    Text {
                        text: "BY PRODUCT"
                        color: usagePopup.root.ink
                        font.family: usagePopup.root.mono
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1
                    }

                    Repeater {
                        model: usagePopup.controller.productRows()
                        delegate: Column {
                            width: productCol.width
                            spacing: 4
                            required property var modelData

                            Row {
                                width: parent.width
                                Text {
                                    width: parent.width - pctLabel.width
                                    text: String(modelData.product || "Unknown").toUpperCase()
                                    color: usagePopup.root.ink
                                    font.family: usagePopup.root.mono
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    id: pctLabel
                                    text: usagePopup.controller.formatPercent(modelData.usagePercent)
                                    color: usagePopup.root.ink
                                    font.family: usagePopup.root.mono
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 8
                                radius: 2
                                color: usagePopup.root.sep

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: parent.width * Math.min(1, Math.max(0,
                                        (Number(modelData.usagePercent) || 0) / 100))
                                    radius: 2
                                    color: usagePopup.root.accent
                                }
                            }
                        }
                    }
                }
            }

            // ── On-demand / prepaid (only when non-zero) ──────────────
            Rectangle {
                visible: usagePopup.controller.ready
                    && (usagePopup.controller.onDemandUsed > 0
                        || usagePopup.controller.prepaidBalance > 0
                        || usagePopup.controller.onDemandCap > 0)
                width: parent.width
                height: visible ? extraCol.implicitHeight + 22 : 0
                radius: usagePopup.root.cornerRadius
                color: usagePopup.root.rowHi
                border.color: usagePopup.root.sep
                border.width: 1

                Column {
                    id: extraCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 11
                    spacing: 6

                    Text {
                        text: "EXTRA"
                        color: usagePopup.root.ink
                        font.family: usagePopup.root.mono
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1
                    }

                    Text {
                        visible: usagePopup.controller.onDemandCap > 0
                            || usagePopup.controller.onDemandUsed > 0
                        width: parent.width
                        text: "ON-DEMAND  "
                            + usagePopup.controller.onDemandUsed
                            + " / " + usagePopup.controller.onDemandCap
                        color: usagePopup.root.inkDeep
                        font.family: usagePopup.root.mono
                        font.pixelSize: 11
                    }

                    Text {
                        visible: usagePopup.controller.prepaidBalance > 0
                        width: parent.width
                        text: "PREPAID  " + usagePopup.controller.prepaidBalance
                        color: usagePopup.root.inkDeep
                        font.family: usagePopup.root.mono
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
