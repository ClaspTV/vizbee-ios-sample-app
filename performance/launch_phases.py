# Reads an exported life-cycle-period table on stdin and prints one CSV row:
# label, run, launch ms (process start to first frame), then each phase in ms.
import re, sys

label, run = sys.argv[1:3]
xml = sys.stdin.read()
ids = dict(re.findall(r'<app-period id="(\d+)" fmt="([^"]+)"', xml))
phases = {}
launch_ms = None
for row in re.findall(r'<row>(.*?)</row>', xml, re.S):
    start = int(re.search(r'<start-time[^>]*>(\d+)<', row).group(1))
    duration = re.search(r'<duration[^>]*>(\d+)<', row)
    period = re.search(r'<app-period (?:id="\d+" fmt="([^"]+)"|ref="(\d+)")', row)
    name = period.group(1) or ids[period.group(2)]
    if name == 'Foreground - Active':
        launch_ms = start / 1e6
        break
    phases[name] = phases.get(name, 0) + int(duration.group(1)) / 1e6
order = ['Initializing - Process Creation', 'Initializing - System Interface Initialization',
         'Initializing - Static Runtime Initialization', 'Launching - UIKit Initialization',
         'Launching - UIKit Scene Creation', 'Launching - didFinishLaunchingWithOptions()',
         'Launching - Initial Frame Rendering']
print(','.join([label, run, f'{launch_ms:.1f}'] + [f'{phases.get(p, 0):.1f}' for p in order]))
