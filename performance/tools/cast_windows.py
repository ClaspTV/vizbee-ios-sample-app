# Reads the PERF_MARK lines CastSessionTests printed and prints the measurement windows, in seconds
# after the app's launch (the "launched" mark), followed by the launch time as epoch seconds:
#   before        the 30 s before the first connect
#   casting-N     the last 2 minutes of playback in cycle N (at most two thirds of it)
#   after-N       the last minute after disconnecting in cycle N (at most half of it)
# A margin of 5 s keeps each window clear of the test's taps.
# Usage: cast_windows.py < xcodebuild.log
# Prints: "launch <epoch>" then "<window> <from s> <to s>" lines
import re, sys
marks = {(m[1], int(m[2])): float(m[3]) for m in re.finditer(r'PERF_MARK (\S+) (\d+) ([\d.]+)', sys.stdin.read())}
if ('launched', 0) not in marks:
    sys.exit('no PERF_MARK lines')
launch = marks[('launched', 0)]
at = lambda name, cycle: marks[(name, cycle)] - launch
print(f'launch {launch:.3f}')
print(f"before {at('connect', 1) - 30:.1f} {at('connect', 1) - 5:.1f}")
cycle = 1
while ('end', cycle) in marks:
    casting = at('disconnect', cycle) - at('playing', cycle)
    after = at('end', cycle) - at('disconnected', cycle)
    print(f"casting-{cycle} {at('disconnect', cycle) - min(120, casting * 2 / 3):.1f} {at('disconnect', cycle) - 5:.1f}")
    print(f"after-{cycle} {at('end', cycle) - min(60, after / 2):.1f} {at('end', cycle) - 1:.1f}")
    cycle += 1
