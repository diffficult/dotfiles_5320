.pragma library

// Static base list for the Quick-mode tile grid. Order matches the
// Samsung-style quick panel - most glanced (battery/audio/wifi/bt)
// first. The Repeater's 12 delegates are built once from this array and
// never torn down; per-tile live data lives in the parallel `dyn` map
// the QuickContainer builds from navbar telemetry on every tick.
var base = [
    { key: "audio",       keywords: "audio sound speaker volume mute pulse pipewire",
      action: "qs -c $HOME/.config/warmind/launcher ipc call audio toggle",
      longAction: "wpctl set-mute @DEFAULT_SINK@ toggle" },
    { key: "network",     keywords: "wifi wireless network internet ssid signal ethernet eth",
      action: "qs -c $HOME/.config/warmind/launcher ipc call network toggle" },
    { key: "bluetooth",   keywords: "bluetooth bt pair device headset speaker keyboard",
      action: "qs -c $HOME/.config/warmind/launcher ipc call bluetooth toggle" },
    { key: "weather",     keywords: "weather forecast temperature wttr rain sun wind",
      action: "qs -c $HOME/.config/warmind/launcher ipc call weather toggle",
      longAction: "qs -c $HOME/.config/warmind/launcher ipc call weather refresh" },
    { key: "cpu",         keywords: "cpu processor memory monitor btop top htop performance load",
      action: "foot -e btop" },
    // Quick tiles currently hidden from the panel.
    // Display is extracted/protected again but remains hidden by default
    // until a laptop-oriented exposure strategy is chosen.
    // { key: "display",     keywords: "display monitor warmth gamma night light temperature dim screen",
    //   action: "qs -c $HOME/.config/warmind/launcher ipc call display toggle" },
    { key: "calendar",    keywords: "calendar date month day today schedule planner google events agenda",
      action: "qs -c $HOME/.config/warmind/launcher ipc call calendar toggle" },
    { key: "screenshots", keywords: "screenshots shots browse pictures captures images gallery",
      action: "qs -c $HOME/.config/warmind/launcher ipc call screenshots toggle",
      longAction: "zsh -c 'grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png'" },
    { key: "videos",      keywords: "videos films clips recordings browse gallery library",
      action: "qs -c $HOME/.config/warmind/launcher ipc call videos toggle",
      longAction: "nemo ~/Videos" },
    { key: "power",       keywords: "power menu suspend hibernate logout restart shutdown lock",
      action: "qs -c $HOME/.config/warmind/launcher ipc call palette openCategory Quick" }
];

// Build the per-tile dynamic map (glyph/label/sub/tone) from live
// navbar state. Caller passes the navbar instance; this function does
// not retain it. Returns {} when navbar is missing so delegate
// bindings can still chain `.glyph`/`.sub` reads via `({}).foo`.
function buildDyn(n) {
    if (!n) return ({});
    const chargingTag = n.batState === "Charging"    ? " · CHARGING"
                      : n.batState === "Full"        ? " · FULL"
                      : n.batState === "Not charging" ? " · PLUGGED"
                      : "";
    return {
        battery: {
            glyph: n.batteryIcon(),
            label: "BATTERY",
            sub: n.batVal + "%" + chargingTag
                 + (n.batPower >= 0.05
                    ? "  " + n.batPower.toFixed(1) + "W"
                    : ""),
            tone: n.batVal <= 10 ? n.seal
                                 : n.batVal <= 20 ? n.indigo
                                                  : n.ink
        },
        audio: {
            glyph: n.audioIcon,
            label: "AUDIO",
            sub: n.audioMuted ? "MUTED" : (n.audioVol + "%"),
            tone: n.audioMuted ? n.seal : n.ink
        },
        network: {
            glyph: n.netIcon,
            label: n.netKind === "wifi" ? "WI-FI"
                   : n.netKind === "eth"  ? "ETHERNET"
                                          : "OFFLINE",
            sub: n.netKind === "wifi"
                 ? ((n.wifiSsid || "(hidden)") + " · " + n.wifiSignal + "%")
                 : n.netKind === "eth" ? "CONNECTED" : "—",
            tone: n.netKind === "none" ? n.inkDeep : n.ink
        },
        bluetooth: {
            glyph: n.bluetooth ? n.bluetooth.icon : "󰂲",
            label: "BLUETOOTH",
            sub: !n.bluetooth || !n.bluetooth.powered ? "OFF"
                              : (n.bluetooth.count > 0 ? n.bluetooth.count + " CONN" : "ON"),
            tone: !n.bluetooth || !n.bluetooth.powered ? n.inkDeep : n.ink
        },
        weather: {
            glyph: !n.weather ? "·"
                 : (n.weather.unavailable ? "?"
                    : (n.weather.loaded ? n.weather.icon : "·")),
            label: "WEATHER",
            sub: !n.weather ? "…"
                 : (n.weather.unavailable ? "OFFLINE"
                    : (n.weather.loaded ? Math.round(n.weather.tempC) + "°C" : "…")),
            tone: n.weather && n.weather.unavailable ? n.inkDeep : n.ink
        },
        display: {
            glyph: n.icoDisplay,
            label: "DISPLAY",
            sub: "DISABLED",
            tone: n.inkDeep
        },
        cpu: {
            glyph: "󰍛",
            label: "CPU",
            sub: Math.round(n.cpuVal) + "%",
            tone: n.cpuVal > 80 ? n.seal : n.ink
        },
        calendar: {
            glyph: "󰃭",
            label: "CALENDAR",
            sub: !n.calendar ? "…"
                 : (n.calendar.error ? "AUTH / CACHE"
                    : (n.calendar.loaded ? ((n.calendar.eventCount || 0) + " EVENTS") : "…")),
            tone: n.calendar && n.calendar.error ? n.seal : n.ink
        },
        screenshots: { glyph: n.icoCamera,  label: "SHOTS",       sub: "BROWSE",           tone: n.ink },
        videos:      { glyph: n.icoFilm,    label: "VIDEOS",      sub: "BROWSE",           tone: n.ink },
        power:       { glyph: n.icoPower,   label: "POWER",       sub: "MENU",             tone: n.ink }
    };
}
