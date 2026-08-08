import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: controller

    property bool active: false
    property string step: "delay"
    property string minutes: ""
    property string message: ""
    property string errorText: ""
    property var reminders: []
    property bool remindersLoaded: false
    property int nowSeconds: Math.floor(Date.now() / 1000)
    readonly property var presets: [5, 10, 15, 30, 60]

    function open() {
        controller.active = true;
        controller.step = "delay";
        controller.minutes = "";
        controller.message = "";
        controller.errorText = "";
        controller.refreshTimers();
    }

    function close() {
        controller.active = false;
    }

    function toggle() {
        if (controller.active)
            controller.close();
        else
            controller.open();
    }

    function validMinutes(value) {
        const text = String(value || "").trim();
        return /^[1-9][0-9]*$/.test(text) ? text : "";
    }

    function chooseDelay(value) {
        const valid = controller.validMinutes(value);
        if (!valid) {
            controller.errorText = "ENTER A POSITIVE NUMBER OF MINUTES";
            return false;
        }
        controller.minutes = valid;
        controller.errorText = "";
        controller.step = "message";
        return true;
    }

    function backToDelay() {
        controller.step = "delay";
        controller.errorText = "";
    }

    function schedule() {
        const valid = controller.validMinutes(controller.minutes);
        if (!valid) {
            controller.step = "delay";
            controller.errorText = "ENTER A POSITIVE NUMBER OF MINUTES";
            return false;
        }
        const body = controller.message.trim() || "Your " + valid + " minutes are up";
        const unit = "warmind-reminder-" + valid + "m-" + Math.floor(Date.now() / 1000);
        // Keep the reminder message as an argv entry rather than interpolating it into a shell command.
        Quickshell.execDetached({
            "command": ["systemd-run", "--user", "--quiet", "--collect", "--on-active=" + valid + "m", "--unit=" + unit, "--description=Warmind Reminder: " + body, "notify-send", "-a", "Warmind Reminder", "-i", "alarm-symbolic", "-u", "normal", "Reminder", body]
        });
        Quickshell.execDetached({
            "command": ["notify-send", "-a", "Warmind Reminder", "-i", "alarm-symbolic", "Reminder set", "In " + valid + " minutes"]
        });
        controller.close();
        return true;
    }

    function refreshTimers() {
        controller.remindersLoaded = false;
        reminderProbe.running = false;
        reminderProbe.running = true;
    }

    function formatTime(epoch) {
        return Qt.formatTime(new Date(epoch * 1000), "HH:mm");
    }

    function formatRemaining(epoch) {
        const remaining = Math.max(0, epoch - controller.nowSeconds);
        const minutes = Math.floor(remaining / 60);
        const seconds = remaining % 60;
        if (minutes > 0)
            return minutes + "M " + seconds + "S";

        return seconds + "S";
    }

    Timer {
        interval: 1000
        repeat: true
        running: controller.active
        onTriggered: controller.nowSeconds = Math.floor(Date.now() / 1000)
    }

    Timer {
        interval: 15000
        repeat: true
        running: controller.active
        onTriggered: controller.refreshTimers()
    }

    Process {
        id: reminderProbe

        running: false
        command: ["bash", "-lc", "systemctl --user list-timers --all --output=json 'warmind-reminder-*.timer' 2>/dev/null" + " | jq -r '.[] | select(.next > 0 and .activates != null)" + " | [.unit, .activates, ((.next / 1000000) | floor)] | @tsv'" + " | while IFS=$'\\t' read -r timer service at; do" + " desc=$(systemctl --user show \"$service\" --property=Description --value 2>/dev/null || true);" + " message=${desc#Warmind Reminder: };" + " jq -cn --arg unit \"$service\" --arg message \"$message\" --argjson at \"$at\"" + " '{unit:$unit,message:$message,at:$at}';" + " done"]

        stdout: StdioCollector {
            onStreamFinished: {
                const items = [];
                const lines = this.text.trim().split("\n");
                for (let i = 0; i < lines.length; ++i) {
                    if (!lines[i])
                        continue;

                    try {
                        items.push(JSON.parse(lines[i]));
                    } catch (_) {
                    }
                }
                items.sort(function(a, b) {
                    return a.at - b.at;
                });
                controller.reminders = items;
                controller.remindersLoaded = true;
            }
        }

    }

}
