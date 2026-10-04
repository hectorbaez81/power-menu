pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// Logic only: the six session actions, the arm-then-confirm flow and the
// per-action visibility settings. The widget and the panel share this instance.
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

    readonly property bool confirm: settings && settings.confirm !== undefined ? settings.confirm : true

    readonly property var actions: [
        { id: "logout",    label: "Log out",   needsConfirm: true  },
        { id: "lock",      label: "Lock",      needsConfirm: false },
        { id: "suspend",   label: "Suspend",   needsConfirm: true  },
        { id: "hibernate", label: "Hibernate", needsConfirm: true  },
        { id: "reboot",    label: "Reboot",    needsConfirm: true  },
        { id: "poweroff",  label: "Power off", needsConfirm: true  }
    ]

    // id of the action waiting for its confirming second click, or "".
    property string armed: ""

    function enabled(id) {
        var key = "show_" + id;
        return settings && settings[key] !== undefined ? settings[key] : true;
    }

    function argvFor(id) {
        switch (id) {
        case "logout":    return ["hyprctl", "dispatch", "hl.dsp.exit()"];
        case "lock":      return ["ryoku-shell", "lock"];
        case "suspend":   return ["ryoku-shell", "suspend"];
        case "hibernate": return [svc.pluginApi.pluginDir + "/bin/hibernate.sh"];
        case "reboot":    return ["systemctl", "reboot"];
        case "poweroff":  return ["systemctl", "poweroff"];
        }
        return [];
    }

    function run(id) {
        var needs = false;
        for (var i = 0; i < actions.length; i++) {
            if (actions[i].id === id)
                needs = actions[i].needsConfirm;
        }
        if (svc.confirm && needs && svc.armed !== id) {
            svc.armed = id;
            disarm.restart();
            return;
        }
        svc.armed = "";
        disarm.stop();
        var argv = svc.argvFor(id);
        if (argv.length > 0)
            Quickshell.execDetached(argv);
        if (svc.pluginApi)
            svc.pluginApi.closePanel();
    }

    Timer {
        id: disarm
        interval: 4000
        onTriggered: svc.armed = ""
    }
}
