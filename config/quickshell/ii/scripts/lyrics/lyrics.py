#!/usr/bin/env python3
"""Fetch synced lyrics for the currently playing MPRIS track.

Source order:
  1. The Navidrome/Subsonic server configured in MyGo (username + password
     from MyGo's settings and the system keyring). Timestamps come straight
     from the library, so no fuzzy online matching is needed.
  2. NetEase Cloud Music (best online coverage for Chinese tracks).
  3. LRCLIB.

Usage: lyrics.py <title> <artist> <duration-seconds>
Output: one line of JSON:
    {"status": "ok", "source": "subsonic", "lines": [{"t": 12.34, "text": "..."}]}
    {"status": "not_found"} / {"status": "no_info"}
"""

import hashlib
import json
import os
import re
import secrets
import shutil
import subprocess
import sys
import urllib.parse
import urllib.request

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
TIMEOUT = 10

MYGO_SETTINGS = os.path.expanduser("~/.config/MyGo 云音乐/settings.json")
MYGO_SECRET_SERVICE = "dev.egoist.cloudmusic"
MYGO_SECRET_ACCOUNT = "navidrome-credentials"

STAMP_RE = re.compile(r"\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]")
# Enhanced LRC / karaoke word timestamps, e.g. "[00:12.34]<00:12.34>word..."
WORD_STAMP_RE = re.compile(r"<\d{1,3}:\d{1,2}(?:[.:]\d{1,3})?>")
# NetEase yrc: "[start_ms,duration_ms](word_start,word_dur,0)word..."
YRC_LINE_RE = re.compile(r"^\[(\d+),(\d+)\](.*)$")
YRC_WORD_RE = re.compile(r"\(\d+,\d+,\d+\)")
# Credit lines ("音乐制作 : ...", "作词：...") are not lyrics.
CREDIT_RE = re.compile(
    r"^\s*(作词|作曲|编曲|制作人?|音乐制作|监制|混音|母带|录音|演唱|原唱|"
    r"出品|吉他|合声|和声|音频编辑|人声|弦乐|贝斯|键盘|钢琴|词|曲)"
    r"[^:：]{0,12}[:：]")


def http_get(url, headers=None):
    req = urllib.request.Request(url, headers={"User-Agent": UA, **(headers or {})})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        return resp.read().decode("utf-8", "replace")


def http_post(url, data, headers=None):
    body = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(
        url, data=body,
        headers={"User-Agent": UA, "Content-Type": "application/x-www-form-urlencoded",
                 **(headers or {})})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        return resp.read().decode("utf-8", "replace")


def norm(text):
    """Loose comparison key: keep letters/digits/CJK, drop punctuation and case."""
    return re.sub(r"[\W_]+", "", (text or "").lower())


def parse_lrc(lrc_text):
    """Parse LRC text into a sorted [{time, text}] list."""
    found = {}
    for raw in (lrc_text or "").splitlines():
        stamps = STAMP_RE.findall(raw)
        if not stamps:
            continue
        text = WORD_STAMP_RE.sub("", STAMP_RE.sub("", raw)).strip()
        for minutes, seconds, fraction in stamps:
            t = int(minutes) * 60 + int(seconds)
            if fraction:
                t += float("0." + fraction)
            found.setdefault(round(t, 3), text)
    return [{"t": t, "text": found[t]} for t in sorted(found)]


def parse_yrc(yrc_text):
    """Parse NetEase word-by-word yrc into line-level entries."""
    lines = []
    for raw in (yrc_text or "").splitlines():
        match = YRC_LINE_RE.match(raw.strip())
        if not match:
            continue
        text = YRC_WORD_RE.sub("", match.group(3)).strip()
        if text:
            lines.append({"t": round(int(match.group(1)) / 1000.0, 3), "text": text})
    return sorted(lines, key=lambda line: line["t"])


