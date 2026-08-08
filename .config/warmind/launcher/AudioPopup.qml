import QtQuick

CardWindow {
    id: audioPopup

    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 500
    layerNamespace: "warmind-audio"
    title: "AUDIO"
    subtitle: controller.audioMuted ? "OUTPUT MUTED" : controller.audioVol + "% OUTPUT"
    footer: "↑↓ ROW · ←→ ADJUST · ENTER ACTIVATE · ESC CLOSE"
    anchorEdge: audioPopup.root.barEdge
    anchorBarX: audioPopup.root.popupAnchorX > 0 ? audioPopup.root.popupAnchorX : audioPopup.width / 2
    anchorBarY: audioPopup.root.popupAnchorY
    onDismiss: audioPopup.controller.close()
    onKeyPressed: function(event) {
        if (event.key === Qt.Key_Q) {
            audioPopup.controller.close();
            event.accepted = true;
            return ;
        }
        if (popupBody.kbdHandle(event))
            event.accepted = true;

    }

    QuickAudioBody {
        id: popupBody

        width: parent.width
        root: audioPopup.root
        controller: audioPopup.controller
        onClose: audioPopup.controller.close()
    }

    headerRight: CalendarChevron {
        root: audioPopup.root
        text: audioPopup.root.icoRefresh
        restColor: audioPopup.root.inkDeep
        font.pixelSize: 22
        onTriggered: audioPopup.controller.refreshAll()
    }

}
