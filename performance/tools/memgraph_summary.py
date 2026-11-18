#!/usr/bin/python3
"""Compares two memory graphs of the same app, taken before and after repeated cast sessions.

Prints leaked objects in each graph (leaks), the heap classes that grew the most (heap), and
the memory regions whose dirty and swapped memory grew (vmmap --summary).

Usage: memgraph_summary.py <before.memgraph> <after.memgraph> [rows]
"""
import re
import subprocess
import sys

UNITS = {"B": 1, "K": 1024, "M": 1024 ** 2, "G": 1024 ** 3}


def run(*command):
    return subprocess.run(command, capture_output=True, text=True).stdout


def size(text):
    match = re.fullmatch(r"([\d.]+)([BKMG]?)", text)
    return float(match.group(1)) * UNITS[match.group(2) or "B"] if match else 0


def leaks(graph):
    match = re.search(r"(\d+) leaks? for (\d+) total leaked bytes", run("leaks", graph))
    return (int(match.group(1)), int(match.group(2))) if match else (None, None)


def heap(graph):
    classes = {}
    rows = re.finditer(r"^\s*(\d+)\s+(\d+)\s+[\d.]+\s+(.+?)\s*$", run("heap", graph).split("CLASS_NAME", 1)[-1], re.M)
    for row in rows:
        name = re.sub(r"0x[0-9a-f]+", "", row.group(3))
        count, total = classes.get(name, (0, 0))
        classes[name] = (count + int(row.group(1)), total + int(row.group(2)))
    return classes


def regions(graph):
    result = {}
    table = run("vmmap", "--summary", graph).split("REGION TYPE", 1)[-1].split("MALLOC ZONE", 1)[0]
    for line in table.splitlines():
        match = re.match(r"^(\S.*?)\s{2,}(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+", line)
        if match and not line.startswith("="):
            result.setdefault(match.group(1), size(match.group(4)) + size(match.group(5)))
    return result


def megabytes(value):
    return f"{value / 1024 ** 2:+.2f} MB"


def main():
    before, after = sys.argv[1], sys.argv[2]
    rows = int(sys.argv[3]) if len(sys.argv) > 3 else 25
    for label, graph in (("before", before), ("after", after)):
        count, total = leaks(graph)
        print(f"Leaks {label}: {count} objects, {total} bytes")
    heap_before, heap_after = heap(before), heap(after)
    print(f"\nHeap: {sum(c for c, _ in heap_before.values())} -> {sum(c for c, _ in heap_after.values())} objects, "
          f"{megabytes(sum(b for _, b in heap_after.values()) - sum(b for _, b in heap_before.values()))}")
    growth = []
    for name in set(heap_before) | set(heap_after):
        count_before, bytes_before = heap_before.get(name, (0, 0))
        count_after, bytes_after = heap_after.get(name, (0, 0))
        growth.append((bytes_after - bytes_before, count_after - count_before, count_after, name))
    print(f"\nHeap classes that grew the most (bytes, objects, objects after):")
    for grown, counted, count, name in sorted(growth, reverse=True)[:rows]:
        if grown > 0 or counted > 0:
            print(f"{grown:>+10} {counted:>+7} {count:>7}  {name}")
    regions_before, regions_after = regions(before), regions(after)
    print("\nRegions that grew, dirty + swapped:")
    for name in sorted(regions_after, key=lambda n: regions_before.get(n, 0) - regions_after[n]):
        grown = regions_after[name] - regions_before.get(name, 0)
        if abs(grown) >= 64 * 1024:
            print(f"{megabytes(grown):>12}  {name}")


if __name__ == "__main__":
    main()
