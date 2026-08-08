import QtQuick
import Quickshell.Io

// LLM backend for the omni-menu. Three modes share the same
// process / probe / streaming machinery:
//   "linux"    - triggered by `# <question>` for Linux / CLI help
//   "general"  - triggered by `? <question>` for general questions
//   "command"  - triggered by `$ <task>` for shell-command suggestions
// Only the system prompt and the placeholder copy differ. Mirrors
// TldrSearch's shape: a synthetic single-row item plus a streamed
// preview body. The HTTP API at 10.0.10.100:8084 streams SSE
// (Server-Sent Events) chunks which a SplitParser appends to previewText.
//
// State machine (status property):
//   ""          probe still running (transient)
//   "no-daemon" remote HTTP endpoint not responding
//   "ok"        endpoint reachable — Enter submits the prompt
//
// Within "ok", `submitted` flips true on Enter and `running` tracks the
// curl subprocess; once running flips back to false the answer is done.
//
// This launcher talks to a remote/shared OpenAI-compatible endpoint
// (llama.cpp-server / vllm / etc.), so palette close must not unload
// the model. Eviction policy belongs to the server/operator, not this
// client UI.
Item {
    id: ollamaChat

    required property string query
    required property bool active
    // "linux" (`#` prefix), "general" (`?` prefix), or "command"
    // (`$` prefix). The mode steers which trigger character parseQuery
    // accepts and which system prompt the model receives.
    property string mode: "linux"

    property var items: []
    property string previewText: ""
    property string prompt: ""
    property string status: ""
    property bool submitted: false
    property string requestError: ""
    property string transientNotice: ""
    readonly property bool running: chatProc.running
    readonly property bool invalidCommandResponse:
        ollamaChat.mode === "command"
        && ollamaChat.submitted
        && !ollamaChat.running
        && ollamaChat.requestError === ""
        && ollamaChat.previewText.trim().length > 0
        && !ollamaChat.canCopyCommand()

    property int _gen: 0
    readonly property string model_: "Qwen2.5-7B-Instruct-Q4_K_M.gguf"
    readonly property string baseUrl: "http://10.0.10.100:8084/v1/chat/completions"
        readonly property string healthUrl: "http://10.0.10.100:8084/health"
    readonly property string triggerChar:
        ollamaChat.mode === "command" ? "$"
      : ollamaChat.mode === "general" ? "?"
      : "#"

    // Emitted from submit() so callers can scroll to top / reset
    // state on each *new* submission specifically — not on every
    // prompt edit (which also flips `submitted` false→true→false).
    signal promptSubmitted()
    // Linux-mode prompt. Steers the model toward terse Arch/CLI help.
    readonly property string linuxSystemPrompt:
          "You are a terse Linux and CLI assistant for an Arch / Hyprland user. "
        + "Reply in devrel style: short, scannable, no preamble, no apologies. "
        + "Lead with the answer or the exact command. "
        + "Wrap every shell snippet in a fenced ```code``` block. "
        + "Use plain hyphens (-), never em dashes. "
        + "If you don't know, say so in one line. "
        + "Skip restating the question."

    readonly property string generalSystemPrompt:
          "You are a terse, no-nonsense general knowledge assistant. "
        + "Answer clearly and directly from knowledge or by searching the web when needed. "
        + "Reply in devrel style: short, scannable, no preamble, no apologies. "
        + "Lead with the answer. "
        + "Use plain hyphens (-), never em dashes. "
        + "If you don't know or need to search, say so in one line. "
        + "Skip restating the question."

    // Command-mode prompt. Output is one shell command (or a
    // pipeline / && chain) inside a single fenced block, nothing else.
    // No prose lets the user copy-paste straight to a terminal.
    readonly property string commandSystemPrompt:
          "You are a Linux shell expert helping an Arch / Hyprland user. "
        + "Given the user's task, output ONE concrete shell command that "
        + "accomplishes it. Combine multiple steps with `&&` or `|`. "
        + "Wrap the command in a single fenced ```bash``` block. "
        + "No prose, no explanation, no preamble, no trailing notes. "
        + "Prefer GNU/coreutils. Quote arguments that need it. "
        + "If the task is unclear or unsafe, output `# unclear` instead."

    readonly property string systemPrompt:
        ollamaChat.mode === "command" ? ollamaChat.commandSystemPrompt
      : ollamaChat.mode === "general" ? ollamaChat.generalSystemPrompt
      : ollamaChat.linuxSystemPrompt

    function clear() {
        ollamaChat.items = [];
        ollamaChat.previewText = "";
        ollamaChat.prompt = "";
        ollamaChat.submitted = false;
        ollamaChat.requestError = "";
        ollamaChat.transientNotice = "";
        noticeClearTimer.stop();
        ollamaChat._gen += 1;
        chatProc.running = false;
        probeProc.running = false;
        ollamaChat.status = "";
        ollamaChat.refreshItems();
    }

    function showNotice(text) {
        ollamaChat.transientNotice = text;
        noticeClearTimer.restart();
    }

    function extractedCommand() {
        const text = (ollamaChat.previewText || "").trim();
        if (text.length === 0) return "";
        const fenced = text.match(/```(?:bash|sh)?\n([\s\S]*?)```/i);
        if (fenced && fenced[1]) return fenced[1].trim();
        return "";
    }

    function canCopyCommand() {
        return ollamaChat.extractedCommand().length > 0;
    }

    function copyCommandToClipboard() {
        const cmd = ollamaChat.extractedCommand();
        if (cmd.length === 0) return false;
        clipProc.command = ["wl-copy", "--", cmd];
        clipProc.running = false;
        clipProc.running = true;
        ollamaChat.showNotice("copied to clipboard");
        return true;
    }

    function cancelRequest() {
        if (!ollamaChat.running) return false;
        ollamaChat._gen += 1;
        chatProc.running = false;
        ollamaChat.requestError = "cancelled";
        ollamaChat.showNotice("generation cancelled");
        return true;
    }

    function parseQuery(q) {
        if (q.charAt(0) !== ollamaChat.triggerChar) return null;
        return { prompt: q.substring(1).trim() };
    }

    function refreshItems() {
        if (!ollamaChat.active) { ollamaChat.items = []; return; }
        const empty = ollamaChat.prompt.length === 0;
        const placeholder = ollamaChat.mode === "command"
            ? "describe a shell task after $"
            : ollamaChat.mode === "general"
                ? "type a question after ?"
                : "type a Linux / CLI question after #";
        ollamaChat.items = [{
            title: "llm " + ollamaChat.model_,
            comment: empty ? placeholder : ollamaChat.prompt,
            keywords: "",
            category: "llm",
            icon: "󱚤",
            rawCategory: true,
            isLlm: true
        }];
    }

    function submit() {
        if (ollamaChat.status !== "ok") return;
        if (ollamaChat.prompt.length === 0) return;
        ollamaChat.submitted = true;
        ollamaChat.requestError = "";
        ollamaChat.transientNotice = "";
        noticeClearTimer.stop();
        ollamaChat.previewText = "";
        ollamaChat._gen += 1;
        chatProc.gen = ollamaChat._gen;
        // OpenAI-compatible chat completions endpoint (non-streaming).
        // stream:false returns the full JSON response in one shot,
        // which avoids Quickshell SplitParser / SSE buffering issues.
        const body = JSON.stringify({
            model: ollamaChat.model_,
            messages: [
                { role: "system", content: ollamaChat.systemPrompt },
                { role: "user", content: ollamaChat.prompt }
            ],
            stream: false
        });
        chatProc.command = ["sh", "-c",
            "curl -s --connect-timeout 2 --max-time 60 \"$1\" -H \"Content-Type: application/json\" -d \"$2\"; rc=$?; "
            + "if [ $rc -eq 0 ]; then exit 0; fi; "
            + "if [ $rc -eq 28 ]; then printf '%s\\n' '{\"__warmind_error\":\"timeout\"}'; "
            + "else printf '%s\\n' '{\"__warmind_error\":\"failed\"}'; fi",
            "sh", ollamaChat.baseUrl, body];
        chatProc.running = false;
        chatProc.running = true;
        ollamaChat.promptSubmitted();
    }

    onActiveChanged: {
        if (ollamaChat.active) {
            // Re-probe on every entry: server restart / model swap
            // performed in a previous activation should be picked up
            // without a menu reload.
            ollamaChat.status = "";
            probeProc.running = false;
            probeProc.running = true;
            ollamaChat.refreshItems();
        } else {
            // User backspaced the trigger prefix while the menu stayed
            // open. Cancel any in-flight stream so curl + server
            // don't keep spending CPU/tokens on an answer no-one is
            // looking at, and bump _gen so late chunks can't backwrite
            // previewText. Keep prompt/items/submitted for the case
            // where they re-type `?` with the same content — clear()
            // is called from close()/category-pivot, not here.
            ollamaChat._gen += 1;
            chatProc.running = false;
            ollamaChat.requestError = "cancelled";
        }
    }

    onQueryChanged: {
        if (!ollamaChat.active) return;
        const parsed = ollamaChat.parseQuery(ollamaChat.query);
        const next = parsed ? parsed.prompt : "";
        if (next !== ollamaChat.prompt) {
            ollamaChat.prompt = next;
            ollamaChat.submitted = false;
            ollamaChat.previewText = "";
            ollamaChat.requestError = "";
            ollamaChat.transientNotice = "";
            // Editing the prompt invalidates any in-flight stream.
            ollamaChat._gen += 1;
            chatProc.running = false;
            ollamaChat.refreshItems();
        }
    }

    // Mode flip mid-activation (user swapped `?` <-> `$` without
    // closing the palette). The system prompt has changed, so any
    // in-flight response from the previous mode is now misaligned.
    // Cancel it and resync prompt from the new query shape.
    onModeChanged: {
        if (!ollamaChat.active) return;
        ollamaChat.submitted = false;
        ollamaChat.previewText = "";
        ollamaChat.requestError = "";
        ollamaChat.transientNotice = "";
        ollamaChat._gen += 1;
        chatProc.running = false;
        const parsed = ollamaChat.parseQuery(ollamaChat.query);
        ollamaChat.prompt = parsed ? parsed.prompt : "";
        ollamaChat.refreshItems();
    }

    // Readiness probe — runs once per LLM activation. Simply checks
    // whether the OpenAI-compatible endpoint responds at all.
    // (No /api/tags equivalent on llama.cpp-server; we skip the
    // "no-model" granularity and treat any HTTP response as ok.)
    Process {
        id: probeProc
        running: false
        command: ["sh", "-c",
            "if ! curl -s --max-time 2 -o /dev/null \"$1\"; then echo no-daemon; exit; fi; "
            + "echo ok",
            "sh", ollamaChat.healthUrl]
        stdout: StdioCollector {
            onStreamFinished: { ollamaChat.status = this.text.trim(); }
        }
    }

    Process {
        id: clipProc
        running: false
        command: ["true"]
    }

    Timer {
        id: noticeClearTimer
        interval: 1200
        repeat: false
        onTriggered: ollamaChat.transientNotice = ""
    }

    // Non-streaming inference via OpenAI-compatible endpoint.
    // StdioCollector buffers the entire JSON response; onStreamFinished
    // extracts choices[0].message.content in one shot. Simpler than SSE
    // streaming and avoids Quickshell SplitParser buffering quirks.
    Process {
        id: chatProc
        running: false
        command: ["true"]
        property int gen: 0
        stdout: StdioCollector {
            onStreamFinished: {
                if (chatProc.gen !== ollamaChat._gen) return;
                const text = this.text.trim();
                if (text.length === 0) return;

                // Synthetic error injected by curl wrapper
                try {
                    const obj = JSON.parse(text);
                    if (typeof obj.__warmind_error === "string") {
                        ollamaChat.requestError = obj.__warmind_error;
                        return;
                    }
                    // OpenAI-compatible error response
                    if (obj.error) {
                        ollamaChat.requestError = obj.error.message || "api error";
                        return;
                    }
                    if (obj.choices && obj.choices[0] && obj.choices[0].message
                        && typeof obj.choices[0].message.content === "string") {
                        ollamaChat.previewText = obj.choices[0].message.content;
                    }
                } catch (e) {
                    // Non-JSON response (rare). Silently skip.
                }
            }
        }
    }
}
