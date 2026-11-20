# Averages the app's power impact in a time window from an exported Power Profiler
# ProcessSubsystemPowerImpact table. Power impact is Xcode's 0-100 score per subsystem, reported
# per second for CPU, display and GPU and every 5-6 s for networking (with Wi-Fi bytes).
# Prints: label, scenario, run, CPU, networking, GPU, CPU+networking+GPU, display, Wi-Fi KB per min,
# CPU instructions (billions per min; exact, for costs too small for the 0.1 steps of power impact)
# Display is printed separately: the app is on screen in every build, so it is not the SDK's cost.
# Usage: energy_summary.py <label> <run> <table.xml> <scenario>=<from s>-<to s> ...
import sys, collections, xml.etree.ElementTree as ET


def main():
    label, run, path = sys.argv[1:4]
    windows = [(w.split('=')[0], *map(float, w.split('=')[1].split('-'))) for w in sys.argv[4:]]
    root = ET.parse(path).getroot()
    columns = [c.find('mnemonic').text for c in root.iter('col')]
    ids = {}
    for el in root.iter():
        if el.get('id'):
            ids[el.get('id')] = el
    res = lambda e: ids[e.get('ref')] if e.get('ref') else e
    rows = []
    for row in root.iter('row'):
        cells = dict(zip(columns, [res(c) for c in row]))
        start, duration = int(cells['start'].text) / 1e9, int(cells['duration'].text) / 1e9
        values = {k: float(cells[k].text) for k in ('cpu-impact', 'display-impact', 'gpu-impact', 'networking-impact', 'wifi-received', 'wifi-transmitted', 'cpu-instructions')
                  if cells.get(k) is not None and cells[k].text is not None}
        rows.append((start, duration, values))
    for scenario, t0, t1 in windows:
        weighted, time = collections.Counter(), collections.Counter()
        for start, duration, values in rows:
            overlap = min(start + duration, t1) - max(start, t0)
            if overlap <= 0:
                continue
            for key, value in values.items():
                if key.startswith(('wifi', 'cpu-instructions')):
                    weighted[key] += value * overlap / duration
                else:
                    weighted[key] += value * overlap
                    time[key] += overlap
        mean = {k: weighted[k] / time[k] for k in time if time[k] and not k.startswith(('wifi', 'cpu-instructions'))}
        cpu, network, gpu = mean.get('cpu-impact', 0), mean.get('networking-impact', 0), mean.get('gpu-impact', 0)
        wifi = (weighted['wifi-received'] + weighted['wifi-transmitted']) / 1024 / ((t1 - t0) / 60)
        instructions = weighted['cpu-instructions'] / 1e9 / ((t1 - t0) / 60)
        print(f'{label},{scenario},{run},{cpu:.3f},{network:.3f},{gpu:.3f},{cpu + network + gpu:.3f},{mean.get("display-impact", 0):.2f},{wifi:.1f},{instructions:.3f}')


main()
