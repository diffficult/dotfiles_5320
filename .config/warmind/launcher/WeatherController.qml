import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: controller

    property var host: null
    property string locationPath: Quickshell.env("HOME") + "/.config/quickshell/weather-location"
    property string location: "Mendoza,Argentina"
    property bool active: false
    property bool loaded: false
    property bool unavailable: false
    property string place: ""
    property real tempC: 0
    property real feelsC: 0
    property int windKmh: 0
    property string windDir: ""
    property int humidity: 0
    property int uv: 0
    property string desc: ""
    property int code: 0
    property string sunrise: ""
    property string sunset: ""
    property real highC: 0
    property real lowC: 0
    property var forecast: []
    property string updatedAt: ""
    property real anchorX: 0
    property real anchorY: 0

    function weatherGlyph(code, night) {
        const n = parseInt(code) || 0;
        if (n === 113) return String.fromCodePoint(night ? 0xe32b : 0xe30d);
        if (n === 116) return String.fromCodePoint(night ? 0xe32e : 0xe302);
        if (n === 119 || n === 122) return String.fromCodePoint(0xe33d);
        if (n === 143 || n === 248 || n === 260) return String.fromCodePoint(0xe313);
        if (n === 176 || n === 263 || n === 353) return String.fromCodePoint(night ? 0xe333 : 0xe308);
        if ([179,227,230,323,326,368].indexOf(n) !== -1) return String.fromCodePoint(night ? 0xe327 : 0xe30a);
        if ([182,185,281,284,311,314,317,320,350,362,365,374,377].indexOf(n) !== -1) return String.fromCodePoint(0xe3ad);
        if ([200,386,389,392,395].indexOf(n) !== -1) return String.fromCodePoint(0xe31d);
        if ([266,293,296,299,302,305,308,356,359].indexOf(n) !== -1) return String.fromCodePoint(0xe318);
        if ([329,332,335,338,371].indexOf(n) !== -1) return String.fromCodePoint(0xe31a);
        return String.fromCodePoint(0xe33d);
    }

    function parseClock(s) {
        const m = String(s).match(/^(\d{1,2}):(\d{2})\s*(AM|PM)?\s*$/i);
        if (!m) return -1;
        let h = parseInt(m[1]);
        const min = parseInt(m[2]);
        if (m[3]) {
            const pm = m[3].toUpperCase() === "PM";
            if (h === 12) h = pm ? 12 : 0;
            else if (pm) h += 12;
        }
        return h * 60 + min;
    }

    readonly property bool isNight: {
        if (controller.host) controller.host.mm;
        const sr = controller.parseClock(controller.sunrise);
        const ss = controller.parseClock(controller.sunset);
        if (sr < 0 || ss < 0) return false;
        const now = new Date();
        const cur = now.getHours() * 60 + now.getMinutes();
        return cur < sr || cur >= ss;
    }

    readonly property string icon: controller.loaded
        ? controller.weatherGlyph(controller.code, controller.isNight)
        : ""

    readonly property string url: {
        const loc = controller.location;
        return "https://wttr.in/" + (loc ? encodeURIComponent(loc) : "") + "?format=j1";
    }

    function fmtTemp(c) {
        const v = Math.round(c);
        return (v > 0 ? "+" : "") + v + "°";
    }

    function refresh() {
        weatherProbe.running = false;
        weatherProbe.running = true;
    }

    function open() {
        controller.anchorX = controller.host ? controller.host.width / 2 : 0;
        if (controller.host && controller.host.weatherAnchorItem) {
            const item = controller.host.weatherAnchorItem;
            const p = item.mapToItem(null, item.width / 2, item.height / 2);
            controller.anchorY = p.y;
        } else {
            controller.anchorY = 0;
        }
        controller.active = true;
    }

    function close() {
        controller.active = false;
    }

    function toggle() {
        if (controller.active) controller.close();
        else controller.open();
    }

    function editLocation() {
        run("mkdir -p \"$(dirname " + JSON.stringify(controller.locationPath) + ")\""
            + " && touch " + JSON.stringify(controller.locationPath)
            + " && foot -e ${EDITOR:-nano} " + JSON.stringify(controller.locationPath));
        controller.close();
    }

    function run(cmd) {
        runner.command = ["zsh", "-c", cmd];
        runner.running = false;
        runner.running = true;
    }

    FileView {
        id: weatherLocFile
        path: controller.locationPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            controller.location = weatherLocFile.text().trim() || "Mendoza,Argentina";
            weatherProbe.running = false;
            weatherProbe.running = true;
        }
    }

    Process {
        id: weatherProbe
        running: false
        command: ["bash", "-lc",
            "URL=" + JSON.stringify(controller.url) + ";"
            + " j=$(curl -fsS --max-time 5 \"$URL\" 2>/dev/null);"
            + " if [ -z \"$j\" ]; then printf 'ERR'; exit 0; fi;"
            + " data=$(printf '%s' \"$j\" | jq -r '"
            + "  .current_condition[0] as $c"
            + "  | .weather as $w"
            + "  | .nearest_area[0] as $a"
            + "  | [$a.areaName[0].value, $c.temp_C, $c.FeelsLikeC,"
            + "     $c.windspeedKmph, $c.winddir16Point, $c.humidity, $c.uvIndex,"
            + "     $c.weatherDesc[0].value, $c.weatherCode,"
            + "     $w[0].astronomy[0].sunrise, $w[0].astronomy[0].sunset,"
            + "     $w[0].maxtempC, $w[0].mintempC,"
            + "     $w[1].date, $w[1].maxtempC, $w[1].mintempC, $w[1].hourly[4].weatherCode,"
            + "     $w[2].date, $w[2].maxtempC, $w[2].mintempC, $w[2].hourly[4].weatherCode]"
            + "  | map(tostring) | join(\"|\")');"
            + " printf 'OK|%s' \"$data\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const txt = this.text.trim();
                if (!txt.startsWith("OK|")) {
                    controller.unavailable = true;
                    return;
                }
                const p = txt.substring(3).split("|");
                if (p.length < 21) {
                    controller.unavailable = true;
                    return;
                }
                controller.place = p[0];
                controller.tempC = parseFloat(p[1]);
                controller.feelsC = parseFloat(p[2]);
                controller.windKmh = parseInt(p[3]);
                controller.windDir = p[4];
                controller.humidity = parseInt(p[5]);
                controller.uv = parseInt(p[6]);
                controller.desc = p[7];
                controller.code = parseInt(p[8]);
                controller.sunrise = p[9];
                controller.sunset = p[10];
                controller.highC = parseFloat(p[11]);
                controller.lowC = parseFloat(p[12]);
                const days = [];
                for (let i = 0; i < 2; i++) {
                    const off = 13 + i * 4;
                    days.push({
                        day: Qt.formatDate(new Date(p[off]), "ddd").toUpperCase(),
                        high: parseFloat(p[off + 1]),
                        low: parseFloat(p[off + 2]),
                        code: parseInt(p[off + 3])
                    });
                }
                controller.forecast = days;
                const now = new Date();
                controller.updatedAt = String(now.getHours()).padStart(2, "0")
                                     + ":" + String(now.getMinutes()).padStart(2, "0");
                controller.loaded = true;
                controller.unavailable = false;
            }
        }
    }

    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: controller.refresh()
    }

    Process { id: runner; running: false }
}
