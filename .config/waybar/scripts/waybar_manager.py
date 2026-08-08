#!/usr/bin/env python3
import json
import os
import sys
import re
import subprocess
from typing import List, Dict, Any, Optional, Union

# Try to import rich, handle failure gracefully
try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.text import Text
    from rich.align import Align
    from rich.theme import Theme
except ImportError:
    print(
        "Error: 'rich' library is required. Please install it with 'pip install rich'"
    )
    sys.exit(1)

# Constants
CONFIG_PATH = os.path.expanduser("~/.config/waybar/config.jsonc")
MODULES_DIR = os.path.expanduser("~/.config/waybar/modules")

# Custom Theme
custom_theme = Theme(
    {
        "info": "dim cyan",
        "warning": "magenta",
        "danger": "bold red",
        "success": "bold green",
        "highlight": "bold blue",
    }
)
console = Console(theme=custom_theme)


class WaybarConfig:
    def __init__(self, path: str):
        self.path = path
        self.raw_data: Union[Dict, List[Dict]] = self._load()
        self.is_multi = isinstance(self.raw_data, list)

    def _strip_comments(self, text: str) -> str:
        pattern = r"//.*?$|/\*.*?\*/"
        regex = re.compile(pattern, re.MULTILINE | re.DOTALL)
        return regex.sub("", text)

    def _load(self) -> Union[Dict, List[Dict]]:
        if not os.path.exists(self.path):
            console.print(f"[danger]Error: Config not found at {self.path}[/danger]")
            sys.exit(1)
        with open(self.path, "r") as f:
            content = f.read()
        try:
            clean_content = self._strip_comments(content)
            return json.loads(clean_content)
        except json.JSONDecodeError as e:
            console.print(f"[danger]Error parsing config.jsonc: {e}[/danger]")
            sys.exit(1)

    def save(self):
        try:
            with open(self.path, "w") as f:
                json.dump(self.raw_data, f, indent=2)

            # Reload Waybar
            subprocess.run(["pkill", "-SIGUSR2", "waybar"], stderr=subprocess.DEVNULL)
            console.print("[success]Waybar config saved and reloaded![/success]")
        except Exception as e:
            console.print(f"[danger]Error saving config: {e}[/danger]")

    def get_monitors(self) -> List[str]:
        if not self.is_multi:
            return ["Default"]
        if isinstance(self.raw_data, list):
            return [
                c.get("output", f"Monitor {i}") for i, c in enumerate(self.raw_data)
            ]
        return ["Default"]

    def get_config_for_monitor(self, monitor: str) -> Dict:
        if not self.is_multi:
            if isinstance(self.raw_data, list):
                return self.raw_data[0]
            return self.raw_data

        if isinstance(self.raw_data, list):
            for cfg in self.raw_data:
                if cfg.get("output") == monitor or monitor.startswith("Monitor"):
                    return cfg
            return self.raw_data[0]
        return self.raw_data

    def switch_style(self, style_name: str) -> bool:
        """Switch between style variants"""
        config_dir = os.path.dirname(self.path)
        styles_dir = os.path.join(config_dir, "styles")
        style_file = os.path.join(styles_dir, f"{style_name}.css")
        target_file = os.path.join(config_dir, "style.css")

        if not os.path.exists(style_file):
            return False

        try:
            # Read the style file and fix the import path
            with open(style_file, "r") as f:
                content = f.read()

            # Replace relative import path for subdirectory with root path
            content = content.replace('@import "../colors.css";', '@import "./colors.css";')

            # Write to target file
            with open(target_file, "w") as f:
                f.write(content)

            # Save current style preference
            current_style_file = os.path.join(config_dir, ".current_style")
            with open(current_style_file, "w") as f:
                f.write(style_name)

            # Reload waybar
            subprocess.run(["pkill", "-SIGUSR2", "waybar"], stderr=subprocess.DEVNULL)
            return True
        except Exception as e:
            console.print(f"[danger]Error switching style: {e}[/danger]")
            return False

    def get_current_style(self) -> str:
        """Get the currently active style"""
        config_dir = os.path.dirname(self.path)
        current_style_file = os.path.join(config_dir, ".current_style")
        if os.path.exists(current_style_file):
            with open(current_style_file, "r") as f:
                return f.read().strip()
        return "original"


class ModuleManager:
    def __init__(self, modules_dir: str):
        self.modules_dir = modules_dir
        self.file_map = self._scan_modules()

    def _scan_modules(self) -> Dict[str, str]:
        """Returns a dict mapping filename -> module_name"""
        mapping = {}
        if not os.path.exists(self.modules_dir):
            return mapping

        for f in sorted(os.listdir(self.modules_dir)):
            if f.endswith(".jsonc"):
                mod_name = self._get_module_name(f)
                mapping[f] = mod_name
        return mapping

    def _get_module_name(self, filename: str) -> str:
        filepath = os.path.join(self.modules_dir, filename)
        try:
            with open(filepath, "r") as f:
                # Basic strip comments
                pattern = r"//.*?$|/\*.*?\*/"
                clean = re.sub(pattern, "", f.read(), flags=re.MULTILINE | re.DOTALL)
                data = json.loads(clean)
                if data:
                    return list(data.keys())[0]
        except:
            pass
        return filename.replace(".jsonc", "")


