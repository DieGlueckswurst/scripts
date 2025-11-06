#!/bin/bash
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
	echo "Homebrew is required. Install from https://brew.sh and re-run." >&2
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

# Parse arguments
DISABLE_WAKE="${DISABLE_WAKE:-0}"
ENABLE_SCREENLOCK="${ENABLE_SCREENLOCK:-1}"

for arg in "$@"; do
	case "$arg" in
		--no-wake)
			DISABLE_WAKE=1
			shift
			;;
		--no-screenlock)
			ENABLE_SCREENLOCK=0
			shift
			;;
		--help|-h)
			echo "Usage: $0 [--no-wake] [--no-screenlock]"
			echo "  --no-wake      Disable Wi-Fi re-enable on wake"
			echo "  --no-screenlock Disable screen lock monitoring"
			exit 0
			;;
		*) ;;
	esac
done

echo "=== Installing Complete Wi-Fi Auto-Disable ==="
echo "This will disable Wi-Fi on:"
echo "- Sleep/lid close (via SleepWatcher)"
if [[ "$ENABLE_SCREENLOCK" == "1" ]]; then
	echo "- Screen lock Command+Control+Q (via Launch Agent)"
fi
echo

# 1. Install SleepWatcher component
echo "1. Setting up SleepWatcher for sleep/wake events..."
BREW_PREFIX="$(brew --prefix)"
TARGET_DIR="${BREW_PREFIX}/etc"
SLEEP_TARGET="${TARGET_DIR}/sleep"
WAKE_TARGET="${TARGET_DIR}/wake"

# Install sleepwatcher
echo "Installing sleepwatcher via Homebrew (if needed)..."
brew list sleepwatcher >/dev/null 2>&1 || brew install sleepwatcher

# Ensure target directory exists
mkdir -p "${TARGET_DIR}"

# Copy scripts
install -m 755 "${SCRIPT_DIR}/scripts/sleep.sh" "${SLEEP_TARGET}"
if [[ "${DISABLE_WAKE}" != "1" ]]; then
	install -m 755 "${SCRIPT_DIR}/scripts/wake.sh" "${WAKE_TARGET}"
else
	rm -f "${WAKE_TARGET}"
fi

# Ensure executable
chmod +x "${SLEEP_TARGET}" || true
[[ -f "${WAKE_TARGET}" ]] && chmod +x "${WAKE_TARGET}" || true

# Start/restart sleepwatcher
if brew services list | awk '$1=="sleepwatcher" {found=1} END {exit !found}'; then
	brew services restart sleepwatcher
else
	brew services start sleepwatcher
fi

echo "✓ SleepWatcher configured"

# 2. Install screen lock monitoring (if enabled)
if [[ "$ENABLE_SCREENLOCK" == "1" ]]; then
	echo
	echo "2. Setting up screen lock monitoring..."
	
	# Make scripts executable
	chmod +x "${SCRIPT_DIR}/scripts/screenlock_monitor.sh"
	chmod +x "${SCRIPT_DIR}/scripts/lock_detector.py"
	
	# Create Launch Agent directory
	mkdir -p "${LAUNCH_AGENTS_DIR}"
	
	# Create Launch Agent plist with correct path
	PLIST_PATH="${LAUNCH_AGENTS_DIR}/com.user.screenlock.plist"
	DETECTOR_SCRIPT="${SCRIPT_DIR}/scripts/lock_detector.py"
	
	# Replace placeholder with actual script path
	sed "s|SCRIPT_PATH_PLACEHOLDER|${DETECTOR_SCRIPT}|g" "${SCRIPT_DIR}/com.user.screenlock.plist" > "${PLIST_PATH}"
	
	# Load the Launch Agent
	launchctl unload "${PLIST_PATH}" 2>/dev/null || true
	launchctl load "${PLIST_PATH}"
	
	echo "✓ Screen lock monitoring configured"
else
	echo "2. Screen lock monitoring disabled (use --no-screenlock to change)"
fi

echo
echo "=== Setup Complete ==="
echo "Sleep script: ${SLEEP_TARGET}"
if [[ -f "${WAKE_TARGET}" ]]; then
	echo "Wake script: ${WAKE_TARGET}"
else
	echo "Wake script: (disabled)"
fi

if [[ "$ENABLE_SCREENLOCK" == "1" ]]; then
	echo "Screen lock agent: ${LAUNCH_AGENTS_DIR}/com.user.screenlock.plist"
	echo "Logs: /tmp/screenlock-monitor.out"
fi

echo
echo "Wi-Fi will now disable on:"
echo "- Sleep/lid close"
if [[ "$ENABLE_SCREENLOCK" == "1" ]]; then
	echo "- Screen lock (Command+Control+Q)"
fi

echo
echo "Test by closing laptop lid or locking screen!"
echo
echo "To uninstall:"
echo "  brew services stop sleepwatcher"
if [[ "$ENABLE_SCREENLOCK" == "1" ]]; then
	echo "  launchctl unload ~/Library/LaunchAgents/com.user.screenlock.plist"
	echo "  rm ~/Library/LaunchAgents/com.user.screenlock.plist"
fi
