# Summarizes a results folder written by run.sh into summary.csv (one row per metric, in the
# layout of the Perf-iOS-Details sheet) and summary.md (readable report).
# Every build is compared with the baseline (the first label). The 95% range of each difference
# is a bootstrap over the runs (10,000 resamples, fixed seed, so it is reproducible).
# Usage: summarize.py <results dir> <baseline label> <label>...
import csv, json, os, random, statistics, sys

OUT, LABELS = sys.argv[1], sys.argv[2:]
BASE = LABELS[0]
PHASES = ['Process creation', 'System interface initialization', 'Static runtime initialization (frameworks and static initializers)',
          'UIKit initialization', 'UIKit scene creation', 'didFinishLaunchingWithOptions (SDK setup)', 'Initial frame rendering']


def read(path):
    path = os.path.join(OUT, path)
    return list(csv.reader(open(path))) if os.path.exists(path) else []


def number(text):
    try:
        return float(text)
    except ValueError:
        return None


def difference_range(base, other, statistic):
    random.seed(1)
    diffs = sorted(statistic(random.choices(other, k=len(other))) - statistic(random.choices(base, k=len(base))) for _ in range(10000))
    return diffs[250], diffs[9749]


metrics = []


def add(scenario, metric, unit, samples, statistic=statistics.mean, tool='', note=''):
    """samples: label -> list of per-run values."""
    if not samples.get(BASE):
        return
    row = {'scenario': scenario, 'metric': metric, 'unit': unit, 'tool': tool, 'note': note,
           'runs': min(len(v) for v in samples.values() if v), 'statistic': statistic.__name__, 'values': {}}
    for label in LABELS:
        values = samples.get(label) or []
        if not values:
            continue
        value = statistic(values)
        entry = {'value': value}
        if label != BASE:
            base = statistic(samples[BASE])
            entry['diff'] = value - base
            entry['diff_pct'] = (value - base) / base * 100 if abs(base) > 1e-9 else None
            if len(values) > 1 and len(samples[BASE]) > 1 and statistic in (statistics.mean, statistics.median):
                entry['range'] = difference_range(samples[BASE], values, statistic)
        row['values'][label] = entry
    metrics.append(row)


def total(values):
    return float(sum(values))


# Launch: Xcode's launch test, every measured launch, and without the first launch of each round.
launches = {}
for row in read('launch/xcode_launch.csv'):
    if len(row) == 4 and number(row[3]) is not None:
        launches.setdefault(row[0], []).append((int(row[2]), number(row[3]) * 1000))
add('Launch', 'Cold launch time (Xcode launch test)', 'ms', {k: [v for _, v in x] for k, x in launches.items()},
    tool='XCTest: XCTApplicationLaunchMetric', note='Every measured launch, rounds of 5 taken in turn across builds')
add('Launch', 'Cold launch time, without the first launch of each round', 'ms', {k: [v for i, v in x if i > 1] for k, x in launches.items()},
    tool='XCTest: XCTApplicationLaunchMetric')

# Launch phases from Instruments.
phases = {}
for row in read('launch-phases/launch_phases.csv'):
    phases.setdefault(row[0], []).append([float(x) for x in row[2:]])
add('Launch', 'Process start to first frame', 'ms', {k: [r[0] for r in x] for k, x in phases.items()},
    tool='Instruments: App Launch', note='One measured launch per round after a discarded warm-up launch')
for i, name in enumerate(PHASES):
    add('Launch phase', name, 'ms', {k: [r[i + 1] for r in x] for k, x in phases.items()}, tool='Instruments: App Launch',
        note='Phases run back to back and add up to the launch time (means)')

# Discovery and idle: CPU and memory of the app and of mDNSResponder.
activity = {}
for row in read('activity/activity.csv'):
    if len(row) in (7, 9):
        activity.setdefault((row[1], row[3]), {}).setdefault(row[0], []).append([float(x) for x in row[4:]])
network = {}
for row in read('activity/network.csv'):
    network.setdefault((row[1], row[3]), {}).setdefault(row[0], []).append(float(row[5]))
