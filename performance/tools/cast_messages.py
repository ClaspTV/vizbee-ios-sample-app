# Counts TCP segments with data and their bytes per minute, for each connection between the device and
# a local-network address, in a capture from profile_cast.sh. On the Cast channel (port 8009) each status
# message from the receiver arrives as one TLS record, usually in one segment.
# Usage: cast_messages.py <capture.pcap> [device IP]
import collections, struct, sys

LINK_HEADERS = {1: 14, 0: 4, 108: 4, 12: 0, 101: 0}


def packets(path):
    with open(path, 'rb') as f:
        header = f.read(24)
        endian = '<' if struct.unpack('<I', header[:4])[0] in (0xa1b2c3d4, 0xa1b23c4d) else '>'
        link = struct.unpack(endian + 'I', header[20:24])[0]
        while True:
            record = f.read(16)
            if len(record) < 16:
                return
            seconds, micros, length, _ = struct.unpack(endian + 'IIII', record)
            yield seconds + micros / 1e6, link, f.read(length)


def main():
    path = sys.argv[1]
    flows, first, last = collections.defaultdict(lambda: [0, 0]), None, None
    for time, link, data in packets(path):
        offset = LINK_HEADERS.get(link, 0)
        if link == 1:
            if struct.unpack('>H', data[12:14])[0] != 0x0800:
                continue
        ip = data[offset:]
        if len(ip) < 20 or ip[0] >> 4 != 4 or ip[9] != 6:
            continue
        header = (ip[0] & 15) * 4
        tcp = ip[header:]
        payload = struct.unpack('>H', ip[2:4])[0] - header - (tcp[12] >> 4) * 4
        if payload <= 0:
            continue
        source, destination = '.'.join(map(str, ip[12:16])), '.'.join(map(str, ip[16:20]))
        if not (source.startswith(('192.168.', '10.', '172.')) and destination.startswith(('192.168.', '10.', '172.'))):
            continue
        sport, dport = struct.unpack('>HH', tcp[:4])
        first = time if first is None else first
        last = time
        flows[(source, sport, destination, dport)][0] += 1
        flows[(source, sport, destination, dport)][1] += payload
    minutes = (last - first) / 60 if first is not None and last > first else 1
    print(f'{minutes:.1f} min captured')
    for (source, sport, destination, dport), (count, size) in sorted(flows.items(), key=lambda x: -x[1][0]):
        if count / minutes >= 1:
            print(f'{source}:{sport} -> {destination}:{dport}  {count / minutes:6.1f} segments/min  {size / minutes / 1024:7.1f} KB/min  {size / count:6.0f} B avg')


main()
