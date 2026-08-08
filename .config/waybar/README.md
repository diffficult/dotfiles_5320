# Warmind Waybar

This directory stores the Waybar configuration that Waybar loads directly at runtime.

## Live install targets

- `config/waybar/*` → `~/.config/waybar/*`
- `config/warmind/waybar/*` → `~/.config/warmind/waybar/*`

## Ownership split

### `config/waybar/`
Waybar-native config consumed directly by Waybar:
- `config.jsonc`
- `modules/*.jsonc`
- `style.css`, `colors.css`, `styles/*.css`
- `scripts/waybar_manager.py`
- module-facing helper scripts still considered part of the Waybar config surface

### `config/warmind/waybar/`
Warmind-owned backend/helpers used by the Waybar config but not part of Waybar's native tree.
Current examples:
- `bin/calendar_daemon.py`
- `bin/calendar_select.sh`
- `bin/calendar-bar-output.py`
- `bin/toggle-calendar.sh`

## Inventory policy

Waybar is intentionally flexible on this machine. Layout, module enablement, ordering, and monitor placement are managed dynamically through `waybar_manager.py`, so the repo stores both the active config and the available module inventory.

The inventory is curated with four states:

### Supported
Maintained, expected to work, and part of the current runtime model.

Current supported modules:
- `workspaces.jsonc`
- `window.jsonc`
- `submap.jsonc`
- `swaync.jsonc`
- `tray.jsonc`
- `pulseaudio.jsonc`
- `screen-recording.jsonc`
- `warmind-calendar.jsonc`
- `clock.jsonc`
- `cpu-script.jsonc`
- `gpu-script.jsonc`
- `disk-script.jsonc`
- `network-script.jsonc`
- `updates-script.jsonc`
- `weather-script.jsonc`

Current supported scripts/backends:
- `scripts/waybar_manager.py`
- `scripts/cpu.sh`
- `scripts/disk.sh`
- `scripts/gpu.sh`
- `scripts/network.sh`
- `scripts/pacman.sh`
- `scripts/screen-recording.sh`
- `scripts/weather-openmeteo.sh`
- `../warmind/waybar/bin/calendar_daemon.py`
- `../warmind/waybar/bin/calendar_select.sh`
- `../warmind/waybar/bin/calendar-bar-output.py`
- `../warmind/waybar/bin/toggle-calendar.sh`

### Variant
Alternative implementations kept on purpose. Not active by default, but still considered valid options.

Current variants:
- `cpu.jsonc`
- `cpu2-script.jsonc`
- `disk.jsonc`
- `network.jsonc`
- `network2-script.jsonc`
- `updates.jsonc`
- `weather.jsonc`
- `scripts/cpu2.sh`
- `scripts/network2.sh`
- `scripts/weather.sh`

### Situational
Useful only in specific environments or workflows.

Current situational modules/scripts:
- `bluetooth.jsonc`
- `cams-colegio.jsonc`
- `memory.jsonc`
- `temperature.jsonc`
- `scripts/toggle_bluetooth.sh`
- `scripts/select_cams_hypr.sh`

### Legacy
Kept only for reference during transition work. Not part of the maintained runtime.

Current legacy artifacts:
- `legacy/scripts/debug_manager.py`

## Curation rule

When a module or script is no longer part of the maintained runtime, prefer moving it under `legacy/` instead of deleting it immediately. Only delete it once we are sure it has no remaining operational value.
