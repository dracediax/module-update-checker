<h1><img src="https://raw.githubusercontent.com/dracediax/module-update-checker/main/logo.png" width="32" style="vertical-align:middle" alt=""> Module Update Checker</h1>

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
- **One-tap install** with automatic backup and rollback (restore via ⚙ menu)
- **Batch updates** — select and update multiple modules at once
- **19 pre-filled repos** — TrickyStore, PlayIntegrityFix, LSPosed, Vector, ReZygisk, Shamiko, SUSFS, and more
- **Notifications** — configurable boot checks, 24h background polling, companion app or shell fallback
- **GitHub token** — unlocks 5,000 API calls/hr, CI build detection, and artifact downloads (`public_repo` scope)
- **Dark & light theme**, search/filter, changelog viewer, debug panel, bug report generator

## Compatibility

| Manager | WebUI | Background | Notifications | Install |
|---------|:-----:|:----------:|:-------------:|:-------:|
| KernelSU Next | ✅ | ✅ | ✅ | ✅ |
| KernelSU (tiann) | ✅ | ✅ | ✅ | ✅ |
| KsuWebUI standalone | ✅ | ✅ | ✅ | ✅ |
| Magisk + KsuWebUI | ✅ | ✅ | ✅ | ✅ |
| APatch + KsuWebUI | ✅ | ✅ | ✅ | ✅ |

## Install

1. Download the latest release zip
2. Flash via your module manager
3. Reboot → open WebUI → toggle on modules to track

## Data

All persistent data at `/data/adb/muc/` — survives module updates.

| File | Purpose |
|------|---------|
| `config.json` | Tracked modules and repo mappings |
| `token` | GitHub PAT (chmod 600) |
| `settings` | Boot mode, debug, companion toggle |
| `ci_installed` | Modules installed from CI builds |
| `update_cache` | Background check results for instant display |
| `history` | Update install log |

## Planned (upon request)

- [ ] Auto-update mode
- [ ] Custom notification sound
- [ ] Randomized package name
- [ ] Magisk terminal setup
