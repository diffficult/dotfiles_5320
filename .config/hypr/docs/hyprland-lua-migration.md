# Hyprland Lua Migration

This config now uses a Lua entrypoint. The old Hyprland hyprlang files were moved out of the live config tree to `~/.config/hypr_conf_bkp/`.

The current live Hyprland process may still be running under the legacy config manager if it was started before `hyprland.lua` existed. In that case, `hyprctl reload` keeps using `hyprland.conf`; it does not switch config managers mid-session.

## Quick Path

1. Hyprland loads `~/.config/hypr/hyprland.lua` when present.
2. Core Hyprland config lives in Lua under `hyprland.lua` and `lua/**`.
3. The old `.conf` schema is backed up in `~/.config/hypr_conf_bkp/`.

## Current Shape

| Area | Lua location | Notes |
|------|--------------|-------|
| Entry point | `hyprland.lua` | Requires modules in load order. |
| Monitors/workspaces | `lua/core/monitors.lua` | Native `hl.monitor` and `hl.workspace_rule`. |
| Env | `lua/core/env.lua` | Runtime `hl.env`; long-lived uwsm env should move outside Hyprland config later. |
| General config | `lua/core/general.lua` | Native `hl.config`. |
| Autostart | `lua/core/autostart.lua` | Uses `hl.on("hyprland.start", ...)` plus `hl.dsp.exec_cmd`. |
| Rules | `lua/core/rules.lua`, `lua/rules/**` | Native `hl.window_rule` modules generated from the previous rule files. |
| Base binds | `lua/core/keybindings.lua`, `lua/lib/binds.lua` | Native Lua bind/submap declarations generated from `keybindings.conf`. |
| Warmind Launcher | `lua/integrations/warmind_launcher.lua` | Generated Lua integration loaded last. |
| Waybar launch | `scripts/waybar-with-lua-shim.sh` | Builds/loads IPC shim so workspace clicks work under Lua manager. |

## Rollback

### Current Session Bridge

If the running compositor was started in legacy mode, keep `~/.config/hypr/hyprland.conf` as a temporary bridge. It sources files from `~/.config/hypr_conf_bkp/` so `hyprctl reload` keeps the current session usable.

After restarting Hyprland into Lua mode, remove the bridge if it still exists:

```bash
rm ~/.config/hypr/hyprland.conf
hyprctl reload
```

Verify the compositor is no longer using the legacy bridge by checking that the expected Lua binds/rules are active.

### Full Legacy Restore

To restore the old hyprlang config from backup:

```bash
mv ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.disabled
cp -a ~/.config/hypr_conf_bkp/hyprland.conf ~/.config/hypr/
cp -a ~/.config/hypr_conf_bkp/monitors.conf ~/.config/hypr/
cp -a ~/.config/hypr_conf_bkp/env.conf ~/.config/hypr/
cp -a ~/.config/hypr_conf_bkp/general.conf ~/.config/hypr/
cp -a ~/.config/hypr_conf_bkp/rules.conf ~/.config/hypr/
cp -a ~/.config/hypr_conf_bkp/autostart.conf ~/.config/hypr/
cp -a ~/.config/hypr_conf_bkp/plugins.conf ~/.config/hypr/
cp -a ~/.config/hypr_conf_bkp/keybindings.conf ~/.config/hypr/
cp -a ~/.config/hypr_conf_bkp/warmind-launcher.conf ~/.config/hypr/
cp -a ~/.config/hypr_conf_bkp/apps ~/.config/hypr/
hyprctl reload
```

To re-enable Lua:

```bash
rm -f ~/.config/hypr/hyprland.conf ~/.config/hypr/monitors.conf ~/.config/hypr/env.conf ~/.config/hypr/general.conf ~/.config/hypr/rules.conf ~/.config/hypr/autostart.conf ~/.config/hypr/plugins.conf ~/.config/hypr/keybindings.conf ~/.config/hypr/warmind-launcher.conf
rm -rf ~/.config/hypr/apps
mv ~/.config/hypr/hyprland.lua.disabled ~/.config/hypr/hyprland.lua
hyprctl reload
```

## Migration Rules

- Use native Lua helpers when the syntax is stable and clear.
- Keep generated integrations out of the live tree once their hyprlang output is no longer active.
- Preserve load order. Warmind Launcher should load after base keybindings when its Lua module is integrated, because it intentionally overrides base binds.
- Use escaped Lua strings or Lua long strings for regex-heavy rules.
- Keep shell-heavy commands as complete strings. Do not split commands by spaces or commas.
- For keybind dispatchers, use Lua `hl.bind`/`hl.define_submap` and native `hl.dsp.*` first.
- Do not rely on bare `hyprctl dispatch workspace N` under Lua manager; it is parsed as invalid Lua.
- Prefer `hyprctl dispatch 'hl.dsp.focus({ workspace = N })'` or `hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = N }))'`.
- `hl.monitor` uses Monitor v2-style keys: `output`, `mode`, `position`, and `scale`.
- Per-device input uses top-level `hl.device({...})`; gestures use `hl.gesture({...})`. Nested `device`/`gesture` inside `hl.config` is ignored.
- Border colors: nest under `general.col` and use rgba strings for gradients, e.g. `{ colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 }`. Numeric colors are `0xAARRGGBB`.
- Hyprlang keys containing `-` may become underscore keys in Lua tables, e.g. `tap-to-click` -> `tap_to_click`.
- Bind repeat flag in Lua is `repeating = true` (`repeatable` is normalized in `lua/lib/binds.lua`).

