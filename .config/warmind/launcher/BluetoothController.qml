import QtQuick
import Quickshell.Io

Item {
    id: controller

    property string icon: "󰂲"
    property bool powered: false
    property int count: 0
    property bool pairable: false
    property bool discoverable: false
    property var devices: []
    property bool scanning: false
    property string devicesSerialised: ""
    property bool active: false

    readonly property string iconOff: "󰂲"
    readonly property string iconOn: "󰂯"
    readonly property string iconConnected: "󰂱"

    function refreshAll() {
        if (devicesProbe.running) return;
        summaryProbe.running = false;
        summaryProbe.running = true;
        devicesProbe.running = false;
        devicesProbe.running = true;
    }

    function open() {
        controller.active = true;
        controller.refreshAll();
    }

    function close() {
        controller.active = false;
    }

    function toggle() {
        if (controller.active) controller.close();
        else controller.open();
    }

    function refreshSummary() {
        summaryProbe.running = false;
        summaryProbe.running = true;
    }

    function refreshDevices() {
        devicesProbe.running = false;
        devicesProbe.running = true;
    }

    function connect(mac) {
        if (!mac) return;
        runCommand("bluetoothctl connect " + mac);
        postActionTimer.restart();
    }

    function disconnect(mac) {
        if (!mac) return;
        runCommand("bluetoothctl disconnect " + mac);
        postActionTimer.restart();
    }

    function togglePower() {
        powered = !powered;
        runCommand("~/.config/warmind/launcher/bin/bluetooth-power-toggle.sh");
        postActionTimer.restart();
    }

    function toggleScan() {
        scanning = !scanning;
        if (scanning) {
            runCommand("setsid -f sh -lc 'bluetoothctl --timeout 15 scan on >/dev/null 2>&1'");
            scanStopTimer.restart();
        } else {
            runCommand("bluetoothctl scan off");
        }
        postActionTimer.restart();
    }

    function togglePairable() {
        pairable = !pairable;
        runCommand("bluetoothctl pairable " + (pairable ? "on" : "off"));
        postActionTimer.restart();
    }

    function toggleDiscoverable() {
        discoverable = !discoverable;
        runCommand("bluetoothctl discoverable " + (discoverable ? "on" : "off"));
        postActionTimer.restart();
    }

    function runCommand(cmd) {
        runner.command = ["bash", "-lc", cmd];
        runner.running = false;
        runner.running = true;
    }

    function syncSummaryIcon() {
        if (!powered) {
            if (icon !== iconOff) icon = iconOff;
            if (count !== 0) count = 0;
            return;
        }
        const want = count > 0 ? iconConnected : iconOn;
        if (icon !== want) icon = want;
    }

    Process {
        id: runner
        running: false
    }

    Timer {
        id: postActionTimer
        interval: 800
        repeat: false
        onTriggered: controller.refreshAll()
    }

    Timer {
        id: scanStopTimer
        interval: 15000
        repeat: false
        onTriggered: {
            controller.scanning = false;
            controller.refreshAll();
        }
    }

    Process {
        id: summaryProbe
        running: false
        command: ["bash", "-lc",
            "bluetoothctl show 2>/dev/null"
            + " | awk -F': ' '/Powered:|Pairable:|Discoverable:|Discovering:/{print $1 \"\\t\" $2}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(s => s.length > 0);
                let nextPowered = false;
                let nextPairable = false;
                let nextDiscoverable = false;
                let nextScanning = false;
                for (const line of lines) {
                    const fields = line.split("\t");
                    if (fields.length < 2) continue;
                    const key = fields[0].trim();
                    const value = fields[1].trim() === "yes";
                    if (key === "Powered") nextPowered = value;
                    else if (key === "Pairable") nextPairable = value;
                    else if (key === "Discoverable") nextDiscoverable = value;
                    else if (key === "Discovering") nextScanning = value;
                }
                if (controller.powered !== nextPowered) controller.powered = nextPowered;
                if (controller.pairable !== nextPairable) controller.pairable = nextPairable;
                if (controller.discoverable !== nextDiscoverable) controller.discoverable = nextDiscoverable;
                if (controller.scanning !== nextScanning) controller.scanning = nextScanning;
                controller.syncSummaryIcon();
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: controller.refreshSummary()
    }

    Process {
        id: devicesProbe
        running: false
        command: ["bash", "-lc",
            "devices=$(bluetoothctl devices 2>/dev/null | awk '/^Device /{mac=$2; $1=\"\"; $2=\"\"; sub(/^  */, \"\", $0); print mac \"\\t\" $0}');"
            + " printf '%s\n' \"$devices\" | while IFS=$'\\t' read -r mac rest; do"
            + "   [ -z \"$mac\" ] && continue;"
            + "   info=$(bluetoothctl info \"$mac\" 2>/dev/null);"
            + "   [ -z \"$info\" ] && continue;"
            + "   name=$(printf '%s\n' \"$info\" | awk -F': ' '/^[[:space:]]*(Alias|Name):/{print $2; exit}');"
            + "   icon=$(printf '%s\n' \"$info\" | awk -F': ' '/^[[:space:]]*Icon:/{print $2; exit}');"
            + "   conn=$(printf '%s\n' \"$info\" | awk -F': ' '/^[[:space:]]*Connected:/{print ($2==\"yes\")?1:0; exit}');"
            + "   paired=$(printf '%s\n' \"$info\" | awk -F': ' '/^[[:space:]]*Paired:/{print ($2==\"yes\")?1:0; exit}');"
            + "   trusted=$(printf '%s\n' \"$info\" | awk -F': ' '/^[[:space:]]*Trusted:/{print ($2==\"yes\")?1:0; exit}');"
            + "   batt=$(printf '%s\n' \"$info\" | awk -F'[()]' '/Battery Percentage/{print $2; exit}' | tr -d '% ');"
            + "   printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \"$mac\" \"${name:-$mac}\" \"${conn:-0}\" \"${paired:-0}\" \"${trusted:-0}\" \"${batt:-}\" \"${icon:-}\";"
            + " done"]
        stdout: StdioCollector {
            onStreamFinished: {
                function btGlyph(iconName, name) {
                    const iconNameLc = (iconName || "").toLowerCase();
                    const nameLc = (name || "").toLowerCase();
                    if (iconNameLc.includes("audio-headset") || iconNameLc.includes("headset")) return "🎧";
                    if (iconNameLc.includes("audio-headphones") || iconNameLc.includes("headphone")) return "🎧";
                    if (iconNameLc.includes("audio-speakers") || iconNameLc.includes("speaker")) return "󰓃";
                    if (iconNameLc.includes("input-keyboard") || iconNameLc.includes("keyboard") || nameLc.includes("keyboard") || nameLc.includes("keychron")) return "";
                    if (iconNameLc.includes("input-mouse") || iconNameLc.includes("mouse") || nameLc.includes("mouse") || nameLc.includes("trackpad")) return "󰍽";
                    if (iconNameLc.includes("phone") || nameLc.includes("iphone") || nameLc.includes("pixel") || nameLc.includes("galaxy")) return "📱";
                    if (iconNameLc.includes("computer") || iconNameLc.includes("laptop") || nameLc.includes("laptop") || nameLc.includes("pc")) return "💻";
                    if (iconNameLc.includes("gamepad") || iconNameLc.includes("gaming") || nameLc.includes("controller") || nameLc.includes("xbox") || nameLc.includes("playstation")) return "🎮";
                    if (iconNameLc.includes("watch") || nameLc.includes("watch") || nameLc.includes("band")) return "⌚";
                    return "";
                }
                const lines = this.text.trim().split("\n").filter(s => s.length > 0);
                const nextDevices = lines.map(line => {
                    const fields = line.split("\t");
                    const name = (fields[1] || "").trim() || (fields[0] || "");
                    const battery = parseInt(fields[5] || "", 10);
                    const iconName = fields[6] || "";
                    return {
                        mac: fields[0] || "",
                        name: name,
                        connected: fields[2] === "1",
                        paired: fields[3] === "1",
                        trusted: fields[4] === "1",
                        battery: isNaN(battery) ? -1 : battery,
                        type: iconName,
                        glyph: btGlyph(iconName, name)
                    };
                });
                nextDevices.sort((a, b) =>
                    (b.connected - a.connected)
                    || (b.paired - a.paired)
                    || (b.trusted - a.trusted)
                    || a.name.localeCompare(b.name));
                const serialised = JSON.stringify(nextDevices);
                if (serialised !== controller.devicesSerialised) {
                    controller.devicesSerialised = serialised;
                    controller.devices = nextDevices;
                }
                const connectedCount = nextDevices.filter(device => device.connected).length;
                if (controller.count !== connectedCount) controller.count = connectedCount;
                controller.syncSummaryIcon();
            }
        }
    }
}
