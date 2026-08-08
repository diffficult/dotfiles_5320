import QtQuick
import Quickshell.Io
import "Data.js" as Data

// One-shot scan of XDG application directories. configparser handles the
// gnarly bits — section headers, continuation lines, encodings, comments,
// mixed quoting. Result is cached on `apps` (annotated) for the session
// and re-runs only on demand via refresh().
Item {
    id: appScan

    property var apps: []
    property bool loaded: false

    signal scanned()

    function refresh() {
        proc.running = false;
        proc.running = true;
    }

    Process {
        id: proc
        running: false
        command: ["python3", "-c", "import os, glob, re, configparser, sys\n" +
            "dirs = [\n" +
            "    os.path.expanduser('~/.local/share/applications'),\n" +
            "    '/usr/share/applications',\n" +
            "    '/var/lib/flatpak/exports/share/applications',\n" +
            "    os.path.expanduser('~/.local/share/flatpak/exports/share/applications'),\n" +
            "    '/var/lib/snapd/desktop/applications',\n" +
            "]\n" +
            "rx = re.compile(r'%[fFuUdDnNickvm]')\n" +
            "seen = set()\n" +
            "out = []\n" +
            "icon_theme = None\n" +
            "icon_cache = {}\n" +
            "try:\n" +
            "    import gi\n" +
            "    gi.require_version('Gtk', '3.0')\n" +
            "    from gi.repository import Gtk\n" +
            "    icon_theme = Gtk.IconTheme.get_default()\n" +
            "except Exception:\n" +
            "    icon_theme = None\n" +
            "def resolve_icon(icon):\n" +
            "    if not icon:\n" +
            "        return ''\n" +
            "    if icon in icon_cache:\n" +
            "        return icon_cache[icon]\n" +
            "    resolved = ''\n" +
            "    if os.path.isabs(icon) and os.path.exists(icon):\n" +
            "        resolved = icon\n" +
            "    elif icon_theme is not None:\n" +
            "        for size in (64, 48, 36, 32, 24, 22, 16):\n" +
            "            try:\n" +
            "                hit = icon_theme.lookup_icon(icon, size, 0)\n" +
            "            except Exception:\n" +
            "                hit = None\n" +
            "            if hit is not None:\n" +
            "                resolved = hit.get_filename() or ''\n" +
            "                if resolved:\n" +
            "                    break\n" +
            "    # Fallback: search the filesystem for the icon name when GTK\n" +
            "    # theme lookup fails.  Covers icons present in hicolor/adwaita\n" +
            "    # but not reachable via the active theme's icon-theme.cache.\n" +
            "    if not resolved:\n" +
            "        icon_base = icon\n" +
            "        if icon.endswith('.png') or icon.endswith('.svg') or icon.endswith('.xpm'):\n" +
            "            icon_base = icon.rsplit('.', 1)[0]\n" +
            "        search_dirs = [\n" +
            "            '/usr/share/icons',\n" +
            "            os.path.expanduser('~/.local/share/icons'),\n" +
            "        ]\n" +
            "        search_sizes = (64, 48, 32, 24, 22, 16)\n" +
            "        for d in search_dirs:\n" +
            "            if not os.path.isdir(d):\n" +
            "                continue\n" +
            "            for size in search_sizes:\n" +
            "                size_dir = os.path.join(d, 'hicolor', str(size) + 'x' + str(size), 'apps')\n" +
            "                if not os.path.isdir(size_dir):\n" +
            "                    continue\n" +
            "                for ext in ('', '.png', '.svg', '.xpm'):\n" +
            "                    cand = os.path.join(size_dir, icon_base + ext)\n" +
            "                    if os.path.exists(cand):\n" +
            "                        resolved = cand\n" +
            "                        break\n" +
            "                if resolved:\n" +
            "                    break\n" +
            "            if resolved:\n" +
            "                break\n" +
            "            # Also try scalable/ for SVG icons\n" +
            "            for ext in ('', '.svg'):\n" +
            "                cand = os.path.join(d, 'hicolor', 'scalable', 'apps', icon_base + ext)\n" +
            "                if os.path.exists(cand):\n" +
            "                    resolved = cand\n" +
            "                    break\n" +
            "            if not resolved:\n" +
            "                # Try the icon name directly under hicolor/symbolic\n" +
            "                for ext in ('', '-symbolic.svg', '-symbolic.png'):\n" +
            "                    cand = os.path.join(d, 'hicolor', 'symbolic', 'apps', icon_base + ext)\n" +
            "                    if os.path.exists(cand):\n" +
            "                        resolved = cand\n" +
            "                        break\n" +
            "    icon_cache[icon] = resolved\n" +
            "    return resolved\n" +
            "for d in dirs:\n" +
            "    if not os.path.isdir(d):\n" +
            "        continue\n" +
            "    for f in sorted(glob.glob(os.path.join(d, '*.desktop'))):\n" +
            "        cp = configparser.RawConfigParser(strict=False, interpolation=None)\n" +
            "        try:\n" +
            "            cp.read(f, encoding='utf-8')\n" +
            "        except Exception:\n" +
            "            continue\n" +
            "        if 'Desktop Entry' not in cp:\n" +
            "            continue\n" +
            "        de = cp['Desktop Entry']\n" +
            "        if de.get('NoDisplay', '').lower() == 'true':\n" +
            "            continue\n" +
            "        if de.get('Hidden', '').lower() == 'true':\n" +
            "            continue\n" +
            "        if de.get('Type', 'Application').strip() != 'Application':\n" +
            "            continue\n" +
            "        name = de.get('Name', '').strip()\n" +
            "        if not name:\n" +
            "            continue\n" +
            "        key = name.lower()\n" +
            "        if key in seen:\n" +
            "            continue\n" +
            "        seen.add(key)\n" +
            "        comment = de.get('Comment', '').strip()\n" +
            "        keywords = de.get('Keywords', '').strip().replace(';', ' ')\n" +
            "        categories = de.get('Categories', '').strip().replace(';', ' ')\n" +
            "        exe = rx.sub('', de.get('Exec', '').strip()).strip()\n" +
            "        if not exe:\n" +
            "            continue\n" +
            "        icon = de.get('Icon', '').strip()\n" +
            "        resolved_icon = resolve_icon(icon)\n" +
            "        gname = de.get('GenericName', '').strip()\n" +
            "        term = '1' if de.get('Terminal', '').lower() == 'true' else ''\n" +
            "        def s(x):\n" +
            "            return x.replace('\\t', ' ').replace('\\n', ' ').replace('\\r', ' ')\n" +
            "        out.append('\\t'.join([s(name), s(comment), s(keywords), s(categories), s(exe), s(icon), s(resolved_icon), s(gname), term]))\n" +
            "sys.stdout.write('\\n'.join(out))\n"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(s => s.length > 0);
                const apps = new Array(lines.length);
                let n = 0;
                for (let i = 0; i < lines.length; i++) {
                    const p = lines[i].split("\t");
                    if (p.length < 9) continue;
                    apps[n++] = {
                        title: p[0],
                        comment: p[1],
                        keywords: (p[2] + " " + p[3] + " " + p[7] + " " + p[1]).toLowerCase(),
                        category: "App",
                        icon: "󰀻",
                        exec: p[4],
                        rawIcon: p[5],
                        resolvedIcon: p[6],
                        // Terminal=true in the .desktop entry — apps like
                        // cliamp need a TTY to render; without one they
                        // exit immediately when launched detached.
                        tui: p[8] === "1" ? "foot -e" : ""
                    };
                }
                apps.length = n;
                appScan.apps = Data.annotate(apps);
                appScan.loaded = true;
                appScan.scanned();
            }
        }
    }

    Component.onCompleted: appScan.refresh()
}