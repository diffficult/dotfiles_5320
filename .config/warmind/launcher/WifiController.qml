import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: controller

    property bool supported: false
    property bool nmAvailable: false
    property bool wifiSupported: false
    property bool radioOn: false
    property bool scanning: false
    property bool active: false
    property bool busy: false
    property string lastError: ""

    property var networks: []
    property string networksSerialised: ""
    property var info: ({})
    property string kind: "disconnected"
    property string label: ""
    property int signal: -1
    property string frequency: ""

    property real prevRxBytes: 0
    property real prevTxBytes: 0
    property real prevSampleTime: 0
    property string prevIface: ""
    property real downloadRate: 0
    property real uploadRate: 0
    property var internetPingSamples: []
    property real internetPingLatency: -1
    property int internetPingPacketLoss: 0

    property string dnsProvider: "DHCP"
    property string dnsServers: ""
    property string dnsMode: ""
    property string pendingDnsProvider: ""

    property bool qrVisible: false
    property bool qrLoading: false
    property var qrRows: []
    property int qrSize: 0
    property string qrError: ""
    property string qrPassword: ""
    property bool qrPasswordVisible: false
    property string qrPasswordError: ""

    property bool speedTestRunning: false
    property string speedTestPhase: ""
    property string speedTestDownloadMbps: ""
    property string speedTestUploadMbps: ""
    property string speedTestError: ""
    property bool speedExpectedStop: false

    readonly property string binDir: Quickshell.env("HOME") + "/.config/warmind/launcher/bin"

    function helper(name) { return controller.binDir + "/" + name; }

    function open() {
        controller.active = true;
        controller.refresh(true);
    }

    function close() {
        controller.active = false;
        controller.hideQr();
        controller.hideSpeedTest();
    }

    function toggle() {
        if (controller.active) controller.close();
        else controller.open();
    }

    function refresh(forceScan) {
        controller.lastError = "";
        if (!statusProc.running) statusProc.running = true;
        if (!detailsProc.running) detailsProc.running = true;
        if (!wifiProc.running) {
            controller.scanning = true;
            wifiProc.command = ["bash", "-lc", controller.wifiProbeScript(forceScan ? "yes" : "no")];
            wifiProc.running = true;
        }
        if (!dnsProc.running) dnsProc.running = true;
    }

    function wifiProbeScript(forceScan) {
        return "set -e; "
            + "if ! command -v nmcli >/dev/null 2>&1; then echo 'NM|off'; echo 'WIFI|off'; echo 'RADIO|off'; exit 0; fi; "
            + "echo 'NM|on'; "
            + "wifi_dev=$(LC_ALL=C nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2==\"wifi\"{print $1; exit}'); "
            + "if [ -z \"$wifi_dev\" ]; then echo 'WIFI|off'; echo 'RADIO|off'; exit 0; fi; "
            + "echo 'WIFI|on'; radio=$(LC_ALL=C nmcli radio wifi 2>/dev/null || echo disabled); "
            + "[ \"$radio\" = enabled ] && echo 'RADIO|on' || { echo 'RADIO|off'; exit 0; }; "
            + "known=$(LC_ALL=C nmcli -t -e no -f NAME,TYPE connection show 2>/dev/null | awk -F: '$2==\"802-11-wireless\"{print $1}' | sed 's/[\\\\|]/_/g'); "
            + "if [ \"" + forceScan + "\" = yes ]; then nmcli device wifi rescan >/dev/null 2>&1 || true; fi; "
            + "LC_ALL=C nmcli -t -e no -f IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan no 2>/dev/null "
            + "| awk -F: -v known=\"$known\" 'BEGIN{n=split(known,k,\"\\n\"); for(i=1;i<=n;i++) seen[k[i]]=1} $2!=\"\" {print \"NET|\" (($1==\"*\")?1:0) \"|\" $2 \"|\" $3 \"|\" $4 \"|\" ((seen[$2])?1:0)}'";
    }

    function parseKeyValues(text) {
        const out = {};
        const lines = String(text || "").split("\n");
        for (const line of lines) {
            if (!line) continue;
            const idx = line.indexOf("\t");
            if (idx < 0) continue;
            out[line.slice(0, idx)] = line.slice(idx + 1).trim();
        }
        return out;
    }

    function updateStatus(text) {
        const fields = String(text || "").trim().split("\t");
        controller.kind = fields[0] || "disconnected";
        controller.label = fields[1] || "";
        controller.signal = fields[2] ? parseInt(fields[2], 10) : -1;
        controller.frequency = fields[3] || "";
    }

    function updateDetails(text) {
        const next = parseKeyValues(text);
        controller.info = next;
        const iface = next.iface || "";
        const rx = parseFloat(next.rx_bytes || "0");
        const tx = parseFloat(next.tx_bytes || "0");
        const now = Date.now() / 1000;

        if (iface !== controller.prevIface || controller.prevSampleTime === 0) {
            controller.prevIface = iface;
            controller.prevRxBytes = rx;
            controller.prevTxBytes = tx;
            controller.prevSampleTime = now;
            controller.downloadRate = 0;
            controller.uploadRate = 0;
        } else {
            const dt = Math.max(0.001, now - controller.prevSampleTime);
            controller.downloadRate = Math.max(0, (rx - controller.prevRxBytes) / dt);
            controller.uploadRate = Math.max(0, (tx - controller.prevTxBytes) / dt);
            controller.prevRxBytes = rx;
            controller.prevTxBytes = tx;
            controller.prevSampleTime = now;
        }

        const ping = parseFloat(next.internet_ping_ms || "");
        const samples = controller.internetPingSamples.slice();
        samples.push(isFinite(ping) && ping >= 0 ? ping : null);
        while (samples.length > 24) samples.shift();
        controller.internetPingSamples = samples;
        let total = 0, count = 0, lost = 0;
        for (const s of samples) {
            if (s === null) { lost++; continue; }
            if (typeof s === "number") { total += s; count++; }
        }
        controller.internetPingLatency = count > 0 ? total / count : -1;
        controller.internetPingPacketLoss = samples.length > 0 ? Math.round((lost / samples.length) * 100) : 0;
    }

    function updateWifi(text) {
        const lines = String(text || "").split("\n").filter(s => s.length > 0);
        let nextNm = false;
        let nextWifi = false;
        let nextRadio = false;
        const next = [];
        for (const line of lines) {
            if (line === "NM|on") { nextNm = true; continue; }
            if (line === "NM|off") { nextNm = false; continue; }
            if (line === "WIFI|on") { nextWifi = true; continue; }
            if (line === "WIFI|off") { nextWifi = false; continue; }
            if (line === "RADIO|on") { nextRadio = true; continue; }
            if (line === "RADIO|off") { nextRadio = false; continue; }
            if (!line.startsWith("NET|")) continue;
            const p = line.split("|");
            if (p.length < 6) continue;
            next.push({
                inUse: p[1] === "1",
                ssid: p[2],
                signal: Math.max(0, Math.min(100, parseInt(p[3], 10) || 0)),
                security: p[4] || "",
                known: p[5] === "1"
            });
        }
        next.sort((a, b) => (b.inUse - a.inUse) || (b.known - a.known) || (b.signal - a.signal) || a.ssid.localeCompare(b.ssid));
        controller.nmAvailable = nextNm;
        controller.wifiSupported = nextWifi;
        controller.supported = nextNm && nextWifi;
        controller.radioOn = nextRadio;
        const serial = JSON.stringify(next);
        if (serial !== controller.networksSerialised) {
            controller.networksSerialised = serial;
            controller.networks = next;
        }
        controller.scanning = false;
    }

    function updateDns(text) {
        const data = parseKeyValues(text);
        controller.dnsProvider = data.provider || "DHCP";
        controller.dnsServers = data.servers || "";
        controller.dnsMode = data.mode || "";
    }

    function runCommand(cmd) {
        controller.busy = true;
        actionProc.command = ["bash", "-lc", cmd];
        actionProc.running = false;
        actionProc.running = true;
    }

    function shellQuote(value) {
        return "'" + String(value || "").replace(/'/g, "'\\''") + "'";
    }

    function toggleRadio() {
        runCommand("nmcli radio wifi " + (controller.radioOn ? "off" : "on"));
    }

    function connectKnown(ssid) {
        if (!ssid) return;
        runCommand("nmcli connection up id " + shellQuote(ssid) + " || nmcli device wifi connect " + shellQuote(ssid));
    }

    function connectWithPassword(ssid, password) {
        if (!ssid || !password) return;
        runCommand("nmcli device wifi connect " + shellQuote(ssid) + " password " + shellQuote(password));
    }

    function disconnect() {
        const iface = controller.info.iface || "";
        if (!iface) return;
        runCommand("nmcli device disconnect " + shellQuote(iface));
    }

    function forget(ssid) {
        if (!ssid) return;
        runCommand("nmcli connection delete id " + shellQuote(ssid));
    }

    function setDns(provider) {
        if (!provider || provider === "Custom") return;
        const con = controller.info.connection || controller.label;
        if (!con) return;
        controller.pendingDnsProvider = provider;
        let cmd = "";
        if (provider === "DHCP") {
            cmd = "nmcli connection modify " + shellQuote(con) + " ipv4.ignore-auto-dns no ipv4.dns '' && nmcli connection up " + shellQuote(con);
        } else if (provider === "Cloudflare") {
            cmd = "nmcli connection modify " + shellQuote(con) + " ipv4.ignore-auto-dns yes ipv4.dns '1.1.1.1 1.0.0.1' && nmcli connection up " + shellQuote(con);
        } else if (provider === "Google") {
            cmd = "nmcli connection modify " + shellQuote(con) + " ipv4.ignore-auto-dns yes ipv4.dns '8.8.8.8 8.8.4.4' && nmcli connection up " + shellQuote(con);
        }
        if (cmd) runCommand(cmd);
    }

    function showQr() {
        controller.qrVisible = true;
        controller.qrLoading = true;
        controller.qrRows = [];
        controller.qrSize = 0;
        controller.qrError = "";
        controller.qrPassword = "";
        controller.qrPasswordVisible = false;
        controller.qrPasswordError = "";
        qrProc.command = [controller.helper("warmind-network-qr"), controller.info.iface || ""];
        qrProc.running = false;
        qrProc.running = true;
    }

    function hideQr() {
        controller.qrVisible = false;
        controller.qrLoading = false;
        controller.qrRows = [];
        controller.qrSize = 0;
        controller.qrError = "";
        controller.qrPassword = "";
        controller.qrPasswordVisible = false;
        controller.qrPasswordError = "";
        if (qrProc.running) qrProc.running = false;
        if (passwordProc.running) passwordProc.running = false;
    }

    function toggleQrPassword() {
        if (controller.qrPasswordVisible) { controller.qrPasswordVisible = false; return; }
        if (controller.qrPassword !== "") { controller.qrPasswordVisible = true; return; }
        controller.qrPasswordError = "";
        passwordProc.command = [controller.helper("warmind-network-password"), controller.info.iface || ""];
        passwordProc.running = false;
        passwordProc.running = true;
    }

    function runSpeedTest() {
        controller.speedTestError = "";
        controller.speedTestDownloadMbps = "";
        controller.speedTestUploadMbps = "";
        controller.speedTestRunning = true;
        controller.speedTestPhase = "download";
        speedExpectedStop = false;
        speedProc.command = [controller.helper("warmind-network-speedtest"), "down"];
        speedProc.running = false;
        speedProc.running = true;
        speedPhaseTimer.restart();
    }

    function hideSpeedTest() {
        controller.speedTestRunning = false;
        controller.speedTestPhase = "";
        controller.speedTestError = "";
        if (speedProc.running) { speedExpectedStop = true; speedProc.running = false; }
        speedPhaseTimer.stop();
    }

    function finishSpeedPhase() {
        if (controller.speedTestPhase === "download") {
            controller.speedTestPhase = "upload";
            speedExpectedStop = false;
            speedProc.command = [controller.helper("warmind-network-speedtest"), "up"];
            speedProc.running = false;
            speedProc.running = true;
            speedPhaseTimer.restart();
            return;
        }
        controller.speedTestPhase = "done";
        controller.speedTestRunning = false;
    }

    Process {
        id: statusProc
        command: [controller.helper("warmind-network-status")]
        stdout: StdioCollector { waitForEnd: true; onStreamFinished: controller.updateStatus(text) }
    }

    Process {
        id: detailsProc
        command: [controller.helper("warmind-network-status"), "--verbose"]
        stdout: StdioCollector { waitForEnd: true; onStreamFinished: controller.updateDetails(text) }
    }

    Process {
        id: wifiProc
        stdout: StdioCollector { waitForEnd: true; onStreamFinished: controller.updateWifi(text) }
        stderr: StdioCollector { waitForEnd: true; onStreamFinished: if (text.trim()) controller.lastError = text.trim() }
        onExited: controller.scanning = false
    }

    Process {
        id: dnsProc
        command: ["bash", "-lc", "iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{ for (i = 1; i <= NF; i++) if ($i == \"dev\") { print $(i + 1); exit } }'); con=$(nmcli -g GENERAL.CONNECTION dev show \"$iface\" 2>/dev/null | head -n1); [ -n \"$con\" ] && [ \"$con\" != \"--\" ] || { printf 'provider\\tDHCP\\nmode\\tdhcp\\n'; exit 0; }; dns=$(nmcli -g ipv4.dns connection show \"$con\" 2>/dev/null | tr -d ' ' | paste -sd, -); ignore=$(nmcli -g ipv4.ignore-auto-dns connection show \"$con\" 2>/dev/null | head -n1); provider=Custom; mode=custom; if [ -z \"$dns\" ]; then provider=DHCP; mode=dhcp; elif [ \"$ignore\" = yes ] && [ \"$dns\" = \"1.1.1.1,1.0.0.1\" ]; then provider=Cloudflare; mode=preset; elif [ \"$ignore\" = yes ] && [ \"$dns\" = \"8.8.8.8,8.8.4.4\" ]; then provider=Google; mode=preset; fi; printf 'provider\\t%s\\nservers\\t%s\\nmode\\t%s\\n' \"$provider\" \"$dns\" \"$mode\""]
        stdout: StdioCollector { waitForEnd: true; onStreamFinished: controller.updateDns(text) }
    }

    Process {
        id: actionProc
        stdout: StdioCollector { waitForEnd: true }
        stderr: StdioCollector { waitForEnd: true; onStreamFinished: if (text.trim()) controller.lastError = text.trim() }
        onExited: {
            controller.busy = false;
            controller.pendingDnsProvider = "";
            postActionTimer.restart();
        }
    }

    Process {
        id: qrProc
        stdout: StdioCollector { waitForEnd: true; onStreamFinished: {
            const rows = text.trim().split("\n").filter(r => r.length > 0);
            controller.qrRows = rows;
            controller.qrSize = rows.length;
        } }
        stderr: StdioCollector { waitForEnd: true; onStreamFinished: if (text.trim()) controller.qrError = text.trim() }
        onExited: function(code) {
            controller.qrLoading = false;
            if (code !== 0 && controller.qrError === "") controller.qrError = "Could not generate Wi-Fi QR";
        }
    }

    Process {
        id: passwordProc
        stdout: StdioCollector { waitForEnd: true; onStreamFinished: controller.qrPassword = text.trim() }
        stderr: StdioCollector { waitForEnd: true; onStreamFinished: if (text.trim()) controller.qrPasswordError = text.trim() }
        onExited: function(code) {
            if (code === 0 && controller.qrPassword !== "") controller.qrPasswordVisible = true;
            else if (controller.qrPasswordError === "") controller.qrPasswordError = "Could not read Wi-Fi password";
        }
    }

    Process {
        id: speedProc
        stdout: SplitParser { onRead: function(line) {
            const v = String(line || "").trim();
            if (!v) return;
            if (controller.speedTestPhase === "download") controller.speedTestDownloadMbps = v;
            else if (controller.speedTestPhase === "upload") controller.speedTestUploadMbps = v;
        } }
        stderr: StdioCollector { waitForEnd: true; onStreamFinished: if (text.trim()) controller.speedTestError = text.trim() }
        onExited: function(code) {
            speedPhaseTimer.stop();
            if (speedExpectedStop) { speedExpectedStop = false; controller.finishSpeedPhase(); return; }
            if (code !== 0) { controller.speedTestRunning = false; controller.speedTestPhase = ""; if (controller.speedTestError === "") controller.speedTestError = "Speed test failed"; return; }
            controller.finishSpeedPhase();
        }
    }

    Timer { id: postActionTimer; interval: 1000; repeat: false; onTriggered: controller.refresh(false) }
    Timer { id: detailsPoll; interval: 1500; repeat: true; running: controller.active; onTriggered: controller.refresh(false) }
    Timer { id: speedPhaseTimer; interval: 5000; repeat: false; onTriggered: { speedExpectedStop = true; speedProc.running = false; } }

    Component.onCompleted: refresh(false)
}
