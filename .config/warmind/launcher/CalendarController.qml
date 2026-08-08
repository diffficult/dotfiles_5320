import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: controller

    property var host: null
    property bool active: false
    property string statePath: Quickshell.env("HOME") + "/.cache/quickshell/warmind/waybar/calendar/state.json"
    property string daemonPath: Quickshell.env("HOME") + "/.config/warmind/waybar/bin/calendar_daemon.py"
    property string selectPath: Quickshell.env("HOME") + "/.config/warmind/waybar/bin/calendar_select.sh"
    property var calState: ({
        current_month: "",
        month_label: "",
        selected_day: "",
        selected_day_label: "",
        selected_events: [],
        weeks: [],
        loading: false,
        stale: false,
        error: null
    })

    readonly property bool loaded: !!(calState && calState.current_month)
    readonly property string currentMonth: calState && calState.current_month ? calState.current_month : ""
    readonly property string monthLabel: calState && calState.month_label ? String(calState.month_label).toUpperCase() : ""
    readonly property string selectedDay: calState && calState.selected_day ? calState.selected_day : ""
    readonly property string selectedDayLabel: calState && calState.selected_day_label ? String(calState.selected_day_label).toUpperCase() : ""
    readonly property var selectedEvents: calState && calState.selected_events ? calState.selected_events : []
    readonly property var weeks: calState && calState.weeks ? calState.weeks : []
    readonly property string error: calState && calState.error ? String(calState.error) : ""
    readonly property int eventCount: selectedEvents ? selectedEvents.length : 0

    function _setLoading(on) {
        const next = Object.assign({}, controller.calState || {});
        next.loading = on;
        controller.calState = next;
    }

    function _reloadState() {
        stateFile.reload();
    }

    function _parseState(raw) {
        try {
            const parsed = JSON.parse(String(raw || "{}").trim() || "{}");
            if (!parsed.weeks) parsed.weeks = [];
            if (!parsed.selected_events) parsed.selected_events = [];
            controller.calState = parsed;
        } catch (e) {
            controller.calState = Object.assign({}, controller.calState || {}, {
                loading: false,
                error: "parse_error"
            });
        }
    }

    function _runDaemon(arg) {
        controller._setLoading(true);
        daemonProc.args = [arg];
        daemonProc.running = false;
        daemonProc.running = true;
    }

    function refresh() { controller._runDaemon("--init"); }
    function goToday() { controller._runDaemon("--init"); }
    function prevMonth() { controller._runDaemon("--prev"); }
    function nextMonth() { controller._runDaemon("--next"); }

    function selectDay(date) {
        if (!date) return;
        controller._setLoading(true);
        selectProc.date = date;
        selectProc.running = false;
        selectProc.running = true;
    }

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

    function _daysFlat() {
        const out = [];
        const rows = controller.weeks || [];
        for (let w = 0; w < rows.length; w++) {
            const week = rows[w] || [];
            for (let d = 0; d < week.length; d++) {
                const day = week[d];
                if (day && day.in_month) out.push(day);
            }
        }
        return out;
    }

    function moveSelection(delta) {
        const days = controller._daysFlat();
        if (!days.length) return false;
        let idx = -1;
        for (let i = 0; i < days.length; i++) {
            if (days[i].date === controller.selectedDay) {
                idx = i;
                break;
            }
        }
        if (idx < 0) idx = 0;
        idx = Math.max(0, Math.min(days.length - 1, idx + delta));
        controller.selectDay(days[idx].date);
        return true;
    }

    function handleKey(event) {
        const k = event.key;
        if (k === Qt.Key_Left) return controller.moveSelection(-1);
        if (k === Qt.Key_Right) return controller.moveSelection(1);
        if (k === Qt.Key_Up) return controller.moveSelection(-7);
        if (k === Qt.Key_Down || k === Qt.Key_Tab) return controller.moveSelection(7);
        if (k === Qt.Key_PageUp) { controller.prevMonth(); return true; }
        if (k === Qt.Key_PageDown) { controller.nextMonth(); return true; }
        if (k === Qt.Key_Home || k === Qt.Key_T) { controller.goToday(); return true; }
        if (k === Qt.Key_R) { controller.refresh(); return true; }
        return false;
    }

    FileView {
        id: stateFile
        path: controller.statePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: controller._parseState(stateFile.text())
    }

    Process {
        id: daemonProc
        property var args: []
        running: false
        command: ["python3", controller.daemonPath].concat(args)
        onExited: function(code) {
            controller._setLoading(false);
            if (code === 0) controller._reloadState();
            else controller.calState = Object.assign({}, controller.calState || {}, { loading: false, error: "daemon_failed" });
        }
    }

    Process {
        id: selectProc
        property string date: ""
        running: false
        command: [controller.selectPath, date]
        onExited: function(code) {
            controller._setLoading(false);
            if (code === 0) controller._reloadState();
            else controller.calState = Object.assign({}, controller.calState || {}, { loading: false, error: "select_failed" });
        }
    }
}
