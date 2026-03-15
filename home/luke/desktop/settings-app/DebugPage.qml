import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    property string journalLog: "(loading...)"

    Flickable {
        anchors.fill: parent
        anchors.margins: 24
        contentHeight: col.implicitHeight
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 16

            Text { text: "Debug"; color: "white"; font.pixelSize: 20; font.weight: Font.Bold }

            GlassCard {
                Layout.fillWidth: true
                title: "User Journal (last 30 lines)"
                collapsible: true

                Rectangle {
                    width: parent.width
                    height: 250
                    radius: 8
                    color: Qt.rgba(0, 0, 0, 0.3)
                    clip: true

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 8
                        contentHeight: jText.implicitHeight

                        Text {
                            id: jText
                            width: parent.width
                            text: journalLog
                            color: Qt.rgba(1, 1, 1, 0.6)
                            font.pixelSize: 10
                            font.family: "monospace"
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            GlassCard {
                Layout.fillWidth: true
                title: "Quick Actions"

                Item {
                    width: parent.width
                    height: 36

                    Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "Reload Hyprland config"; color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 13 }

                    Rectangle {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: 80; height: 30; radius: 8
                        color: nrMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.1)
                        Text { anchors.centerIn: parent; text: "Reload"; color: Qt.rgba(1, 1, 1, 0.7); font.pixelSize: 12 }
                        MouseArea { id: nrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: hyprReload.running = true }
                    }
                }
            }
        }
    }

    Process { id: jReader; running: false; command: ["sh", "-c", "journalctl --user --no-pager -n 30 2>/dev/null || echo '(no journal)'"]; stdout: SplitParser { splitMarker: ""; onRead: data => journalLog = data } }
    Process { id: hyprReload; running: false; command: ["sh", "-c", "hyprctl reload 2>&1 || true"] }

    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: jReader.running = true }
}
