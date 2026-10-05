import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

QuickToggleButton {
    id: root

    visible: AcpiPlatformProfile.available
    toggled: AcpiPlatformProfile.profile !== "balanced"
    buttonIcon: AcpiPlatformProfile.icon
    onClicked: AcpiPlatformProfile.cycle()

    StyledToolTip {
        text: `${Translation.tr("Energy Profile")}: ${AcpiPlatformProfile.profile}`
    }
}
