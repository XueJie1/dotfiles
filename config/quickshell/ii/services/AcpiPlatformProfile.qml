pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string profilePath: "/sys/firmware/acpi/platform_profile"
    readonly property list<string> profiles: [
        "low-power",
        "quiet",
        "balanced",
        "balanced-performance",
        "performance"
    ]
    property string profile: ""
    property bool profileRead: false
    readonly property bool available: profileRead && profile !== ""

    readonly property string icon: {
        switch (profile) {
        case "low-power": return "energy_savings_leaf"
        case "quiet": return "volume_down"
        case "balanced": return "balance"
        case "balanced-performance": return "speed"
        case "performance": return "local_fire_department"
        default: return "bolt"
        }
    }

    function cycle(): void {
        if (!root.available || setProfile.running)
            return;

        const currentIndex = root.profiles.indexOf(root.profile);
        const nextIndex = currentIndex < 0 ? 0 : (currentIndex + 1) % root.profiles.length;
        setProfile.targetProfile = root.profiles[nextIndex];
        setProfile.running = true;
    }

    Process {
        id: readProfile
        command: ["cat", root.profilePath]
        running: true

        stdout: StdioCollector {
            id: profileCollector
            onStreamFinished: {
                const value = profileCollector.text.trim();
                root.profile = root.profiles.includes(value) ? value : "";
                root.profileRead = true;
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.profile = "";
                root.profileRead = true;
            }
        }
    }

    Process {
        id: setProfile
        property string targetProfile: ""
        command: [
            "pkexec",
            "sh",
            "-c",
            `echo "$1" | tee ${root.profilePath}`,
            "quickshell-platform-profile",
            targetProfile
        ]

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.profile = targetProfile;
            else
                readProfile.running = true;
        }
    }
}
