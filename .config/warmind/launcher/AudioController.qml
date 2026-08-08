import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: controller

    required property var host
    property string audioIcon: ""
    property int audioVol: 0
    property bool audioMuted: false
    property var audioSinks: []
    property string audioDefaultSink: ""
    property string _audioSinksSer: ""
    property bool active: false
    property int inputVol: 0
    property bool inputMuted: false
    property string inputIcon: "󰍬"
    property var audioSources: []
    property string audioDefaultSource: ""
    property string _audioSourcesSer: ""
    readonly property bool inputReady: audioDefaultSource.length > 0
    readonly property var pipewireNodes: Pipewire.nodes ? Pipewire.nodes.values : []
    readonly property var inputNode: {
        for (let i = 0; i < pipewireNodes.length; ++i) {
            if (String(pipewireNodes[i].id) === audioDefaultSource)
                return pipewireNodes[i];

        }
        return null;
    }
    readonly property real inputPeak: Math.max(0, Math.min(1, inputPeakMonitor.peak || 0))

    function showOsd(kind, label, value, max, text, progress, muted) {
        if (controller.host && controller.host.osd)
            controller.host.osd.show(kind, label, value, max, text, progress, 1800, muted);
    }

    function defaultSinkName() {
        const sink = controller.audioSinks.find((s) => s.isDefault);
        return sink ? sink.name : "OUTPUT";
    }

    function defaultSourceName() {
        const source = controller.audioSources.find((s) => s.isDefault);
        return source ? source.name : "INPUT";
    }

    function setVolume(pct) {
        pct = Math.max(0, Math.min(150, Math.round(pct)));
        controller.audioVol = pct;
        controller.host.run("wpctl set-volume @DEFAULT_SINK@ " + (pct / 100).toFixed(2));
        controller.showOsd("volume", controller.defaultSinkName(), pct, 150, pct + "%", true, controller.audioMuted || pct <= 0);
    }

    function toggleMute() {
        controller.audioMuted = !controller.audioMuted;
        controller.host.run("wpctl set-mute @DEFAULT_SINK@ toggle");
        controller.showOsd("volume", controller.defaultSinkName(), controller.audioVol, 150, controller.audioMuted ? "MUTED" : controller.audioVol + "%", true, controller.audioMuted);
    }

    function setDefaultSink(id) {
        if (!id)
            return ;

        controller.audioDefaultSink = id;
        controller.host.run("wpctl set-default " + id);
        controller.refreshAudioSinks();
        controller.showOsd("volume", "OUTPUT", controller.audioVol, 150, "SINK " + id, false, false);
    }

    function setInputVolume(pct) {
        pct = Math.max(0, Math.min(150, Math.round(pct)));
        controller.inputVol = pct;
        controller.host.run("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + (pct / 100).toFixed(2));
        controller.showOsd("mic", controller.defaultSourceName(), pct, 150, pct + "%", true, controller.inputMuted || pct <= 0);
    }

    function toggleInputMute() {
        controller.inputMuted = !controller.inputMuted;
        controller.host.run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle");
        controller.showOsd("mic", controller.defaultSourceName(), controller.inputVol, 150, controller.inputMuted ? "MUTED" : controller.inputVol + "%", true, controller.inputMuted);
    }

    function setDefaultSource(id) {
        if (!id)
            return ;

        controller.audioDefaultSource = id;
        controller.host.run("wpctl set-default " + id);
        sourceRefreshDelay.restart();
        controller.showOsd("mic", "INPUT", controller.inputVol, 150, "SOURCE " + id, false, false);
    }

    function open() {
        controller.active = true;
        controller.refreshAll();
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

    function refreshAll() {
        audioProbe.running = false;
        audioProbe.running = true;
        inputProbe.running = false;
        inputProbe.running = true;
        controller.refreshAudioSinks();
        controller.refreshAudioSources();
    }

    function refreshAudioSinks() {
        audioSinksProbe.running = false;
        audioSinksProbe.running = true;
    }

    function refreshAudioSources() {
        audioSourcesProbe.running = false;
        audioSourcesProbe.running = true;
    }

    Process {
        id: audioProbe

        running: false
        command: ["bash", "-lc", "wpctl get-volume @DEFAULT_SINK@ 2>/dev/null || echo 'Volume: 0'"]

        stdout: StdioCollector {
            onStreamFinished: {
                const txt = this.text.trim();
                const m = txt.match(/Volume:\s*([\d.]+)/);
                const v = m ? Math.round(parseFloat(m[1]) * 100) : 0;
                const muted = txt.includes("[MUTED]");
                controller.audioVol = isNaN(v) ? 0 : v;
                controller.audioMuted = muted;
                if (muted)
                    controller.audioIcon = controller.host.icoMute;
                else if (isNaN(v) || v <= 0)
                    controller.audioIcon = controller.host.icoVol1;
                else if (v < 50)
                    controller.audioIcon = controller.host.icoVol2;
                else
                    controller.audioIcon = controller.host.icoVol3;
            }
        }

    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            audioProbe.running = false;
            audioProbe.running = true;
        }
    }

    Process {
        id: inputProbe

        running: false
        command: ["bash", "-lc", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || echo 'Volume: 0'"]

        stdout: StdioCollector {
            onStreamFinished: {
                const txt = this.text.trim();
                const m = txt.match(/Volume:\s*([\d.]+)/);
                const v = m ? Math.round(parseFloat(m[1]) * 100) : 0;
                const muted = txt.includes("[MUTED]");
                controller.inputVol = isNaN(v) ? 0 : v;
                controller.inputMuted = muted;
                controller.inputIcon = muted ? "󰍭" : "󰍬";
            }
        }

    }

    Timer {
        interval: 2000
        running: controller.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            inputProbe.running = false;
            inputProbe.running = true;
        }
    }

    Process {
        id: audioSinksProbe

        running: false
        command: ["bash", "-lc", "wpctl status 2>/dev/null | awk '" + "  /^Audio$/                                    {sec=\"audio\"; branch=\"\"; next}" + "  /^[A-Z][a-zA-Z]+$/                           {sec=\"\";      branch=\"\"; next}" + "  /^[[:space:]]*[├└]─[[:space:]]*Sinks:/       {branch=\"sinks\"; next}" + "  /^[[:space:]]*[├└]─/                          {branch=\"\";      next}" + "  sec==\"audio\" && branch==\"sinks\" {" + "    star=(index($0,\"*\")>0 && index($0,\"*\")<index($0,\".\")) ? 1 : 0;" + "    line=$0;" + "    sub(/^[ │├─└*]+/, \"\", line);" + "    if (match(line, /^([0-9]+)\\. (.+)\\[/, m)) {" + "      gsub(/[ \\t]+$/, \"\", m[2]);" + "      printf \"%s\\t%s\\t%d\\n\", m[1], m[2], star;" + "    }" + "  }'"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter((s) => {
                    return s.length > 0;
                });
                const sinks = lines.map((line) => {
                    const f = line.split("\t");
                    return {
                        "id": f[0] || "",
                        "name": (f[1] || "").trim(),
                        "isDefault": f[2] === "1"
                    };
                });
                const ser = JSON.stringify(sinks);
                if (ser !== controller._audioSinksSer) {
                    controller._audioSinksSer = ser;
                    controller.audioSinks = sinks;
                }
                const def = sinks.find((s) => {
                    return s.isDefault;
                });
                if (def && controller.audioDefaultSink !== def.id)
                    controller.audioDefaultSink = def.id;

            }
        }

    }

    Process {
        id: audioSourcesProbe

        running: false
        command: ["bash", "-lc", "wpctl status 2>/dev/null | awk '" + "  /^Audio$/                                    {sec=\"audio\"; branch=\"\"; next}" + "  /^[A-Z][a-zA-Z]+$/                           {sec=\"\";      branch=\"\"; next}" + "  /^[[:space:]]*[├└]─[[:space:]]*Sources:/     {branch=\"sources\"; next}" + "  /^[[:space:]]*[├└]─/                          {branch=\"\";      next}" + "  sec==\"audio\" && branch==\"sources\" {" + "    star=(index($0,\"*\")>0 && index($0,\"*\")<index($0,\".\")) ? 1 : 0;" + "    line=$0;" + "    sub(/^[ │├─└*]+/, \"\", line);" + "    if (match(line, /^([0-9]+)\\. (.+)\\[/, m)) {" + "      gsub(/[ \\t]+$/, \"\", m[2]);" + "      printf \"%s\\t%s\\t%d\\n\", m[1], m[2], star;" + "    }" + "  }'"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter((s) => {
                    return s.length > 0;
                });
                const sources = lines.map((line) => {
                    const f = line.split("\t");
                    return {
                        "id": f[0] || "",
                        "name": (f[1] || "").trim(),
                        "isDefault": f[2] === "1"
                    };
                });
                const ser = JSON.stringify(sources);
                if (ser !== controller._audioSourcesSer) {
                    controller._audioSourcesSer = ser;
                    controller.audioSources = sources;
                }
                const def = sources.find((s) => {
                    return s.isDefault;
                });
                if (def && controller.audioDefaultSource !== def.id)
                    controller.audioDefaultSource = def.id;

            }
        }

    }

    Timer {
        id: sourceRefreshDelay

        interval: 350
        repeat: false
        onTriggered: controller.refreshAll()
    }

    PwNodePeakMonitor {
        id: inputPeakMonitor

        node: controller.inputNode
        enabled: controller.active && !!controller.inputNode
    }

}
