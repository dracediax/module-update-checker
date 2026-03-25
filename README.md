# Module Update Checker

> KernelSU module with a WebUI that tracks your installed modules and checks GitHub for updates.

![KernelSU](https://img.shields.io/badge/KernelSU-Module-green?style=flat-square)
![Android](https://img.shields.io/badge/Android-12%2B-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## Features

- **Auto-discovery** — finds all installed modules, including those at non-standard paths (e.g. `/data/adb/rezygisk/`)
- **GitHub release tracking** — checks the GitHub Releases API for each tracked module
- **Smart version matching** — normalizes version strings by stripping build metadata, `-release` suffixes, commit hashes, and parenthetical info
- **Push notifications** — sends an Android notification when updates are found
- **Per-module toggles** — choose which modules to track, with pre-filled repo mappings for common modules
- **Debug panel** — built-in diagnostics to inspect module discovery and API responses

## Screenshots

*Open the WebUI from KernelSU manager to see the module list and check for updates.*

## Install

1. Download the latest zip from [Releases](https://github.com/dracediax/module-update-checker/releases)
2. Flash via **KernelSU Manager**
3. Open the module's **WebUI** from KernelSU Manager
4. Toggle on the modules you want to track, fill in any missing `owner/repo` fields
5. Tap **Save Configuration**, then **Check for Updates Now**

## How It Works

The WebUI runs inside KernelSU's WebUI environment and uses `ksu.exec()` to run shell commands on device.

| Step | What happens |
|------|-------------|
| **Discovery** | `find /data/adb -name module.prop` locates all installed modules |
| **Prop reading** | `grep '^field=' module.prop` extracts each field individually |
| **Update check** | `curl` fetches the latest GitHub release, `tag_name` is compared against the installed version |
| **Notification** | `cmd notification post` sends an Android notification with update details |

All commands pipe through `tr` to collapse multi-line output onto a single line — a workaround for the exec() limitation described below.

## Known Limitations

### `ksu.exec()` returns only the first line

The KSU WebUI `exec()` API truncates output at the first newline. This affects every shell command — `cat`, `ls`, `head`, and `curl` all return only line 1.

**Workaround:** All commands are designed around this constraint:
- Module props: `grep '^key='` returns one matching line
- Directory listings: `find ... | tr '\n' '|'` collapses paths onto one line
- GitHub API: `curl ... | tr -d '\n'` flattens JSON to a single line

### SUSFS (`susfs4ksu`) version mismatch

The SUSFS module's `module.prop` reports the **susfs kernel component version** (e.g. `v2.0.0-0419e67`), not the **module wrapper version** (e.g. `v1.5.2-R26`). These are two different version schemes maintained independently.

If you install SUSFS from a CI/nightly build, the version diverges further from the stable release tags. The update checker will always flag it as mismatched.

**Recommendation:** Leave SUSFS un-tracked. The module has its own built-in `updateJson` update mechanism within KernelSU Manager.

### Version comparison is string-based

The checker normalizes and compares version strings — it does not do semantic version ordering. This means:
- A module at `v2.0` compared to a release tagged `v1.9` will show as "different" (correct), but it won't tell you which is newer
- Modules with unusual version schemes may produce false positives

### GitHub API rate limits

Unauthenticated GitHub API requests are limited to **60/hour**. If you track many modules and check frequently, you may hit this limit. The checker does not currently use authentication.

## Pre-filled Repos

These modules have their GitHub repos pre-filled:

| Module ID | Repository |
|-----------|-----------|
| `zygisk_lsposed` | [JingMatrix/LSPosed](https://github.com/JingMatrix/LSPosed) |
| `rezygisk` | [PerformanC/ReZygisk](https://github.com/PerformanC/ReZygisk) |
| `tricky_store` | [5ec1cff/TrickyStore](https://github.com/5ec1cff/TrickyStore) |
| `playintegrityfix` | [KOWX712/PlayIntegrityFix](https://github.com/KOWX712/PlayIntegrityFix) |
| `susfs4ksu` | [sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) |
| `Yurikey` | [Yurii0307/yurikey](https://github.com/Yurii0307/yurikey) |
| `dmverity-props-spoof` | [dracediax/dmverity-props-spoof](https://github.com/dracediax/dmverity-props-spoof) |

You can manually enter any `owner/repo` for modules not in this list.

## License

MIT
