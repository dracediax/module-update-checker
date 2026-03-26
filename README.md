# Module Update Checker

> Track, check, and update your KernelSU / Magisk / APatch modules — all from one WebUI.

![KernelSU](https://img.shields.io/badge/KernelSU-Module-green?style=flat-square)
![Magisk](https://img.shields.io/badge/Magisk-Compatible-blue?style=flat-square)
![APatch](https://img.shields.io/badge/APatch-Compatible-purple?style=flat-square)
![Android](https://img.shields.io/badge/Android-12%2B-orange?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## What It Does

- Discovers all installed modules automatically
- Checks GitHub for newer versions
- **One-tap update** — download and install directly from the WebUI
- **Boot notifications** — get notified after every reboot if updates are available
- **Instant results** — background checks are cached, so the WebUI shows updates immediately

---

## Quick Start

1. Download the latest `.zip` from [Releases](https://github.com/dracediax/module-update-checker/releases)
2. Flash via your module manager
3. Open the module's **WebUI**
4. Toggle on modules to track, fill in any missing repos
5. **Save Configuration** → **Check for Updates Now**

That's it. After reboot, you'll get a notification if updates are available.

---

## Compatibility

| Manager | Full Support | Notes |
|---------|-------------|-------|
| [KernelSU Next](https://github.com/rifsxd/KernelSU-Next) | Yes | |
| [KernelSU](https://github.com/tiann/KernelSU) | Yes | |
| [KsuWebUI](https://github.com/adivenxnataly/KsuWebUI) | Yes | Standalone WebUI — works with any manager |
| Magisk + [KsuWebUI](https://github.com/adivenxnataly/KsuWebUI) | Yes | Install KsuWebUI for the full experience |
| APatch + [KsuWebUI](https://github.com/adivenxnataly/KsuWebUI) | Yes | Install KsuWebUI for the full experience |
| Magisk (without KsuWebUI) | Partial | Background checks + notifications work, no WebUI |

---

## Pre-filled Repos

These modules are auto-detected — just toggle them on:

| Module | Repository |
|--------|-----------|
| LSPosed | [JingMatrix/LSPosed](https://github.com/JingMatrix/LSPosed) |
| ReZygisk | [PerformanC/ReZygisk](https://github.com/PerformanC/ReZygisk) |
| ZygiskNext | [Dr-TSNG/ZygiskNext](https://github.com/Dr-TSNG/ZygiskNext) |
| Shamiko | [LSPosed/LSPosed.github.io](https://github.com/LSPosed/LSPosed.github.io) |
| Tricky Store | [5ec1cff/TrickyStore](https://github.com/5ec1cff/TrickyStore) |
| Play Integrity Fix | [KOWX712/PlayIntegrityFix](https://github.com/KOWX712/PlayIntegrityFix) |
| Tricky Addon UTL | [KOWX712/Tricky-Addon-Update-Target-List](https://github.com/KOWX712/Tricky-Addon-Update-Target-List) |
| SUSFS | [sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) |
| Yurikey | [Yurii0307/yurikey](https://github.com/Yurii0307/yurikey) |
| NoHello | [MhmRdd/NoHello](https://github.com/MhmRdd/NoHello) |
| Anti-Bootloop | [Kolass2004/anti-bootloop-module](https://github.com/Kolass2004/anti-bootloop-module) |
| DM-Verity Props Spoof | [dracediax/dmverity-props-spoof](https://github.com/dracediax/dmverity-props-spoof) |
| Module Update Checker | [dracediax/module-update-checker](https://github.com/dracediax/module-update-checker) |

You can manually enter any `owner/repo` for modules not in this list.

---

<details>
<summary><b>How It Works</b></summary>

### WebUI (Manual Check)

The WebUI runs inside the manager's WebUI environment and uses `ksu.exec()` to run shell commands.

| Step | What happens |
|------|-------------|
| **Discovery** | `find /data/adb -name module.prop` locates all installed modules |
| **Prop reading** | `grep '^field=' module.prop` extracts each field individually |
| **Update check** | `curl` fetches the latest GitHub release, `tag_name` is compared against installed version |
| **Update install** | Downloads the `.zip` asset, installs via `ksud module install` (fallback: manual unzip) |
| **Notification** | `su 2000 -c 'cmd notification post'` sends an Android notification |

All commands pipe through `tr` to collapse multi-line output — a workaround for the `ksu.exec()` first-line-only limitation.

### Background Check (service.sh)

After boot, `service.sh` waits for network connectivity, then checks all tracked modules:

- Runs initial check after boot + network ready (~30-60s)
- Caches results to `/data/adb/muc_update_cache` — WebUI loads these instantly
- Re-checks every 24 hours
- Polls every 60s for WebUI trigger files
- Deduplicates notifications within the same boot cycle

### Data Files

| File | Purpose |
|------|---------|
| `/data/adb/muc_config.json` | Tracked modules config (persists across updates) |
| `/data/adb/muc_update_cache` | Cached check results for instant WebUI display |
| `/data/adb/muc_ksu_package` | Detected KSU manager package name |

</details>

<details>
<summary><b>Known Limitations</b></summary>

### exec() returns only the first line

The KSU WebUI `exec()` API truncates at the first newline. All commands are designed around this using `grep` (single-line match) and `tr` (collapse newlines).

### Notifications show as "Shell"

Notifications are posted as shell user (UID 2000) — they appear under "Shell". The title includes "Module Update Checker:" to identify the source.

### Notifications are not tappable

`cmd notification post` doesn't support click intents from the shell context. A companion APK would be needed.

### SUSFS version mismatch

SUSFS reports the kernel component version, not the module version. These are independent version schemes. **Recommendation:** Leave SUSFS un-tracked — it has its own update mechanism.

### String-based version comparison

Versions are normalized and compared as strings, not semantically. `v2.0` vs `v1.9` shows as "different" but doesn't indicate which is newer.

### GitHub rate limits

Unauthenticated requests: **60/hour**. Heavy use may hit this.

### Update button needs `.zip` asset

The update button only appears if the GitHub release contains a `.zip` file.

</details>

---

## License

MIT
