import QtQuick
import Ryoku.PluginKit.Singletons

// The panel, styled after the qsbar Network panel: a "Power" header with a close
// button, SESSION / SYSTEM sections of outlined rows, and Power off as the solid
// primary button at the bottom. With "Ask before acting" on, the first click arms
// an action ("· confirm") and the second runs it; the arm drops after four seconds.
Item {
    id: root

    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 300
    property bool active: false

    readonly property var service: pluginApi ? pluginApi.mainInstance : null

    // Design tokens mirrored from qsbar/Theme.qml (the Network panel), expressed
    // through the plugin kit's Theme. The kit's Theme.radius is 0, so the 6px
    // button radius of the Network panel is held here.
    readonly property real btnRadius: 6 * root.s
    readonly property color sep: Theme.frameBorder                       // ink @ 18%
    readonly property color fillIdle: Qt.rgba(0, 0, 0, 0.12)
    readonly property color fillHover: Theme.frameBg                     // accent @ 10%
    readonly property color fillActive: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
    readonly property color fillPrimaryHover: Qt.lighter(Theme.accent, 1.15)

    readonly property var groups: [
        { title: "SESSION", ids: ["logout", "lock"] },
        { title: "SYSTEM",  ids: ["suspend", "hibernate", "reboot"] }
    ]

    function shown(id) {
        return root.service ? root.service.enabled(id) : false;
    }

    function labelFor(id) {
        var list = root.service ? root.service.actions : [];
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id)
                return list[i].label;
        }
        return id;
    }

    function isArmed(id) {
        return root.service !== null && root.service.armed === id;
    }

    // Flat model: a section label followed by its visible rows. A section whose
    // actions are all hidden in settings disappears with its label.
    readonly property var entries: {
        var out = [];
        for (var g = 0; g < root.groups.length; g++) {
            var visibleIds = root.groups[g].ids.filter(function(id) { return root.shown(id); });
            if (visibleIds.length === 0)
                continue;
            out.push({ kind: "label", text: root.groups[g].title, id: "" });
            for (var i = 0; i < visibleIds.length; i++)
                out.push({ kind: "row", text: "", id: visibleIds[i] });
        }
        return out;
    }

    implicitWidth: root.widthBudget
    implicitHeight: col.implicitHeight + 24 * root.s

    Column {
        id: col
        x: 12 * root.s
        y: 12 * root.s
        width: root.width - 24 * root.s
        spacing: 8 * root.s

        // ── header ──
        Item {
            width: col.width
            height: 24 * root.s

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Power"
                color: Theme.bright
                font.family: Theme.mono
                font.pixelSize: 13 * root.s
                font.letterSpacing: 2
                font.weight: Font.Medium
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "✕"
                color: closeArea.containsMouse ? Theme.accent : Theme.dim
                font.pixelSize: 12 * root.s
                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -4 * root.s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.pluginApi) root.pluginApi.closePanel()
                }
            }
        }

        Rectangle { width: col.width; height: 1; color: root.sep }

        // ── sections ──
        Column {
            width: col.width
            spacing: 4 * root.s
            visible: root.entries.length > 0

            Repeater {
                model: root.entries

                delegate: Item {
                    id: entry
                    required property var modelData
                    required property int index

                    readonly property bool isLabel: entry.modelData.kind === "label"
                    readonly property bool armedNow: !entry.isLabel && root.isArmed(entry.modelData.id)
                    readonly property bool hot: !entry.isLabel && area.containsMouse

                    width: col.width
                    // Labels after the first get extra headroom to separate the sections.
                    height: entry.isLabel ? (entry.index === 0 ? 16 : 24) * root.s : 30 * root.s

                    // section label
                    Text {
                        visible: entry.isLabel
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2 * root.s
                        text: entry.modelData.text
                        color: Theme.dim
                        font.family: Theme.mono
                        font.pixelSize: 10 * root.s
                        font.letterSpacing: 1
                    }

                    // action row (Network list row idiom)
                    Rectangle {
                        visible: !entry.isLabel
                        anchors.fill: parent
                        radius: root.btnRadius
                        color: entry.armedNow ? root.fillActive : (entry.hot ? root.fillHover : root.fillIdle)
                        border.width: 1
                        border.color: (entry.armedNow || entry.hot) ? Theme.accent : root.sep
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 8 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6 * root.s

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.labelFor(entry.modelData.id)
                                color: (entry.armedNow || entry.hot) ? Theme.accent : Theme.bright
                                font.family: Theme.mono
                                font.pixelSize: 11 * root.s
                                font.weight: entry.armedNow ? Font.Medium : Font.Normal
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Text {
                                visible: entry.armedNow
                                anchors.verticalCenter: parent.verticalCenter
                                text: "· confirm"
                                color: Theme.accent
                                font.family: Theme.mono
                                font.pixelSize: 9 * root.s
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 7 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            color: (entry.armedNow || entry.hot) ? Theme.accent : Theme.dim
                            font.family: Theme.mono
                            font.pixelSize: 13 * root.s
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            enabled: !entry.isLabel
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.service) root.service.run(entry.modelData.id)
                        }
                    }
                }
            }
        }

        // ── primary action: Power off ──
        Rectangle {
            width: col.width
            height: 1
            color: root.sep
            visible: root.shown("poweroff") && root.entries.length > 0
        }

        Rectangle {
            id: powerOff
            readonly property bool armedNow: root.isArmed("poweroff")

            visible: root.shown("poweroff")
            width: col.width
            height: 28 * root.s
            radius: root.btnRadius
            color: (powerOffArea.containsMouse || powerOff.armedNow) ? root.fillPrimaryHover : Theme.accent
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: powerOff.armedNow ? "Click again to power off" : root.labelFor("poweroff")
                color: Theme.cardBot
                font.family: Theme.mono
                font.pixelSize: 11 * root.s
                font.weight: powerOff.armedNow ? Font.Medium : Font.Normal
            }

            MouseArea {
                id: powerOffArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.service) root.service.run("poweroff")
            }
        }
    }
}
