#!/bin/bash
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
	echo "Homebrew is required. Install from https://brew.sh and re-run." >&2
	exit 1
fi

BREW_PREFIX="$(brew --prefix)"
TARGET_DIR="${BREW_PREFIX}/etc"
SLEEP_TARGET="${TARGET_DIR}/sleep"
WAKE_TARGET="${TARGET_DIR}/wake"

 echo "Installing sleepwatcher via Homebrew (if needed)..."
brew list sleepwatcher >/dev/null 2>&1 || brew install sleepwatcher

# Ensure target directory exists
mkdir -p "${TARGET_DIR}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Args: --no-wake or env DISABLE_WAKE=1 skips installing the wake script
DISABLE_WAKE="${DISABLE_WAKE:-0}"
for arg in "$@"; do
	case "$arg" in
		--no-wake)
			DISABLE_WAKE=1
			shift
			;;
		*) ;;
	 esac
done

# Copy scripts to the locations used by the Homebrew service plist
install -m 755 "${SCRIPT_DIR}/scripts/sleep.sh" "${SLEEP_TARGET}"
if [[ "${DISABLE_WAKE}" != "1" ]]; then
	install -m 755 "${SCRIPT_DIR}/scripts/wake.sh" "${WAKE_TARGET}"
else
	rm -f "${WAKE_TARGET}"
fi

# Ensure executable
chmod +x "${SLEEP_TARGET}" || true
[[ -f "${WAKE_TARGET}" ]] && chmod +x "${WAKE_TARGET}" || true

# Start/restart daemon so changes take effect
if brew services list | awk '$1=="sleepwatcher" {found=1} END {exit !found}'; then
	brew services restart sleepwatcher
else
	brew services start sleepwatcher
fi

echo "Setup complete."
echo "Sleep script: ${SLEEP_TARGET}"
if [[ -f "${WAKE_TARGET}" ]]; then
	echo "Wake script: ${WAKE_TARGET}"
else
	echo "Wake script: (disabled)"
fi
echo "Tip: export WIFI_DEVICE=en0 to override interface detection."
echo "Tip: pass --no-wake or set DISABLE_WAKE=1 to disable wake re-enable."
