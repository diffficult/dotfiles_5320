import QtQuick
import Quickshell
import Quickshell.Io
import "Data.js" as Data

// fd-backed file search + file preview. Query mode now uses fd for
// discovery and fzf --filter for fuzzy ranking inside prioritized
// scopes (Projects / Downloads / Documents / rest of HOME).
Item {
    id: fileSearch

    required property string query
    required property var queryTokens
    required property bool active
    required property var selectedItem

    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string projectsDir: homeDir + "/Projects"
    readonly property string downloadsDir: homeDir + "/Downloads"
    readonly property string documentsDir: homeDir + "/Documents"

    property var items: []
    property string previewPath: ""
    property string previewText: ""
    property string previewMeta: ""
    readonly property bool running: fdProc.running

    readonly property string previewKind: {
        if (!fileSearch.previewPath) return "";
        const ext = Data.fileExt(fileSearch.previewPath);
        if (Data.imageExts.indexOf(ext) >= 0) return "image";
        if (Data.textExts.indexOf(ext) >= 0) return "text";
        return "meta";
    }

    function clear() {
        fileSearch.items = [];
        fileSearch.previewPath = "";
        fileSearch.previewText = "";
        fileSearch.previewMeta = "";
        fdDebounce.stop();
    }

    function updatePreview() {
        if (!fileSearch.active) return;
        const it = fileSearch.selectedItem;
        const path = (it && it.path) || "";
        if (path === fileSearch.previewPath) return;
        fileSearch.previewPath = path;
        fileSearch.previewText = "";
        fileSearch.previewMeta = "";
        if (!path) return;
        const kind = fileSearch.previewKind;
        if (kind === "text") {
            fileSearch.previewText = "Loading…";
            textPreviewProc.command = ["head", "-c", "8192", path];
            textPreviewProc.running = false;
            textPreviewProc.running = true;
        } else if (kind === "meta") {
            fileSearch.previewMeta = "Loading…";
            metaPreviewProc.command = ["sh", "-c",
                "stat -c 'SIZE   %s bytes\nMTIME  %y' \"$1\" 2>/dev/null; "
                + "printf 'MIME   '; file -b --mime-type \"$1\" 2>/dev/null",
                "sh", path];
            metaPreviewProc.running = false;
            metaPreviewProc.running = true;
        }
    }

    function buildFdRegex(tokens) {
        return tokens.join(".*");
    }

    function buildSearchScript() {
        const excludes = Data.fdExcludes.map(function(name) {
            return " --exclude " + JSON.stringify(name);
        }).join("");
        return "set -eu\n"
            + "query=\"$1\"\n"
            + "home=\"$2\"\n"
            + "regex=\"$3\"\n"
            + "projects=\"$home/Projects\"\n"
            + "downloads=\"$home/Downloads\"\n"
            + "documents=\"$home/Documents\"\n"
            + "tab=$(printf '\\t')\n"
            + "fd_base() { fd --type f" + excludes + " \"$@\"; }\n"
            + "tag_lines() {\n"
            + "  awk -v home=\"$home\" '\n"
            + "    function tildify(dir) {\n"
            + "      if (index(dir, home) == 1) return \"~\" substr(dir, length(home) + 1);\n"
            + "      return dir;\n"
            + "    }\n"
            + "    function scope_rank(path) {\n"
            + "      if (path == home \"/Projects\" || index(path, home \"/Projects/\") == 1) return 1;\n"
            + "      if (path == home \"/Downloads\" || index(path, home \"/Downloads/\") == 1) return 2;\n"
            + "      if (path == home \"/Documents\" || index(path, home \"/Documents/\") == 1) return 3;\n"
            + "      return 9;\n"
            + "    }\n"
            + "    function scope_name(rank) {\n"
            + "      return rank == 1 ? \"PROJECTS\" : rank == 2 ? \"DOWNLOADS\" : rank == 3 ? \"DOCUMENTS\" : \"HOME\";\n"
            + "    }\n"
            + "    {\n"
            + "      path = $0;\n"
            + "      if (path == \"\") next;\n"
            + "      rank = scope_rank(path);\n"
            + "      name = path; sub(/^.*\\//, \"\", name);\n"
            + "      dir = path; sub(/\\/[^\\/]+$/, \"\", dir);\n"
            + "      printf \"%d\\t%s\\t%s\\t%s\\t%s\\n\", rank, scope_name(rank), name, tildify(dir), path;\n"
            + "    }\n'
"
            + "}\n"
            + "emit_initial() {\n"
            + "  {\n"
            + "    [ -d \"$projects\" ] && fd_base --max-results 50 . \"$projects\";\n"
            + "    [ -d \"$downloads\" ] && fd_base --max-results 35 . \"$downloads\";\n"
            + "    [ -d \"$documents\" ] && fd_base --max-results 35 . \"$documents\";\n"
            + "  } 2>/dev/null | tag_lines | awk -F \"\\t\" '!seen[$5]++' | sort -t \"$tab\" -k1,1n -k3,3f | head -n 120\n"
            + "}\n"
            + "emit_query() {\n"
            + "  raw=\"$1\"\n"
            + "  tagged=$(mktemp)\n"
            + "  filtered=$(mktemp)\n"
            + "  if printf '%s' \"$raw\" | grep -q '/'; then\n"
            + "    prefix=\"**/\"\n"
            + "    case \"$raw\" in\n"
            + "      /*|\\**) prefix=\"\" ;;\n"
            + "    esac\n"
            + "    fd_base --max-results 1200 --glob --full-path \"$prefix$raw\" \"$home\" 2>/dev/null | tag_lines > \"$tagged\"\n"
            + "  elif printf '%s' \"$raw\" | grep -Eq '[*?]'; then\n"
            + "    fd_base --max-results 1200 --glob \"$raw\" \"$home\" 2>/dev/null | tag_lines > \"$tagged\"\n"
            + "  else\n"
            + "    fd_base --max-results 1600 \"$regex\" \"$home\" 2>/dev/null | tag_lines > \"$tagged\"\n"
            + "    if command -v fzf >/dev/null 2>&1; then\n"
            + "      : > \"$filtered\"\n"
            + "      for rank in 1 2 3 9; do\n"
            + "        awk -F \"\\t\" -v rank=\"$rank\" '$1 == rank' \"$tagged\" \\\n"
            + "          | fzf --filter=\"$raw\" --delimiter=\"$tab\" --with-nth=3,4,5 --tiebreak=index 2>/dev/null || true\n"
            + "      done > \"$filtered\"\n"
            + "      if [ -s \"$filtered\" ]; then mv \"$filtered\" \"$tagged\"; fi\n"
            + "    fi\n"
            + "  fi\n"
            + "  awk -F \"\\t\" '!seen[$5]++' \"$tagged\" | sort -t \"$tab\" -k1,1n | head -n 200\n"
            + "  rm -f \"$tagged\" \"$filtered\"\n"
            + "}\n"
            + "if [ -z \"$query\" ]; then\n"
            + "  emit_initial\n"
            + "else\n"
            + "  emit_query \"$query\"\n"
            + "fi\n";
    }

    function refreshSearch() {
        if (!fileSearch.active) {
            fileSearch.clear();
            return;
        }
        fdProc.command = ["sh", "-c", fileSearch.buildSearchScript(), "sh", fileSearch.query.trim(), fileSearch.homeDir, fileSearch.buildFdRegex(fileSearch.queryTokens)];
        fdProc.running = false;
        fdProc.running = true;
    }

    onQueryChanged: { if (fileSearch.active) fdDebounce.restart(); }
    onSelectedItemChanged: { if (fileSearch.active) fileSearch.updatePreview(); }
    onActiveChanged: {
        if (fileSearch.active) fdDebounce.restart();
        else fileSearch.clear();
    }

    Process {
        id: fdProc
        running: false
        command: ["sh", "-c", "true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(s => s.length > 0);
                const out = new Array(lines.length);
                for (let i = 0; i < lines.length; i++) {
                    const p = lines[i].split("\t");
                    if (p.length < 5) continue;
                    out[i] = {
                        title: p[2],
                        subtitle: p[3],
                        comment: p[3],
                        keywords: (p[2] + " " + p[3] + " " + p[4]).toLowerCase(),
                        category: p[1],
                        icon: Data.fileIcon(p[4]),
                        path: p[4],
                        exec: Data.openUrl(p[4]),
                        scopeRank: parseInt(p[0], 10),
                        rowKind: "file"
                    };
                }
                fileSearch.items = out.filter(function(it) { return !!it; });
                fileSearch.updatePreview();
            }
        }
    }

    Timer {
        id: fdDebounce
        interval: 120
        repeat: false
        onTriggered: fileSearch.refreshSearch()
    }

    Process {
        id: textPreviewProc
        running: false
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: { fileSearch.previewText = this.text; }
        }
    }
    Process {
        id: metaPreviewProc
        running: false
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: { fileSearch.previewMeta = this.text; }
        }
    }
}