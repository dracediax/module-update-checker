# <img src="https://raw.githubusercontent.com/dracediax/module-update-checker/main/logo.png" width="28" alt=""> Module Update Checker

A root module manager for **KernelSU**, **Magisk**, and **APatch** on Android 12+.
Track, check, and update your modules from one place.

<p>
  <a href="https://github.com/dracediax/module-update-checker/releases"><img src="https://img.shields.io/github/v/release/dracediax/module-update-checker?style=for-the-badge&color=blue&label=Download" alt="Download"></a>
  <img src="https://img.shields.io/badge/Android-12%2B-green?style=for-the-badge" alt="Android 12+">
  <img src="https://img.shields.io/badge/KernelSU-✓-green?style=for-the-badge" alt="KernelSU">
  <img src="https://img.shields.io/badge/Magisk-✓-green?style=for-the-badge" alt="Magisk">
  <img src="https://img.shields.io/badge/APatch-✓-green?style=for-the-badge" alt="APatch">
</p>

## Features

- **Three-tier updates** — stable releases, pre-releases, and CI/nightly builds — shown simultaneously, each with its own color
- **One-tap install** with automatic backup and rollback (restore via gear menu)
- **Batch updates** — select and update multiple modules at once
- **Smart repo matching** — 22+ known repos with fuzzy name detection. Forks and renamed modules auto-resolve (TrickyStore, PIF, Integrity Box, TEESimulator, etc.)
- **Scheduled checks** — pick a daily check time (default 08:00) or check every N hours. One sleep timer, zero polling, zero battery drain. Overdue on next boot? Catches up immediately
- **Notifications** — companion app or shell fallback
- **GitHub token** — unlocks 5,000 API calls/hr, CI build detection, and artifact downloads (`public_repo` scope)
- **Dark & light theme**, search/filter, changelog viewer, debug panel, bug report generator

## Compatibility

| Manager | WebUI | Background | Notifications | Install | Notes |
|---------|:-----:|:----------:|:-------------:|:-------:|-------|
| KernelSU Next | ✅ | ✅ | ✅ | ✅ | |
| KernelSU (tiann) | ✅ | ✅ | ✅ | ✅ | |
| Magisk + KsuWebUI | ✅ | ✅ | ✅ | ✅ | |
| APatch + KsuWebUI | ✅ | ✅ | ✅ | ✅ | |
| KsuWebUI standalone | ✅ | ✅ | ✅ | ✅ | |
| rsuntk KSU | ✅ | ✅ | ✅ | ✅ | Non-GKI support (kernel 4.4+) |
| Wild KSU | ✅ | ✅ | ✅ | ✅ | Extended "WebUI-Next" API |
| SukiSU-Ultra | ✅ | ✅ | ✅ | ✅ | MMRL-enhanced WebUI, built-in SUSFS |
| ReSukiSU | ✅* | ✅* | ✅* | ✅* | Requires metamodule or modules won't mount |

\* Runtime detection (`ksu`/`ksuwebui` objects) — no hardcoded package names. Install falls back to manual extract if `ksud` is renamed.

## Install

1. Download the latest release zip
2. Flash via your module manager
3. Reboot, open WebUI, toggle on modules to track

## Data

All persistent data at `/data/adb/muc/` — survives module updates.

| File | Purpose |
|------|---------|
| `config.json` | Tracked modules and repo mappings |
| `token` | GitHub PAT (chmod 600) |
| `settings` | Check mode, check time, interval (hours), debug, companion, theme |
| `ci_installed` | Modules installed from CI builds (id, artifact, module name) |
| `update_cache` | Background check results for instant display |
| `version_override` | Cached release tags for version-mismatch modules (SUSFS) |
| `last_scheduled_check` | Timestamp of last scheduled check (excludes manual) |
| `history` | Update install log |

## Planned (upon request)

- [ ] Auto-update mode
- [ ] Custom notification sound
- [ ] Randomized package name
- [ ] Magisk terminal setup

<details>
<summary><b>How it works</b></summary>

**WebUI** runs shell commands via `ksu.exec()` — module discovery, GitHub API queries, and module installation all happen through root shell calls from the browser context.

**service.sh** starts after boot, waits for network, then runs the smart scheduler. Two modes: **time-based** (calculates exact seconds until the chosen HH:MM, sleeps, checks, repeats every 24h) or **interval** (every N hours — calculates remaining time to next fire on boot, catches up immediately if overdue). Both modes run a single background sleep with no polling loops and no wakeups between checks.

**Companion app** (~58KB) is a standalone WebView that loads the module's `index.html` via root IPC. No superuser permission needed — the service.sh daemon executes commands on its behalf. Can be disabled in Settings; notifications fall back to shell.

**Notifications** use `su 2000` (shell UID) because Android silently discards notifications posted from root (UID 0). The companion app provides branded, tappable notifications when installed.

</details>
