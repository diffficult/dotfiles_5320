import QtQuick

CardWindow {
    id: calendarPopup
    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 780
    layerNamespace: "warmind-calendar"
    title: ""
    subtitle: ""
    footer: "R REFRESH · T TODAY · PGUP/PGDN MONTH · ESC"

    anchorEdge: calendarPopup.root.barEdge
    anchorBarX: calendarPopup.root.popupAnchorX > 0 ? calendarPopup.root.popupAnchorX : (calendarPopup.width / 2)
    anchorBarY: calendarPopup.root.popupAnchorY

    onDismiss: calendarPopup.controller.close()
    onKeyPressed: function(event) {
        if (event.key === Qt.Key_Q) {
            calendarPopup.controller.close();
            event.accepted = true;
            return;
        }
        if (calendarPopup.controller.handleKey(event)) {
            event.accepted = true;
        }
    }

    CalendarPane {
        width: parent.width
        root: calendarPopup.root
        controller: calendarPopup.controller
        compact: false
    }
}