## Waybar + Legacy IPC Shim

Waybar's `hyprland/workspaces` module hardcodes IPC:

```text
dispatch workspace N
```

Under Lua config manager that becomes invalid Lua (`hl.dispatch(workspace N)`), so bar clicks stop switching workspaces even though keybinds still work.

This config launches waybar through:

```bash
~/.config/hypr/scripts/waybar-with-lua-shim.sh
```

That launcher:

1. Builds `lib/libhypr_dispatch_shim.so` from `lib/hypr_dispatch_shim.c` if missing/outdated (`gcc` required once).
2. `LD_PRELOAD`s the shim into waybar only.
3. Rewrites `dispatch workspace N` / `focusworkspaceoncurrentmonitor N` into `dispatch hl.dsp.focus({ workspace = N })`.

The compiled `.so` is local runtime output and is not versioned in dotfiles. Scroll uses `scripts/hypr-workspace.sh` directly.

## Deprecated scripts (post-migration)

Moved out of the live path:

- `~/.local/bin/hypr_scripts/deprecated/rofi-power-menu` — replaced by Warmind power menu
- `~/.local/bin/hypr_scripts/deprecated/enter-submap` — submaps enter via native Lua callbacks
- `~/.config/waybar/scripts/deprecated/select_cams_hypr.sh` — superseded by Warmind cams; not wired in active waybar config

## Warmind QML / external clients (Lua IPC)

Anything still emitting bare `hyprctl dispatch <legacy>` will fail under Lua manager until updated. Known live paths under `~/.config/warmind`:

| Location | Legacy call | Lua-safe direction |
|----------|-------------|--------------------|
| `WindowSearch.qml` | `dispatch workspace` / `focuswindow address:` | `hl.dsp.focus({ workspace = ... })`, `hl.dsp.focus({ window = "address:..." })` |
| `CamsController.qml` | workspace / setfloating / resizewindowpixel / movewindowpixel / closewindow | native `hl.dsp.window.*` + focus forms |
| `PowerController.qml` | `dispatch exit` | `hl.dsp.exit()` (do not probe live) |
| `modules/expose/shell.qml` | workspace + focuswindow | same as WindowSearch |
| `DisplayController.qml` | `dispatch dpms off` | keep `wlopm` (already preferred on this system) |
| `KeybindSearch.qml` | only label matching for old `hyprctl keyword` / `enter-submap` strings | update labels when bind text changes |

## Reusable Checklist

- [ ] Inventory sourced `.conf` files and preserve their load order.
- [ ] Convert monitors, workspaces, env, and general config first.
- [ ] Convert autostart with `hl.on("hyprland.start", ...)`.
- [x] Convert rules to `hl.window_rule` modules.
- [x] Convert base binds to `hl.bind` and `hl.define_submap`.
- [x] Move deprecated hyprlang files to `~/.config/hypr_conf_bkp/` after Lua is proven stable.
- [ ] Load the new Warmind Launcher Lua module after base keybindings.

## Validation

After the pure Lua cleanup:

```bash
lua <mock validation script>
hyprctl reload
hyprctl configerrors
hyprctl binds -j | jq 'length'
```

Expected checks:

- `hyprctl reload` returns `ok`.
- `hyprctl configerrors` is empty.
- Bind count remains stable.
- Warmind Launcher overrides should be rechecked after integrating its new Lua module.
- Submaps like `resize` and `gaps` expose their `Escape -> reset` binds.
- If bind count drops to Hyprland defaults, the current compositor is still using the legacy config manager and needs the temporary bridge or a full restart into Lua mode.

## Warmind Launcher Notes

Warmind Launcher's old hyprlang output was moved to `~/.config/hypr_conf_bkp/warmind-launcher.conf`. The live Hyprland config no longer reads it.

When migrating Warmind Launcher itself, emit Lua directly instead of hyprlang:

- `unbind = MODS, KEY` -> `hl.unbind("MODS + KEY")`
- `bind = MODS, KEY, exec, CMD` -> `hl.bind("MODS + KEY", hl.dsp.exec_cmd("CMD"))`
- `windowrule { ... }` -> `hl.window_rule({ match = { ... }, ... })`

Keep the new Lua integration loaded after base keybindings so launcher overrides remain intentional.
