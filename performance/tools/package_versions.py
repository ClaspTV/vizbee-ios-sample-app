# Prints the Swift packages a checkout resolves to, as "name version" pairs separated by spaces.
# Usage: package_versions.py <checkout dir>
import glob, json, sys
pins = []
for path in glob.glob(sys.argv[1] + '/**/Package.resolved', recursive=True):
    for pin in json.load(open(path)).get('pins', []):
        state = pin.get('state', {})
        pins.append(f"{pin.get('identity')} {state.get('version') or state.get('revision', '')[:8]}")
print(' '.join(sorted(set(pins))) or 'none')
