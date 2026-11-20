# Reads an exported activity-monitor-process-live table of a long idle run and prints the app's memory
# growth per minute (least-squares slope of the median memory in each minute from <from min> on; Vizbee's
# passive scan runs once a minute, so this is growth per passive scan), its memory at the start and end of
# that period, and its CPU over the period.
# Usage: idle_slope.py <label> <run> <from min> <to min> < table.xml
# Prints: label,run,MB per minute,first-minute MB,last-minute MB,CPU %
import os, statistics, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from activity_rows import rows

label, run, first, last = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
samples = [(time, cpu, memory) for process, time, cpu, memory, _, _ in rows(sys.stdin.read()) if process == 'VizbeeDemo']
start = samples[0][0]
minutes = {}
for time, cpu, memory in samples:
    minutes.setdefault(int((time - start) // 60), []).append((time, cpu, memory))
points = [(m, statistics.median(x[2] for x in minutes[m])) for m in range(first, last) if m in minutes]
n = len(points)
mean_x, mean_y = sum(p[0] for p in points) / n, sum(p[1] for p in points) / n
slope = sum((x - mean_x) * (y - mean_y) for x, y in points) / sum((x - mean_x) ** 2 for x, _ in points)
window = [s for s in samples if first * 60 <= s[0] - start < last * 60]
cpu = 100 * (window[-1][1] - window[0][1]) / (window[-1][0] - window[0][0])
print(f'{label},{run},{slope:.4f},{points[0][1]:.2f},{points[-1][1]:.2f},{cpu:.2f}')
