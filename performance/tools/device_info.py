# Reads `xcrun devicectl list devices --json-output` and describes one device by its UDID.
# Usage: device_info.py <udid> <devices.json> [--short]
#   --short prints "<devicectl identifier> <file-safe name>"; otherwise prints JSON.
import json, re, sys
udid, path = sys.argv[1:3]
for device in json.load(open(path))['result']['devices']:
    hardware, properties = device['hardwareProperties'], device['deviceProperties']
    if hardware.get('udid') != udid:
        continue
    if '--short' in sys.argv:
        name = re.sub(r'[^A-Za-z0-9]+', '-', hardware.get('marketingName', 'device')).strip('-')
        print(device['identifier'], f"{name}-iOS-{properties.get('osVersionNumber', '')}")
    else:
        print(json.dumps({'udid': udid, 'identifier': device['identifier'], 'name': properties.get('name'),
                          'model': hardware.get('marketingName'), 'product_type': hardware.get('productType'),
                          'os_version': properties.get('osVersionNumber'), 'os_build': properties.get('osBuildUpdate')}, indent=2))
    break
