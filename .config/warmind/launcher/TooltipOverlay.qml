import QtQuick
import Quickshell
import Quickshell.Wayland

// Click-through layer pinned above everything. Position is computed from
// the bar-window-local anchor (set by the hovered module) and the current
// barEdge so the tip sits just off the bar's inner edge, centred on the
// icon along the bar's axis.
PanelWindow {
    id: tooltipOverlay
    required property var root

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-tooltip"
    mask: Region {}

    // Keep alive briefly so the fade-out can play before the window is
    // torn down on first show; afterwards visibility tracks reveal.
    property real reveal: root.tooltipShown ? 1 : 0
    Behavior on reveal {
        NumberAnimation {
            duration: tooltipOverlay.root.tooltipShown ? 160 : 120
            easing.type: tooltipOverlay.root.tooltipShown ? Easing.OutCubic : Easing.InCubic
        }
    }
    visible: reveal > 0.001

    Rectangle {
        id: tip
        readonly property int gap:  6
        readonly property int padH: 8
        readonly property int padV: 3

        width:  tipLabel.implicitWidth  + padH * 2
        height: tipLabel.implicitHeight + padV * 2

        // X / Y derive from barEdge: the tip hugs the bar's inner edge
        // along the perpendicular axis and centres on the icon along the
        // parallel axis (clamped a few px from the screen edge so long
        // labels don't fall off-screen).
        x: {
            const r = tooltipOverlay.root;
            if (r.barEdge === "left")  return r.barHeight + gap;
            if (r.barEdge === "right") return parent.width - r.barHeight - width - gap;
            const center = r.tooltipBarX;
            return Math.max(4, Math.min(parent.width - width - 4, center - width / 2));
        }
        y: {
            const r = tooltipOverlay.root;
            if (r.barEdge === "top")    return r.barHeight + gap;
            if (r.barEdge === "bottom") return parent.height - r.barHeight - height - gap;
            const center = r.tooltipBarY;
            return Math.max(4, Math.min(parent.height - height - 4, center - height / 2));
        }

        color: tooltipOverlay.root.bg
        border.color: tooltipOverlay.root.sep
        border.width: 1
        radius: tooltipOverlay.root.cornerRadius
        opacity: tooltipOverlay.reveal

        Text {
            id: tipLabel
            anchors.centerIn: parent
            text: tooltipOverlay.root.tooltipText
            color: tooltipOverlay.root.ink
            font.family: tooltipOverlay.root.mono
            font.pixelSize: 10
            font.letterSpacing: 1
        }
    }
}
