import QtQuick
import Ryoku.PluginKit.Singletons

// The panel: one row per action. With "Ask before acting" on, the first click
// arms a row ("Click again to confirm") and the second runs it; the arm drops
// after four seconds.
Item {
    id: root

    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 260
    property bool active: false

    readonly property var service: pluginApi ? pluginApi.mainInstance : null

    implicitWidth: root.widthBudget
    implicitHeight: col.implicitHeight + 24 * root.s

    Column {
        id: col
        x: 12 * root.s
        y: 12 * root.s
        width: root.width - 24 * root.s
        spacing: 6 * root.s

        Repeater {
            model: root.service ? root.service.actions : []

            delegate: Rectangle {
                id: row
                required property var modelData

                readonly property bool armedNow: root.service && root.service.armed === row.modelData.id

                visible: root.service ? root.service.enabled(row.modelData.id) : false
                width: col.width
                height: visible ? 38 * root.s : 0
                radius: Theme.radius
                color: row.armedNow ? Theme.accent : (area.containsMouse ? Theme.cardBot : "transparent")
                border.width: 1
                border.color: row.armedNow ? Theme.accent : Theme.dim

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12 * root.s
                    text: row.armedNow ? "Click again to confirm: " + row.modelData.label : row.modelData.label
                    color: row.armedNow ? Theme.cardBot : Theme.bright
                    font.family: Theme.font
                    font.pixelSize: 13 * root.s
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: if (root.service) root.service.run(row.modelData.id)
                }
            }
        }
    }
}
