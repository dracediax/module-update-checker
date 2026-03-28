# Module Update Checker

<p align="center">
  <img src="https://raw.githubusercontent.com/dracediax/module-update-checker/main/logo.png" width="80" alt="MUC Logo">
</p>

Track, check, and update your root modules — all from one place.

## Features

<details open>
<summary><b>Update Management</b></summary>

- **Three-tier updates** — Release (green), Pre-release (purple), CI/nightly (amber) shown simultaneously
- **One-tap install** — download and flash modules directly from the WebUI
- **Batch updates** — select multiple modules and update them all at once
- **Rollback** — automatic backup before every update, restore via ⚙ menu
- **Changelog viewer** — view release notes before installing
- **CI install marker** — installed nightly builds show in amber with (CI) tag
</details>

<details>
<summary><b>Module Discovery</b></summary>

- Auto-discovers all installed modules from `/data/adb/modules/`
- 19 pre-configured repositories (TrickyStore, PlayIntegrityFix, LSPosed, Vector, ReZygisk, Shamiko, SUSFS, and more)
- Smart name-based resolution for modules sharing the same ID
- Custom repository input for any GitHub-hosted module
- Search and filter modules in real-time
</details>

<details>
<summary><b>Notifications</b></summary>

- Boot check with configurable modes (every boot, cooldown, daily, manual)
- Background polling every 24 hours
- Companion app for tappable notifications with branded icon
- Shell fallback when companion is disabled
</details>

<details>
<summary><b>GitHub Token</b></summary>

- Without token: 60 API calls/hour, release checks only
- With token: 5,000 calls/hour + CI build detection + artifact downloads
- Token needs `public_repo` scope for CI artifact downloads
- Stored at `/data/adb/muc/token` (chmod 600)
</details>

<details>
<summary><b>UI</b></summary>

- Dark and light theme (toggle in Settings)
- Per-module settings via ⚙ icon (top-right corner)
- Debug panel with download logs, API stats, service log
- Bug report generator (sanitized, copy to clipboard)
- Progressive module loading with progress bar
</details>

## Compatibility

| Manager | WebUI | Background Checks | Notifications | Install |
|---------|-------|-------------------|---------------|---------|
| KernelSU Next | ✅ | ✅ | ✅ | ✅ |
| KernelSU (tiann) | ✅ | ✅ | ✅ | ✅ |
| KsuWebUI (standalone) | ✅ | ✅ | ✅ | ✅ |
| Magisk + KsuWebUI | ✅ | ✅ | ✅ | ✅ |
| APatch + KsuWebUI | ✅ | ✅ | ✅ | ✅ |

## Install

1. Download the latest release zip
2. Flash via your module manager
3. Reboot
4. Open WebUI → toggle on modules you want to track

## Data

All persistent data lives at `/data/adb/muc/` — survives module updates.

| File | Purpose |
|------|---------|
| `config.json` | Tracked modules and settings |
| `token` | GitHub PAT (chmod 600) |
| `settings` | Boot mode, debug toggle, companion toggle |
| `ci_installed` | Modules installed from CI builds |
| `update_cache` | Cached update results for instant display |
| `history` | Update install history |

## Planned

- [ ] Auto-update mode (download + install without interaction)
- [ ] Custom notification sound
- [ ] Randomized package name
- [ ] Magisk terminal setup (configure without WebUI)
