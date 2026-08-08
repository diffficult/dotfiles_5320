import QtQuick
import Quickshell
import Quickshell.Widgets
import QtQuick.Layouts

// Camera monitor popup. Lets the user select up to 4 feeds from a 16-channel
// NVR, pick a monitor/corner/workspace, and launch them as positioned mpv
// windows. Also serves as a toggle (close all if any are running).
CardWindow {
    id: camsPopup
    required property var root
    required property var controller

    theme: root
    revealed: controller.active
    cardWidth: 760
    layerNamespace: "warmind-cams"
    title: "CAMS"
    subtitle: controller.isRunning ? "RUNNING  ·  CLOSE ALL" : "SELECT FEEDS"

    onDismiss: controller.active = false
    onKeyPressed: function(event) {
        if (event.key === Qt.Key_Q || event.key === Qt.Key_Escape) {
            controller.active = false;
            event.accepted = true;
        }
    }

    Column {
        width: parent.width
        spacing: 16
        topPadding: 12
        bottomPadding: 16

        // ── Corner selector ────────────────────────────────
        Row {
            spacing: 12
            leftPadding: 16
            rightPadding: 16

            Text {
                text: "Corner"
                font.pixelSize: 16
                font.family: root.fontFamily
                color: root.ink
                anchors.verticalCenter: parent.verticalCenter
            }

            Repeater {
                model: [
                    { label: "󰧄 TL", value: "top-left" },
                    { label: "󰧆 TR", value: "top-right" },
                    { label: "󰦸 BL", value: "bottom-left" },
                    { label: "󰦺 BR", value: "bottom-right" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: 56
                    height: 32
                    radius: 6
                    color: controller.corner === modelData.value ? root.indigo : root.paper
                    border.color: controller.corner === modelData.value ? root.indigo : root.seal
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: 14
                        font.family: root.fontFamily
                        color: controller.corner === modelData.value ? "#ffffff" : root.ink
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: controller.corner = modelData.value
                    }
                }
            }
        }

        // ── Workspace selector ─────────────────────────────
        Row {
            spacing: 12
            leftPadding: 16
            rightPadding: 16

            Text {
                text: "Workspace"
                font.pixelSize: 16
                font.family: root.fontFamily
                color: root.ink
                anchors.verticalCenter: parent.verticalCenter
            }

            Repeater {
                model: ["", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
                delegate: Rectangle {
                    required property string modelData
                    width: modelData === "" ? 48 : 36
                    height: 32
                    radius: 6
                    color: controller.workspace === modelData ? root.indigo : root.paper
                    border.color: controller.workspace === modelData ? root.indigo : root.seal
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData === "" ? "Current" : modelData
                        font.pixelSize: 14
                        font.family: root.fontFamily
                        color: controller.workspace === modelData ? "#ffffff" : root.ink
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: controller.workspace = modelData
                    }
                }
            }
        }

        // ── Camera grid ────────────────────────────────────
        Grid {
            columns: 4
            spacing: 8
            leftPadding: 16
            rightPadding: 16

            Repeater {
                model: 16
                delegate: Rectangle {
                    required property int index
                    readonly property string camId: String(index + 1).padStart(2, "0")
                    readonly property bool isSelected: controller.selectedCams.includes(camId)

                    width: (camsPopup.cardWidth - 32 - 24) / 4
                    height: 48
                    radius: 6
                    color: isSelected ? root.indigo : root.paper
                    border.color: isSelected ? root.indigo : root.seal
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: camId
                        font.pixelSize: 16
                        font.family: root.fontFamily
                        font.bold: isSelected
                        color: isSelected ? "#ffffff" : root.ink
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            let ids = controller.selectedCams.slice();
                            const pos = ids.indexOf(camId);
                            if (pos >= 0) {
                                ids.splice(pos, 1);
                            } else if (ids.length < controller.maxFeeds) {
                                ids.push(camId);
                            }
                            controller.selectedCams = ids;
                        }
                    }
                }
            }
        }

        // ── Selected count + action buttons ────────────────
        Row {
            spacing: 12
            leftPadding: 16
            rightPadding: 16

            Text {
                text: controller.selectedCams.length + " / " + controller.maxFeeds + " selected"
                font.pixelSize: 14
                font.family: root.fontFamily
                color: root.seal
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: 20; height: 1 }

            Rectangle {
                width: 96
                height: 36
                radius: 6
                color: controller.selectedCams.length > 0 ? root.green : root.paper
                border.color: controller.selectedCams.length > 0 ? root.green : root.seal
                border.width: 1
                visible: !controller.isRunning

                Text {
                    anchors.centerIn: parent
                    text: "Launch"
                    font.pixelSize: 15
                    font.family: root.fontFamily
                    font.bold: true
                    color: controller.selectedCams.length > 0 ? "#ffffff" : root.ink
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (controller.selectedCams.length > 0) {
                            controller.launch(controller.selectedCams, controller.targetMonitor, controller.corner, controller.workspace);
                            controller.active = false;
                        }
                    }
                }
            }

            Rectangle {
                width: 110
                height: 36
                radius: 6
                color: controller.isRunning ? root.red : root.paper
                border.color: controller.isRunning ? root.red : root.seal
                border.width: 1
                visible: controller.isRunning

                Text {
                    anchors.centerIn: parent
                    text: "Close All"
                    font.pixelSize: 15
                    font.family: root.fontFamily
                    font.bold: true
                    color: controller.isRunning ? "#ffffff" : root.ink
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        controller.closeAll();
                        controller.active = false;
                    }
                }
            }
        }
    }
}
