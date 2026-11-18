# Reads an exported activity-monitor-process-live table recorded with --all-processes and prints,
# for each named process, its average CPU % and median and peak memory footprint in a window
# measured from the app's first sample (its launch).
# Usage: process_summary.py <label> <scenario> <run> <from s> <to s> <app name> <process name>... < table.xml
# Prints: label,scenario,run,process,CPU %,median MB,peak MB,median threads,median Mach ports
import os, statistics, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from activity_rows import rows
label, scenario, run, start, end, app = sys.argv[1:7]
names = sys.argv[7:]
samples = {}
for process, time, cpu_total, memory, threads, ports in rows(sys.stdin.read()):
    samples.setdefault(process, []).append((time, cpu_total, memory, threads, ports))
if app not in samples:
    sys.exit(f'{label},{scenario},{run},{app},NO_SAMPLES')
launch = samples[app][0][0]
for name in [app] + names:
    window = [s for s in samples.get(name, []) if launch + float(start) <= s[0] <= launch + float(end)]
    if len(window) < 2:
        print(f'{label},{scenario},{run},{name},NO_SAMPLES'); continue
    cpu = 100 * (window[-1][1] - window[0][1]) / (window[-1][0] - window[0][0])
    memory = [s[2] for s in window]
    counts = [statistics.median(c) if (c := [s[i] for s in window if s[i] is not None]) else float('nan') for i in (3, 4)]
    print(f'{label},{scenario},{run},{name},{cpu:.2f},{statistics.median(memory):.1f},{max(memory):.1f},{counts[0]:g},{counts[1]:g}')
