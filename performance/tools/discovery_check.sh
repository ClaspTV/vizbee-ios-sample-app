#!/bin/bash
#
#  discovery_check.sh
#
#  Reads a network capture and prints the device's local address, how many discovery probes
#  the device sent, and one line per device that answered:
#    SSDP <address> <SERVER header>     (Vizbee and other UPnP discovery)
#    Cast <instance name>               (Google Cast Bonjour discovery)
#
#  Usage: ./discovery_check.sh <capture.pcap> <ssdp|googlecast|any>
#
set -uo pipefail

PCAP=$1
TYPE=$2

packets() { tcpdump -r "$PCAP" -n "$@" 2> /dev/null; }

address=$(packets 'ip and not dst net 10.0.0.0/8 and not dst net 172.16.0.0/12 and not dst net 192.168.0.0/16 and not ip multicast and not ip broadcast' | grep -oE ' IP (10|172\.(1[6-9]|2[0-9]|3[01])|192\.168)\.[0-9]+\.[0-9]+\.[0-9]+ > ' | awk '{sub(/\.[0-9]+$/, "", $2); print $2}' | sort | uniq -c | sort -rn | awk 'NR == 1 {print $2}')
echo "Device address: $address"
probes=0
if [ "$TYPE" = ssdp ] || [ "$TYPE" = any ]; then
    probes=$((probes + $(packets 'udp dst port 1900 and dst host 239.255.255.250' | wc -l)))
fi
if [ "$TYPE" = googlecast ] || [ "$TYPE" = any ]; then
    probes=$((probes + $(packets 'udp port 5353' | grep -F '_googlecast._tcp.local' | grep -cF '?' || true)))
fi
echo "Probes: $probes"
if [ "$TYPE" = ssdp ] || [ "$TYPE" = any ]; then
    packets -A 'udp src port 1900 and not dst host 239.255.255.250' \
        | awk '/^[0-9:.]+ IP / {split($3, a, "."); ip = a[1] "." a[2] "." a[3] "." a[4]; if (!(ip in server)) server[ip] = ""} toupper($0) ~ /^SERVER:/ {sub(/\r$/, ""); server[ip] = substr($0, 9)} END {for (ip in server) print "SSDP " ip " " server[ip]}' \
        | sort -k2,2
fi
if [ "$TYPE" = googlecast ] || [ "$TYPE" = any ]; then
    packets 'udp port 5353' | grep -F '_googlecast._tcp.local' | grep -vF '?' \
        | grep -oE '[^ ]+\._googlecast\._tcp\.local' | grep -v '^_' | sed 's/\._googlecast\._tcp\.local$//' \
        | sort -u | sed 's/^/Cast /'
fi
exit 0