class TUI:
    def __init__(self):
        pass

    def clear(self):
        os.system("clear")

    def fzf(
        self,
        lines: List[str],
        header: str,
        height: str = "40%",
        preview: Optional[str] = None,
    ) -> Optional[str]:
        cmd = [
            "fzf",
            "--ansi",
            f"--header={header}",
            "--layout=reverse",
            "--border=rounded",
            "--margin=2%",
            f"--height={height}",
            "--prompt=❯ ",
            "--pointer=➜",
        ]
        if preview:
            cmd.extend(
                ["--preview", preview, "--preview-window=right:50%:wrap:border-left"]
            )

        try:
            result = subprocess.run(
                cmd,
                input="\n".join(lines).encode(),
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
            )
            if result.returncode == 0:
                return result.stdout.decode().strip()
            return None
        except FileNotFoundError:
            console.print("[danger]Error: fzf is not installed.[/danger]")
            sys.exit(1)

    def show_monitor_selection(self, monitors: List[str]) -> Optional[str]:
        if len(monitors) == 1:
            return monitors[0]

        self.clear()
        console.print(
            Panel(
                Align.center(Text("Select Monitor", style="bold highlight")),
                border_style="blue",
            )
        )

        lines = [f"{m}" for m in monitors]
        choice = self.fzf(lines, "Choose config to edit", height="20%")
        return choice if choice else None

    def style_menu(self, config: WaybarConfig) -> bool:
        """Interactive style selection menu"""
        current_style = config.get_current_style()

        self.clear()
        console.print(
            Panel(
                Align.center(Text("Switch Waybar Style", style="bold highlight")),
                border_style="cyan",
            )
        )

        console.print()
        console.print(f"  {'●' if current_style == 'original' else '○'} [bold]Original[/bold] (current default style)")
        console.print(f"  {'●' if current_style == 'pill' else '○'} [bold]Pill-shaped[/bold] (fully rounded sections)")
        console.print(f"  {'●' if current_style == 'rounded' else '○'} [bold]Rounded rectangles[/bold] (moderately rounded corners)")
        console.print()

        options = [
            "1. Original (current default style)",
            "2. Pill-shaped (fully rounded sections)",
            "3. Rounded rectangles",
        ]

        choice = self.fzf(options, "Select style (ESC to cancel)", height="30%")

        if not choice:
            return False

        style_map = {"1.": "original", "2.": "pill", "3.": "rounded"}
        for key, style_name in style_map.items():
            if choice.startswith(key):
                if config.switch_style(style_name):
                    self.clear()
                    console.print(f"[success]✓ Switched to {style_name} style![/success]")
                    input("\nPress Enter to continue...")
                    return True
                else:
                    self.clear()
                    console.print(f"[danger]✗ Failed to switch to {style_name} style[/danger]")
                    input("\nPress Enter to continue...")
                    return False
        return False

    def main_menu(self, monitor_name: str) -> Optional[str]:
        self.clear()
        title = Text(f"Waybar Manager ({monitor_name})", style="bold highlight")
        console.print(Panel(Align.center(title), border_style="blue"))

        options = [
            "1. 📦 Toggle/Add Modules",
            "2. 🔃 Reorder Modules",
            "3. 🎨 Switch Style",
            "4. 💾 Save & Reload",
            "5. 🚪 Exit",
        ]

        return self.fzf(options, "Main Menu", height="30%")

    def build_module_list(
        self, config_data: Dict, module_mgr: ModuleManager
    ) -> List[str]:
        lines = []
        includes = config_data.get("include", [])

        # Positions
        left = config_data.get("modules-left", [])
        center = config_data.get("modules-center", [])
        right = config_data.get("modules-right", [])

        for fname, mod_name in module_mgr.file_map.items():
            path = f"modules/{fname}"
            is_included = path in includes

            pos = ""
            if mod_name in left:
                pos = "LEFT"
            elif mod_name in center:
                pos = "CENTER"
            elif mod_name in right:
                pos = "RIGHT"

            # Formatting
            status_icon = "●" if is_included and pos else "○"
            status_color = "green" if is_included and pos else "dim white"
            if is_included and not pos:
                status_icon = "?"
                status_color = "yellow"

            # ANSI for FZF
            fmt_status = f"\033[{32 if status_color == 'green' else 33 if status_color == 'yellow' else 2}m{status_icon}\033[0m"
            fmt_name = f"\033[1m{mod_name:<25}\033[0m"

            fmt_pos = ""
            if pos == "LEFT":
                fmt_pos = f"\033[34m{pos:<8}\033[0m"
            elif pos == "CENTER":
                fmt_pos = f"\033[35m{pos:<8}\033[0m"
            elif pos == "RIGHT":
                fmt_pos = f"\033[36m{pos:<8}\033[0m"
            else:
                fmt_pos = f"{'':<8}"

            fmt_file = f"\033[2m({fname})\033[0m"

            lines.append(f"{fmt_status}  {fmt_name} {fmt_pos} {fmt_file}")

        return lines

    def toggle_menu(self, config_data: Dict, module_mgr: ModuleManager) -> bool:
        while True:
            lines = self.build_module_list(config_data, module_mgr)
            preview = "bat --color=always --style=numbers --line-range=:50 ~/.config/waybar/modules/$(echo {} | awk -F'[()]' '{print $(NF-1)}')"

            choice = self.fzf(
                lines,
                "Select module to toggle (ESC to back)",
                height="80%",
                preview=preview,
            )
            if not choice:
                break

            # Parse selection
            # Remove ANSI codes to extract filename
            clean = re.sub(r"\x1b\[[0-9;]*m", "", choice)
            fname = clean.split("(")[-1].strip(")")
            mod_name = module_mgr.file_map.get(fname)
            include_path = f"modules/{fname}"

            # Check state
            is_included = include_path in config_data.get("include", [])
            pos_key = None
            if mod_name in config_data.get("modules-left", []):
                pos_key = "modules-left"
            elif mod_name in config_data.get("modules-center", []):
                pos_key = "modules-center"
            elif mod_name in config_data.get("modules-right", []):
                pos_key = "modules-right"

            if is_included and pos_key:
                # Disable
                config_data["include"].remove(include_path)
                config_data[pos_key].remove(mod_name)
            else:
                # Enable -> Ask Position
                pos_opts = ["1. Left", "2. Center", "3. Right"]
                p_choice = self.fzf(pos_opts, "Select Position", height="20%")

                if p_choice:
                    target = (
                        "modules-left"
                        if "Left" in p_choice
                        else "modules-center"
                        if "Center" in p_choice
                        else "modules-right"
                    )

                    if "include" not in config_data:
                        config_data["include"] = []
                    if include_path not in config_data["include"]:
                        config_data["include"].append(include_path)

                    if target not in config_data:
                        config_data[target] = []
                    config_data[target].append(mod_name)

            return True  # Signal changed
        return False

    def reorder_menu(self, config_data: Dict) -> bool:
        while True:
            # Select section
            sections = ["1. Modules Left", "2. Modules Center", "3. Modules Right"]
            sec_choice = self.fzf(sections, "Select Section", height="20%")
            if not sec_choice:
                break

            key = (
                "modules-left"
                if "Left" in sec_choice
                else "modules-center"
                if "Center" in sec_choice
                else "modules-right"
            )
            modules = config_data.get(key, [])

            if not modules:
                console.print(f"[warning]No modules in {key}[/warning]")
                input("Enter to continue...")
                continue

            # Select module to move
            mod_lines = [f"{i + 1:02d}. {m}" for i, m in enumerate(modules)]
            mod_choice = self.fzf(mod_lines, f"Reorder {key}", height="50%")
            if not mod_choice:
                continue

            idx = int(mod_choice.split(".")[0]) - 1
            selected_mod = modules[idx]

            # Select action
            actions = ["↑ Move Up", "↓ Move Down", "⤒ Top", "⤓ Bottom", "✕ Remove"]
            act = self.fzf(actions, f"Action for {selected_mod}", height="30%")
            if not act:
                continue

            changed = False
            if "Up" in act and idx > 0:
                modules[idx], modules[idx - 1] = modules[idx - 1], modules[idx]
                changed = True
            elif "Down" in act and idx < len(modules) - 1:
                modules[idx], modules[idx + 1] = modules[idx + 1], modules[idx]
                changed = True
            elif "Top" in act and idx > 0:
                modules.insert(0, modules.pop(idx))
                changed = True
            elif "Bottom" in act and idx < len(modules) - 1:
                modules.append(modules.pop(idx))
                changed = True
            elif "Remove" in act:
                modules.pop(idx)
                changed = True

            if changed:
                config_data[key] = modules
                return True
        return False


def main():
    tui = TUI()
    config = WaybarConfig(CONFIG_PATH)
    mod_mgr = ModuleManager(MODULES_DIR)

    while True:
        # 1. Select Monitor (if applicable)
        monitors = config.get_monitors()
        selected_monitor_name = tui.show_monitor_selection(monitors)

        if not selected_monitor_name:
            console.print("[info]Goodbye![/info]")
            break

        # Get the specific dict object for this monitor
        active_config = config.get_config_for_monitor(selected_monitor_name)

        # 2. Main Menu Loop for this monitor
        while True:
            choice = tui.main_menu(selected_monitor_name)

            if not choice or "Exit" in choice:
                break  # Go back to monitor selection (or exit if single)

            dirty = False
            if "Toggle" in choice:
                dirty = tui.toggle_menu(active_config, mod_mgr)
            elif "Reorder" in choice:
                dirty = tui.reorder_menu(active_config)
            elif "Style" in choice:
                tui.style_menu(config)
            elif "Save" in choice:
                config.save()

            if dirty:
                config.save()

        if not config.is_multi:
            break


if __name__ == "__main__":
    main()
