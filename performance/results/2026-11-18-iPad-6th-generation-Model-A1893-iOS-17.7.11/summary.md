# SDK performance: iPad (6th generation) (Model A1893), iOS 17.7.11

Device: iPad (3) (iPad (6th generation) (Model A1893), iPad7,5), iOS 17.7.11

| Build | Git ref | Commit | Packages |
|---|---|---|---|
| no-sdk | origin/performance/no-sdk | f8ac925c1f | none |
| vizbee-sdk | origin/performance/vizbee-sdk | d7e6e14d44 | google-cast-sdk-m1 4.8.0 vizbee-homeos-sdk 1.0.3 vizbee-homesso-sdk 1.0.3 vizbee-ios-sdk 6.10.0 |
| google-cast-sdk | origin/performance/google-cast-sdk | d2380d1e8a | google-cast-sdk-m1 4.8.0 |

Network: device address 192.168.1.241. Devices that answered discovery in the smoke test:

- vizbee-sdk: SSDP 192.168.1.145 Linux/2.6 UPnP/1.1 quick_ssdp/1.1
- vizbee-sdk: SSDP 192.168.1.185 Roku/16.0.4 UPnP/1.0 Roku/16.0.4
- vizbee-sdk: Cast BRAVIA-BF1-45e92f25e3181d3ec7d21baa1a85fd1e
- google-cast-sdk: Cast BRAVIA-BF1-45e92f25e3181d3ec7d21baa1a85fd1e

Warning: in these activity runs the app sent discovery probes but no TV answered, so their discovery and idle values do not include talking to TVs: google-cast-sdk run 1, google-cast-sdk run 2, google-cast-sdk run 4.

Values are the statistic over all runs; differences are against no-sdk, with the 95% range in brackets.

