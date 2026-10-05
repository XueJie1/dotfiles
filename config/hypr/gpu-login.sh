# Sourced by .zprofile for the SDDM Hyprland session only.
# Use /dev/dri/cardN paths here. PCI by-path names contain ':' and must not be
# placed in AQ_DRM_DEVICES, whose device separator is also ':'.
unset AQ_DRM_DEVICES

if [[ ! -e "$HOME/.config/hypr/gpu-auto-selection" ]]; then
    intel_card=/dev/dri/card1
    nvidia_card=/dev/dri/card0

    if [[ -c "$intel_card" && -r "$intel_card" && -w "$intel_card" &&
          -c "$nvidia_card" && -r "$nvidia_card" && -w "$nvidia_card" ]]; then
        export AQ_DRM_DEVICES="$nvidia_card:$intel_card"
    else
        printf '%s\n' 'Hyprland GPU selection: DRM devices unavailable; using automatic selection.' >&2
    fi
fi
