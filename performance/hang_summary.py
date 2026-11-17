# Counts hangs in an exported potential-hangs table (Time Profiler), split into launch + discovery
# (first 35 s of the recording) and the rest.
# Usage: hang_summary.py <label> <run> < table.xml
# Prints: label,run,hangs in 0-35 s,hangs after 35 s,longest hang ms,hang types
import re, sys
label, run = sys.argv[1:3]
xml = sys.stdin.read()
values, hangs = {}, []
for row in re.findall(r'<row>(.*?)</row>', xml, re.S):
    cells = []
    for m in re.finditer(r'<([\w-]+)(?: id="(\d+)")?(?: ref="(\d+)")?(?: fmt="([^"]*)")?[^>]*?(/?)>', row):
        tag, cid, ref, fmt, closed = m.groups()
        if tag in ('thread', 'process', 'pid', 'device-session', 'tid'):
            if ref: cells.append(values.get(ref))
            elif cid: values[cid] = (None, fmt); cells.append(values[cid])
            continue
        if ref:
            cells.append(values.get(ref)); continue
        text = '' if closed else re.match(r'([^<]*)', row[m.end():]).group(1)
        if cid: values[cid] = (text, fmt)
        cells.append((text, fmt))
    hangs.append((int(cells[0][0]) / 1e9, int(cells[1][0]) / 1e6, cells[2][1]))
early = [h for h in hangs if h[0] < 35]
late = [h for h in hangs if h[0] >= 35]
longest = max((h[1] for h in hangs), default=0)
types = ' '.join(sorted({h[2] for h in hangs}))
print(f'{label},{run},{len(early)},{len(late)},{longest:.0f},{types}')
