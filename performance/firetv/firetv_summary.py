# Turns the samples of measure_firetv.sh into CSV lines.
# sample <label> <run> <scenario> "<before>" "<after>" < memory samples
#   before and after: uptime in s, app CPU ticks, main thread CPU ticks, threads (from /proc, 100 ticks per s)
#   memory samples: one line per dumpsys meminfo, TOTAL PSS and TOTAL SWAP PSS in KB
#   prints: label,run,scenario,CPU %,main-thread ms per min,threads,memory MB (PSS + swapped PSS, median),PSS MB,swapped PSS MB
# session <label> <session> < memory samples
#   prints: label,session,memory MB,PSS MB,swapped PSS MB
# summary <firetv.csv> <sessions.csv>
#   prints the mean of each metric per build and scenario, and the memory growth per session
#   (least-squares slope from session 2 on, so a one-time cost in the first session is left out)
import statistics, sys

TICKS = 100


def memory(lines):
    samples = [tuple(int(x) / 1024 for x in line.split()) for line in lines if line.strip()]
    pss = statistics.median(s[0] for s in samples)
    swap = statistics.median(s[1] for s in samples)
    return pss + swap, pss, swap


def slope(points):
    mean_x = sum(x for x, _ in points) / len(points)
    mean_y = sum(y for _, y in points) / len(points)
    return sum((x - mean_x) * (y - mean_y) for x, y in points) / sum((x - mean_x) ** 2 for x, _ in points)


mode = sys.argv[1]
if mode == 'sample':
    label, run, scenario, before, after = sys.argv[2:7]
    t0, cpu0, main0, _ = (float(x) for x in before.split())
    t1, cpu1, main1, threads = (float(x) for x in after.split())
    minutes = (t1 - t0) / 60
    total, pss, swap = memory(sys.stdin)
    print(f'{label},{run},{scenario},{100 * (cpu1 - cpu0) / TICKS / (t1 - t0):.2f},'
          f'{1000 * (main1 - main0) / TICKS / minutes:.0f},{threads:.0f},{total:.1f},{pss:.1f},{swap:.1f}')
elif mode == 'session':
    label, session = sys.argv[2:4]
    total, pss, swap = memory(sys.stdin)
    print(f'{label},{session},{total:.1f},{pss:.1f},{swap:.1f}')
elif mode == 'summary':
    rows = [line.strip().split(',') for line in open(sys.argv[2]) if 'FAILED' not in line]
    groups = {}
    for label, run, scenario, cpu, main, threads, total, pss, swap in rows:
        groups.setdefault((label, scenario), []).append((float(cpu), float(main), float(threads), float(total)))
    print('build,scenario,runs,CPU %,main-thread ms per min,threads,memory MB')
    for (label, scenario), values in groups.items():
        means = [statistics.mean(v[i] for v in values) for i in range(4)]
        print(f'{label},{scenario},{len(values)},{means[0]:.2f},{means[1]:.0f},{means[2]:.0f},{means[3]:.1f}')
    if len(sys.argv) > 3:
        sessions = {}
        for line in open(sys.argv[3]):
            label, session, total, _, _ = line.strip().split(',')
            sessions.setdefault(label, []).append((int(session), float(total)))
        print('build,sessions,memory after session 1 MB,after last MB,growth MB per session (from session 2)')
        for label, points in sessions.items():
            later = [p for p in points if p[0] >= 2]
            print(f'{label},{len(points)},{points[0][1]:.1f},{points[-1][1]:.1f},{slope(later):.3f}')
