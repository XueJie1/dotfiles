import QtQuick
import qs
import qs.services

QuickToggleModel {
    name: Translation.tr("Energy Profile")
    available: AcpiPlatformProfile.available
    toggled: AcpiPlatformProfile.profile !== "balanced"
    icon: AcpiPlatformProfile.icon
    statusText: AcpiPlatformProfile.profile
    mainAction: () => AcpiPlatformProfile.cycle()
    tooltipText: Translation.tr("Click to cycle through platform profiles")
}
