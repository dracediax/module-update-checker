<h1><img src="logo.png" height="38" align="center" alt=""> Module Update Checker</h1>

**Track, check, and update your root modules — all from one place.**

[![KernelSU](https://img.shields.io/badge/KernelSU-Module-green?style=for-the-badge)](https://github.com/tiann/KernelSU)
[![Magisk](https://img.shields.io/badge/Magisk-Compatible-blue?style=for-the-badge)](https://github.com/topjohnwu/Magisk)
[![APatch](https://img.shields.io/badge/APatch-Compatible-purple?style=for-the-badge)](https://github.com/bmax121/APatch)
[![Android](https://img.shields.io/badge/Android-12%2B-orange?style=for-the-badge)](https://developer.android.com)

---

### Features

- **Auto-discovery** — finds all installed modules, no manual setup
- **One-tap updates** — download, install, or update all at once
- **Notifications** — get notified when modules have updates available, on boot and every 24h
- **Standalone app** — notification tap and home screen shortcut open MUC directly ([see features](#standalone-app) | [hide from root detectors](#hiding-from-root-detectors))
- **Nightly builds** — detects CI/nightly builds from GitHub Actions ([requires token](#github-token))
- **Background checks** — configurable: every boot, daily, or manual only
- **18+ pre-filled repos** — just toggle and go ([see list](#pre-filled-repos))
- **Minimal battery usage** — no persistent services or wake locks ([see Battery & Performance](#battery--performance))

---

### Quick Start

```
1. Download the latest .zip from Releases
2. Flash via KSU / Magisk / APatch
3. Reboot
4. Open the WebUI → toggle modules → Save → Check for Updates
```

Updates are checked automatically on boot and every 24 hours.

---

### Compatibility

| Manager | WebUI | Background | Notifications | Install |
|---------|:-----:|:----------:|:-------------:|:-------:|
| KernelSU Next | Yes | Yes | Yes | Yes |
| KernelSU | Yes | Yes | Yes | Yes |
| KsuWebUI standalone | Yes | Yes | Yes | Yes |
| Magisk + KsuWebUI | Yes | Yes | Yes | Yes |
| APatch + KsuWebUI | Yes | Yes | Yes | Yes |
| Magisk (no WebUI) | — | Yes | Yes | — |

---

### Standalone App

A companion app is bundled with the module and auto-installed on boot. It provides:

- **Direct access** — opens the full MUC WebUI without going through KSU Manager
- **Notification tap** — tap any update notification to jump straight into MUC
- **Home screen shortcut** — pin MUC to your home screen
- **Branded notifications** — shows "Module Update Checker" with custom icon
- **No root grant needed** — communicates with the module's root daemon via IPC, no Superuser prompt required

The module also works inside KSU Manager's WebUI as usual.

---

### Pre-filled Repos

18 modules auto-detected — just toggle them on. Enter any `owner/repo` for others.

<details>
<summary>View all supported modules</summary>

| Module | Repository | Notes |
|--------|-----------|-------|
| Vector / LSPosed | [JingMatrix/LSPosed](https://github.com/JingMatrix/LSPosed) | |
| LSPosed Irena | [re-zero001/LSPosed-Irena](https://github.com/re-zero001/LSPosed-Irena) | [CI only](#github-token) |
| ReZygisk | [PerformanC/ReZygisk](https://github.com/PerformanC/ReZygisk) | |
| ZygiskNext | [Dr-TSNG/ZygiskNext](https://github.com/Dr-TSNG/ZygiskNext) | |
| Shamiko | [LSPosed/LSPosed.github.io](https://github.com/LSPosed/LSPosed.github.io) | |
| TrickyStore | [5ec1cff/TrickyStore](https://github.com/5ec1cff/TrickyStore) | Auto-detected by name |
| TEESimulator | [JingMatrix/TEESimulator](https://github.com/JingMatrix/TEESimulator) | Auto-detected by name |
| TEESimulator-RS | [Enginex0/TEESimulator-RS](https://github.com/Enginex0/TEESimulator-RS) | Auto-detected by name |
| Play Integrity Fix | [KOWX712/PlayIntegrityFix](https://github.com/KOWX712/PlayIntegrityFix) | |
| Tricky Addon UTL | [KOWX712/Tricky-Addon-Update-Target-List](https://github.com/KOWX712/Tricky-Addon-Update-Target-List) | |
| SUSFS | [sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) | Version mismatch possible |
| Yurikey | [Yurii0307/yurikey](https://github.com/Yurii0307/yurikey) | |
| NoHello | [MhmRdd/NoHello](https://github.com/MhmRdd/NoHello) | |
| Anti-Bootloop | [Kolass2004/anti-bootloop-module](https://github.com/Kolass2004/anti-bootloop-module) | |
| DM-Verity Props Spoof | [dracediax/dmverity-props-spoof](https://github.com/dracediax/dmverity-props-spoof) | |
| Module Update Checker | [dracediax/module-update-checker](https://github.com/dracediax/module-update-checker) | Self-updating |
| Stepless Volume | [dracediax/stepless-volume](https://github.com/dracediax/stepless-volume) | |
| Wireless ADB | [dracediax/wireless-adb](https://github.com/dracediax/wireless-adb) | |

</details>

---

### GitHub Token

A personal access token is **optional** but unlocks additional features:

| | Without token | With token |
|---|:---:|:---:|
| Release updates | Yes | Yes |
| API rate limit | 60/hour | 5,000/hour |
| CI/nightly builds | — | Yes |
| CI artifact install | — | Yes |
| Per-module CI muting | — | Yes |

**How to get one:**
1. Go to [github.com/settings/tokens](https://github.com/settings/tokens)
2. Generate new token (classic)
3. Leave **all scopes unchecked** — no permissions needed
4. Paste it in Settings > GitHub Token

**Security:** The token is stored in plaintext at `/data/adb/muc_token` (chmod 600). It has no scopes, so it can only read public repos — but it is tied to your GitHub account. Any root app could read it.

> **CI-only modules** like [LSPosed Irena](https://github.com/re-zero001/LSPosed-Irena) publish builds via GitHub Actions instead of Releases. A token is required to detect and download these nightly builds.

---

<details>
<summary><b>Settings</b></summary>

| Boot check mode | Behavior |
|------|----------|
| Every boot | Always checks on reboot |
| Every boot (skip if <1h) | Default — skips if checked recently |
| Once a day | Checks if 24+ hours since last |
| Manual only | Only checks when you press the button |

</details>

<details>
<summary><b>How It Works</b></summary>

**WebUI** — Runs shell commands via `ksu.exec()`: `find` for module discovery, `curl` for GitHub API, `ksud module install` for updates.

**service.sh** — Background daemon that checks on boot + every 24h, caches results, installs the companion app, sends notifications, and runs a root IPC handler for the standalone app.

**Companion app** (~58KB) — Standalone WebView that loads the module's WebUI directly. Communicates with the root daemon via file-based IPC — no Superuser permission needed. Also handles notifications and home screen shortcuts.

**Data** — Config, cache, token, and settings stored at `/data/adb/muc/` so they persist across module updates.

</details>

<details>
<summary><b>Battery & Performance</b></summary>

**Negligible.** One network burst on boot, then idle. No persistent services or wake locks. The IPC daemon uses <1% CPU (20ms poll interval, no-op when idle).

</details>

<details>
<summary><b>Known Limitations</b></summary>

- SUSFS reports kernel version instead of module version — may show false updates
- CI artifacts require a [GitHub token](#github-token)
- Update button requires a `.zip` release asset
- Some modules share the same ID (e.g. TrickyStore / TEESimulator) — resolved automatically by module name

</details>

<details>
<summary><b>Hiding from Root Detectors</b></summary>

The standalone companion app (`com.dracediax.muc`) is visible in the package list and could be flagged by root detection apps. To hide it:

1. Install [HMA-OSS](https://github.com/myflavor/HMA-OSS) (Hide My Applist)
2. Add `com.dracediax.muc` to the hide list
3. Select which apps should not see it (e.g. banking apps, games with root detection)

HMA-OSS hides the app from package manager queries — root detectors won't know it's installed. The module itself (`module-update-checker` in `/data/adb/modules/`) should be handled separately via SUSFS or similar.

</details>

---

### Planned Features

These features are on the roadmap. If you'd like to see one prioritized, [open an issue](https://github.com/dracediax/module-update-checker/issues).

| Feature | Description |
|---------|-------------|
| Auto-update mode | Download and install updates automatically without user interaction |
| Custom notification sound | Configurable alert sound for update notifications |
| Randomized package name | Generate random APK package name at flash time to avoid root detection without HMA |
| Magisk terminal setup | `setup.sh` for configuring tracked modules without WebUI |
| Update history | Log of what was updated and when |

---

### License

MIT
