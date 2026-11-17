# Sums the iPad's network bytes by kind from an rvictl packet capture, in a window measured from the app's launch.
# Skips the links the Xcode tools use to reach the device (fe80:: link-local or fd ULA addresses on both ends).
# Usage: net_summary.py <label> <scenario> <run> <from s> <to s> <launch epoch s> <capture.pcap>
# Prints: label,scenario,run,kind,KB in the window,KB per minute
import re, subprocess, sys
label, scenario, run, start, end, launch, pcap = sys.argv[1:8]
lo, hi = float(launch) + float(start), float(launch) + float(end)
kinds = ['ssdp', 'mdns', 'dns', 'lan', 'internet']
total = dict.fromkeys(kinds, 0)
text = subprocess.run(['tcpdump', '-r', pcap, '-n', '-tt', '-v'], capture_output=True, text=True).stdout
packets = re.split(r'\n(?=\d{10}\.\d+ )', text)
for p in packets:
    m = re.match(r'(\d{10}\.\d+) (IP6?) ', p)
    if not m or not lo <= float(m.group(1)) <= hi:
        continue
    size = re.search(r'length (\d+)\)' if m.group(2) == 'IP' else r'payload length: (\d+)', p)
    ends = re.search(r'(\S+) > (\S+): ', p)
    if not size or not ends:
        continue
    src, dst = ends.groups()
    if all(re.match(r'(fe80:|fd[0-9a-f]{2}:)', a) for a in (src, dst)):
        continue
    nbytes = int(size.group(1)) + (40 if m.group(2) == 'IP6' else 0)
    ports = {src.rsplit('.', 1)[-1], dst.rsplit('.', 1)[-1]}
    if '1900' in ports: kind = 'ssdp'
    elif '5353' in ports: kind = 'mdns'
    elif '53' in ports: kind = 'dns'
    elif all(re.match(r'(192\.168\.|10\.|172\.(1[6-9]|2\d|3[01])\.|22[4-9]\.|23\d\.|ff0|fe80)', a) for a in (src, dst)): kind = 'lan'
    else: kind = 'internet'
    total[kind] += nbytes
minutes = (hi - lo) / 60
for kind in kinds + ['total']:
    value = sum(total.values()) if kind == 'total' else total[kind]
    print(f'{label},{scenario},{run},{kind},{value / 1024:.1f},{value / 1024 / minutes:.1f}')
