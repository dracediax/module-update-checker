# Module Update Checker

> KernelSU module with a WebUI that tracks your installed modules, checks GitHub for updates, and can update them directly.

![KernelSU](https://img.shields.io/badge/KernelSU-Module-green?style=flat-square)
![Android](https://img.shields.io/badge/Android-12%2B-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## Features

- **Auto-discovery** — finds all installed modules, including those at non-standard paths (e.g. `/data/adb/rezygisk/`)
- **GitHub release tracking** — checks the GitHub Releases API for each tracked module
- **Smart version matching** — normalizes version strings by stripping build metadata, `-release` suffixes, commit hashes, and parenthetical info
- **One-tap updates** — download and install module updates directly from the WebUI
- **Self-updating** — can detect and update itself
- **Push notifications** — Android notification on boot when updates are found, and on manual check
- **Background checks** — `service.sh` runs a 24-hour auto-check cycle after boot with network-aware startup
- **Notification dedup** — won't re-fire the same notification if the same updates are still pending
- **Persistent config** — configuration survives module updates (stored at `/data/adb/muc_config.json`)
- **Dynamic KSU manager detection** — auto-detects the KSU manager package name (supports randomized package names)
- **Per-module toggles** — choose which modules to track, with pre-filled repo mappings for common modules
- **Reboot prompt** — banner and reboot button appear after installing updates
- **Debug panel** — built-in diagnostics for module discovery, version normalization, API calls, and notification attempts

## Install

1. Download the latest zip from [Releases](https://github.com/dracediax/module-update-checker/releases)
2. Flash via **KernelSU Manager**
3. Open the module's **WebUI** from KernelSU Manager
4. Toggle on the modules you want to track, fill in any missing `owner/repo` fields
5. Tap **Save Configuration**, then **Check for Updates Now**

## How It Works

### WebUI (Manual Check)

The WebUI runs inside KernelSU's WebUI environment and uses `ksu.exec()` to run shell commands on device.

| Step | What happens |
|------|-------------|
| **Discovery** | `find /data/adb -name module.prop` locates all installed modules |
| **Prop reading** | `grep '^field=' module.prop` extracts each field individually |
| **Update check** | `curl` fetches the latest GitHub release, `tag_name` is compared against the installed version |
| **Update install** | Downloads the release `.zip` asset, installs via `ksud module install` (fallback: manual unzip) |
| **Notification** | `su 2000 -c 'cmd notification post'` sends an Android notification |

All commands pipe through `tr` to collapse multi-line output onto a single line — a workaround for the `ksu.exec()` first-line-only limitation.

### Background Check (service.sh)

After boot, `service.sh` waits for network connectivity (pings `github.com`), then checks all tracked modules against GitHub. If updates are found, it posts a single consolidated notification.

- Runs an initial check ~30s after boot
- Polls every 60s for WebUI trigger files (immediate notification relay)
- Re-checks every 24 hours
- Deduplicates notifications — won't re-fire if the same updates are still pending

## Known Limitations

### `ksu.exec()` returns only the first line

The KSU WebUI `exec()` API truncates output at the first newline. All commands are designed around this:
- Module props: `grep '^key='` returns one matching line
- Directory listings: `find ... | tr '\n' '|'` collapses paths onto one line
- GitHub API: `curl ... | tr -d '\n'` flattens JSON to a single line

### Notifications show as "Shell"

Android notifications are posted via `cmd notification post` as the shell user (UID 2000). This means they appear under the "Shell" app name. The notification title includes "Module Update Checker:" to identify the source. Changing the sender name would require a companion APK.

### Notifications are not interactive

Tapping the notification does not open the KSU Manager WebUI. Android's `cmd notification post` does not support content intents from the shell user context. A companion APK would be needed for tap-to-open functionality.

### SUSFS (`susfs4ksu`) version mismatch

The SUSFS module's `module.prop` reports the **kernel component version**, not the **module wrapper version**. These are independently maintained version schemes.

**Recommendation:** Leave SUSFS un-tracked. It has its own built-in update mechanism within KernelSU Manager.

### Version comparison is string-based

The checker normalizes and compares version strings — it does not do semantic version ordering. Modules at `v2.0` compared to a release tagged `v1.9` will show as "different" but won't indicate which is newer.

### GitHub API rate limits

Unauthenticated GitHub API requests are limited to **60/hour**. If you track many modules and check frequently, you may hit this limit.

### Update button requires `.zip` release asset

The one-tap update button only appears if the GitHub release contains a `.zip` file in its assets. Releases with only source archives won't show the button.

## Pre-filled Repos

These modules have their GitHub repos pre-filled:

| Module ID | Repository |
|-----------|-----------|
| `zygisk_lsposed` | [JingMatrix/LSPosed](https://github.com/JingMatrix/LSPosed) |
| `rezygisk` | [PerformanC/ReZygisk](https://github.com/PerformanC/ReZygisk) |
| `tricky_store` | [5ec1cff/TrickyStore](https://github.com/5ec1cff/TrickyStore) |
| `playintegrityfix` | [KOWX712/PlayIntegrityFix](https://github.com/KOWX712/PlayIntegrityFix) |
| `TA_utl` | [KOWX712/Tricky-Addon-Update-Target-List](https://github.com/KOWX712/Tricky-Addon-Update-Target-List) |
| `susfs4ksu` | [sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) |
| `Yurikey` | [Yurii0307/yurikey](https://github.com/Yurii0307/yurikey) |
| `dmverity-props-spoof` | [dracediax/dmverity-props-spoof](https://github.com/dracediax/dmverity-props-spoof) |
| `module-update-checker` | [dracediax/module-update-checker](https://github.com/dracediax/module-update-checker) |

You can manually enter any `owner/repo` for modules not in this list.

## License

MIT