def title_matches(wanted, candidate):
    a, b = norm(wanted), norm(candidate)
    if not a or not b:
        return False
    if a == b or a in b or b in a:
        return True
    # Word-level match, useful for titles like "Song (Live)" vs "Song"
    for word in re.split(r"[\s\-_/]+", wanted.lower()):
        if len(word) > 2 and norm(word) and norm(word) in b:
            return True
    return False


def artist_matches(wanted, candidate):
    if not wanted or not candidate:
        return False
    a, b = norm(wanted), norm(candidate)
    return a in b or b in a


# ---------------------------------------------------------------- Subsonic

def mygo_server():
    """(address, username, password) from MyGo's settings + keyring, or None."""
    try:
        with open(MYGO_SETTINGS, encoding="utf-8") as handle:
            settings = json.load(handle)
        if settings.get("platform") != "navidrome":
            return None
        config = (settings.get("navidrome") or {}).get("config") or {}
        address = (config.get("address") or "").rstrip("/")
        username = config.get("username") or ""
        if not address or not username:
            return None

        tool = shutil.which("secret-tool")
        if not tool:
            return None
        env = dict(os.environ)
        if not env.get("DBUS_SESSION_BUS_ADDRESS"):
            runtime = env.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
            bus = os.path.join(runtime, "bus")
            if os.path.exists(bus):
                env["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path={bus}"
        result = subprocess.run(
            [tool, "lookup", "service", MYGO_SECRET_SERVICE,
             "account", MYGO_SECRET_ACCOUNT],
            capture_output=True, text=True, timeout=5, env=env)
        if result.returncode != 0 or not result.stdout.strip():
            return None
        password = (json.loads(result.stdout).get("password") or "")
        if not password:
            return None
        return address, username, password
    except Exception:
        return None


def subsonic_get(address, username, password, method, params):
    """OpenSubsonic request with salted-token auth (no password in the URL)."""
    salt = secrets.token_hex(6)
    token = hashlib.md5((password + salt).encode("utf-8")).hexdigest()
    query = {
        "u": username, "t": token, "s": salt,
        "v": "1.16.1", "c": "quickshell-lyrics", "f": "json",
    }
    query.update(params)
    url = f"{address}/rest/{method}.view?" + urllib.parse.urlencode(query)
    payload = json.loads(http_get(url))
    return payload.get("subsonic-response") or {}


def fetch_subsonic(title, artist, duration):
    server = mygo_server()
    if not server:
        return []
    address, username, password = server

    found = subsonic_get(address, username, password, "search3", {
        "query": f"{title} {artist}".strip(),
        "songCount": 10, "artistCount": 0, "albumCount": 0,
    })
    songs = (found.get("searchResult3") or {}).get("song") or []

    ranked = []
    for song in songs:
        song_title = song.get("title") or song.get("name") or ""
        if not title_matches(title, song_title):
            continue
        score = 1.0
        if artist_matches(artist, song.get("artist") or ""):
            score += 2
        try:
            song_duration = float(song.get("duration") or 0)
            if duration and song_duration:
                delta = abs(song_duration - duration)
                score += 2 if delta <= 5 else (0.5 if delta <= 20 else 0)
        except (TypeError, ValueError):
            pass
        ranked.append((score, song))
    ranked.sort(key=lambda item: item[0], reverse=True)

    for _, song in ranked[:3]:
        try:
            lyrics = subsonic_get(address, username, password,
                                  "getLyricsBySongId", {"id": song["id"]})
        except Exception:
            continue
        entries = (lyrics.get("lyricsList") or {}).get("structuredLyrics") or []
        for entry in entries:
            if entry.get("synced") is False:
                continue
            lines = []
            for line in entry.get("line") or []:
                text = (line.get("value") or "").strip()
                start = line.get("start")
                if text and isinstance(start, (int, float)):
                    lines.append({"t": round(float(start) / 1000.0, 3), "text": text})
            if len({line["t"] for line in lines}) < 2:
                continue  # unsynced: every line shares the same timestamp
            lines.sort(key=lambda line: line["t"])
            return lines
    return []


# ---------------------------------------------------------------- NetEase

def netease_search(title, artist):
    try:
        payload = http_post(
            "https://music.163.com/api/search/get/web",
            {"s": f"{title} {artist}".strip(), "type": 1, "offset": 0, "limit": 10},
            {"Referer": "https://music.163.com/"},
        )
        songs = (json.loads(payload).get("result") or {}).get("songs") or []
    except Exception:
        return None

    best, best_score = None, 0
    for song in songs:
        name = song.get("name") or ""
        artists = " ".join(a.get("name", "") for a in song.get("artists") or [])
        if not title_matches(title, name):
            continue
        score = 1
        if artist_matches(artist, artists):
            score += 2
        duration = song.get("duration") or 0
        if duration and duration / 1000.0 > 0:
            # duration is compared later; keep it as a tie-breaker
            score += 0.5
        if score > best_score:
            best, best_score = song, score
    return best


def fetch_netease(title, artist):
    song = netease_search(title, artist)
    if not song:
        return []
    try:
        payload = http_get(
            f"https://music.163.com/api/song/lyric?id={song['id']}&lv=-1&tv=-1&kv=-1&yv=-1",
            {"Referer": "https://music.163.com/"},
        )
        data = json.loads(payload)
    except Exception:
        return []
    if data.get("nolyric"):
        return []
    lines = parse_lrc((data.get("lrc") or {}).get("lyric") or "")
    if not lines:
        # Some karaoke-only entries ship word-timed yrc without plain lrc.
        lines = parse_yrc((data.get("yrc") or {}).get("lyric") or "")
    return lines


# ---------------------------------------------------------------- LRCLIB

def fetch_lrclib(title, artist, duration):
    urls = [
        "https://lrclib.net/api/get?" + urllib.parse.urlencode(
            {"track_name": title, "artist_name": artist, "duration": int(duration)}),
        "https://lrclib.net/api/search?" + urllib.parse.urlencode(
            {"track_name": title, "artist_name": artist}),
        "https://lrclib.net/api/search?" + urllib.parse.urlencode(
            {"q": f"{title} {artist}"}),
    ]
    for url in urls:
        try:
            data = json.loads(http_get(url))
        except Exception:
            continue
        if isinstance(data, list):
            data = next((d for d in data
                         if d.get("syncedLyrics") and title_matches(title, d.get("trackName", ""))),
                        None)
        if not data or not data.get("syncedLyrics"):
            continue
        if not title_matches(title, data.get("trackName", "")):
            continue
        lines = parse_lrc(data["syncedLyrics"])
        if lines:
            return lines
    return []


def clean(lines):
    """Drop the credit lines that library/karaoke lyrics often include."""
    result = [line for line in lines
              if line["text"] and not CREDIT_RE.match(line["text"])]
    return result or lines


def main():
    if len(sys.argv) < 4:
        print(json.dumps({"status": "no_info"}, ensure_ascii=False))
        return
    title, artist = sys.argv[1].strip(), sys.argv[2].strip()
    try:
        duration = float(sys.argv[3])
    except ValueError:
        duration = 0.0
    if not title:
        print(json.dumps({"status": "no_info"}, ensure_ascii=False))
        return

    for source, fetch in (
        ("subsonic", lambda: fetch_subsonic(title, artist, duration)),
        ("netease", lambda: fetch_netease(title, artist)),
        ("lrclib", lambda: fetch_lrclib(title, artist, duration)),
    ):
        try:
            lines = clean(fetch())
        except Exception:
            lines = []
        if lines:
            print(json.dumps({"status": "ok", "source": source, "lines": lines},
                             ensure_ascii=False, separators=(",", ":")))
            return

    print(json.dumps({"status": "not_found"}, ensure_ascii=False))


if __name__ == "__main__":
    main()
