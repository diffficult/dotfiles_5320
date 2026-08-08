import QtQuick
import Quickshell
import Quickshell.Io

// Live theme controller for OmniMenu/desktop surfaces.
// Supports a curated set of TokyoNight + Catppuccin schemes with
// switchable accent colors, plus persistence in Quickshell state.
Item {
    id: theme

    readonly property var schemes: ({
        "tokyonight-storm": {
            family: "tokyonight",
            label: "TokyoNight Storm",
            paper: "#24283b",
            ink: "#c0caf5",
            inkDeep: "#a9b1d6",
            sumi: "#565f89",
            bgHigh: "#414868",
            warn: "#f7768e",
            defaultAccent: "purple",
            accentOrder: ["blue", "cyan", "green", "orange", "purple", "red", "yellow"],
            accents: {
                blue:   "#7aa2f7",
                cyan:   "#7dcfff",
                green:  "#9ece6a",
                orange: "#ff9e64",
                purple: "#bb9af7",
                red:    "#f7768e",
                yellow: "#e0af68"
            }
        },
        "tokyonight-night": {
            family: "tokyonight",
            label: "TokyoNight Night",
            paper: "#1a1b26",
            ink: "#c0caf5",
            inkDeep: "#a9b1d6",
            sumi: "#565f89",
            bgHigh: "#414868",
            warn: "#f7768e",
            defaultAccent: "purple",
            accentOrder: ["blue", "cyan", "green", "orange", "purple", "red", "yellow"],
            accents: {
                blue:   "#7aa2f7",
                cyan:   "#7dcfff",
                green:  "#9ece6a",
                orange: "#ff9e64",
                purple: "#bb9af7",
                red:    "#f7768e",
                yellow: "#e0af68"
            }
        },
        "tokyonight-day": {
            family: "tokyonight",
            label: "TokyoNight Day",
            paper: "#e1e2e7",
            ink: "#3760bf",
            inkDeep: "#6172b0",
            sumi: "#8990b3",
            bgHigh: "#c4c8da",
            warn: "#f52a65",
            defaultAccent: "purple",
            accentOrder: ["blue", "cyan", "green", "orange", "purple", "red", "yellow"],
            accents: {
                blue:   "#2e7de9",
                cyan:   "#007197",
                green:  "#587539",
                orange: "#b15c00",
                purple: "#9854f1",
                red:    "#f52a65",
                yellow: "#8c6c3e"
            }
        },
        "catppuccin-latte": {
            family: "catppuccin",
            label: "Catppuccin Latte",
            paper: "#eff1f5",
            ink: "#4c4f69",
            inkDeep: "#5c5f77",
            sumi: "#6c6f85",
            bgHigh: "#ccd0da",
            warn: "#d20f39",
            defaultAccent: "mauve",
            accentOrder: ["rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach", "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender"],
            accents: {
                rosewater: "#dc8a78",
                flamingo:  "#dd7878",
                pink:      "#ea76cb",
                mauve:     "#8839ef",
                red:       "#d20f39",
                maroon:    "#e64553",
                peach:     "#fe640b",
                yellow:    "#df8e1d",
                green:     "#40a02b",
                teal:      "#179299",
                sky:       "#04a5e5",
                sapphire:  "#209fb5",
                blue:      "#1e66f5",
                lavender:  "#7287fd"
            }
        },
        "catppuccin-frappe": {
            family: "catppuccin",
            label: "Catppuccin Frappe",
            paper: "#303446",
            ink: "#c6d0f5",
            inkDeep: "#b5bfe2",
            sumi: "#838ba7",
            bgHigh: "#414559",
            warn: "#e78284",
            defaultAccent: "mauve",
            accentOrder: ["rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach", "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender"],
            accents: {
                rosewater: "#f2d5cf",
                flamingo:  "#eebebe",
                pink:      "#f4b8e4",
                mauve:     "#ca9ee6",
                red:       "#e78284",
                maroon:    "#ea999c",
                peach:     "#ef9f76",
                yellow:    "#e5c890",
                green:     "#a6d189",
                teal:      "#81c8be",
                sky:       "#99d1db",
                sapphire:  "#85c1dc",
                blue:      "#8caaee",
                lavender:  "#babbf1"
            }
        },
        "catppuccin-macchiato": {
            family: "catppuccin",
            label: "Catppuccin Macchiato",
            paper: "#24273a",
            ink: "#cad3f5",
            inkDeep: "#b8c0e0",
            sumi: "#8087a2",
            bgHigh: "#363a4f",
            warn: "#ed8796",
            defaultAccent: "mauve",
            accentOrder: ["rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach", "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender"],
            accents: {
                rosewater: "#f4dbd6",
                flamingo:  "#f0c6c6",
                pink:      "#f5bde6",
                mauve:     "#c6a0f6",
                red:       "#ed8796",
                maroon:    "#ee99a0",
                peach:     "#f5a97f",
                yellow:    "#eed49f",
                green:     "#a6da95",
                teal:      "#8bd5ca",
                sky:       "#91d7e3",
                sapphire:  "#7dc4e4",
                blue:      "#8aadf4",
                lavender:  "#b7bdf8"
            }
        },
        "catppuccin-mocha": {
            family: "catppuccin",
            label: "Catppuccin Mocha",
            paper: "#1e1e2e",
            ink: "#cdd6f4",
            inkDeep: "#bac2de",
            sumi: "#7f849c",
            bgHigh: "#313244",
            warn: "#f38ba8",
            defaultAccent: "mauve",
            accentOrder: ["rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach", "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender"],
            accents: {
                rosewater: "#f5e0dc",
                flamingo:  "#f2cdcd",
                pink:      "#f5c2e7",
                mauve:     "#cba6f7",
                red:       "#f38ba8",
                maroon:    "#eba0ac",
                peach:     "#fab387",
                yellow:    "#f9e2af",
                green:     "#a6e3a1",
                teal:      "#94e2d5",
                sky:       "#89dceb",
                sapphire:  "#74c7ec",
                blue:      "#89b4fa",
                lavender:  "#b4befe"
            }
        }
    })

    readonly property var accentLabels: ({
        blue: "Blue", cyan: "Cyan", green: "Green", orange: "Orange",
        purple: "Purple", red: "Red", yellow: "Yellow",
        rosewater: "Rosewater", flamingo: "Flamingo", pink: "Pink",
        mauve: "Mauve", maroon: "Maroon", peach: "Peach", teal: "Teal",
        sky: "Sky", sapphire: "Sapphire", lavender: "Lavender"
    })

    property string schemeKey: "tokyonight-night"
    property string accentKey: "purple"
    readonly property string statePath: Quickshell.statePath("warmind/launcher/theme.json")
    property bool _themeStateHydrating: false
    property bool _themeStateLoaded: false

    readonly property var schemeKeys: [
        "tokyonight-storm", "tokyonight-night", "tokyonight-day",
        "catppuccin-latte", "catppuccin-frappe", "catppuccin-macchiato", "catppuccin-mocha"
    ]

    readonly property var currentScheme: theme.schemeData(theme.schemeKey)
    readonly property color paper:   currentScheme.paper
    readonly property color ink:     currentScheme.ink
    readonly property color inkDeep: currentScheme.inkDeep
    readonly property color sumi:    currentScheme.sumi
    readonly property color bgHighColor: currentScheme.bgHigh
    readonly property color indigo:  theme.currentAccentColor
    readonly property color seal:    theme.currentAccentColor

    readonly property color bg:     Qt.rgba(paper.r, paper.g, paper.b, 0.97)
    readonly property color fg:     ink
    readonly property color muted:  sumi
    readonly property color accent: seal
    readonly property color warn:   currentScheme.warn
    readonly property color sep:    Qt.rgba(bgHighColor.r, bgHighColor.g, bgHighColor.b, 0.36)
    readonly property color rowHi:  Qt.rgba(bgHighColor.r, bgHighColor.g, bgHighColor.b, 0.14)
    readonly property color rowSel: Qt.rgba(seal.r, seal.g, seal.b, 0.22)

    readonly property color currentAccentColor: {
        const accents = currentScheme.accents || {};
        return accents[theme.accentKey] || accents[currentScheme.defaultAccent] || "#bb9af7";
    }

    readonly property string mono:  "JetBrainsMono Nerd Font"
    readonly property string serif: "serif"

    readonly property int  radius:       6
    property int           cornerRadius: 6
    readonly property bool round:        cornerRadius > 0
    readonly property real barOpacity:   0.94

    function schemeData(key) {
        return theme.schemes[key] || theme.schemes["tokyonight-night"];
    }
    function schemeLabel(key) {
        const s = theme.schemeData(key);
        return s.label || key;
    }
    function defaultAccentForScheme(key) {
        return theme.schemeData(key).defaultAccent || "purple";
    }
    function isValidScheme(key) {
        return !!theme.schemes[key];
    }
    function isValidAccentForScheme(accent, scheme) {
        const s = theme.schemeData(scheme);
        return !!(s.accents && s.accents[accent]);
    }
    function accentEntries(scheme) {
        const s = theme.schemeData(scheme || theme.schemeKey);
        const out = [];
        const order = s.accentOrder || [];
        for (let i = 0; i < order.length; i++) {
            const key = order[i];
            if (s.accents && s.accents[key]) {
                out.push({
                    key: key,
                    label: theme.accentLabels[key] || key,
                    color: s.accents[key]
                });
            }
        }
        return out;
    }
    function applySelection(scheme, accent, persist) {
        const nextScheme = theme.isValidScheme(scheme) ? scheme : "tokyonight-night";
        const nextAccent = theme.isValidAccentForScheme(accent, nextScheme)
            ? accent
            : theme.defaultAccentForScheme(nextScheme);
        theme._themeStateHydrating = true;
        theme.schemeKey = nextScheme;
        theme.accentKey = nextAccent;
        theme._themeStateHydrating = false;
        theme._themeStateLoaded = true;
        if (persist) theme.scheduleThemeSave();
    }
    function selectScheme(key) {
        theme.applySelection(key, theme.accentKey, true);
    }
    function selectAccent(key) {
        if (!theme.isValidAccentForScheme(key, theme.schemeKey)) return;
        theme.applySelection(theme.schemeKey, key, true);
    }
    function scheduleThemeSave() {
        if (theme._themeStateHydrating || !theme._themeStateLoaded) return;
        themeSaveDebounce.restart();
    }
    function setCorners(mode) {
        theme.cornerRadius = (mode === "round" || mode === 6) ? 6 : 0;
    }
    function toggleCorners() { theme.setCorners(theme.round ? "sharp" : "round"); }

    Component.onCompleted: {
        if (!theme._themeStateLoaded) theme._themeStateLoaded = true;
    }

    Timer {
        id: themeSaveDebounce
        interval: 120
        repeat: false
        onTriggered: {
            const payload = JSON.stringify({
                schemeKey: theme.schemeKey,
                accentKey: theme.accentKey
            });
            themeSaveProc.command = [
                "sh", "-c",
                "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"",
                "sh", theme.statePath, payload
            ];
            themeSaveProc.running = false;
            themeSaveProc.running = true;
        }
    }

    Process { id: themeSaveProc; running: false; command: ["true"] }

    FileView {
        id: themeStateFile
        path: theme.statePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(themeStateFile.text());
                theme.applySelection(data.schemeKey, data.accentKey, false);
            } catch (_) {
                theme._themeStateLoaded = true;
            }
        }
    }
}
