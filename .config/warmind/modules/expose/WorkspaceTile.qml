import QtQuick

// One workspace tile, Kanagawa Dragon vocabulary:
//   - sharp ink-card with a single hairline border
//   - vertical accent stripe on the left edge (sumi -> indigo -> seal as
//     the workspace becomes current -> selected)
//   - top calligraphy strip with the workspace kanji + id, hairline rule
//     beneath
//   - hanko seal stamp (slightly rotated red circle with 現 kanji) sits in
//     the bottom-right corner when this workspace is currently active on
//     its monitor
//   - body shows the cached `grim` screenshot if one exists, otherwise a
//     schematic class-name view; an accent ring is overlaid on the
//     most-recently-focused window in both modes
Item {
    id: tile

    // ---- inputs ----
    required property var shell           // ShellRoot
    required property var ws              // workspace object from hyprctl
    required property var mon             // monitor object the workspace lives on
    required property var wsClients       // hyprctl clients on this workspace
    required property string activeAddr   // most-recently-focused client address
    required property bool focused        // keyboard-selected tile
    required property bool current        // currently active on its monitor
    required property string thumbPath    // file path to the cached PNG
    required property int   thumbTick     // bump to force Image reload
    required property bool  thumbExists   // whether the PNG actually exists on disk

    signal jump(int wsId)
    signal focusWindow(string address)
    signal hovered(int wsIndex)
    property int wsIndex: 0

    // ---- derived ----
    readonly property real monW: mon && mon.width  ? mon.width  : 1920
    readonly property real monH: mon && mon.height ? mon.height : 1080
    readonly property color stripeColor: focused
        ? tile.shell.seal
        : (current ? tile.shell.indigo : Qt.rgba(tile.shell.sumi.r, tile.shell.sumi.g, tile.shell.sumi.b, 0.45))
    readonly property bool schematicMode: thumb.status !== Image.Ready

    // ---- outer halo: subtle hairline ring when keyboard-selected ----
    // Two stacked offset rects read as a softer glow than a single border.
    Rectangle {
        anchors.centerIn: card
        width: card.width + 18; height: card.height + 18
        radius: card.radius + 6
        color: "transparent"
        border.color: Qt.rgba(tile.shell.seal.r, tile.shell.seal.g, tile.shell.seal.b, 0.18)
        border.width: 1
        opacity: tile.focused ? 1 : 0
        z: -2
        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    }
    Rectangle {
        anchors.centerIn: card
        width: card.width + 10; height: card.height + 10
        radius: card.radius + 3
        color: "transparent"
        border.color: Qt.rgba(tile.shell.seal.r, tile.shell.seal.g, tile.shell.seal.b, 0.35)
        border.width: 1
        opacity: tile.focused ? 1 : 0
        z: -1
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    // ---- card ----
    Rectangle {
        id: card
        anchors.fill: parent
        color: Qt.rgba(tile.shell.paper.r, tile.shell.paper.g, tile.shell.paper.b, 0.62)
        radius: 4
        border.color: tile.focused
            ? Qt.rgba(tile.shell.seal.r, tile.shell.seal.g, tile.shell.seal.b, 0.92)
            : (tile.current
                ? Qt.rgba(tile.shell.indigo.r, tile.shell.indigo.g, tile.shell.indigo.b, 0.55)
                : Qt.rgba(tile.shell.sumi.r, tile.shell.sumi.g, tile.shell.sumi.b, 0.32))
        border.width: tile.focused ? 2 : 1
        antialiasing: true
        clip: true
        Behavior on border.color { ColorAnimation { duration: 200 } }

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: head.height
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.bottomMargin: 4
            color: Qt.rgba(tile.shell.wash.r, tile.shell.wash.g, tile.shell.wash.b, 0.18)
            border.color: Qt.rgba(tile.shell.sumi.r, tile.shell.sumi.g, tile.shell.sumi.b, 0.16)
            border.width: 1
        }

        // ---- thumbnail ----
        Image {
            id: thumb
            anchors.fill: parent
            anchors.topMargin: head.height
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.bottomMargin: 4
            source: tile.thumbExists && tile.thumbPath
                ? ("file://" + tile.thumbPath + "?v=" + tile.thumbTick)
                : ""
            fillMode: Image.PreserveAspectFit
            cache: false
            asynchronous: true
            smooth: true
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 260 } }
            visible: status === Image.Ready
        }

        // ---- projected stage (matches thumb's PreserveAspectFit) ----
        Item {
            id: stage
            readonly property real availW: parent.width  - 8
            readonly property real availH: parent.height - head.height - 8
            readonly property real s: Math.min(availW / tile.monW, availH / tile.monH)
            width:  tile.monW * s
            height: tile.monH * s
            x: (parent.width - width) / 2
            y: head.height + (parent.height - head.height - height) / 2
            clip: true

            // Schematic fallback rectangles — only when no thumbnail.
            Repeater {
                model: tile.wsClients
                delegate: Rectangle {
                    required property var modelData
                    visible: tile.schematicMode
                    readonly property bool isActive: modelData.address === tile.activeAddr
                    readonly property real lx: (modelData.at  && modelData.at.length  >= 2) ? (modelData.at[0]  - (tile.mon ? tile.mon.x : 0)) : 0
                    readonly property real ly: (modelData.at  && modelData.at.length  >= 2) ? (modelData.at[1]  - (tile.mon ? tile.mon.y : 0)) : 0
                    readonly property real lw: (modelData.size && modelData.size.length >= 2) ? modelData.size[0] : 0
                    readonly property real lh: (modelData.size && modelData.size.length >= 2) ? modelData.size[1] : 0
                    x: lx * stage.s
                    y: ly * stage.s
                    width:  Math.max(8, lw * stage.s)
                    height: Math.max(8, lh * stage.s)
                    radius: 2
                    color: isActive
                        ? Qt.rgba(tile.shell.seal.r, tile.shell.seal.g, tile.shell.seal.b, 0.22)
                        : Qt.rgba(tile.shell.ink.r,  tile.shell.ink.g,  tile.shell.ink.b,  0.08)
                    border.color: isActive
                        ? tile.shell.seal
                        : Qt.rgba(tile.shell.indigo.r, tile.shell.indigo.g, tile.shell.indigo.b, 0.45)
                    border.width: isActive ? 2 : 1

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        text: (modelData["class"] || "").toLowerCase()
                        color: isActive ? tile.shell.ink : tile.shell.inkDeep
                        opacity: isActive ? 0.95 : 0.65
                        font.family: tile.shell.mono
                        font.pixelSize: Math.max(7, Math.min(13, parent.height * 0.18))
                        font.italic: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Active-window accent ring over the screenshot.
            Repeater {
                model: tile.wsClients
                delegate: Rectangle {
                    required property var modelData
                    visible: !tile.schematicMode && modelData.address === tile.activeAddr
                    readonly property real lx: (modelData.at  && modelData.at.length  >= 2) ? (modelData.at[0]  - (tile.mon ? tile.mon.x : 0)) : 0
                    readonly property real ly: (modelData.at  && modelData.at.length  >= 2) ? (modelData.at[1]  - (tile.mon ? tile.mon.y : 0)) : 0
                    readonly property real lw: (modelData.size && modelData.size.length >= 2) ? modelData.size[0] : 0
                    readonly property real lh: (modelData.size && modelData.size.length >= 2) ? modelData.size[1] : 0
                    x: lx * stage.s
                    y: ly * stage.s
                    width:  Math.max(8, lw * stage.s)
                    height: Math.max(8, lh * stage.s)
                    color: "transparent"
                    border.color: tile.shell.seal
                    border.width: 3
                    radius: 3
                }
            }

            // Per-window hit areas.
            Repeater {
                model: tile.wsClients
                delegate: MouseArea {
                    required property var modelData
                    readonly property real lx: (modelData.at  && modelData.at.length  >= 2) ? (modelData.at[0]  - (tile.mon ? tile.mon.x : 0)) : 0
                    readonly property real ly: (modelData.at  && modelData.at.length  >= 2) ? (modelData.at[1]  - (tile.mon ? tile.mon.y : 0)) : 0
                    readonly property real lw: (modelData.size && modelData.size.length >= 2) ? modelData.size[0] : 0
                    readonly property real lh: (modelData.size && modelData.size.length >= 2) ? modelData.size[1] : 0
                    x: lx * stage.s
                    y: ly * stage.s
                    width:  Math.max(8, lw * stage.s)
                    height: Math.max(8, lh * stage.s)
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: tile.hovered(tile.wsIndex)
                    onClicked: tile.focusWindow(modelData.address)
                }
            }
        }

        // ---- empty workspace ----
        // 空 (kuu) — "empty" — at low opacity, when the workspace has no
        // windows. Sits centered in the body region (below the head).
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: head.height / 2
            visible: tile.wsClients.length === 0
            text: "空"
            color: tile.shell.sumi
            opacity: 0.22
            font.family: tile.shell.serif
            font.pixelSize: 56
            font.weight: Font.Light
        }

        // ---- calligraphy strip ----
        Item {
            id: head
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 36

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(tile.shell.paper.r, tile.shell.paper.g, tile.shell.paper.b, 0.78)
            }

            Text {
                id: kanjiMark
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: tile.shell.kanji(tile.ws.id)
                color: tile.current ? tile.shell.indigo
                    : (tile.focused ? tile.shell.seal : tile.shell.inkDeep)
                opacity: tile.focused || tile.current ? 1.0 : 0.78
                font.family: tile.shell.serif
                font.pixelSize: 19
                font.weight: Font.Light
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Text {
                id: idLabel
                anchors.left: kanjiMark.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                text: String(tile.ws.id).padStart(2, "0")
                color: tile.shell.sumi
                opacity: 0.6
                font.family: tile.shell.mono
                font.pixelSize: 10
                font.letterSpacing: 2.5
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                spacing: 8

                Text {
                    visible: tile.mon && Object.keys(tile.shell.monitorsByName).length > 1
                    text: tile.mon ? tile.mon.name : ""
                    color: tile.shell.sumi
                    opacity: 0.48
                    font.family: tile.shell.mono
                    font.pixelSize: 9
                    font.italic: true
                    font.letterSpacing: 1.2
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    visible: tile.mon && Object.keys(tile.shell.monitorsByName).length > 1
                    width: 1; height: 9
                    color: tile.shell.sumi
                    opacity: 0.28
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: tile.wsClients.length === 0 ? "empty"
                        : (tile.wsClients.length + (tile.wsClients.length === 1 ? " win" : " wins"))
                    color: tile.shell.sumi
                    opacity: 0.58
                    font.family: tile.shell.mono
                    font.pixelSize: 9
                    font.italic: true
                    font.letterSpacing: 1.2
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Hairline rule under the strip
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: tile.shell.sumi
                opacity: 0.18
            }
        }

        // ---- left accent stripe ----
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            color: tile.stripeColor
            opacity: tile.focused || tile.current ? 0.95 : 0.55
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        // ---- hanko stamp (only when this is the currently-active workspace) ----
        // Slightly rotated red circle with 現 ("now") in paper color — like a
        // Japanese signature seal. Sits in the bottom-right corner of the card.
        Item {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 10
            anchors.bottomMargin: 10
            width: 22; height: 22
            visible: tile.current
            opacity: tile.current ? 0.95 : 0
            rotation: -7
            Behavior on opacity { NumberAnimation { duration: 240 } }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: tile.shell.seal
                border.color: Qt.darker(tile.shell.seal, 1.4)
                border.width: 1
            }
            Text {
                anchors.centerIn: parent
                text: "現"
                color: tile.shell.paper
                font.family: tile.shell.serif
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }

        // ---- tile-level hit ----
        MouseArea {
            anchors.fill: parent
            z: -1
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: tile.hovered(tile.wsIndex)
            onClicked: tile.jump(tile.ws.id)
        }
    }
}
