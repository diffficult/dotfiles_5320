import QtQuick

Item {
    id: controller

    property bool active: false
    property string kind: "status"
    property string glyph: "󰍡"
    property string label: ""
    property string text: ""
    property int value: 0
    property int max: 100
    property bool progress: false
    property int duration: 1800

    function glyphFor(nextKind, nextValue, muted) {
        const v = Math.max(0, Math.min(100, Number(nextValue) || 0));
        if (nextKind === "volume") {
            if (muted || v <= 0) return "󰝟";
            if (v < 50) return "󰕿";
            if (v < 85) return "󰖀";
            return "󰕾";
        }
        if (nextKind === "mic") return muted ? "󰍭" : "󰍬";
        if (nextKind === "brightness") return "󰃠";
        if (nextKind === "warmth") return "󰖨";
        if (nextKind === "gamma") return "󰃟";
        if (nextKind === "media") return "󰝚";
        return "󰍡";
    }

    function show(nextKind, nextLabel, nextValue, nextMax, nextText, hasProgress, nextDuration, muted) {
        controller.kind = nextKind || "status";
        controller.label = nextLabel || "";
        controller.value = Math.max(0, Math.round(Number(nextValue) || 0));
        controller.max = Math.max(1, Math.round(Number(nextMax) || 100));
        controller.text = nextText || (hasProgress ? controller.value + "%" : "");
        controller.progress = !!hasProgress;
        controller.duration = Math.max(250, Math.round(Number(nextDuration) || 1800));
        controller.glyph = controller.glyphFor(controller.kind, controller.max > 0 ? controller.value * 100 / controller.max : controller.value, !!muted);
        controller.active = true;
        hideTimer.restart();
    }

    function showPayload(payloadJson) {
        try {
            const p = JSON.parse(payloadJson || "{}");
            controller.show(
                p.kind || "status",
                p.label || "",
                p.value === undefined ? 0 : p.value,
                p.max === undefined ? 100 : p.max,
                p.text || "",
                p.progress === undefined ? p.value !== undefined : p.progress,
                p.duration === undefined ? 1800 : p.duration,
                !!p.muted
            );
            return true;
        } catch (e) {
            return false;
        }
    }

    function close() {
        controller.active = false;
        hideTimer.stop();
    }

    Timer {
        id: hideTimer
        interval: controller.duration
        repeat: false
        onTriggered: controller.active = false
    }
}
