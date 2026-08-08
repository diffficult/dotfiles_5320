import QtQuick

Item {
    id: body
    required property var root
    required property var controller
    width: parent ? parent.width : 0

    signal close()

    implicitHeight: pane.implicitHeight + 8

    function kbdHandle(event) {
        return body.controller ? body.controller.handleKey(event) : false;
    }

    Component.onCompleted: {
        if (body.controller && !body.controller.loaded) body.controller.refresh();
    }

    CalendarPane {
        id: pane
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 6
        root: body.root
        controller: body.controller
        compact: true
    }
}
