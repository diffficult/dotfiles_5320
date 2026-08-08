import QtQuick

CardWindow {
    id: displayPopup
    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 480
    layerNamespace: "warmind-display"
    title: "DISPLAY"
    subtitle: controller.statusText()
    footer: "↑↓ ROW · ←→ ADJUST · ENTER ACTIVATE · ESC"

    anchorEdge: displayPopup.root.barEdge
    anchorBarX: displayPopup.root.popupAnchorX
    anchorBarY: displayPopup.root.popupAnchorY

    headerRight: CalendarChevron {
        root: displayPopup.root
        text: displayPopup.root.icoRefresh
        restColor: displayPopup.root.inkDeep
        font.pixelSize: 22
        onTriggered: displayPopup.controller.resetDisplay()
    }

    onDismiss: displayPopup.controller.close()
    onKeyPressed: function(event) {
        if (event.key === Qt.Key_Q) {
            displayPopup.controller.close();
            event.accepted = true;
            return;
        }
        if (popupBody.kbdHandle(event)) {
            event.accepted = true;
        }
    }

    QuickDisplayBody {
        id: popupBody
        width: parent.width
        root: displayPopup.root
        controller: displayPopup.controller
        onClose: displayPopup.controller.close()
    }
}
