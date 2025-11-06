#!/bin/bash
set -euo pipefail

# Screen lock monitor that disables Wi-Fi when screen locks
# This complements SleepWatcher for full coverage

# Optional overrides (same as sleep.sh)
WIFI_DEVICE="${WIFI_DEVICE:-}"
WIFI_SERVICE="${WIFI_SERVICE:-}"

# Detect the Wi‑Fi interface name (same logic as sleep.sh)
detect_wifi_device() {
	# 1) Try ioreg for the active AirPort interface
	if command -v ioreg >/dev/null 2>&1; then
		dev="$(ioreg -r -n AirPort -a 2>/dev/null | sed -n 's/.*\"IOInterfaceName\" = \"\([^"]\+\)\".*/\1/p' | head -n1)" || true
		if [[ -n "$dev" ]]; then echo "$dev"; return 0; fi
	fi

	# 2) Try system_profiler to find the first Wi‑Fi interface
	if command -v system_profiler >/dev/null 2>&1; then
		dev="$(system_profiler SPNetworkDataType 2>/dev/null | awk '/^\s*Hardware/ {inwifi=0} /Wi-Fi|AirPort/ {inwifi=1} inwifi && /BSD Device Name:/ {print $4; exit}')" || true
		if [[ -n "$dev" ]]; then echo "$dev"; return 0; fi
	fi

	# 3) Fallback to networksetup parsing
	if command -v /usr/sbin/networksetup >/dev/null 2>&1; then
		/usr/sbin/networksetup -listallhardwareports 2>/dev/null | awk '
			/^Hardware Port:/ {block=$0; dev=""}
			/^Device:/ {dev=$2}
			/^$/{ if (block ~ /Wi-Fi|AirPort/) { if (dev != "") { print dev; exit } } }
			END { if (block ~ /Wi-Fi|AirPort/ && dev != "") { print dev } }
		'
		return 0
	fi

	return 1
}

if [[ -z "${WIFI_DEVICE}" ]]; then
	WIFI_DEVICE="$(detect_wifi_device || true)"
fi

# Try map device to service name
if [[ -z "${WIFI_SERVICE}" && -n "${WIFI_DEVICE}" ]]; then
	WIFI_SERVICE="$(/usr/sbin/networksetup -listnetworkserviceorder 2>/dev/null | awk -v d="${WIFI_DEVICE}" '/^\(Hardware Port:/ {svc=$0} /Device:/ {if ($0 ~ "Device: " d ")") {sub(/^\(Hardware Port: /, "", svc); sub(/, Device:.*/, "", svc); print svc; exit}}')"
fi

# Fallback to common service names if still empty
if [[ -z "${WIFI_SERVICE}" ]]; then
	for name in "Wi-Fi" "WLAN" "Wi‑Fi" "Airport"; do
		if /usr/sbin/networksetup -listallnetworkservices 2>/dev/null | tail -n +2 | grep -Fxq "$name"; then
			WIFI_SERVICE="$name"; break
		fi
	done
fi

# If detection fails, exit without error
if [[ -z "${WIFI_SERVICE}" ]]; then
	exit 0
fi

# Turn Wi‑Fi off on screen lock
/usr/sbin/networksetup -setairportpower "${WIFI_SERVICE}" off || true

# Log the action (optional)
echo "$(date): Screen locked - Wi-Fi disabled" >> ~/Library/Logs/wifi-screenlock.log 2>/dev/null || true
