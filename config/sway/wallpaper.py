#!/usr/bin/python
"""Sway wallpaper and one Matugen invocation per startup/change/tool open."""
import configparser
import fcntl
import json
import os
from pathlib import Path
import random
import signal
import subprocess
import sys

ROOT = Path.home() / '.config/sway'
STATE = Path.home() / '.local/state/sway'
CONFIG = ROOT / 'waypaper.ini'
IMAGES = {'.jpg', '.jpeg', '.png', '.webp', '.bmp'}
VIDEOS = {'.mp4', '.mkv', '.webm', '.mov'}

def main():
    # Do not apply a Sway wallpaper to another compositor.
    subprocess.run(['swaymsg', '-t', 'get_version'], check=True, stdout=subprocess.DEVNULL)
    STATE.mkdir(parents=True, exist_ok=True)
    mode = sys.argv[1] if len(sys.argv) > 1 else 'startup'
    with (STATE / 'wallpaper.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if mode == 'apply':
            path = Path(sys.argv[2])
        elif mode == 'random':
            path = random.choice([p for p in (Path.home() / 'Pictures/wallpapers').iterdir()
                                  if p.is_file() and p.suffix.lower() in IMAGES])
        elif mode == 'video':
            path = random.choice([p for p in (Path.home() / 'Videos').rglob('*')
                                  if p.is_file() and p.suffix.lower() in VIDEOS])
        else:
            try:
                path = Path(json.loads((STATE / 'wallpaper.json').read_text())['path'])
            except (OSError, ValueError, KeyError):
                cf = configparser.ConfigParser(interpolation=None)
                cf.read(CONFIG)
                path = Path(cf.get('Settings', 'wallpaper')).expanduser()
        path = path.expanduser().resolve(strict=True)
        if not path.is_file():
            raise ValueError('Wallpaper must be a file')
        image = path
        if path.suffix.lower() in VIDEOS:
            image = STATE / 'wallpaper-frame.png'
            subprocess.run(['ffmpeg', '-y', '-hide_banner', '-loglevel', 'error',
                            '-i', str(path), '-frames:v', '1', '-an', str(image)], check=True)
        try:
            data = json.loads((STATE / 'mpvpaper.json').read_text())
            proc = Path('/proc') / str(data['pid'])
            # Avoid signalling a reused PID or another desktop's wallpaper process.
            if proc.joinpath('stat').read_text().split()[21] == data['start']:
                os.kill(data['pid'], signal.SIGTERM)
        except (OSError, ValueError, KeyError, ProcessLookupError):
            pass
        command = f'output * bg {json.dumps(str(image), ensure_ascii=False)} fill'
        (ROOT / 'wallpaper.conf').write_text(command + '\n')
        subprocess.run(['swaymsg', command], check=True)
        (STATE / 'wallpaper.json').write_text(json.dumps({'path': str(path)}))
        if path.suffix.lower() in VIDEOS:
            log = (STATE / 'mpvpaper.log').open('a')
            proc = subprocess.Popen(['mpvpaper', '*', str(path), '-o', 'no-audio loop-file hwdec=auto'],
                                    stdout=log, stderr=log, start_new_session=True)
            log.close()
            try:
                start = Path(f'/proc/{proc.pid}/stat').read_text().split()[21]
                (STATE / 'mpvpaper.json').write_text(json.dumps({'pid': proc.pid, 'start': start}))
            except OSError:
                pass
        # Explicit session config has no Niri/Hyprland hooks or outputs.
        cache = Path(os.environ.get('XDG_CACHE_HOME', str(Path.home() / '.cache')))
        (cache / 'matugen').mkdir(parents=True, exist_ok=True)
        with (STATE / 'matugen.log').open('a') as log:
            result = subprocess.run(['matugen', '--config', str(ROOT / 'matugen/config.toml'),
                                     'image', str(image), '-m', 'dark', '--source-color-index', '0'],
                                    stdout=log, stderr=log)
        if result.returncode:
            print('Wallpaper set; Matugen failed. See ~/.local/state/sway/matugen.log', file=sys.stderr)
        else:
            for line in (ROOT / 'colors.conf').read_text().splitlines():
                subprocess.run(['swaymsg', line], check=True, stdout=subprocess.DEVNULL)
            subprocess.run(['fcitx5-remote', '-r'], check=False)
            # Waybar watches colors.css; do not rebuild GTK windows with SIGUSR2.
    if mode == 'gui':
        # Waypaper probes its default backend before parsing --config-file.
        # Give it a Sway-only default as well, so it cannot start Niri's awww.
        os.environ['XDG_CONFIG_HOME'] = str(ROOT / 'waypaper-config')
        os.execv('/usr/bin/waypaper', ['waypaper', '--config-file', str(CONFIG)])

if __name__ == '__main__':
    main()
