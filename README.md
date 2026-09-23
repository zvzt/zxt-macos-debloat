# ZXT macOS Debloat

A configurable macOS background-service optimizer focused on reducing optional background work without blindly disabling core macOS infrastructure.

ZXT now defaults to a **Balanced** profile and lets you choose whether to keep or disable **Siri**, **Apple Intelligence**, and **Spotlight indexing**.

> Designed primarily for personal Apple Silicon Macs. Service labels vary between macOS releases, so ZXT automatically skips labels that are not present on your system.

## Quick install / update

Run this in Terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zvzt/zxt-macos-debloat/main/install.sh)
```

The first install opens a setup wizard. Existing installs keep their saved configuration when updated.

Python 3 is required. If you use Homebrew and do not already have Python 3:

```bash
brew install python
```

## First-time setup

The installer asks four things:

1. **Profile**
   - `balanced` — recommended for most people; trims telemetry, analytics, experiments, Tips, and promotional background work.
   - `aggressive` — adds many more optional services. It can affect HomeKit, Screen Time, family controls, Sidecar, printing, controllers, Photos analysis, Maps helpers, and other Apple features.
2. **Siri**
   - `keep` — Siri stays available.
   - `disable` — disables the Siri launchd targets in the optional Siri module.
3. **Apple Intelligence**
   - `keep` — Apple Intelligence services stay available.
   - `disable` — disables the optional Apple Intelligence service module.
4. **Spotlight indexing**
   - `keep` — recommended. ZXT leaves Spotlight indexing alone.
   - `off` — disables indexing on the startup volume using `mdutil`. Spotlight file-content search may be reduced until indexing is re-enabled.

ZXT does **not** disable Spotlight's core launchd infrastructure. Spotlight indexing is controlled separately and can be restored at any time.

Apple documents Spotlight privacy/indexing behavior here: [Apple Support — Spotlight search privacy](https://support.apple.com/guide/mac-help/mchl1bb43b84/mac).

## Common commands

Show your current configuration and status:

```bash
zxt status
```

Open the configuration wizard again:

```bash
zxt configure
```

Preview what ZXT would change without changing anything:

```bash
zxt apply --dry-run
```

Apply your saved configuration:

```bash
zxt apply
```

Check the installation and required macOS tools:

```bash
zxt doctor
```

List selected services and whether they exist on this macOS build:

```bash
zxt list
```

Restore changes made by ZXT:

```bash
zxt restore
```

Show every command:

```bash
zxt help
```

## Change features quickly

Switch between the two profiles:

```bash
zxt profile balanced
zxt profile aggressive
```

Keep or disable Siri:

```bash
zxt siri keep
zxt siri disable
```

Keep or disable Apple Intelligence:

```bash
zxt intelligence keep
zxt intelligence disable
```

Spotlight controls:

```bash
zxt spotlight status
zxt spotlight keep
zxt spotlight off
zxt spotlight on
zxt spotlight reindex
```

`zxt spotlight keep` means "leave Spotlight alone" and restores indexing only if ZXT previously disabled it. `zxt spotlight on` explicitly enables indexing. `zxt spotlight reindex` rebuilds the Spotlight index and can temporarily increase CPU and disk activity.

## What changed in v2

- Balanced profile is now the default.
- Aggressive extras are separated from the safer base profile.
- Siri is optional instead of always being disabled.
- Apple Intelligence is optional instead of always being disabled.
- Spotlight is a separate explicit choice.
- `zxt apply --dry-run` previews changes.
- `zxt doctor` checks the installation.
- `zxt configure` provides a repeatable setup wizard.
- `zxt` with no arguments now shows status instead of immediately making changes.
- Restore state only records launchd targets that ZXT actually changed. Services already disabled before ZXT are left owned by the user/system and are not re-enabled by normal restore.
- Updating preserves your config and state.
- Startup reapply jobs remain limited to ZXT-selected launchd targets.
- A dedicated uninstaller restores ZXT-managed changes before removing ZXT.

## Safety model

ZXT intentionally does **not** target core services such as `launchd`, `WindowServer`, `tccd`, `securityd`, `powerd`, `runningboardd`, `dasd`, `mds`, `mdworker`, or CoreSpotlight infrastructure.

The Balanced profile is the recommended choice if you want fewer background processes without intentionally removing major macOS features.

The Aggressive profile is for personal Macs where you understand the feature tradeoffs. Do not use the Aggressive profile on a managed/work Mac unless you know which services your organization requires.

Before applying a profile, you can always run:

```bash
zxt apply --dry-run
```

## Restore

To restore launchd changes recorded by ZXT and restore Spotlight if ZXT was the tool that disabled it:

```bash
zxt restore
```

Restart macOS afterward so restored services can return normally.

## Uninstall

Run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zvzt/zxt-macos-debloat/main/uninstall.sh)
```

The uninstaller first calls `zxt restore`, removes only ZXT's own LaunchAgents/LaunchDaemon and command symlink, then removes `~/.zxt-macos-debloat`.

## Files

```text
~/.zxt-macos-debloat/
├── zxt
├── config.json
├── presets/
│   ├── balanced.txt
│   ├── aggressive.txt
│   ├── siri.txt
│   └── apple-intelligence.txt
└── state/
```

ZXT installs the command at:

```text
/usr/local/bin/zxt
```

## Troubleshooting

### `zxt: command not found`

Run:

```bash
ls -l /usr/local/bin/zxt
```

If the link is missing, run the installer again.

### Something you use stopped working

First switch back to the Balanced profile and keep optional features enabled:

```bash
zxt profile balanced
zxt siri keep
zxt intelligence keep
zxt spotlight keep
```

If needed, restore all ZXT-managed changes:

```bash
zxt restore
```

### Spotlight search is incomplete

Enable indexing:

```bash
zxt spotlight on
```

If Spotlight itself is behaving incorrectly, rebuild the index:

```bash
zxt spotlight reindex
```

Reindexing can take time and temporarily use more CPU/disk.

## Credits

This project was inspired by and originally based on work from [OleksandrKrupko/mac-os-debloat](https://github.com/OleksandrKrupko/mac-os-debloat).

Maintained as ZXT macOS Debloat by [zvzt](https://github.com/zvzt).
