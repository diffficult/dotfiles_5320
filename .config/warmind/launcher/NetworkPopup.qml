import QtQuick

CardWindow {
    id: networkPopup
    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 700
    layerNamespace: "warmind-network"
    title: "NETWORK"
    subtitle: controller.kind === "wifi"
        ? (controller.label || "WI-FI")
        : controller.kind === "ethernet" ? "ETHERNET"
        : controller.nmAvailable ? "DISCONNECTED" : "NETWORKMANAGER UNAVAILABLE"
    footer: "↑↓ ROW · ENTER ACTIVATE · R REFRESH · Q QR · S SPEED · ESC CLOSE"

    anchorEdge: networkPopup.root.barEdge
    anchorBarX: networkPopup.root.popupAnchorX > 0
        ? networkPopup.root.popupAnchorX : networkPopup.width / 2
    anchorBarY: networkPopup.root.popupAnchorY

    headerRight: CalendarChevron {
        root: networkPopup.root
        text: networkPopup.root.icoRefresh
        restColor: networkPopup.root.inkDeep
        font.pixelSize: 22
        onTriggered: networkPopup.controller.refresh()
    }

    onDismiss: networkPopup.controller.close()
    onKeyPressed: function(event) {
        if (event.key === Qt.Key_R) {
            networkPopup.controller.refresh();
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Q) {
            networkPopup.controller.close();
            event.accepted = true;
            return;
        }
        if (popupBody.kbdHandle(event)) event.accepted = true;
    }

    Flickable {
        id: networkScroller
        width: parent.width
        height: Math.min(660, Math.max(180, popupBody.implicitHeight))
        contentWidth: width
        contentHeight: popupBody.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        QuickWifiBody {
            id: popupBody
            width: networkScroller.width
            root: networkPopup.root
            nav: networkPopup.root
            controller: networkPopup.controller
            onClose: networkPopup.controller.close()
        }
    }
}
