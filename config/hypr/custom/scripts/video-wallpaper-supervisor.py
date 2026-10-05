#!/usr/bin/env python3
"""Own one mpvpaper per active output; recover after hotplug and child exit."""
import fcntl
import json
import logging
from logging.handlers import RotatingFileHandler
import os
from pathlib import Path
import select
import signal
import socket
import subprocess
import sys
import threading
import time

runtime = Path(os.environ['XDG_RUNTIME_DIR'])
session = os.environ['HYPRLAND_INSTANCE_SIGNATURE']
control_path = runtime / ('video-wallpaper-' + session + '.sock')
lock_path = control_path.with_suffix('.lock')

if sys.argv[1:] == ['--stop']:
    try:
        with socket.socket(socket.AF_UNIX) as client:
            client.settimeout(12)
            client.connect(str(control_path))
            client.sendall(b'stop')
            client.recv(16)  # EOF only after children have been stopped.
    except (FileNotFoundError, ConnectionRefusedError, ConnectionResetError):
        pass
    sys.exit(0)

video, options = sys.argv[1:]
state = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'video-wallpaper'
state.mkdir(parents=True, exist_ok=True)
log = logging.getLogger('wallpaper')
log.setLevel(logging.INFO)
handler = RotatingFileHandler(state / 'wallpaper.log', maxBytes=2_000_000, backupCount=3)
handler.setFormatter(logging.Formatter('%(asctime)s %(message)s'))
log.addHandler(handler)
lock = open(lock_path, 'w')
try:
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
except BlockingIOError:
    log.info('Supervisor already running; ignoring duplicate launch')
    sys.exit(0)

control_path.unlink(missing_ok=True)
control = socket.socket(socket.AF_UNIX)
control.bind(str(control_path))
control.listen(1)
children = {}
retry = {}
running = True
stop_client = None
events = None

def shutdown(*_):
    global running
    running = False

def capture(name, process):
    for line in process.stdout:
        if line.strip() and not line.lstrip().startswith(('V:', 'AV:', 'A:')):
            log.info('[%s pid=%s] %s', name, process.pid, line.rstrip())
    process.stdout.close()

def stop(name):
    process = children.pop(name)
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
    log.info('Stopped %s pid=%s exit=%s', name, process.pid, process.returncode)

signal.signal(signal.SIGTERM, shutdown)
signal.signal(signal.SIGINT, shutdown)
log.info('Supervisor started pid=%s video=%s', os.getpid(), video)
topology = None
dirty = False
buffer = b''
next_check = 0
try:
    while running:
        if events is None:
            try:
                events = socket.socket(socket.AF_UNIX)
                events.connect(str(runtime / 'hypr' / session / '.socket2.sock'))
                events.setblocking(False)
                dirty = True
            except OSError:
                if events:
                    events.close()
                events = None
                if not (runtime / 'hypr' / session).exists():
                    break
        now = time.monotonic()
        if now >= next_check:
            next_check = now + 2
            try:
                result = subprocess.run(['hyprctl', 'monitors', '-j'], capture_output=True, text=True, timeout=3, check=True)
                monitors = json.loads(result.stdout)
                current = {m['name']: (m['width'], m['height'], m.get('scale'), m.get('transform')) for m in monitors if not m.get('disabled') and m.get('dpmsStatus', True)}
            except (OSError, ValueError, subprocess.SubprocessError) as error:
                log.warning('Monitor query failed: %s', error)
            else:
                if current != topology or dirty:
                    log.info('Output change: %s -> %s; rebuilding players', topology, current)
                    for name in list(children):
                        stop(name)
                    retry.clear()
                    topology = current
                    dirty = False
                for name in current:
                    if name in children and children[name].poll() is not None:
                        log.warning('Player exited on %s code=%s; retry in 5 seconds', name, children[name].returncode)
                        stop(name)
                        retry[name] = time.monotonic() + 5
                    if name not in children and time.monotonic() >= retry.get(name, 0):
                        try:
                            process = subprocess.Popen(['mpvpaper', '-o', options, name, video], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, errors='replace')
                            children[name] = process
                            threading.Thread(target=capture, args=(name, process), daemon=True).start()
                            log.info('Started %s pid=%s', name, process.pid)
                        except OSError as error:
                            log.error('Launch failed on %s: %s', name, error)
                            retry[name] = time.monotonic() + 5
        ready, _, _ = select.select([control] + ([events] if events else []), [], [], 0.5)
        if control in ready:
            stop_client, _ = control.accept()
            stop_client.settimeout(1)
            try:
                stop_client.recv(16)
            except socket.timeout:
                pass
            shutdown()
        if events and events in ready:
            data = events.recv(65536)
            if not data:
                events.close()
                events = None
            else:
                buffer += data
                while b'\n' in buffer:
                    line, buffer = buffer.split(b'\n', 1)
                    if line.startswith((b'monitoradded', b'monitorremoved', b'configreloaded')):
                        log.info('Hyprland event: %s', line.decode(errors='replace'))
                        dirty = True
finally:
    for name in list(children):
        stop(name)
    control.close()
    control_path.unlink(missing_ok=True)
    if stop_client:
        stop_client.close()
    log.info('Supervisor stopped')
