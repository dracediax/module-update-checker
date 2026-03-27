<h1><img src="logo.png" height="38" align="center" alt=""> Module Update Checker</h1>

### Track, check, and update your KernelSU / Magisk / APatch modules — all from one WebUI.

[![KernelSU](https://img.shields.io/badge/KernelSU-Module-green?style=for-the-badge)](https://github.com/tiann/KernelSU)
[![Magisk](https://img.shields.io/badge/Magisk-Compatible-blue?style=for-the-badge)](https://github.com/topjohnwu/Magisk)
[![APatch](https://img.shields.io/badge/APatch-Compatible-purple?style=for-the-badge)](https://github.com/bmax121/APatch)
[![Android](https://img.shields.io/badge/Android-12%2B-orange?style=for-the-badge)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

---

### Features

| Feature | Description |
|---------|-------------|
| Auto-discovery | Finds all installed modules automatically |
| GitHub tracking | Checks releases + CI builds for newer versions |
| One-tap update | Download and install directly from the WebUI |
| Update All | Single button to update all modules at once |
| Semantic versioning | Proper numeric comparison (handles rc tags, multi-part versions) |
| Notifications | Branded alerts with custom icon on boot and every 24h |
| Notification tap | Opens KSU Manager on tap |
| Instant results | Background checks cached — WebUI loads instantly |
| CI builds | Detects nightly builds from GitHub Actions (with token) |
| CI artifact install | Unwraps and installs CI artifacts directly |
| Smart muting | Per-module CI notification control |
| Progress bar | Live per-module progress during checks |

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

| Manager | WebUI | Background Checks | Notifications | Update Install |
|---------|-------|-------------------|---------------|---------------|
| KernelSU Next | Full | Full | Full | Full |
| KernelSU | Full | Full | Full | Full |
| KsuWebUI (standalone) | Full | Full | Full | Full |
| Magisk + KsuWebUI | Full | Full | Full | Full |
| APatch + KsuWebUI | Full | Full | Full | Full |
| Magisk (no WebUI) | N/A | Full | Full | N/A |

**WebUI APIs supported:** `ksu.exec()`, `ksuwebui.exec()` — works across KernelSU, KSU Next, and KsuWebUI standalone.

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
| Module Update Checker | [dracediax/module-update-checker](https://github.com/dracediax/module-update-checker) | Self-updating |
| Stepless Volume | [dracediax/stepless-volume](https://github.com/dracediax/stepless-volume) | |
| Wireless ADB | [dracediax/wireless-adb](https://github.com/dracediax/wireless-adb) | |

Enter any `owner/repo` manually for modules not listed.

</details>

---

### Companion APK

A lightweight companion app (16KB) is bundled and auto-installed on boot for enhanced notifications:

| Feature | Status |
|---------|--------|
| Branded notifications | "Module Update Checker" sender name |
| Custom notification icon | MUC logo icon |
| Tap notification | Opens KSU Manager |
| Home screen shortcut | WIP — ShortcutManager integration |

The module works fully without the companion app — falls back to shell notifications.

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

**service.sh** — Checks on boot + every 24h. Caches results. Installs/updates companion APK. Sends branded notifications.

**Companion APK** (16KB) — BroadcastReceiver for notifications via `am broadcast`. No launcher icon, no services.

**Data files** — All at `/data/adb/` (persist across updates): config, cache, token, settings, stats.

</details>

<details>
<summary><b>Known Limitations</b></summary>

- `exec()` returns first line only — all commands use `grep`/`tr` workarounds
- SUSFS reports kernel version, not module version
- CI artifacts require GitHub token
- Update button needs `.zip` release asset
- KSU Next WebUI activity is not exported — can't deep-link notification tap to module page

</details>

---

### License

MIT
