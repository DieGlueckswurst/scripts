### mac_os_helper: SleepWatcher Wi‑Fi toggle

This helper automates disabling Wi‑Fi when your Mac sleeps/locks and re‑enables it on wake using SleepWatcher.

- **Sleep script**: turns Wi‑Fi off
- **Wake script**: turns Wi‑Fi on
- **Auto‑detects** your Wi‑Fi device (e.g., en0). You can override via `WIFI_DEVICE`.

### Requirements
- macOS
- Homebrew (`brew`)

### Quick start

```bash
cd mac_os_helper
chmod +x install_sleepwatcher.sh
./install_sleepwatcher.sh
```

What this does:
- Installs `sleepwatcher` via Homebrew if needed
- Copies scripts to `$(brew --prefix)/etc/sleep` and `$(brew --prefix)/etc/wake`
- Starts (or restarts) the SleepWatcher service

### Disable re-enable on wake (optional)
If you want Wi‑Fi to stay off after sleep/wake (so you can visually confirm it is off), install with wake disabled:

```bash
./install_sleepwatcher.sh --no-wake
# or
DISABLE_WAKE=1 ./install_sleepwatcher.sh
```


Re‑enable later by reinstalling without the flag.

### Override Wi‑Fi interface (optional)
By default, we auto‑detect your Wi‑Fi device using `networksetup -listallhardwareports`. To force a device (e.g., `en1`):

```bash
export WIFI_DEVICE=en1
./install_sleepwatcher.sh
```

You can also edit the installed files directly at:
- `$(brew --prefix)/etc/sleep`
- `$(brew --prefix)/etc/wake`

### Verify
- Check Wi‑Fi service names (preferred):
  ```bash
  networksetup -listallnetworkservices | tail -n +2
  ```
- Check service status: `brew services list | grep sleepwatcher`

### Uninstall / Disable
```bash
brew services stop sleepwatcher
rm -f "$(brew --prefix)/etc/sleep" "$(brew --prefix)/etc/wake"
# Optional: brew uninstall sleepwatcher
```

### Notes
- The Homebrew service for SleepWatcher looks for scripts at `$(brew --prefix)/etc/sleep` and `$(brew --prefix)/etc/wake`.
- If auto‑detection fails (rare), the scripts exit without error; set `WIFI_DEVICE` to override.
- Locking your screen is not always treated as a full system sleep by macOS. SleepWatcher reliably runs on sleep/wake; screen lock behavior can vary by version and settings.
