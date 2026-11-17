# Reads an exported life-cycle-period table on stdin and prints one CSV row:
# label, run, launch ms (process start to first frame), then each phase in ms.
# Instruments reports some phases more than once with overlapping times, so each
# phase runs from its first start to the next phase's first start. The phases
# then add up exactly to the launch time.
import re, sys

ORDER = ['Initializing - Process Creation', 'Initializing - System Interface Initialization',
         'Initializing - Static Runtime Initialization', 'Launching - UIKit Initialization',
         'Launching - UIKit Scene Creation', 'Launching - didFinishLaunchingWithOptions()',
         'Launching - Initial Frame Rendering']

label, run = sys.argv[1:3]
xml = sys.stdin.read()
ids = dict(re.findall(r'<app-period id="(\d+)" fmt="([^"]+)"', xml))
first = {}
for row in re.findall(r'<row>(.*?)</row>', xml, re.S):
    start = int(re.search(r'<start-time[^>]*>(\d+)<', row).group(1)) / 1e6
    period = re.search(r'<app-period (?:id="\d+" fmt="([^"]+)"|ref="(\d+)")', row)
    first.setdefault(period.group(1) or ids[period.group(2)], start)
launch = first['Foreground - Active']
starts = sorted([(first[name], name) for name in ORDER if name in first] + [(launch, 'end')])
phases = {name: end - start for (start, name), (end, _) in zip(starts, starts[1:])}
print(','.join([label, run, f'{launch:.1f}'] + [f'{phases.get(name, 0):.1f}' for name in ORDER]))
