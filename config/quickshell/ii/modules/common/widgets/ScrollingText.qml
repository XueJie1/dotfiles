import qs.modules.common
import QtQuick

// Single-line text that scrolls horizontally when it overflows.
// The scroll is driven by playback position (not a free-running animation),
// so it stays in sync when pausing or seeking. Its duration is the smaller of
// the natural reading speed and the gap until the next lyric line.
Item {
    id: root

    property string text: ""
    property int textPixelSize: Appearance.font.pixelSize.smallie
    property color textColor: Appearance.colors.colPrimary
    property real playbackPosition: 0
    property real lineStart: 0
    property real lineEnd: 0
    property real pixelsPerSecond: 42 // comfortable marquee speed
    property int endPadding: 6

    implicitWidth: 0
    implicitHeight: label.implicitHeight
    clip: true

    readonly property real overflow: Math.max(0, label.implicitWidth + root.endPadding - width)
    readonly property real gapMs: Math.max(0, (root.lineEnd - root.lineStart) * 1000)
    readonly property real naturalMs: root.overflow > 0
        ? (root.overflow / Math.max(1, root.pixelsPerSecond) * 1000) : 0
    // Finish before the next line arrives, but don't linger longer than needed.
    readonly property real scrollMs: root.overflow > 0
        ? Math.min(root.naturalMs, Math.max(700, root.gapMs - 200)) : 0
    readonly property real progress: root.scrollMs > 0
        ? Math.max(0, Math.min(1, (root.playbackPosition - root.lineStart) * 1000 / root.scrollMs)) : 0
    // Short lines fit: stay perfectly still, no animation at all.
    readonly property bool scrolling: root.overflow > 2 && root.scrollMs > 0

    property bool snap: false // skip animation right after a line change

    onTextChanged: {
        root.snap = true
        snapTimer.restart()
    }

    Timer {
        id: snapTimer
        interval: 60
        onTriggered: root.snap = false
    }

    StyledText {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        font.pixelSize: root.textPixelSize
        color: root.textColor
        x: root.scrolling
            ? -root.overflow * root.progress
            : (root.width - implicitWidth) / 2

        // Playback position is sampled a few times per second; smooth it out.
        Behavior on x {
            enabled: root.scrolling && !root.snap
            NumberAnimation { duration: 160; easing.type: Easing.Linear }
        }
    }
}
