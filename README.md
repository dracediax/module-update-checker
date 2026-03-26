# Module Update Checker

### Track, check, and update your KernelSU / Magisk / APatch modules — all from one WebUI.

[![KernelSU](https://img.shields.io/badge/KernelSU-Module-green?style=for-the-badge)](https://github.com/tiann/KernelSU)
[![Magisk](https://img.shields.io/badge/Magisk-Compatible-blue?style=for-the-badge)](https://github.com/topjohnwu/Magisk)
[![APatch](https://img.shields.io/badge/APatch-Compatible-purple?style=for-the-badge)](https://github.com/bmax121/APatch)
[![Android](https://img.shields.io/badge/Android-12%2B-orange?style=for-the-badge)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

---

### Features

| | |
|---|---|
| Auto-discovery | Finds all installed modules automatically |
| GitHub tracking | Checks releases + CI builds for newer versions |
| One-tap update | Download and install directly from the WebUI |
| Notifications | Branded alerts on boot and every 24 hours |
| Instant results | Background checks cached — WebUI loads instantly |
| CI builds | Detects nightly builds from GitHub Actions (with token) |
| Smart muting | Per-module CI notification control |
| Progress bar | Live per-module progress during checks |

> **WIP:** Tap-to-open notifications and home screen shortcut are [in progress](#-wip-features)

---

### Quick Start

```
1. Download the latest .zip from Releases
2. Flash via your module manager
3. Reboot
4. Open the WebUI → toggle modules → Save → Check for Updates
```

That's it. Updates are checked on boot and every 24 hours automatically.

---

### Compatibility

| Manager | Support |
|---------|---------|
| KernelSU Next | Full |
| KernelSU | Full |
| KsuWebUI (standalone) | Full |
| Magisk + KsuWebUI | Full |
| APatch + KsuWebUI | Full |
| Magisk (no WebUI) | Background only |

---

### Pre-filled Repos

Auto-detected — just toggle them on:

<details>
<summary>View all 18 supported modules</summary>

| Module | Repository | Notes |
|--------|-----------|-------|
| Vector / LSPosed | [JingMatrix/LSPosed](https://github.com/JingMatrix/LSPosed) | Formerly LSPosed |
| LSPosed Irena | [re-zero001/LSPosed-Irena](https://github.com/re-zero001/LSPosed-Irena) | CI only, needs token |
| ReZygisk | [PerformanC/ReZygisk](https://github.com/PerformanC/ReZygisk) | |
| ZygiskNext | [Dr-TSNG/ZygiskNext](https://github.com/Dr-TSNG/ZygiskNext) | |
| Shamiko | [LSPosed/LSPosed.github.io](https://github.com/LSPosed/LSPosed.github.io) | |
| TrickyStore | [5ec1cff/TrickyStore](https://github.com/5ec1cff/TrickyStore) | Auto-detected by name |
| TEESimulator | [JingMatrix/TEESimulator](https://github.com/JingMatrix/TEESimulator) | Auto-detected by name |
| TEESimulator-RS | [Enginex0/TEESimulator-RS](https://github.com/Enginex0/TEESimulator-RS) | Auto-detected by name |
| Play Integrity Fix | [KOWX712/PlayIntegrityFix](https://github.com/KOWX712/PlayIntegrityFix) | |
| Tricky Addon UTL | [KOWX712/Tricky-Addon-Update-Target-List](https://github.com/KOWX712/Tricky-Addon-Update-Target-List) | |
| SUSFS | [sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) | May show false updates |
| Yurikey | [Yurii0307/yurikey](https://github.com/Yurii0307/yurikey) | |
| NoHello | [MhmRdd/NoHello](https://github.com/MhmRdd/NoHello) | |
| Anti-Bootloop | [Kolass2004/anti-bootloop-module](https://github.com/Kolass2004/anti-bootloop-module) | |
| DM-Verity Props Spoof | [dracediax/dmverity-props-spoof](https://github.com/dracediax/dmverity-props-spoof) | |
| Module Update Checker | [dracediax/module-update-checker](https://github.com/dracediax/module-update-checker) | |
| Stepless Volume | [dracediax/stepless-volume](https://github.com/dracediax/stepless-volume) | |
| Wireless ADB | [dracediax/wireless-adb](https://github.com/dracediax/wireless-adb) | |

Enter any `owner/repo` manually for modules not listed.

</details>

---

### WIP Features

| Feature | Status | Details |
|---------|--------|---------|
| Tap notification to open WebUI | Companion APK installed, notifications branded | KSU Next intent targeting WIP |
| Home screen shortcut | ShortcutManager integrated | Same intent issue |
| Custom notification icon | System default used | Needs bundled icon |

---

<details>
<summary><b>Settings</b></summary>

**Boot Check Mode**
| Mode | Behavior |
|------|----------|
| Every boot | Always check |
| Every boot (skip <1h) | Default — smart cooldown |
| Once a day | 24h+ since last check |
| Manual only | WebUI button only |

**GitHub Token** — Unlocks CI builds, 5,000 req/hr, per-module muting. No scopes needed.

**API Usage** — Live stats: calls, limit, reset timer, last check.

</details>

<details>
<summary><b>Battery Impact</b></summary>

**Negligible.** One network burst on boot, then sleeps. No persistent services, no wake locks. Companion app runs for milliseconds per broadcast.

</details>

<details>
<summary><b>How It Works</b></summary>

**WebUI** — `ksu.exec()` runs shell commands: `find` for discovery, `curl` for GitHub API, `ksud module install` for updates.

**service.sh** — Checks on boot + every 24h. Caches results. Installs companion APK. Sends branded notifications.

**Companion APK** (12KB) — BroadcastReceiver for notifications via `am broadcast`. No launcher icon, no services.

**Data files** — All at `/data/adb/` (persist across updates): config, cache, token, settings, stats.

</details>

<details>
<summary><b>Known Limitations</b></summary>

- `exec()` returns first line only — all commands use `grep`/`tr` workarounds
- SUSFS reports kernel version, not module version
- String-based version comparison (no semantic ordering)
- CI artifacts require GitHub token
- Update button needs `.zip` release asset

</details>

---

### License

MIT