| Scenario | Metric | Unit | no-sdk | vizbee-sdk | google-cast-sdk | Runs |
|---|---|---|---|---|---|---|
| Launch | Cold launch time (Xcode launch test) | ms | 848.81 | 996.84 (+148.04, +97.09 to +199.23) | 1007.36 (+158.55, +107.36 to +213.62) | 20 |
| Launch | Cold launch time, without the first launch of each round | ms | 823.63 | 957.01 (+133.37, +97.51 to +168.69) | 994.82 (+171.19, +121.73 to +230.88) | 16 |
| Launch | Process start to first frame | ms | 645.68 | 758.46 (+112.78, +97.76 to +127.45) | 918.86 (+273.18, +248.73 to +294.07) | 9 |
| Launch phase | Process creation | ms | 368.92 | 350.35 (-18.57, -38.01 to +1.37) | 373.42 (+4.5, -18.71 to +26.82) | 9 |
| Launch phase | System interface initialization | ms | 15.17 | 36.53 (+21.36, +16.68 to +27.19) | 29.12 (+13.95, +9.19 to +19.28) | 9 |
| Launch phase | Static runtime initialization (frameworks and static initializers) | ms | 5.68 | 30.11 (+24.43, +19.14 to +31.08) | 17.32 (+11.64, +10.37 to +12.94) | 9 |
| Launch phase | UIKit initialization | ms | 50.26 | 45.37 (-4.89, -9.05 to -0.76) | 43.6 (-6.66, -11.88 to -1.02) | 9 |
| Launch phase | UIKit scene creation | ms | 2.25 | 3.15 (+0.9, -0.15 to +2.26) | 3.09 (+0.84, -0.04 to +2) | 9 |
| Launch phase | didFinishLaunchingWithOptions (SDK setup) | ms | 29.59 | 126.1 (+96.51, +89.69 to +103.76) | 236.62 (+207.03, +194.66 to +218.73) | 9 |
| Launch phase | Initial frame rendering | ms | 173.79 | 166.84 (-6.95, -15.93 to +1.88) | 215.67 (+41.88, +30.37 to +53.15) | 9 |
| Discovery | Memory footprint | MB | 11.7 | 18.68 (+6.98, +6.68 to +7.3) | 14.58 (+2.88, +2.84 to +2.9) | 5 |
| Discovery | Peak memory footprint | MB | 11.9 | 19.6 (+7.7) | 14.7 (+2.8) | 5 |
| Discovery | CPU usage (app) | % | 0.01 | 2.11 (+2.1, +1.96 to +2.28) | 0.13 (+0.12, +0.09 to +0.15) | 5 |
| Discovery | CPU usage (mDNSResponder, system Bonjour service) | % | 0.03 | 0.13 (+0.11, +0.06 to +0.16) | 0.15 (+0.13, +0.07 to +0.18) | 5 |
| Discovery | CPU usage (app + mDNSResponder) | % | 0.04 | 2.24 (+2.21, +2.06 to +2.37) | 0.28 (+0.25, +0.17 to +0.31) | 5 |
| Discovery | Network traffic (total) | KB per min | 11 | 150.9 (+139.9, +109.6 to +158.8) | 20.1 (+9.1, -1.8 to +47.1) | 5 |
| Discovery | Network traffic (local network: SSDP, mDNS, DNS, LAN) | KB per min | 4.64 | 127 (+122.36, +113.18 to +130.54) | 21.28 (+16.64, +3.52 to +32.28) | 5 |
| Discovery | Network traffic: SSDP | KB per min | 0 | 38.48 (+38.48, +36.28 to +41.22) | 0 (+0, +0 to +0) | 5 |
| Discovery | Network traffic: mDNS | KB per min | 3.08 | 12.68 (+9.6, +3.38 to +16.38) | 14.74 (+11.66, +1.8 to +27.08) | 5 |
| Discovery | Network traffic: LAN (HTTP to devices) | KB per min | 1.36 | 75.84 (+74.48, +63.94 to +84.76) | 6.54 (+5.18, -0.48 to +14.58) | 5 |
| Discovery | Network traffic (internet) | KB per min | 8.3 | 24.5 (+16.2, +0.1 to +26.9) | 10 (+1.7, -4.2 to +5.1) | 5 |
| Idle | Memory footprint | MB | 11.62 | 18.64 (+7.02, +6.74 to +7.3) | 14.54 (+2.92, +2.86 to +2.98) | 5 |
| Idle | Peak memory footprint | MB | 11.9 | 19.6 (+7.7) | 14.9 (+3) | 5 |
| Idle | CPU usage (app) | % | 0.01 | 1.4 (+1.39, +1.34 to +1.43) | 0.13 (+0.12, +0.11 to +0.12) | 5 |
| Idle | CPU usage (mDNSResponder, system Bonjour service) | % | 0.02 | 0.13 (+0.11, +0.09 to +0.13) | 0.13 (+0.11, +0.09 to +0.14) | 5 |
| Idle | CPU usage (app + mDNSResponder) | % | 0.03 | 1.53 (+1.5, +1.45 to +1.54) | 0.26 (+0.23, +0.2 to +0.26) | 5 |
| Idle | Network traffic (total) | KB per min | 10.1 | 28.3 (+18.2, -575.7 to +42.9) | 20.9 (+10.8, -583.1 to +50.6) | 5 |
| Idle | Network traffic (local network: SSDP, mDNS, DNS, LAN) | KB per min | 4.72 | 24.44 (+19.72, +17.54 to +21.78) | 11.84 (+7.12, +4.46 to +9.92) | 5 |
| Idle | Network traffic: SSDP | KB per min | 0 | 1.58 (+1.58, +1.44 to +1.68) | 0 (+0, +0 to +0) | 5 |
| Idle | Network traffic: mDNS | KB per min | 2.84 | 10.58 (+7.74, +6.16 to +9.32) | 10 (+7.16, +4.96 to +9.7) | 5 |
| Idle | Network traffic: LAN (HTTP to devices) | KB per min | 1.38 | 11.52 (+10.14, +9.36 to +11.12) | 1.3 (-0.08, -0.16 to +0) | 5 |
| Idle | Network traffic (internet) | KB per min | 3.8 | 4.1 (+0.3, -591.6 to +20.8) | 10 (+6.2, -585.7 to +45.1) | 5 |
| Launch + Discovery | Hangs over 250 ms in the first 35 s | count | 0 | 0 (+0) | 0 (+0) | 3 |
| Launch + Discovery | Hangs after 35 s | count | 0 | 0 (+0) | 0 (+0) | 3 |
| Launch + Discovery | Longest hang | ms | 0 | 0 (+0) | 0 (+0) | 3 |
| Cast: before connecting | Memory footprint | MB | 23.5 | 29.77 (+6.27, +5.63 to +6.8) | 26.63 (+3.13, +3.03 to +3.23) | 3 |
| Cast: before connecting | CPU usage (app) | % | 0 | 0.32 (+0.32, +0.3 to +0.34) | 0.13 (+0.13, +0.12 to +0.13) | 3 |
| Cast: before connecting | CPU usage (app + mDNSResponder) | % | 0.01 | 0.41 (+0.41, +0.39 to +0.42) | 0.26 (+0.25, +0.22 to +0.27) | 3 |
| Cast: before connecting | Threads | count | 3 | 11 (+8, +8 to +8) | 6.83 (+3.83, +3 to +5) | 3 |
| Cast: before connecting | Mach ports | count | 126 | 170.67 (+44.67, +43.67 to +45.67) | 147.83 (+21.83, +20 to +23.5) | 3 |
| Cast: before connecting | Network traffic (LAN, to the TVs) | KB per min | 1.3 | 2.5 (+1.2, +0 to +3.6) | 1.7 (+0.4, +0 to +0.6) | 3 |
| Cast: before connecting | Network traffic (total) | KB per min | 3.1 | 24.7 (+21.6, +13.6 to +23.8) | 14.9 (+11.8, +4.4 to +569.3) | 3 |
| Cast: casting | Memory footprint | MB | 25.43 | 36.53 (+11.1, +10.73 to +11.53) | 32.53 (+7.1, +6.93 to +7.23) | 3 |
| Cast: casting | CPU usage (app) | % | 0.01 | 3.91 (+3.9, +3.81 to +4.03) | 1.08 (+1.07, +1.01 to +1.11) | 3 |
| Cast: casting | CPU usage (app + mDNSResponder) | % | 0.03 | 4.01 (+3.98, +3.89 to +4.11) | 1.22 (+1.19, +1.15 to +1.24) | 3 |
| Cast: casting | Threads | count | 3 | 11.33 (+8.33, +8 to +9) | 8.33 (+5.33, +5 to +6) | 3 |
| Cast: casting | Mach ports | count | 140.67 | 218 (+77.33, +76.33 to +78.33) | 214 (+73.33, +70.33 to +75.33) | 3 |
| Cast: casting | Network traffic (LAN, to the TVs) | KB per min | 1.4 | 69.63 (+68.23, +67.3 to +70) | 17.8 (+16.4, +15.7 to +16.8) | 3 |
| Cast: casting | Network traffic (total) | KB per min | 5.9 | 82.8 (+76.9, +58 to +77.4) | 34.2 (+28.3, +6.5 to +67.8) | 3 |
| Cast: after disconnecting | Memory footprint | MB | 25.37 | 35.7 (+10.33, +10.03 to +10.63) | 32.23 (+6.87, +6.73 to +6.97) | 3 |
| Cast: after disconnecting | CPU usage (app) | % | 0 | 0.23 (+0.23, +0.21 to +0.25) | 0.13 (+0.13, +0.11 to +0.16) | 3 |
| Cast: after disconnecting | CPU usage (app + mDNSResponder) | % | 0 | 0.43 (+0.43, +0.4 to +0.47) | 0.25 (+0.25, +0.2 to +0.32) | 3 |
| Cast: after disconnecting | Threads | count | 3 | 11 (+8, +8 to +8) | 6.67 (+3.67, +3 to +4) | 3 |
| Cast: after disconnecting | Mach ports | count | 136.33 | 194.33 (+58, +56.67 to +59) | 210.33 (+74, +73.33 to +74.67) | 3 |
| Cast: after disconnecting | Network traffic (LAN, to the TVs) | KB per min | 1.4 | 4.83 (+3.43, +2.8 to +3.9) | 1.23 (-0.17, -0.37 to +0) | 3 |
| Cast: after disconnecting | Network traffic (total) | KB per min | 6.5 | 147.7 (+141.2, +8.1 to +281.8) | 14.5 (+8, +3.3 to +27.5) | 3 |
| Cast: not freed after disconnecting | Memory footprint | MB | 1.87 | 5.93 (+4.07, +3.77 to +4.43) | 5.6 (+3.73, +3.53 to +3.93) | 3 |
| Cast: not freed after disconnecting | Threads | count | 0 | 0 (+0, +0 to +0) | -0.17 (-0.17, -2 to +1) | 3 |
| Cast: not freed after disconnecting | Mach ports | count | 10.33 | 23.67 (+13.33, +11.67 to +15) | 62.5 (+52.17, +50.17 to +54.67) | 3 |
| Cast: not freed after disconnecting | CPU usage (app) | % | 0 | -0.09 (-0.09, -0.09 to -0.08) | 0 (+0, -0.01 to +0.03) | 3 |
| Repeated cast sessions | Memory growth per cycle | MB per cycle | 0.02 | 0.48 (+0.45) | 0.07 (+0.04) | 1 |
| Repeated cast sessions | Memory after the last cycle minus before the first | MB | 2.3 | 9.6 (+7.3) | 6.3 (+4) | 1 |
| Repeated cast sessions | Threads after the last cycle minus before the first | count | 0 | 0 (+0) | 1 (+1) | 1 |
