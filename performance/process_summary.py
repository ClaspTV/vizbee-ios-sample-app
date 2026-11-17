# Reads an exported activity-monitor-process-live table recorded with --all-processes and prints
# average CPU % and median memory for each named process in a window measured from the app's launch.
# Usage: process_summary.py <label> <scenario> <run> <from s> <to s> <app name> <process name>... < table.xml
import re, statistics, sys
label, scenario, run, start, end, app = sys.argv[1:7]
names = sys.argv[7:]
xml = sys.stdin.read()
values, process_names, samples = {}, {}, {}
for row in re.findall(r'<row>(.*?)</row>', xml, re.S):
    first = re.search(r'<process (?:id="(\d+)" fmt="([^"]*)"|ref="(\d+)")', row)
    if first.group(1):
        process_names[first.group(1)] = first.group(2)
        process = first.group(2)
    else:
        process = process_names.get(first.group(3), '')
    process = re.sub(r' \(\d+\)$', '', process)
    cells = []
    for m in re.finditer(r'<(\w[\w-]*)(?: id="(\d+)")?(?: ref="(\d+)")?(?: fmt="[^"]*")?\s*(/?)>', row):
        tag, cid, ref, closed = m.groups()
        if tag in ('pid', 'device-session', 'process'):
            continue
        if ref:
            cells.append(values.get(ref)); continue
        if closed:
            cells.append(None); continue
        text = re.match(r'([^<]*)', row[m.end():]).group(1)
        if cid: values[cid] = text
        cells.append(text)
    if len(cells) < 8 or cells[4] is None or cells[7] is None:
        continue
    samples.setdefault(process, []).append((float(cells[0]) / 1e9, float(cells[4]) / 1e9, float(cells[7]) / 1048576))
if app not in samples:
    sys.exit(f'{label},{scenario},{run},NO_APP_SAMPLES')
launch = samples[app][0][0]
for name in [app] + names:
    window = [s for s in samples.get(name, []) if launch + float(start) <= s[0] <= launch + float(end)]
    if len(window) < 2:
        print(f'{label},{scenario},{run},{name},NO_SAMPLES'); continue
    cpu = 100 * (window[-1][1] - window[0][1]) / (window[-1][0] - window[0][0])
    print(f'{label},{scenario},{run},{name},{cpu:.2f},{statistics.median(s[2] for s in window):.1f}')
