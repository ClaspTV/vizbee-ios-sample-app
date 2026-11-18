# Parses an exported activity-monitor-process-live table into
# (process name, time s, cumulative CPU time s, physical footprint MB, threads, Mach ports) samples.
import re


def rows(xml):
    values, process_names = {}, {}
    for row in re.findall(r'<row>(.*?)</row>', xml, re.S):
        first = re.search(r'<process (?:id="(\d+)" fmt="([^"]*)"|ref="(\d+)")', row)
        if first.group(1):
            process_names[first.group(1)] = first.group(2)
        process = re.sub(r' \(\d+\)$', '', first.group(2) if first.group(1) else process_names.get(first.group(3), ''))
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
        if len(cells) < 8 or cells[4] is None or cells[7] is None:
            continue
        count = lambda cell: int(cell) if cell and cell.isdigit() else None
        yield process, float(cells[0]) / 1e9, float(cells[4]) / 1e9, float(cells[7]) / 1048576, count(cells[5]), count(cells[6])
