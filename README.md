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
- **Automatic notifications** — checks on boot and every 24 hours, notifies you when updates are found
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
| TrickyStore / TEESimulator | Enter manually: `5ec1cff/TrickyStore` or `JingMatrix/TEESimulator` |
| Play Integrity Fix | [KOWX712/PlayIntegrityFix](https://github.com/KOWX712/PlayIntegrityFix) |
| Tricky Addon UTL | [KOWX712/Tricky-Addon-Update-Target-List](https://github.com/KOWX712/Tricky-Addon-Update-Target-List) |
| SUSFS | [sidex15/susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) |
| Yurikey | [Yurii0307/yurikey](https://github.com/Yurii0307/yurikey) |
| NoHello | [MhmRdd/NoHello](https://github.com/MhmRdd/NoHello) |
| Anti-Bootloop | [Kolass2004/anti-bootloop-module](https://github.com/Kolass2004/anti-bootloop-module) |
| DM-Verity Props Spoof | [dracediax/dmverity-props-spoof](https://github.com/dracediax/dmverity-props-spoof) |
| Vector (zygisk_vector) | [JingMatrix/LSPosed](https://github.com/JingMatrix/LSPosed) |
| Module Update Checker | [dracediax/module-update-checker](https://github.com/dracediax/module-update-checker) |
| Stepless Volume | [dracediax/stepless-volume](https://github.com/dracediax/stepless-volume) |
| Wireless ADB | [dracediax/wireless-adb](https://github.com/dracediax/wireless-adb) |

You can manually enter any `owner/repo` for modules not in this list.

---

<details>
<summary><b>Battery Impact</b></summary>

**Negligible.** The module has no continuous background activity.

- **service.sh** runs a `sleep 60` loop to check for a trigger file — this is a simple file existence check, not a network call. CPU usage is effectively zero.
- **API calls** only happen on boot (once) and every 24 hours (once). With 8 tracked modules, that's 8 short HTTPS requests per day.
- **The WebUI** only runs while you have it open. No background WebView, no persistent process. API stats are read from a file — no polling or timers.
- **Notifications** use Android's built-in `cmd notification post` — no persistent service or wake lock.

In short: one brief network burst on boot, then the module sleeps until the next day.

</details>

---

<details>
<summary><b>Settings</b></summary>

The WebUI has a **Settings** panel with the following options:

### Boot Check Mode

Controls when `service.sh` checks for updates after a reboot:

| Mode | Behavior |
|------|----------|
| **Every boot** | Always checks after reboot, no cooldown — uses an API call every time |
| **Every boot (skip if checked <1h ago)** | Default. Checks on boot but skips if last check was less than 1 hour ago — rebooting 5 times in 30 minutes only triggers 1 check |
| **Once a day** | Only checks if 24+ hours since last check — reboot 10 times today, only checks once |
| **Manual only** | No auto-checks at all — only when you press "Check for Updates Now" in the WebUI |

All modes still allow manual checks via the WebUI button.

**Recommendation:** Leave it on the default. Switch to "Every boot" only if you need instant checks and don't reboot often. Use "Once a day" if you reboot frequently.

### GitHub Token (Optional)

A Personal Access Token increases the API rate limit from **60 to 5,000 requests/hour**. The module works fine without one.

**Setup:**
1. Go to [github.com/settings/tokens](https://github.com/settings/tokens)
2. Click **Generate new token (classic)**
3. Name it (e.g. "module-update-checker")
4. **Leave all scope checkboxes unchecked** — no permissions needed
5. In the WebUI Settings, enable "Use Personal Access Token", paste it, Save Configuration

**Security:** Token is stored in plaintext at `/data/adb/muc_token` (chmod 600). Any root app can read it. No scopes = can only read public repos, but it's tied to your GitHub account.

### API Usage Stats

The Settings panel shows real-time API usage:
- **Calls this hour** — how many API requests have been made
- **Hourly limit** — 60 (no token) or 5,000 (with token)
- **Resets in** — countdown until the hourly limit resets
- **Last check** — how long ago the last update check ran

</details>

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

After boot, `service.sh` waits for network connectivity, then runs continuously:

| When | What happens |
|------|-------------|
| **~30-60s after boot** | Initial check — fetches latest versions from GitHub |
| **Every 24 hours** | Automatic re-check — catches updates even if you don't reboot |
| **Every 60 seconds** | Polls for trigger files (lightweight file check, no network) |
| **Manual check** | Triggered from WebUI "Check for Updates Now" button |

- Results are cached to `/data/adb/muc_update_cache` — WebUI loads these instantly on open
- Notifications are deduplicated within the same boot cycle (won't spam you)

### Data Files

| File | Purpose |
|------|---------|
| `/data/adb/muc_config.json` | Tracked modules config (persists across updates) |
| `/data/adb/muc_update_cache` | Cached check results for instant WebUI display |
| `/data/adb/muc_ksu_package` | Detected KSU manager package name |
| `/data/adb/muc_token` | GitHub Personal Access Token (optional, chmod 600) |
| `/data/adb/muc_settings` | User settings (boot check mode) |
| `/data/adb/muc_api_stats` | API call counter and hour window |
| `/data/adb/muc_last_check` | Timestamp of last update check |

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

Without a token: **60 requests/hour**. With a token: **5,000/hour**. Each tracked module uses one request per check. Normal use won't hit the limit either way — see the GitHub Token section above for setup.

### Update button needs `.zip` asset

The update button only appears if the GitHub release contains a `.zip` file.

</details>

---

## License

MIT
