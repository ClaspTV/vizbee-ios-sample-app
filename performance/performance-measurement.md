# SDK Performance Measurement

This page describes how we measure what the Vizbee SDK costs an app at run time: launch time, CPU, memory, network, hangs, casting and leaks. The same method applies to iOS, Android, Android TV and Fire TV, so results can be compared across platforms and SDK releases.

The scripts are in this folder; [README.md](README.md) covers setup and options for iOS. Each run's summary is kept in `results/<date>-<device>/` (summary files only). Optimisation findings are tracked in the SDK repo's PERFORMANCE-OPTIMIZATION.md.

## Goal

- One command runs everything unattended, and anyone can rerun it on any machine.
- Every platform reports the same metrics in the same CSV format.
- Accuracy first: the same device, the same network and TVs, and the builds measured in turn within each round.
- Results are differences from the app without an SDK, with a 95% range, never raw numbers alone.
- Optimising the SDK is a later, separate step.

## Three builds, three branches

The same sample app (same screens, same videos) is kept on three branches that differ only in the cast SDK. A fourth branch holds the scripts.

| Branch | Build | Cast integration |
|---|---|---|
| `performance/no-sdk` | Without SDK | None. Baseline. |
| `performance/vizbee-sdk` | Vizbee SDK | Vizbee SDK with its own receiver. |
| `performance/google-cast-sdk` | Google Cast SDK | Google Cast SDK with the Default Media Receiver. |
| `performance/tools` | (scripts) | Runner, measurement scripts, summary, README. |

- Each SDK uses its normal production setup, with no tuning for the test.
- The runner builds all three as Release builds from the branch heads on origin. The summary records each build's commit and SDK package versions.
- Each branch holds the UI tests the runner drives: a launch test, and a cast session test that connects to the TV, plays a video, stops it and disconnects. In the Without SDK build the cast test walks through the same screens without casting.

## How it is automated

```
performance/run.sh --device <device id> --tv "<TV name>"           # about 3.5 h on iOS
performance/run.sh --device <device id> --tv "<TV name>" --quick   # 1 round of each, to check the setup
```

`--tv` is part of the TV's name as the cast device list shows it. Steps, in order:

1. **build**: check out each branch from origin and build it.
2. **smoke**: launch each build once, and check that it sends discovery probes and that a TV answers. The run stops here if the network or the TVs are wrong.
3. **launch**, **activity**, **hangs**: launch and home-screen measurements.
4. **cast**, **leaks**, **memgraph**: cast sessions with the TV named in `--tv`.
5. **summary**: one table, `summary.md` and `summary.csv`, with each build's value, the difference from Without SDK and its 95% range.

**launch-phases** is not in the default steps. It splits launch time into phases, such as framework loading and SDK setup in `didFinishLaunching`, to show what to optimise. Run it with `--steps launch-phases` when working on launch time. The launch time difference from the **launch** step is the measurement.

Rules that keep runs comparable:

- Within each round the builds run in turn (Without, Vizbee, Google Cast). If the device slows down during the run, all builds are affected equally.
- Builds that vary little from run to run (Without SDK, Google Cast) are measured in odd rounds only in the activity and cast steps. The precision of a difference depends on the build that varies most, which is measured in every round.
- Every recording has a time limit. A stuck recording is stopped and only that run is dropped.
- Every run is checked for TV answers. Runs where no TV answered are listed in the summary.
- The cast test fails, and its run is dropped, if the video does not start playing on the TV.
- The device must be on the same Wi-Fi as the TVs. The TVs stay on with standby off for the whole run. Compare only runs made with the same TVs. The summary records the network and the TVs that answered.
- Recordings, packet captures and logs stay in the results folder next to the summary.

## How each metric is measured

Run counts are per build, per device.

| Step | Metrics | How (iOS) | Runs |
|---|---|---|---|
| launch | Cold launch time | Xcode launch test (`XCTApplicationLaunchMetric`) | 6 rounds of 5 launches |
| launch-phases (optional) | Process start to first frame, and each launch phase, including SDK setup in `didFinishLaunching` | Instruments App Launch | 10 |
| activity | CPU of the app and of the system Bonjour service, memory footprint, network traffic by type (SSDP, mDNS, LAN, internet). Windows: discovery 5–35 s after launch, idle 60–240 s | Instruments Activity Monitor (all processes) and a packet capture of the device's Wi-Fi traffic | 4-min runs: Vizbee 5, others 3 |
| hangs | Hangs over 250 ms, longest hang | Instruments Time Profiler | 3 runs of 60 s |
| cast | CPU, memory, threads, Mach ports and network before connecting, while playing on the TV and after disconnecting; what is not freed (after minus before) | Cast session test with Activity Monitor and a packet capture | Vizbee 3 sessions, others 2 |
| leaks | Memory growth per connect/disconnect cycle, leaked memory | Cast session test, 10 cycles, with Activity Monitor, then with Instruments Leaks | 1 + 1 |
| memgraph | Leaked objects, and which classes and memory regions grew from the first to the last session | Cast session test, 10 cycles, as an Xcode memory performance test that saves a memory graph on the device before and after | 1 |

