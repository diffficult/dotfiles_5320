import QtQuick
import "Data.js" as Data

// Surfaces only the navbar popups we still want as dedicated palette rows.
// Weather and Calendar now live through their Quick/toggle integrations,
// so this list keeps just the gallery-style capture popups.
Item {
    id: navbarApps

    readonly property var candidates: [
        { target: "screenshots", title: "Screenshots", icon: "󰄀", category: "Capture",
          keywords: "screenshots browse view gallery thumbnails recent" },
        { target: "videos",      title: "Videos",      icon: "󰕧", category: "Capture",
          keywords: "videos browse view gallery thumbnails recordings recent screen record" }
    ]

    readonly property var items: Data.annotate(candidates.map(c => ({
        title: c.title,
        icon: c.icon,
        category: c.category,
        keywords: c.keywords,
        exec: "qs -c desktop ipc call " + c.target + " " + (c.verb || "open")
    })))

    // Kept for callers that still nudge a refresh — now a no-op.
    function probe() {}
}
