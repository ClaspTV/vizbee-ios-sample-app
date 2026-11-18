# SDK performance measurement (iOS)

The method, shared with the other platforms, is described in [SDK Performance Measurement](performance-measurement.md). This page covers running it on iOS.

Measures what an SDK costs an app on a real device, by comparing Release builds of this sample app that differ only in the SDK they contain:

| Build | Branch | Contains |
|---|---|---|
| no-sdk | `performance/no-sdk` | The sample app with no casting SDK (the baseline) |
| vizbee-sdk | `performance/vizbee-sdk` | The sample app with the Vizbee SDK |
| google-cast-sdk | `performance/google-cast-sdk` | The sample app with the Google Cast SDK instead of Vizbee, discovery starting at launch |

The builds and the git refs they come from are listed in `variants.conf`. Change a ref to a commit to pin it, or add a line to compare another build. The first line is the baseline.

## What is measured

| Step | Metric | Tool | Runs (default) |
|---|---|---|---|
| launch | Cold launch time | Xcode launch test (`XCTApplicationLaunchMetric`, `testLaunchPerformance`) | 6 rounds of 5 launches per build |
| launch-phases | Launch time split into phases (process creation, framework loading, `didFinishLaunching`, first frame) | Instruments App Launch | 10 per build |
| activity | Memory footprint, CPU of the app and of mDNSResponder (the system Bonjour service), network traffic, for discovery (5-35 s after launch) and idle (60-240 s) on the home screen | Instruments Activity Monitor (all processes) and a packet capture of the device's traffic | 5 runs of 4 minutes per build |
| hangs | Main-thread hangs over 250 ms during launch and discovery | Instruments Time Profiler (Hangs) | 3 runs of 60 s per build |
| cast | Memory, CPU, threads, Mach ports and network before connecting, while casting and after disconnecting; what is not freed after disconnecting (after minus before) | `CastSessionTests` (connect to the TV, play a video on it for 3 minutes, disconnect, stay 3 minutes), Instruments Activity Monitor (all processes) and a packet capture | 3 runs per build |
| leaks | Memory growth per cycle over 10 cast sessions (connect, 30 s of playback, disconnect), and leaked memory | `CastSessionTests` with Activity Monitor, then with Instruments Leaks | 1 run with Activity Monitor and 1 with Leaks per build |

Every step takes the builds in turn, round by round, so a change on the device during the run (temperature, background activity) affects every build the same way. Each step installs the build it measures; the first launch after an install is not measured.

`summary.md` and `summary.csv` give each metric for every build, the difference from the baseline, and the 95% range of that difference (a bootstrap over the runs). `summary.csv` uses the column order of the Perf-iOS-Details sheet.

## Requirements

- A Mac with Xcode (tested with Xcode 26.3) signed in to an Apple developer team that can sign the sample app.
- `tcpdump` access to `/dev/bpf*` without sudo: install Wireshark's ChmodBPF (it adds you to the `access_bpf` group), then log out and back in.
- The device connected by USB, trusted, with Developer Mode on.
- On the device: Settings > Display & Brightness > Auto-Lock set to Never, the device unlocked, and on the same Wi-Fi network as the TVs.
- The TVs switched on for the whole run, with their automatic standby turned off. Discovery costs depend on the TVs that answer, so use the same TVs when comparing runs.
- Local Network access allowed for the sample app. All builds share one bundle ID, so allowing it once is enough. If the smoke test reports no discovery probes, open the app on the device, tap Allow, and run again.

## Running

```bash
# All steps, about 5 hours
performance/run.sh --device <device udid> --tv <TV name>

# A quick check of the setup: every step once
performance/run.sh --device <device udid> --tv <TV name> --quick

# Some steps only, into an existing results folder
performance/run.sh --device <device udid> --out performance/results/<folder> --steps activity,summary
```

`--tv` is part of the TV's name as the cast device list shows it, for example `BRAVIA`. Both SDKs cast to this TV, each to its usual receiver app (Vizbee's receiver for the Vizbee SDK, the Default Media Receiver for Google Cast), so use a TV that supports both, such as a Chromecast or a TV with Google Cast built in. The build without an SDK goes through the same screens without casting.

Find the device UDID with `xcrun devicectl list devices` or in Xcode's Devices window. Results go to `performance/results/<date>-<device>-iOS-<version>/`. Only `summary.md`, `summary.csv`, `device.json` and `variants.csv` are checked in; recordings, captures and logs stay local:

| File | What it holds |
|---|---|
| `summary.md`, `summary.csv` | The results |
| `device.json`, `variants.csv` | The device, and each build's git ref, commit and package versions |
| `smoke/<build>/discovery.txt` | The device's address and the devices that answered discovery |
| `launch/*.xcresult` | Xcode launch test results; open in Xcode |
| `launch-phases/<build>/run-N.trace` | Instruments App Launch traces |
| `activity/<build>/run-N.trace`, `run-N.pcap`, `run-N.discovery.txt` | Activity Monitor traces, packet captures, and the devices that answered |
| `hangs/<build>/run-N.trace` | Time Profiler traces; see the Hangs lane |
| `cast/<build>/run-N.trace`, `run-N.pcap`, `run-N.log` | Activity Monitor traces, packet captures, and the test log with the time of each step (`PERF_MARK` lines) |
| `cycles/<build>/run-N.*` | The same, for the repeated cast sessions |
| `leaks/<build>.trace` | Instruments Leaks traces; open in Instruments to see each leak and its backtrace |
| `*.csv` in each folder | Every run's values |

The smoke test stops the run if a build crashes, sends no discovery probes, or no TV answers its probes (the discovery type for each build is in `variants.conf`). The devices that answered are listed in `summary.md`. During the activity step, a run where the app sent probes but no TV answered (for example because a TV went to standby) is listed in `activity/no_answer.csv` and flagged in `summary.md`. An Instruments recording still running 2 minutes after its time limit is stopped; a hangs or launch-phases recording is then tried once more, and an activity run is skipped.

Keep the device untouched while it runs. To see one run over time: `tools/activity_timeline.py [process] < activity/<build>/run-N.trace.xml`.

## Notes on accuracy

- Builds are Release builds, built fresh from the refs in `variants.conf` for every run.
- Network traffic is all of the device's Wi-Fi traffic, so it includes other apps and iOS. The links the Xcode tools use to reach the device are excluded. Internet traffic varies with iOS background activity, so its median is used; local network traffic (SSDP, mDNS, LAN) is what the SDKs' discovery sends and receives.
- Bonjour (mDNS) discovery runs in the system process mDNSResponder, not in the app, so it is reported separately and added to the app's CPU.
