#!/usr/bin/env python3
"""Own one mpvpaper per active output; recover after hotplug and child exit.

Freeze a player with SIGSTOP while a real fullscreen window covers that output.
mpvpaper --auto-pause still redraws the held frame on Hyprland, so it does not
drop CPU. Maximize (fullscreen mode 2) leaves gaps and the bar, so it does not
count as covered.
"""
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
# Intel sessions keep the baked options (hwdec=vaapi). The NVIDIA-only greetd
# session opens only the RTX 3050, where that VA-API path is the Intel driver.
# nvdec is the decoder that actually runs on this GPU; mpvpaper forces vo=libmpv,
# so vo/gpu-api flags are not part of the set.
if os.environ.get('HYPRLAND_NVIDIA_ONLY') == '1':
    options = 'no-config no-audio loop-file hwdec=nvdec profile=fast video-sync=audio panscan=1.0'
state = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'video-wallpaper'
state.mkdir(parents=True, exist_ok=True)
log = logging.getLogger('wallpaper')
log.setLevel(logging.INFO)
handler = RotatingFileHandler(state / 'wallpaper.log', maxBytes=2_000_000, backupCount=3)
handler.setFormatter(logging.Formatter('%(asctime)s %(message)s'))
log.addHandler(handler)
if os.environ.get('HYPRLAND_NVIDIA_ONLY') == '1':
    log.info('NVIDIA-only session; mpvpaper options: %s', options)
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
paused = set()
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
    paused.discard(name)
    if process.poll() is None:
        # A stopped process does not run its SIGTERM handler until continued.
        try:
            os.kill(process.pid, signal.SIGCONT)
        except ProcessLookupError:
            pass
        process.terminate()
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
    log.info('Stopped %s pid=%s exit=%s', name, process.pid, process.returncode)

def covered_outputs(monitors, clients):
    shown = {}
    for monitor in monitors:
        if monitor.get('disabled') or not monitor.get('dpmsStatus', True):
            continue
        special = (monitor.get('specialWorkspace') or {}).get('name') or ''
        workspace = (monitor.get('activeWorkspace') or {}).get('id')
        shown[monitor.get('id')] = (monitor['name'], workspace, special)
    covered = set()
    for client in clients:
        # 1 = fullscreen. 2 = maximize, which does not cover the wallpaper.
        if client.get('fullscreen') != 1 or not client.get('mapped') or client.get('hidden'):
            continue
        output = shown.get(client.get('monitor'))
        if not output:
            continue
        name, workspace, special = output
        client_workspace = client.get('workspace') or {}
        if client.get('pinned') or (special and client_workspace.get('name') == special) or (not special and client_workspace.get('id') == workspace):
            covered.add(name)
    return covered

def sync_pause(monitors):
    try:
        result = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True, timeout=3, check=True)
        clients = json.loads(result.stdout)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        log.warning('Client query failed: %s', error)
        return
    covered = covered_outputs(monitors, clients)
    for name, process in list(children.items()):
        if process.poll() is not None:
            paused.discard(name)
            continue
        want = name in covered
        if want == (name in paused):
            continue
        try:
            os.kill(process.pid, signal.SIGSTOP if want else signal.SIGCONT)
        except ProcessLookupError:
            paused.discard(name)
            continue
        if want:
            paused.add(name)
            log.info('Paused %s pid=%s because a fullscreen window covers it', name, process.pid)
        else:
            paused.discard(name)
            log.info('Resumed %s pid=%s', name, process.pid)

signal.signal(signal.SIGTERM, shutdown)
signal.signal(signal.SIGINT, shutdown)
log.info('Supervisor started pid=%s video=%s', os.getpid(), video)
topology = None
dirty = False
occlusion_dirty = True
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
        if now >= next_check or occlusion_dirty:
            check_topology = now >= next_check
            if check_topology:
                next_check = now + 2
            occlusion_dirty = False
            try:
                result = subprocess.run(['hyprctl', 'monitors', '-j'], capture_output=True, text=True, timeout=3, check=True)
                monitors = json.loads(result.stdout)
                current = {m['name']: (m['width'], m['height'], m.get('scale'), m.get('transform')) for m in monitors if not m.get('disabled') and m.get('dpmsStatus', True)}
            except (OSError, ValueError, subprocess.SubprocessError) as error:
                log.warning('Monitor query failed: %s', error)
            else:
                if check_topology and (current != topology or dirty):
                    log.info('Output change: %s -> %s; rebuilding players', topology, current)
                    for name in list(children):
                        stop(name)
                    retry.clear()
                    topology = current
                    dirty = False
                if check_topology:
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
                sync_pause(monitors)
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
                    event = line.split(b'>>', 1)[0]
                    if event in (b'monitoradded', b'monitorremoved', b'configreloaded'):
                        log.info('Hyprland event: %s', line.decode(errors='replace'))
                        dirty = True
                    elif event in (
                        b'fullscreen', b'openwindow', b'closewindow', b'movewindow', b'movewindowv2',
                        b'workspace', b'workspacev2', b'focusedmon', b'changefloatingmode',
                        b'activespecial', b'pin', b'minimized',
                    ):
                        occlusion_dirty = True
finally:
    for name in list(children):
        stop(name)
    control.close()
    control_path.unlink(missing_ok=True)
    if stop_client:
        stop_client.close()
    log.info('Supervisor stopped')
