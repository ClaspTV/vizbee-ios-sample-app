# Summarises the Leaks and Allocations Statistics tables exported from an Instruments Leaks recording.
# Usage: leaks_summary.py <label> <completed sessions> <Leaks.xml> <Statistics.xml>
# Prints: label,sessions,leaked objects,leaked bytes,leaked bytes Vizbee,leaked bytes Google Cast,
#         heap kept bytes,allocations,allocated MB,string allocations
import html, re, sys

label, sessions, leaks_file, stats_file = sys.argv[1:5]


def rows(path):
    try:
        text = open(path).read()
    except OSError:
        return []
    return [{k: html.unescape(v) for k, v in re.findall(r'([\w-]+)="([^"]*)"', r)} for r in re.findall(r'<row ([^>]*?)/?>', text)]


def owner(row):
    text = ' '.join(row.values())
    if re.search(r'\bVZB|Vizbee', text):
        return 'vizbee'
    if re.search(r'\bGCK|GoogleCast', text):
        return 'googlecast'
    return 'other'


def size(row):
    for key in ('size', 'bytes', 'leaked-bytes'):
        if row.get(key, '').lstrip('-').isdigit():
            return int(row[key])
    return 0


leaks = rows(leaks_file)
leaked = {'vizbee': 0, 'googlecast': 0, 'other': 0}
for row in leaks:
    leaked[owner(row)] += size(row)
stats = {r['category']: r for r in rows(stats_file) if 'category' in r}
heap = stats.get('All Heap Allocations', {})
strings = sum(int(r['count-total']) for c, r in stats.items() if c.startswith('CFString') or c == 'Swift.__StringStorage')
print(','.join(str(v) for v in (
    label, sessions, len(leaks), sum(leaked.values()), leaked['vizbee'], leaked['googlecast'],
    heap.get('persistent-bytes', ''), heap.get('count-total', ''),
    round(int(heap.get('total-bytes', 0)) / 1e6, 1), strings)))
