# Prints one process's CPU % and memory per 10-second bucket from an exported activity-monitor-process-live table.
# Usage: activity_timeline.py [process name, default VizbeeDemo] < table.xml
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from activity_rows import rows
name = sys.argv[1] if len(sys.argv) > 1 else 'VizbeeDemo'
samples = [s[1:] for s in rows(sys.stdin.read()) if s[0] == name]
start = samples[0][0]
for b in range(0, int(samples[-1][0] - start) // 10 * 10, 10):
    bucket = [s for s in samples if start + b <= s[0] <= start + b + 10]
    if len(bucket) < 2:
        continue
    cpu = 100 * (bucket[-1][1] - bucket[0][1]) / (bucket[-1][0] - bucket[0][0])
    print(f'{b:4d}-{b + 10:<4d}s  cpu {cpu:6.2f}%  mem {bucket[-1][2]:6.1f} MB  ' + '#' * int(cpu * 2))
