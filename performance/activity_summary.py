# Reads an exported activity-monitor-process-live table and prints one CSV row:
# label, scenario, run, average CPU % (CPU time used / time measured), median memory MB,
# peak memory MB, for the samples between <from s> and <to s>.
import re, statistics, sys

label, scenario, run, start_s, end_s = sys.argv[1:6]
start_ns, end_ns = float(start_s) * 1e9, float(end_s) * 1e9
xml = sys.stdin.read()
values = {}
samples = []
for row in re.findall(r'<row>(.*?)</row>', xml, re.S):
    cells = []
    for match in re.finditer(r'<(\w[\w-]*)(?: id="(\d+)")?(?: ref="(\d+)")?(?: fmt="[^"]*")?\s*(/?)>', row):
        tag, cell_id, ref, closed = match.groups()
        if tag in ('pid', 'device-session'):
            continue
        if ref:
            cells.append((tag, values.get(ref)))
            continue
        if closed:
            cells.append((tag, None))
            continue
        text = re.match(r'([^<]*)', row[match.end():]).group(1)
        if cell_id:
            values[cell_id] = text
        cells.append((tag, text))
    cells = [c for c in cells if c[0] not in ('process',)]
    # column order: start, duration, process-uid, cpu-percent, cpu-total, threads, ports, memory, ...
    start = float(cells[0][1])
    cpu_total = cells[4][1]
    memory = cells[7][1]
    if cpu_total is None or memory is None:
        continue
    samples.append((start, float(cpu_total), float(memory)))
window = [s for s in samples if start_ns <= s[0] <= end_ns]
if len(window) < 2:
    raise SystemExit(f'{label},{scenario},{run},NO_SAMPLES')
cpu = (window[-1][1] - window[0][1]) / (window[-1][0] - window[0][0]) * 100
memory = [s[2] / 1048576 for s in window]
print(f'{label},{scenario},{run},{cpu:.2f},{statistics.median(memory):.1f},{max(memory):.1f}')
