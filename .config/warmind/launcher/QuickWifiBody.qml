import QtQuick

Item {
    id: body
    required property var root
    required property var nav
    required property var controller
    width: parent ? parent.width : 0

    signal close()

    property int kbdIndex: 0
    property string passwordSsid: ""
    property string passwordText: ""
    readonly property bool hasWifi: controller && controller.wifiSupported
    readonly property bool hasActiveIface: !!(controller && controller.info && controller.info.iface)
    readonly property var knownNetworks: controller ? controller.networks.filter(n => n.inUse || n.known) : []
    readonly property var otherNetworks: controller ? controller.networks.filter(n => !n.inUse && !n.known) : []
    readonly property var flatRows: knownNetworks.concat(otherNetworks)

    implicitHeight: col.implicitHeight + 8

    Component.onCompleted: if (body.controller) body.controller.refresh(true)

    function kbdHandle(event) {
        const key = event.key;
        const max = 4 + body.flatRows.length;
        if (key === Qt.Key_R) { body.controller.refresh(true); return true; }
        if (key === Qt.Key_Q) { body.controller.showQr(); return true; }
        if (key === Qt.Key_S) { body.controller.runSpeedTest(); return true; }
        if (key === Qt.Key_Up) { body.kbdIndex = Math.max(0, body.kbdIndex - 1); return true; }
        if (key === Qt.Key_Down || key === Qt.Key_Tab) { body.kbdIndex = Math.min(Math.max(0, max - 1), body.kbdIndex + 1); return true; }
        if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space) { body.activateIndex(body.kbdIndex); return true; }
        return false;
    }

    function activateIndex(i) {
        if (!body.controller) return;
        if (i === 0 && body.controller.kind === "wifi") { body.controller.showQr(); return; }
        if (i === 1 && body.hasWifi) { body.controller.toggleRadio(); return; }
        if (i === 2) { body.controller.setDns("DHCP"); return; }
        if (i === 3) { body.controller.runSpeedTest(); return; }
        const net = body.flatRows[i - 4];
        if (net) body.activateNetwork(net);
    }

    function activateNetwork(net) {
        if (!net || !body.controller || body.controller.busy) return;
        if (net.inUse) { body.controller.disconnect(); return; }
        if (net.known) { body.controller.connectKnown(net.ssid); return; }
        if (isProtected(net)) { body.passwordSsid = net.ssid; body.passwordText = ""; return; }
        body.controller.connectKnown(net.ssid);
    }

    function isProtected(net) {
        return net && net.security && net.security.length > 0 && net.security.toLowerCase() !== "open" && net.security !== "--";
    }

    function networkIcon(signal) {
        if (!body.nav) return "󰤨";
        return body.nav.wifiBarsGlyph(signal || 0);
    }

    function heroIcon() {
        if (!body.controller) return "󰤮";
        if (body.controller.kind === "wifi") return networkIcon(body.controller.signal);
        if (body.controller.kind === "ethernet") return "󰈀";
        return "󰤮";
    }

    function heroTitle() {
        if (!body.controller) return "Network";
        if (body.controller.kind === "wifi") return body.controller.info.ssid || body.controller.label || "Wi-Fi";
        if (body.controller.kind === "ethernet") return body.controller.info.connection || "Ethernet";
        return "Disconnected";
    }

    function heroSubtitle() {
        if (!body.controller) return "";
        if (body.controller.kind === "wifi") return "COUNTING COLLISIONS";
        if (body.controller.kind === "ethernet") return "HANDLING PACKETS";
        if (!body.controller.nmAvailable) return "NETWORKMANAGER UNAVAILABLE";
        return "NO ACTIVE NETWORK";
    }

    function formatBytes(bytes) {
        const n = Number(bytes || 0);
        if (n < 1024) return Math.round(n) + " B";
        if (n < 1024 * 1024) return (n / 1024).toFixed(1) + " KB";
        if (n < 1024 * 1024 * 1024) return (n / (1024 * 1024)).toFixed(1) + " MB";
        return (n / (1024 * 1024 * 1024)).toFixed(2) + " GB";
    }

    function formatRate(bytes) { return formatBytes(bytes) + "/s"; }
    function formatPing(ms) { const n = Number(ms); return isFinite(n) && n >= 0 ? Math.round(n) + " ms" : "--"; }
    function detail(key, fallback) { return body.controller && body.controller.info ? (body.controller.info[key] || fallback || "--") : (fallback || "--"); }

    component SectionLabel: Text {
        required property var rootRef
        color: rootRef.inkDeep
        font.family: rootRef.mono
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 1.4
    }

    component InfoLabel: Text {
        required property var rootRef
        color: rootRef.inkDeep
        font.family: rootRef.mono
        font.pixelSize: 11
    }

    component InfoValue: Text {
        required property var rootRef
        color: rootRef.ink
        font.family: rootRef.mono
        font.pixelSize: 11
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
    }

    component Pill: Rectangle {
        id: pill
        required property var rootRef
        property string label: ""
        property bool selected: false
        property bool focused: false
        signal clicked()
        height: 38
        radius: rootRef.cornerRadius
        color: selected || focused ? rootRef.rowSel : "transparent"
        border.color: selected || focused ? rootRef.seal : rootRef.sep
        border.width: focused ? 2 : 1
        Text {
            anchors.centerIn: parent
            text: pill.label
            color: pill.selected ? pill.rootRef.ink : pill.rootRef.fg
            font.family: pill.rootRef.mono
            font.pixelSize: 11
        }
        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.clicked() }
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 6
        spacing: 14

        Item {
            width: parent.width
            height: Math.max(70, heroLabels.implicitHeight + 10)

            Text {
                id: heroGlyph
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: body.heroIcon()
                color: body.root.ink
                font.family: body.root.mono
                font.pixelSize: 34
            }

            Column {
                id: heroLabels
                anchors.left: heroGlyph.right
                anchors.leftMargin: 16
                anchors.right: heroActions.left
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                Text {
                    width: parent.width
                    text: body.heroTitle()
                    color: body.root.ink
                    font.family: body.root.mono
                    font.pixelSize: 20
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: body.heroSubtitle()
                    color: body.root.inkDeep
                    font.family: body.root.mono
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 2
                    elide: Text.ElideRight
                }
            }

            Row {
                id: heroActions
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Pill {
                    visible: body.controller && body.controller.kind === "wifi"
                    width: 46
                    rootRef: body.root
                    label: "󰐲"
                    focused: body.kbdIndex === 0
                    onClicked: body.controller.showQr()
                }
                Pill {
                    visible: body.hasWifi
                    width: 84
                    rootRef: body.root
                    label: body.controller && body.controller.radioOn ? "ON" : "OFF"
                    selected: body.controller && body.controller.radioOn
                    focused: body.kbdIndex === 1
                    onClicked: body.controller.toggleRadio()
                }
            }
        }

        Grid {
            visible: body.hasActiveIface
            width: parent.width
            columns: 4
            columnSpacing: 22
            rowSpacing: 10

            InfoLabel { rootRef: body.root; width: (parent.width - 66) / 4; text: "Ping" }
            InfoValue { rootRef: body.root; width: (parent.width - 66) / 4; text: body.formatPing(body.controller.internetPingLatency) }
            InfoLabel { rootRef: body.root; width: (parent.width - 66) / 4; text: "Packet Loss" }
            InfoValue { rootRef: body.root; width: (parent.width - 66) / 4; text: (body.controller.internetPingPacketLoss || 0) + "%" }

            InfoLabel { rootRef: body.root; width: (parent.width - 66) / 4; text: "Receiving" }
            InfoValue { rootRef: body.root; width: (parent.width - 66) / 4; text: body.formatRate(body.controller.downloadRate) }
            InfoLabel { rootRef: body.root; width: (parent.width - 66) / 4; text: "Sending" }
            InfoValue { rootRef: body.root; width: (parent.width - 66) / 4; text: body.formatRate(body.controller.uploadRate) }

            InfoLabel { rootRef: body.root; width: (parent.width - 66) / 4; text: "Downloaded" }
            InfoValue { rootRef: body.root; width: (parent.width - 66) / 4; text: body.formatBytes(body.detail("rx_bytes", "0")) }
            InfoLabel { rootRef: body.root; width: (parent.width - 66) / 4; text: "Uploaded" }
            InfoValue { rootRef: body.root; width: (parent.width - 66) / 4; text: body.formatBytes(body.detail("tx_bytes", "0")) }

            InfoLabel { rootRef: body.root; width: (parent.width - 66) / 4; text: "IP Address" }
            InfoValue { rootRef: body.root; width: (parent.width - 66) / 4; text: body.detail("ip") }
            InfoLabel { rootRef: body.root; width: (parent.width - 66) / 4; text: "Gateway" }
            InfoValue { rootRef: body.root; width: (parent.width - 66) / 4; text: body.detail("gateway") }
        }

        Rectangle { width: parent.width; height: 1; color: body.root.sep }

        Column {
            width: parent.width
            spacing: 10
            SectionLabel { rootRef: body.root; text: "DNS PROVIDER" }
            Row {
                width: parent.width
                spacing: 10
                readonly property real cell: (width - spacing * 3) / 4
                Pill { rootRef: body.root; width: parent.cell; label: "DHCP"; selected: body.controller && body.controller.dnsProvider === "DHCP"; focused: body.kbdIndex === 2; onClicked: body.controller.setDns("DHCP") }
                Pill { rootRef: body.root; width: parent.cell; label: "Cloudflare"; selected: body.controller && body.controller.dnsProvider === "Cloudflare"; onClicked: body.controller.setDns("Cloudflare") }
                Pill { rootRef: body.root; width: parent.cell; label: "Google"; selected: body.controller && body.controller.dnsProvider === "Google"; onClicked: body.controller.setDns("Google") }
                Pill { rootRef: body.root; width: parent.cell; label: "Custom"; selected: body.controller && body.controller.dnsProvider === "Custom"; onClicked: {} }
            }
            Text {
                visible: body.controller && body.controller.dnsServers !== ""
                width: parent.width
                text: "Current: " + body.controller.dnsServers
                    + (body.controller.dnsMode === "custom" ? " · custom" : "")
                color: body.root.inkDeep
                font.family: body.root.mono
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Rectangle { width: parent.width; height: 1; color: body.root.sep }

        Column {
            width: parent.width
            spacing: 10
            Item {
                width: parent.width
                height: Math.max(speedLabel.implicitHeight, speedRun.implicitHeight)
                SectionLabel { id: speedLabel; rootRef: body.root; text: "SPEED TEST"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                Pill { id: speedRun; rootRef: body.root; width: 68; label: body.controller && body.controller.speedTestRunning ? "RUNNING" : "Run"; focused: body.kbdIndex === 3; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; onClicked: body.controller.runSpeedTest() }
            }
            Text {
                visible: body.controller && (body.controller.speedTestRunning || body.controller.speedTestPhase === "done" || body.controller.speedTestError !== "")
                width: parent.width
                text: body.controller.speedTestError !== ""
                      ? body.controller.speedTestError
                      : "Down " + (body.controller.speedTestDownloadMbps || "--") + " Mbps · Up " + (body.controller.speedTestUploadMbps || "--") + " Mbps"
                color: body.controller && body.controller.speedTestError !== "" ? body.root.warn : body.root.inkDeep
                font.family: body.root.mono
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }
        }

        Rectangle {
            visible: body.controller && body.controller.qrVisible
            width: parent.width
            height: qrColumn.implicitHeight + 24
            radius: body.root.cornerRadius
            color: Qt.rgba(body.root.ink.r, body.root.ink.g, body.root.ink.b, 0.04)
            border.color: body.root.sep
            border.width: 1

            Column {
                id: qrColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                SectionLabel { rootRef: body.root; text: "WI-FI QR" }
                Text {
                    visible: body.controller.qrLoading || body.controller.qrError !== ""
                    width: parent.width
                    text: body.controller.qrLoading ? "Generating QR code..." : body.controller.qrError
                    color: body.controller.qrError !== "" ? body.root.warn : body.root.inkDeep
                    font.family: body.root.mono
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                }
                Grid {
                    visible: body.controller.qrSize > 0 && body.controller.qrError === ""
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: body.controller.qrSize
                    Repeater {
                        model: body.controller.qrSize * body.controller.qrSize
                        Rectangle {
                            required property int index
                            readonly property int r: Math.floor(index / body.controller.qrSize)
                            readonly property int c: index % body.controller.qrSize
                            width: 5
                            height: 5
                            color: body.controller.qrRows[r].charAt(c) === "1" ? body.root.ink : body.root.bg
                        }
                    }
                }
                Row {
                    visible: body.controller.qrSize > 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    Pill { rootRef: body.root; width: 120; label: body.controller.qrPasswordVisible ? "Hide password" : "Show password"; onClicked: body.controller.toggleQrPassword() }
                    Pill { rootRef: body.root; width: 70; label: "Close"; onClicked: body.controller.hideQr() }
                }
                Text {
                    visible: body.controller.qrPasswordVisible || body.controller.qrPasswordError !== ""
                    width: parent.width
                    text: body.controller.qrPasswordError !== "" ? body.controller.qrPasswordError : body.controller.qrPassword
                    color: body.controller.qrPasswordError !== "" ? body.root.warn : body.root.ink
                    font.family: body.root.mono
                    font.pixelSize: 11
                    wrapMode: Text.WrapAnywhere
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        NetworkSection {
            title: "KNOWN NETWORKS"
            rows: body.knownNetworks
            offset: 4
        }

        NetworkSection {
            title: "OTHER NETWORKS"
            rows: body.otherNetworks
            offset: 4 + body.knownNetworks.length
        }

        Text {
            visible: body.hasWifi && body.controller && body.controller.radioOn && body.controller.networks.length === 0 && !body.controller.scanning
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "NO NETWORKS FOUND"
            color: body.root.inkDeep
            font.family: body.root.mono
            font.pixelSize: 10
            font.letterSpacing: 2
        }

        Text {
            visible: body.controller && body.controller.lastError !== ""
            width: parent.width
            text: body.controller.lastError
            color: body.root.warn
            font.family: body.root.mono
            font.pixelSize: 10
            wrapMode: Text.Wrap
        }
    }

    component NetworkSection: Column {
        required property string title
        required property var rows
        required property int offset
        width: body.width
        spacing: 8
        visible: rows.length > 0

        SectionLabel { rootRef: body.root; text: parent.title }
        Repeater {
            model: rows
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool focused: body.kbdIndex === index + offset
                readonly property bool protectedNet: body.isProtected(modelData)
                readonly property bool passwordOpen: body.passwordSsid === modelData.ssid
                width: body.width
                height: rowContent.implicitHeight + (passwordOpen ? passRow.implicitHeight + 12 : 0) + 14
                radius: body.root.cornerRadius
                color: modelData.inUse || focused ? body.root.rowSel : netMouse.containsMouse ? body.root.rowHi : "transparent"
                border.color: modelData.inUse || focused ? body.root.seal : body.root.sep
                border.width: focused ? 2 : 1

                MouseArea {
                    id: netMouse
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: rowContent.implicitHeight + 14
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { body.kbdIndex = index + offset; body.activateNetwork(modelData); }
                }

                Item {
                    id: rowContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    implicitHeight: Math.max(ssidColumn.implicitHeight, lockIcon.implicitHeight, wifiIcon.implicitHeight)

                    Text {
                        id: wifiIcon
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: body.networkIcon(modelData.signal)
                        color: modelData.inUse ? body.root.seal : body.root.inkDeep
                        font.family: body.root.mono
                        font.pixelSize: 19
                    }
                    Column {
                        id: ssidColumn
                        anchors.left: wifiIcon.right
                        anchors.leftMargin: 12
                        anchors.right: lockIcon.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Text {
                            width: parent.width
                            text: modelData.ssid
                            color: body.root.ink
                            font.family: body.root.mono
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: modelData.inUse || modelData.known
                            text: modelData.inUse ? "Connected" : "Known"
                            color: body.root.inkDeep
                            font.family: body.root.mono
                            font.pixelSize: 10
                        }
                    }
                    Text {
                        id: lockIcon
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: protectedNet ? "󰌾" : ""
                        color: body.root.inkDeep
                        font.family: body.root.mono
                        font.pixelSize: 15
                    }
                }

                Row {
                    id: passRow
                    visible: passwordOpen
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: rowContent.bottom
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8
                    height: visible ? implicitHeight : 0

                    TextInput {
                        id: passwordEdit
                        width: parent.width - connectPill.width - 8
                        height: 34
                        text: body.passwordText
                        echoMode: TextInput.Password
                        color: body.root.ink
                        font.family: body.root.mono
                        font.pixelSize: 12
                        clip: true
                        onTextChanged: body.passwordText = text
                        Keys.onReturnPressed: body.controller.connectWithPassword(modelData.ssid, body.passwordText)
                        Keys.onEscapePressed: { body.passwordSsid = ""; body.passwordText = ""; }
                        Rectangle { anchors.fill: parent; z: -1; radius: body.root.cornerRadius; color: body.root.bg; border.color: body.root.sep }
                    }
                    Pill {
                        id: connectPill
                        rootRef: body.root
                        width: 86
                        label: "Connect"
                        onClicked: body.controller.connectWithPassword(modelData.ssid, body.passwordText)
                    }
                }
            }
        }
    }
}