for scenario, window in (('Discovery', '5-35 s after launch'), ('Idle', '60-240 s after launch')):
    key = scenario.lower()
    app = activity.get((key, 'VizbeeDemo'), {})
    bonjour = activity.get((key, 'mDNSResponder'), {})
    tool = 'Instruments: Activity Monitor (all processes)'
    add(scenario, 'Memory footprint', 'MB', {k: [r[1] for r in x] for k, x in app.items()}, tool=tool, note=f'Median footprint, {window}')
    add(scenario, 'Peak memory footprint', 'MB', {k: [r[2] for r in x] for k, x in app.items()}, statistic=max, tool=tool, note=window)
    add(scenario, 'CPU usage (app)', '%', {k: [r[0] for r in x] for k, x in app.items()}, tool=tool, note=f'CPU time / elapsed time, {window}')
    add(scenario, 'CPU usage (mDNSResponder, system Bonjour service)', '%', {k: [r[0] for r in x] for k, x in bonjour.items()}, tool=tool,
        note='Bonjour discovery runs in this system process, not in the app')
    add(scenario, 'CPU usage (app + mDNSResponder)', '%', {k: [a[0] + b[0] for a, b in zip(app.get(k, []), bonjour.get(k, []))] for k in app},
        tool=tool)
    kinds = ['ssdp', 'mdns', 'dns', 'lan']
    local = {k: [sum(v) for v in zip(*[network.get((key, kind), {}).get(k, []) for kind in kinds])] for k in network.get((key, 'total'), {})}
    tool = 'Packet capture (rvictl + tcpdump)'
    add(scenario, 'Network traffic (total)', 'KB per min', network.get((key, 'total'), {}), statistic=statistics.median, tool=tool,
        note=f'All the device\'s Wi-Fi traffic, {window}; median, since internet traffic varies with iOS background activity')
    add(scenario, 'Network traffic (local network: SSDP, mDNS, DNS, LAN)', 'KB per min', local, tool=tool, note=window)
    for kind, name in (('ssdp', 'SSDP'), ('mdns', 'mDNS'), ('lan', 'LAN (HTTP to devices)')):
        add(scenario, f'Network traffic: {name}', 'KB per min', network.get((key, kind), {}), tool=tool, note=window)
    add(scenario, 'Network traffic (internet)', 'KB per min', network.get((key, 'internet'), {}), statistic=statistics.median, tool=tool, note=window)

# Hangs.
hangs = {}
for row in read('hangs/hangs.csv'):
    hangs.setdefault(row[0], []).append((int(row[2]), int(row[3]), float(row[4])))
add('Launch + Discovery', 'Hangs over 250 ms in the first 35 s', 'count', {k: [h[0] for h in x] for k, x in hangs.items()}, statistic=total,
    tool='Instruments: Time Profiler (Hangs)', note='Total over all runs')
add('Launch + Discovery', 'Hangs after 35 s', 'count', {k: [h[1] for h in x] for k, x in hangs.items()}, statistic=total,
    tool='Instruments: Time Profiler (Hangs)', note='Total over all runs')
add('Launch + Discovery', 'Longest hang', 'ms', {k: [h[2] for h in x] for k, x in hangs.items()}, statistic=max,
    tool='Instruments: Time Profiler (Hangs)')


# Casting: before connecting, while casting and after disconnecting, from the cast and cycles steps.
def cast_rows(folder):
    """(label, run, window, process) -> [CPU %, median MB, peak MB, threads, ports]"""
    return {(r[0], r[2], r[1], r[3]): [float(x) for x in r[4:]] for r in read(f'{folder}/activity.csv') if len(r) == 9}


def per_run(rows, value):
    """label -> [value(run) for each run], skipping runs value() cannot compute."""
    out = {}
    for label, run in sorted({(k[0], k[1]) for k in rows}, key=lambda k: int(k[1])):
        try:
            out.setdefault(label, []).append(value(lambda window, process='VizbeeDemo': rows[(label, run, window, process)]))
        except KeyError:
            pass
    return out


cast = cast_rows('cast')
cast_network = {(r[0], r[2], r[1], r[3]): float(r[5]) for r in read('cast/network.csv')}
tool = 'Instruments: Activity Monitor (all processes), CastSessionTests'
windows = {'before': 'the 30 s before connecting', 'casting-1': 'the last 2 minutes of playback on the TV',
           'after-1': 'the last minute of 3 minutes after disconnecting'}
for window, scenario in (('before', 'Cast: before connecting'), ('casting-1', 'Cast: casting'), ('after-1', 'Cast: after disconnecting')):
    note = windows[window]
    add(scenario, 'Memory footprint', 'MB', per_run(cast, lambda w: w(window)[1]), tool=tool, note=f'Median footprint, {note}')
    add(scenario, 'CPU usage (app)', '%', per_run(cast, lambda w: w(window)[0]), tool=tool, note=note)
    add(scenario, 'CPU usage (app + mDNSResponder)', '%', per_run(cast, lambda w: w(window)[0] + w(window, 'mDNSResponder')[0]), tool=tool, note=note)
    add(scenario, 'Threads', 'count', per_run(cast, lambda w: w(window)[3]), tool=tool, note=f'Median, {note}')
    add(scenario, 'Mach ports', 'count', per_run(cast, lambda w: w(window)[4]), tool=tool, note=f'Median, {note}')
    for kind, name, statistic in (('lan', 'LAN, to the TVs', statistics.mean), ('total', 'total', statistics.median)):
        add(scenario, f'Network traffic ({name})', 'KB per min',
            {label: [v for (l, _, w, k), v in cast_network.items() if (l, w, k) == (label, window, kind)] for label in LABELS},
            statistic=statistic, tool='Packet capture (rvictl + tcpdump)', note=note)
