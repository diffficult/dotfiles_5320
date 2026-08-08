import QtQuick
import Quickshell

// Combined entry point: one Quickshell process hosting both the navbar and
// the omni-menu command palette. Both share the same Theme instance, so an
// omarchy theme swap propagates atomically to bar + popups + palette.
//
// Launch with:
//   qs -n -d -c desktop
//
// Toggle the palette from a Hyprland keybind. The shell registers
// GlobalShortcut entries so the keypress is delivered to the running
// process directly (no `qs` client fork on the hot path):
//   bind = SUPER, SPACE, global, quickshell:palette-toggle
//   bind = ALT,   SPACE, global, quickshell:palette-quick
ShellRoot {
    id: root

    Theme { id: theme }

    Navbar {
        id: nav
        theme: theme
        onPaletteToggleRequested: omni.toggle()
    }
    OmniMenu { id: omni; theme: theme; navbar: nav }
}
