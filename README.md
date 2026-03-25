# Module Update Checker

KernelSU module with a WebUI that lists your installed KSU modules and checks GitHub for updates.

## Features

- Auto-discovers all installed modules (including non-standard paths)
- Shows module name, version, and ID
- Per-module GitHub repo mapping with pre-filled known repos
- Toggle tracking per module
- Checks GitHub releases for newer versions
- Smart version normalization (strips build metadata, suffixes, etc.)

## Install

Flash the zip via KernelSU manager, then open the module's WebUI.

## How it works

Uses `ksu.exec()` to discover modules via `find` and reads `module.prop` fields with `grep` (workaround for KSU WebUI's single-line exec output). Checks GitHub releases API for `tag_name` to compare against installed versions.

## Known limitation

`ksu.exec()` returns only the first line of command output. All shell commands are designed around this constraint using `grep`, `tr`, and pipe tricks.
