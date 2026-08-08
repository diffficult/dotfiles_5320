import QtQuick
import QtQuick.Layouts

Rectangle {
    required property var root

    Layout.alignment: root.isHorizontal ? Qt.AlignVCenter : Qt.AlignHCenter
    Layout.preferredWidth:  root.isHorizontal ? 1  : 12
    Layout.preferredHeight: root.isHorizontal ? 12 : 1
    Layout.leftMargin:   root.isHorizontal ? 4 : 0
    Layout.rightMargin:  root.isHorizontal ? 4 : 0
    Layout.topMargin:    root.isHorizontal ? 0 : 4
    Layout.bottomMargin: root.isHorizontal ? 0 : 4
    color: root.sep
}