scenario = 'Cast: not freed after disconnecting'
note = 'After disconnecting minus before connecting, per run; near 0 when the session\'s resources are released'
add(scenario, 'Memory footprint', 'MB', per_run(cast, lambda w: w('after-1')[1] - w('before')[1]), tool=tool, note=note)
add(scenario, 'Threads', 'count', per_run(cast, lambda w: w('after-1')[3] - w('before')[3]), tool=tool, note=note)
add(scenario, 'Mach ports', 'count', per_run(cast, lambda w: w('after-1')[4] - w('before')[4]), tool=tool, note=note)
add(scenario, 'CPU usage (app)', '%', per_run(cast, lambda w: w('after-1')[0] - w('before')[0]), tool=tool, note=note)


def slope(points):
    """Least-squares slope of (x, y) points."""
    mx, my = statistics.mean(p[0] for p in points), statistics.mean(p[1] for p in points)
    return sum((x - mx) * (y - my) for x, y in points) / sum((x - mx) ** 2 for x, _ in points)


cycles = cast_rows('cycles')
count = max([int(k[2].split('-')[1]) for k in cycles if k[2].startswith('after-')] or [0])
if count > 1:
    note = f'{count} cycles of connect, 30 s of playback and disconnect'
    add('Repeated cast sessions', 'Memory growth per cycle', 'MB per cycle',
        per_run(cycles, lambda w: slope([(n, w(f'after-{n}')[1]) for n in range(1, count + 1)])), tool=tool,
        note=f'Slope of the footprint after each disconnect; {note}')
    add('Repeated cast sessions', 'Memory after the last cycle minus before the first', 'MB',
        per_run(cycles, lambda w: w(f'after-{count}')[1] - w('before')[1]), tool=tool, note=note)
    add('Repeated cast sessions', 'Threads after the last cycle minus before the first', 'count',
        per_run(cycles, lambda w: w(f'after-{count}')[3] - w('before')[3]), tool=tool, note=note)


def fmt(value, signed=False):
    if value is None:
        return ''
    text = f'{value:+.2f}' if signed else f'{value:.2f}'
    return text.rstrip('0').rstrip('.') if '.' in text else text


device = json.load(open(os.path.join(OUT, 'device.json')))
device_name = f"{device['model']}, iOS {device['os_version']}"
header = ['Device', 'Scenario', 'Metric', 'Unit', BASE]
for label in LABELS[1:]:
    header += [label, f'{label} difference', f'{label} difference %', f'{label} difference 95% range']
header += ['Runs', 'Statistic', 'Tool', 'Notes']
with open(os.path.join(OUT, 'summary.csv'), 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(header)
    for m in metrics:
        row = [device_name, m['scenario'], m['metric'], m['unit'], fmt(m['values'].get(BASE, {}).get('value'))]
        for label in LABELS[1:]:
            e = m['values'].get(label, {})
            rng = e.get('range')
            row += [fmt(e.get('value')), fmt(e.get('diff'), True), '' if e.get('diff_pct') is None else f"{e['diff_pct']:+.1f}%",
                    f'{fmt(rng[0], True)} to {fmt(rng[1], True)}' if rng else '']
        writer.writerow(row + [m['runs'], m['statistic'], m['tool'], m['note']])

variants = read('variants.csv')
lines = [f'# SDK performance: {device_name}', '',
         f"Device: {device['name']} ({device['model']}, {device['product_type']}), iOS {device['os_version']}", '', '| Build | Git ref | Commit | Packages |', '|---|---|---|---|']
lines += [f'| {v[0]} | {v[1]} | {v[2][:10]} | {v[3]} |' for v in variants]
discovery = {label: open(path).read().splitlines() for label in LABELS
             if os.path.exists(path := os.path.join(OUT, 'smoke', label, 'discovery.txt'))}
if discovery:
    address = next((line.split(': ', 1)[1] for found in discovery.values() for line in found if line.startswith('Device address:')), '')
    lines += ['', f'Network: device address {address}. Devices that answered discovery in the smoke test:', '']
    lines += [f'- {label}: {line}' for label, found in discovery.items() for line in found if line.startswith(('SSDP ', 'Cast '))]
no_answer = read('activity/no_answer.csv')
if no_answer:
    lines += ['', 'Warning: in these activity runs the app sent discovery probes but no TV answered, so their discovery and idle values '
              'do not include talking to TVs: ' + ', '.join(f'{label} run {run}' for label, run in no_answer) + '.']
lines += ['', 'Values are the statistic over all runs; differences are against ' + BASE + ', with the 95% range in brackets.', '',
          '| Scenario | Metric | Unit | ' + ' | '.join(LABELS) + ' | Runs |', '|' + '---|' * (len(LABELS) + 4)]
for m in metrics:
    cells = [fmt(m['values'].get(BASE, {}).get('value'))]
    for label in LABELS[1:]:
        e = m['values'].get(label, {})
        rng = e.get('range')
        cells.append(f"{fmt(e.get('value'))} ({fmt(e.get('diff'), True)}" + (f', {fmt(rng[0], True)} to {fmt(rng[1], True)})' if rng else ')') if e else '')
    lines.append(f"| {m['scenario']} | {m['metric']} | {m['unit']} | " + ' | '.join(cells) + f" | {m['runs']} |")
open(os.path.join(OUT, 'summary.md'), 'w').write('\n'.join(lines) + '\n')
print('\n'.join(lines))
