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
- Checks GitHub **releases and CI builds** for newer versions
- **One-tap update** — download and install directly from the WebUI
- **Notifications** — checks on boot and every 24 hours, notifies when updates are found
- **Instant results** — background checks are cached, WebUI shows updates immediately
- **Smart CI handling** — CI builds shown as info when release is current, notifies when unmuted
- **Per-module CI muting** — mute CI notifications per repo (CI info + update button still visible)
- **Progress bar** — shows per-module progress during update check
- **Companion app** — bundled 12KB helper for branded notifications

---

## Quick Start

1. Download the latest `.zip` from [Releases](https://github.com/dracediax/module-update-checker/releases)
2. Flash via your module manager
3. Reboot (companion app installs automatically)
4. Open the module's **WebUI**
5. Toggle on modules to track, fill in any missing repos
6. **Save Configuration** → **Check for Updates Now**

After reboot, you'll get a notification if updates are available.

---

## Compatibility

| Manager | Full Support |
|---------|-------------|
| [KernelSU Next](https://github.com/rifsxd/KernelSU-Next) | Yes |
| [KernelSU](https://github.com/tiann/KernelSU) | Yes |
| [KsuWebUI](https://github.com/adivenxnataly/KsuWebUI) | Yes — standalone, works with any manager |
| Magisk + [KsuWebUI](https://github.com/adivenxnataly/KsuWebUI) | Yes |
| APatch + [KsuWebUI](https://github.com/adivenxnataly/KsuWebUI) | Yes |
| Magisk (without KsuWebUI) | Partial — background checks + notifications, no WebUI |

---

## Pre-filled Repos

These modules are auto-detected — just toggle them on:

| Module | Repository | Notes |
|--------|-----------|-------|
| Vector / LSPosed | [JingMatrix/LSPosed](https://github.com/JingMatrix/LSPosed) | Formerly LSPosed, now rebranded as Vector |
| LSPosed Irena | [re-zero001/LSPosed-Irena](https://github.com/re-zero001/LSPosed-Irena) | CI builds only — no releases, download requires GitHub token |
| ReZygisk | [PerformanC/ReZygisk](https://github.com/PerformanC/ReZygisk) | |
| ZygiskNext | [Dr-TSNG/ZygiskNext](https://github.com/Dr-TSNG/ZygiskNext) | |
| Shamiko | [LSPosed/LSPosed.github.io](https://github.com/LSPosed/LSPosed.github.io) | |
| TrickyStore | [5ec1cff/TrickyStore](https://github.com/5ec1cff/TrickyStore) | Auto-detected by name, shares module ID `tricky_store` |
| TEESimulator | [JingMatrix/TEESimulator](https://github.com/JingMatrix/TEESimulator) | Auto-detected by name, shares module ID `tricky_store` |
| TEESimulator-RS | [Enginex0/TEESimulator-RS](https://github.com/Enginex0/TEESimulator-RS) | Auto-detected by name, shares module ID `tricky_store` |
| Play Integrity Fix | [KOWX712/PlayIntegrityFix](https://github.com/KOWX712/PlayIntegrityFix) | |
| Tricky Addon UTL | [KOWX712/Tricky-Addon-Update-Target-List](https://github.com/KOWX712/Tricky-Addon-Update-Target-List) | |
| SUSFS | [sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) | Reports kernel version, not module version — may show false updates |
| Yurikey | [Yurii0307/yurikey](https://github.com/Yurii0307/yurikey) | |
| NoHello | [MhmRdd/NoHello](https://github.com/MhmRdd/NoHello) | |
| Anti-Bootloop | [Kolass2004/anti-bootloop-module](https://github.com/Kolass2004/anti-bootloop-module) | |
| DM-Verity Props Spoof | [dracediax/dmverity-props-spoof](https://github.com/dracediax/dmverity-props-spoof) | |
| Module Update Checker | [dracediax/module-update-checker](https://github.com/dracediax/module-update-checker) | |
| Stepless Volume | [dracediax/stepless-volume](https://github.com/dracediax/stepless-volume) | |
| Wireless ADB | [dracediax/wireless-adb](https://github.com/dracediax/wireless-adb) | |

You can manually enter any `owner/repo` for modules not in this list.

---

## WIP Features

These features are partially implemented and being worked on:

| Feature | Status | What's needed |
|---------|--------|---------------|
| **Tap notification to open WebUI** | Companion APK installed, broadcasts work, but tap intent doesn't launch KSU WebUI | Need to find correct intent/activity for KSU Next's randomized package |
| **Home screen shortcut** | ShortcutManager code in APK, but shortcut doesn't appear | Same KSU intent issue — shortcut target activity may not be exported |
| **Custom notification icon** | Using system default icon | Need to bundle a proper icon in the APK |

**Current notification behavior:** Shows as "Module Update Checker" (not "Shell") but tapping does nothing yet.

---

<details>
<summary><b>Battery Impact</b></summary>

**Negligible.** No continuous background activity.

- **service.sh** — `sleep 60` loop for trigger file check (file existence, no network)
- **API calls** — once on boot, once every 24 hours
- **WebUI** — only runs while open, no background process
- **Companion app** — no services, no wake locks, only runs for a split second when a broadcast arrives

</details>

<details>
<summary><b>Settings</b></summary>

### Boot Check Mode

| Mode | Behavior |
|------|----------|
| **Every boot** | Always checks, no cooldown |
| **Every boot (skip if checked <1h ago)** | Default — saves API calls if you reboot often |
| **Once a day** | Only if 24+ hours since last check |
| **Manual only** | No auto-checks — only via WebUI button |

### GitHub Token

A token unlocks:
- **5,000 req/hr** (vs 60)
- **CI/nightly build detection** from GitHub Actions
- **One-tap CI installs**
- **Per-module "Mute CI notifications"** toggle

The module works without a token — you just won't see CI builds.

### API Usage Stats

Live display: calls used, hourly limit, reset timer, last check time.

</details>

<details>
<summary><b>CI Builds</b></summary>

- With token: checks both releases AND CI builds for every module
- Without token: CI only checked as fallback when no releases exist
- CI only shown when downloadable artifacts exist (no false positives)
- **Release up to date?** CI shown as grey info — no notification
- **CI unmuted?** Triggers notification + "Update to CI" button
- **Muted?** Info still visible, no notification
- Each module has "Mute CI notifications" checkbox (only with token)

</details>

<details>
<summary><b>How It Works</b></summary>

### WebUI

| Step | What happens |
|------|-------------|
| **Discovery** | `find /data/adb -name module.prop` |
| **Prop reading** | `grep '^field=' module.prop` per field |
| **Update check** | `curl` GitHub Releases API, fallback to Actions API |
| **Install** | Downloads `.zip`, installs via `ksud module install` (fallback: manual unzip) |
| **Notification** | Companion APK via `am broadcast`, fallback to `su 2000 cmd notification post` |

### Background (service.sh)

| When | What |
|------|------|
| After boot | Install companion APK, grant permissions, check for updates |
| Every 24h | Re-check |
| Every 60s | Poll for trigger files (no network) |

### Data Files

All at `/data/adb/` — persist across module updates:

| File | Purpose |
|------|---------|
| `muc_config.json` | Tracked modules |
| `muc_update_cache` | Cached results for instant WebUI |
| `muc_ksu_package` | KSU manager package name |
| `muc_token` | GitHub token (optional) |
| `muc_settings` | Boot mode, debug toggle |
| `muc_api_stats` | API call counter |
| `muc_last_check` | Last check timestamp |

</details>

<details>
<summary><b>Known Limitations</b></summary>

- **exec() returns first line only** — all commands use `grep`/`tr` workarounds
- **Notifications not tappable** — companion APK installed but KSU WebUI intent not yet working (WIP)
- **SUSFS version mismatch** — reports kernel version, not module version
- **String-based version comparison** — no semantic ordering
- **Rate limits** — 60/hr without token, 5,000/hr with token
- **Update button needs .zip asset** — only for releases with downloadable zips
- **CI artifacts need token** — GitHub Actions downloads require authentication

</details>

---

## License

MIT
