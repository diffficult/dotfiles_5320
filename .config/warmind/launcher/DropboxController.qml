import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: controller

    property bool active: false
    property bool installed: false
    property bool running: false
    property bool authenticated: false
    property string directory: ""
    property bool directoryAvailable: false
    property string plan: ""
    property string statusText: "CHECKING"
    property double usedBytes: 0
    property double quotaBytes: 0
    property var files: []
    property string actionStatus: ""
    property string lastError: ""
    readonly property bool quotaKnown: quotaBytes > 0

    function open() {
        controller.active = true;
        controller.refresh();
    }

    function close() {
        controller.active = false;
    }

    function toggle() {
        if (controller.active) controller.close();
        else controller.open();
    }

    function refresh() {
        statusProbe.running = false;
        statusProbe.running = true;
    }

    function startSync() {
        if (!controller.installed || controller.running) return;
        runControl(["dropbox-cli", "start"], "Starting Dropbox...");
    }

    function stopSync() {
        if (!controller.running) return;
        runControl(["dropbox-cli", "stop"], "Stopping Dropbox...");
    }

    function login() {
        if (!controller.installed) return;
        runControl(["dropbox-cli", "start"], "Starting Dropbox login...");
    }

    function openDirectory() {
        if (!controller.directory) return;
        Quickshell.execDetached(["xdg-open", controller.directory]);
    }

    function openFile(file) {
        if (!file || !file.path) return;
        Quickshell.execDetached(["xdg-open", file.path]);
    }

    function runControl(command, status) {
        controller.actionStatus = status;
        controller.lastError = "";
        controlProcess.command = command;
        controlProcess.running = false;
        controlProcess.running = true;
    }

    Timer {
        id: postActionTimer
        interval: 1000
        repeat: false
        onTriggered: controller.refresh()
    }

    Timer {
        interval: 60000
        repeat: true
        running: controller.active && controller.installed && controller.authenticated
        onTriggered: controller.refresh()
    }

    Process {
        id: statusProbe
        running: false
        command: ["python3", Quickshell.env("HOME") + "/.config/warmind/launcher/bin/dropbox-status.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const status = JSON.parse(this.text);
                    controller.installed = status.installed === true;
                    controller.running = status.running === true;
                    controller.authenticated = status.authenticated === true;
                    controller.directory = String(status.directory || "");
                    controller.directoryAvailable = status.directoryAvailable === true;
                    controller.plan = String(status.plan || "");
                    controller.statusText = String(status.statusText || "Unavailable");
                    controller.usedBytes = Number(status.usedBytes || 0);
                    controller.quotaBytes = Number(status.quotaBytes || 0);
                    controller.files = Array.isArray(status.files) ? status.files : [];
                    controller.lastError = "";
                } catch (_) {
                    controller.lastError = "Failed to read Dropbox status";
                }
            }
        }
    }

    Process {
        id: controlProcess
        running: false
        stdout: StdioCollector { id: controlStdout; waitForEnd: true }
        stderr: StdioCollector { id: controlStderr; waitForEnd: true }
        onExited: function(exitCode) {
            const output = String(controlStdout.text || "") + "\n" + String(controlStderr.text || "");
            if (exitCode !== 0) controller.lastError = output.trim() || "Dropbox command failed";
            else controller.actionStatus = output.trim() || "Done";
            const match = output.match(/https?:\/\/\S+/);
            if (match && match[0]) Qt.openUrlExternally(match[0]);
            postActionTimer.restart();
        }
    }

    function formatBytes(bytes) {
        let value = Number(bytes || 0);
        const units = ["B", "KB", "MB", "GB", "TB"];
        let unit = 0;
        while (value >= 1000 && unit < units.length - 1) {
            value /= 1000;
            unit += 1;
        }
        const decimals = value >= 100 || unit === 0 ? 0 : (value >= 10 ? 1 : 2);
        return value.toFixed(decimals).replace(/\.0+$/, "") + " " + units[unit];
    }

    function usageText() {
        return controller.quotaKnown
            ? controller.formatBytes(controller.usedBytes) + " OF " + controller.formatBytes(controller.quotaBytes)
            : controller.formatBytes(controller.usedBytes);
    }

    function relativeTime(timestamp) {
        const seconds = Math.max(0, Math.floor(Date.now() / 1000) - Number(timestamp || 0));
        if (seconds < 60) return "JUST NOW";
        if (seconds < 3600) return Math.floor(seconds / 60) + "M AGO";
        if (seconds < 86400) return Math.floor(seconds / 3600) + "H AGO";
        return Math.floor(seconds / 86400) + "D AGO";
    }
}