How the numbers are computed:

- **CPU** in a window is the CPU time used divided by the window's length.
- **Memory, threads and ports** in a window are the median of the samples. Peak memory is the highest sample.
- **Across runs**: mean for launch, CPU and memory. Median for network, because iOS's own internet traffic sometimes spikes in one run. Maximum for peaks and the longest hang. Total for hang counts.
- **Difference** from Without SDK, with a 95% range from a bootstrap (10,000 resamples).
- **Memory growth per cycle** is the slope of the memory left after each disconnect, over the 10 cycles.

### Why 6 rounds of 5 launches

- The first launch of each round follows a reinstall and is slower: on an iPad 6th gen by 126 ms without an SDK, 199 ms with Vizbee and 63 ms with Google Cast. Launches 2–5 are still cold launches (XCTest ends the app between them) but leave out this one-off cost. With one launch per round every sample would be a first launch.
- Single launches vary by 50–110 ms. With about 30 launches per build the 95% range of a difference is about ±50 ms. With 5 it would be about ±100 ms, too wide to tell the SDKs apart.
- Taking the builds in turn over 6 rounds spreads any drift across all three. Each round costs a reinstall and a test-runner start, so the extra launches within a round are cheap.

## Results format

Every platform writes the same `summary.csv`, one row per metric:

```csv
Device,Scenario,Metric,Unit,no-sdk,vizbee-sdk,vizbee-sdk difference,vizbee-sdk difference %,vizbee-sdk difference 95% range,google-cast-sdk,google-cast-sdk difference,google-cast-sdk difference %,google-cast-sdk difference 95% range,Runs,Statistic,Tool,Notes
"iPad (6th generation), iOS 17.7.11",Launch,Cold launch time (Xcode launch test),ms,848.81,996.84,+148.04,+17.4%,+97.09 to +199.23,1007.36,+158.55,+18.7%,+107.36 to +213.62,20,mean,XCTest: XCTApplicationLaunchMetric,"Every measured launch, rounds of 5 taken in turn across builds"
```

- Scenario and metric names, units and windows are the same on every platform. A metric a platform cannot measure is left out, not filled with a substitute.
- The summary header records the device, the OS version, the build commits, the SDK versions, the network and the TVs that answered.

## Android, Android TV and Fire TV

Keep the same three branches, steps, windows, run counts, statistics and CSV columns, and swap only the tools. Suggested equivalents, driven over `adb` from one script:

| Metric | iOS tool | Android equivalent (suggested) |
|---|---|---|
| Cold launch time | Xcode launch test | Macrobenchmark `StartupTimingMetric`, cold start |
| Launch phases, SDK setup | Instruments App Launch | Perfetto trace, with SDK setup as a trace section in `Application.onCreate` |
| CPU | Activity Monitor | CPU time from `/proc/<pid>/stat`, or Perfetto, over the same windows |
| Memory footprint | Activity Monitor | `dumpsys meminfo` total PSS, sampled over the window |
| Threads, Mach ports | Activity Monitor | Threads from `/proc/<pid>/status`; open file descriptors in place of Mach ports |
| Network by type | Packet capture (rvictl + tcpdump) | tcpdump on a rooted or test device, or PCAPdroid; per-app totals from `dumpsys netstats` |
| Hangs over 250 ms | Time Profiler | Perfetto main-thread slices over 250 ms, or Macrobenchmark `FrameTimingMetric` |
| Cast sessions | XCUITest | UI Automator test with the same steps, and timestamped marks in logcat |
| Leaks | Instruments Leaks | Heap dump after the cycles (LeakCanary or Android Studio), plus the same growth-per-cycle slope |

## Open items

- On Android TV and Fire TV the SDK is the receiver, so "discovery" and "cast" become "advertising" and "receiving a session". The TV scenarios need agreeing before their first run.
- A full packet capture on Android needs a rooted or test device. Without one, report network totals only.
- iOS results so far cover the iPad 6th gen. The iPhone 13 and iPhone 14 runs are still to do.
