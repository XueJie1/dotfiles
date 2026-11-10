pragma Singleton
pragma ComponentBehavior: Bound

// Synced-lyrics backend for the bar media widget.
// Adapted from end4-pC (illogical-impulse fork)'s LyricsService.
// The fetcher tries the MyGo/Navidrome library first, then online sources.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    // Prefer a player that reports an artist (music apps) over browser/video
    // players, which usually only expose a title. Falls back to the active player.
    function artistCandidates() {
        return Mpris.players.values.filter(p =>
            String(p.trackTitle ?? "").trim() !== "" &&
            String(p.trackArtist ?? "").trim() !== "")
    }

    readonly property var preferredPlayer: {
        const active = MprisController.activePlayer
        if (active && String(active.trackArtist ?? "").trim() !== "")
            return active
        const candidates = artistCandidates()
        return candidates.find(p => p.isPlaying) ?? candidates[0] ?? active
    }

    readonly property MprisPlayer player: preferredPlayer

    property var lines: []
    property int activeIndex: -1
    property string status: "idle" // idle | loading | ok | not_found | no_info
    property string source: ""
    property string loadedKey: ""
    property real position: 0

    readonly property string currentLine: (activeIndex >= 0 && activeIndex < lines.length)
        ? (lines[activeIndex].text ?? "") : ""
    readonly property string nextLine: (activeIndex + 1 >= 0 && activeIndex + 1 < lines.length)
        ? (lines[activeIndex + 1].text ?? "") : ""
    readonly property real lineStart: (activeIndex >= 0 && activeIndex < lines.length)
        ? (lines[activeIndex].t ?? 0) : 0
    readonly property real lineEnd: {
        if (activeIndex < 0 || activeIndex >= lines.length) return 0
        if (activeIndex + 1 < lines.length) return Math.max(lineStart, lines[activeIndex + 1].t ?? lineStart)
        return lineStart + 5 // last line: no next timestamp to lean on
    }

    function syncPosition() {
        const pos = player?.position ?? 0
        position = pos
        let idx = -1
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].t <= pos + 0.12) idx = i
            else break
        }
        if (idx !== activeIndex)
            activeIndex = idx
    }

    // Quickshell interpolates position from the last MPRIS sample, so reading
    // it on a tick is enough; no D-Bus polling needed.
    Timer {
        interval: 100
        repeat: true
        running: root.status === "ok" && root.lines.length > 0 && (root.player?.isPlaying ?? false)
        onTriggered: root.syncPosition()
    }

    Process {
        id: lyricsProc
        running: false

        stdout: SplitParser {
            onRead: data => {
                const text = String(data ?? "").trim()
                if (text === "") return
                let payload
                try {
                    payload = JSON.parse(text)
                } catch (e) {
                    return
                }
                if (payload.status !== "ok" || !payload.lines || payload.lines.length === 0) {
                    root.lines = []
                    root.activeIndex = -1
                    root.status = payload.status || "not_found"
                    return
                }
                root.lines = payload.lines
                root.source = payload.source || ""
                root.activeIndex = -1
                root.status = "ok"
                root.syncPosition()
            }
        }
    }

    function refresh(force) {
        const title = String(player?.trackTitle ?? "").trim()
        const artist = String(player?.trackArtist ?? "").trim()
        const length = Math.round(player?.length ?? 0)
        const key = `${title}\u0001${artist}\u0001${length}`

        if (title === "") {
            loadedKey = ""
            lines = []
            activeIndex = -1
            status = "no_info"
            return
        }
        if (!force && key === loadedKey) return

        loadedKey = key
        lines = []
        activeIndex = -1
        status = "loading"

        lyricsProc.running = false
        lyricsProc.command = [
            "python3",
            `${Directories.scriptPath}/lyrics/lyrics.py`,
            title, artist, String(length)
        ]
        lyricsProc.running = true
    }

    Connections {
        target: root.player
        function onTrackTitleChanged() { root.refresh() }
        function onTrackArtistChanged() { root.refresh() }
        function onPlaybackStateChanged() { root.syncPosition() }
        function onPositionChanged() { root.syncPosition() } // seeks while paused
    }

    onPlayerChanged: refresh()
    Component.onCompleted: refresh()
}
