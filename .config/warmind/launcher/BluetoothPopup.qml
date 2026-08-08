import QtQuick

CardWindow {
    id: bluetoothPopup
    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 520
    layerNamespace: "warmind-bluetooth"
    title: "BLUETOOTH"
    subtitle: !controller.powered ? "POWER OFF"
        : controller.count > 0 ? controller.count + " CONNECTED"
        : controller.scanning ? "SCANNING" : "READY"
    footer: "↑↓ ROW · ENTER ACTIVATE · R REFRESH · ESC CLOSE"

    anchorEdge: bluetoothPopup.root.barEdge
    anchorBarX: bluetoothPopup.root.popupAnchorX > 0
        ? bluetoothPopup.root.popupAnchorX : bluetoothPopup.width / 2
    anchorBarY: bluetoothPopup.root.popupAnchorY

    headerRight: CalendarChevron {
        root: bluetoothPopup.root
        text: bluetoothPopup.root.icoRefresh
        restColor: bluetoothPopup.root.inkDeep
        font.pixelSize: 22
        onTriggered: bluetoothPopup.controller.refreshAll()
    }

    onDismiss: bluetoothPopup.controller.close()
    onKeyPressed: function(event) {
        if (event.key === Qt.Key_R) {
            bluetoothPopup.controller.refreshAll();
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Q) {
            bluetoothPopup.controller.close();
            event.accepted = true;
            return;
        }
        if (popupBody.kbdHandle(event)) event.accepted = true;
    }

    Flickable {
        id: deviceScroller
        width: parent.width
        height: Math.min(500, Math.max(140, popupBody.implicitHeight))
        contentWidth: width
        contentHeight: popupBody.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        QuickBluetoothBody {
            id: popupBody
            width: deviceScroller.width
            root: bluetoothPopup.root
            controller: bluetoothPopup.controller
            scroller: deviceScroller
            onClose: bluetoothPopup.controller.close()
        }
    }
}
