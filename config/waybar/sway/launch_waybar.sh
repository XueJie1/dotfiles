#!/bin/bash
set -euo pipefail
style=${1:-2}
case "$style" in 1|2) ;; *) echo "Usage: $0 [1|2]" >&2; exit 2 ;; esac
# Use the environment of the Sway session which invoked this launcher.
export SWAYSOCK=${SWAYSOCK:-$XDG_RUNTIME_DIR/sway-ipc.$UID.$(pgrep -u "$UID" -x sway | tail -1).sock}
# Refresh the CPU sensor path when hwmon numbering changes at boot.
python3 - <<'SENSOR'
from pathlib import Path
import re
root = Path.home()/'.config/waybar/sway'
for sensor in Path('/sys/class/hwmon').glob('hwmon*/temp*_input'):
    try:
        if (sensor.parent/'name').read_text().strip() != 'coretemp':
            continue
        label = sensor.with_name(sensor.name.replace('_input', '_label'))
        if label.read_text().strip() != 'Core 0':
            continue
        for name in ('config1', 'config2'):
            path = root/name
            old = path.read_text()
            new = re.sub(r'("hwmon-path"\s*:\s*)"[^"]*"', lambda m: m[1] + '"' + str(sensor) + '"', old)
            if old != new:
                path.write_text(new)
        break
    except OSError:
        continue
SENSOR
systemctl --user import-environment SWAYSOCK WAYLAND_DISPLAY XDG_RUNTIME_DIR
for other in 1 2; do
    if [[ $other != "$style" ]]; then
        systemctl --user stop "sway-waybar@$other.service"
    fi
done
# Retire only unmanaged Sway bars; leave other desktops' bars alone.
python3 - <<'PYTHON'
from pathlib import Path
import os, signal
configs = {os.fsencode(str(Path.home()/'.config/waybar/sway'/f'config{i}')) for i in (1,2)}
for proc in Path('/proc').glob('[0-9]*'):
    try:
        args = proc.joinpath('cmdline').read_bytes().split(b'\0')
        if args and Path(os.fsdecode(args[0])).name == 'waybar' and configs.intersection(args):
            if b'sway-waybar@' not in proc.joinpath('cgroup').read_bytes():
                os.kill(int(proc.name), signal.SIGTERM)
    except (OSError, ValueError):
        pass
PYTHON
systemctl --user reset-failed "sway-waybar@$style.service" 2>/dev/null || true
systemctl --user restart "sway-waybar@$style.service"
