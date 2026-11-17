# Prints CPU % and memory per 10-second bucket from an exported activity-monitor-process-live table.
import re, sys
xml = sys.stdin.read()
values, samples = {}, []
for row in re.findall(r'<row>(.*?)</row>', xml, re.S):
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
    if cells[4] is None or cells[7] is None:
        continue
    samples.append((float(cells[0]) / 1e9, float(cells[4]) / 1e9, float(cells[7]) / 1048576))
for b in range(0, int(samples[-1][0]) // 10 * 10, 10):
    w = [s for s in samples if b <= s[0] <= b + 10]
    if len(w) < 2: continue
    cpu = (w[-1][1] - w[0][1]) / (w[-1][0] - w[0][0]) * 100
    print(f'{b:4d}-{b+10:<4d}s  cpu {cpu:6.2f}%  mem {w[-1][2]:6.1f} MB  ' + '#' * int(cpu * 2))
