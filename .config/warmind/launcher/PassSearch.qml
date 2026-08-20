import QtQuick
import Quickshell
import Quickshell.Io

// Password-store integration with deferred decrypt.
//
// Final UX model:
//   list      — filterable list of pass entries
//   unlocking — waiting for pass show / pinentry-rofi
//   overview  — unlocked entry with quick actions + field rows
//
// Autotype sequence (from entry's "autotype:" field, default "user :tab pass"):
//   pass      → type password
//   user      → type username
//   :tab      → press Tab
//   :space    → press Space
//   :enter    → press Return
//   :delay    → sleep 1s
//   <field>   → type value of that field
Item {
    id: root

    required property string query
    property var allItems: []
    property var items: []
    property int selectedIndex: 0
    property string view: "list"   // "list" | "unlocking" | "overview"
    property string sessionLockState: "locked"  // "locked" | "unlocking" | "unlocked"
    readonly property bool sessionUnlocked: sessionLockState === "unlocked"

    // Decrypted entry state
    property string currentEntry: ""
    property string currentEntryTitle: ""
    property string currentEntrySubtitle: ""
    property string currentPassword: ""
    property string currentUsername: ""
    property string currentUrl: ""
    property string currentOtp: ""
    property string currentOtpUri: ""
    property string currentAutotype: ""
    property var currentFields: ({})
    property var overviewItemsAll: []

    property int listIndexBeforeUnlock: 0
    property string listQueryBeforeUnlock: ""
    property string status: ""   // "" | "unlocking" | "waiting_pinentry" | "unlock_failed" | "unlock_cancelled" | "copied" | "typed"
    property string unlockError: ""
    property bool decryptSucceeded: false

    readonly property string storeRoot: Quickshell.env("HOME") + "/.password-store"
    readonly property int typeDelayMs: 20
    readonly property int tabDelayMs: 60
    readonly property int startDelayMs: 300
    readonly property string usernameField: "user"
    readonly property var usernameFields: ["user", "login", "username"]
    readonly property string urlField: "url"
    readonly property string autotypeField: "autotype"
    readonly property string otpField: "otp_method"

    signal itemActivated(var item)
    signal requestQueryChange(string value)

    function reset() {
        view = "list"
        // Refresh the entry list every time Pass mode opens so new
        // ~/.password-store entries appear without a launcher restart.
        listProc.running = false
        listProc.running = true
        sessionLockState = "locked"
        status = ""
        unlockError = ""
        decryptSucceeded = false
        currentEntry = ""
        currentEntryTitle = ""
        currentEntrySubtitle = ""
        currentPassword = ""
        currentUsername = ""
        currentUrl = ""
        currentOtp = ""
        currentOtpUri = ""
        currentAutotype = ""
        currentFields = ({})
        overviewItemsAll = []
        listQueryBeforeUnlock = ""
        waitingForPinentryTimer.stop()
        clearStatusTimer.stop()
        items = _filteredEntries()
        selectedIndex = 0
    }

    function goBack() {
        if (view === "overview" || view === "unlocking") {
            view = "list"
            requestQueryChange(listQueryBeforeUnlock)
            items = _filteredEntriesWithQuery(listQueryBeforeUnlock)
            selectedIndex = Math.max(0, Math.min(listIndexBeforeUnlock, items.length - 1))
            status = ""
            waitingForPinentryTimer.stop()
            return true
        }
        return false
    }

    function selectItem(item) {
        if (!item) return
        if (view === "list") {
            _decryptEntry(item)
            return
        }
        if (view === "overview") {
            _activatePrimary(item)
        }
    }

    function activateSecondary(item) {
        if (!item || view !== "overview") return
        _activateSecondary(item)
    }

    function kbdHandle(event) {
        if (view === "unlocking") {
            if (event.key === Qt.Key_Escape) {
                goBack()
                event.accepted = true
            }
            return
        }
        if (event.key === Qt.Key_Up) {
            selectedIndex = Math.max(0, selectedIndex - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            selectedIndex = Math.min(items.length - 1, selectedIndex + 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (event.modifiers & Qt.ControlModifier)
                activateSecondary(items[selectedIndex])
            else
                selectItem(items[selectedIndex])
            event.accepted = true
        }
    }

    onQueryChanged: {
        if (view === "list") {
            items = _filteredEntries()
            selectedIndex = 0
        } else if (view === "overview") {
            items = _filteredOverviewItems()
            selectedIndex = items.length > 0 ? 0 : -1
        }
    }

    function _tokensFor(text) {
        return (text || "").toLowerCase().split(/\s+/).filter(function(t) { return t.length > 0 })
    }

    function _filteredEntriesWithQuery(text) {
        if (!text) return allItems
        var tokens = _tokensFor(text)
        return allItems.filter(function(it) {
            var hay = it.keywords.toLowerCase()
            return tokens.every(function(t) { return hay.includes(t) })
        })
    }

    function _filteredEntries() {
        return _filteredEntriesWithQuery(query)
    }

    function _filteredOverviewItems() {
        if (!query) return overviewItemsAll
        var tokens = _tokensFor(query)
        return overviewItemsAll.filter(function(it) {
            var hay = ((it.title || "") + " " + (it.subtitle || "") + " "
                      + (it.fieldKey || "") + " " + (it.actionId || "")).toLowerCase()
            return tokens.every(function(t) { return hay.includes(t) })
        })
    }

    Component.onCompleted: {
        listProc.running = false
        listProc.running = true
    }

    Process {
        id: listProc
        command: ["find", root.storeRoot, "-name", "*.gpg", "-type", "f",
                  "-not", "-path", "*/.git/*"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n").filter(function(l) { return l.length > 0 })
                var prefix = root.storeRoot + "/"
                root.allItems = lines.map(function(path) {
                    var entry = path.replace(prefix, "").replace(/\.gpg$/, "")
                    var parts = entry.split("/")
                    var name = parts[parts.length - 1]
                    var folder = parts.slice(0, -1).join("/")
                    return {
                        entryPath: entry,
                        title: name,
                        subtitle: folder,
                        icon: "",
                        keywords: entry.replace(/\//g, " "),
                        category: "Pass",
                        exec: ""
                    }
                })
                root.items = root._filteredEntries()
            }
        }
    }

    function _decryptEntry(item) {
        root.listIndexBeforeUnlock = root.selectedIndex
        root.listQueryBeforeUnlock = query
        root.currentEntry = item.entryPath
        root.currentEntryTitle = item.title || item.entryPath
        root.currentEntrySubtitle = item.subtitle || item.entryPath
        root.unlockError = ""
        root.decryptSucceeded = false
        root.status = "unlocking"
        root.sessionLockState = "unlocking"
        root.view = "unlocking"
        root.items = []
        waitingForPinentryTimer.restart()
        decryptProc.command = ["zsh", "-c", "pass show " + JSON.stringify(item.entryPath) + " 2>&1"]
        decryptProc.running = false
        decryptProc.running = true
    }

    Process {
        id: decryptProc
        stdout: StdioCollector {
            onStreamFinished: {
                var text = this.text || ""
                var lines = text.split("\n")
                var firstLine = lines.length > 0 ? lines[0].trim() : ""
                if (!firstLine) {
                    root.decryptSucceeded = false
                    return
                }

                root.currentPassword = lines[0]
                var fields = { pass: lines[0] }
                var hasOtp = false
                var otpUri = ""

                for (var i = 1; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (!line) continue
                    if (line.startsWith("otpauth://")) {
                        otpUri = line
                        hasOtp = true
                        continue
                    }
                    var colon = line.indexOf(": ")
                    if (colon > 0) {
                        var k = line.substring(0, colon).toLowerCase()
                        var v = line.substring(colon + 2)
                        fields[k] = v
                        if (k === root.otpField) hasOtp = true
                    }
                }

                root.currentFields = fields
                root.currentUsername = ""
                for (var f = 0; f < root.usernameFields.length; f++) {
                    var alias = root.usernameFields[f]
                    if (fields[alias]) {
                        root.currentUsername = fields[alias]
                        break
                    }
                }
                root.currentUrl = fields[root.urlField] || ""
                root.currentAutotype = fields[root.autotypeField] || ""
                root.currentOtp = hasOtp ? "1" : ""
                root.currentOtpUri = otpUri
                root.decryptSucceeded = true
            }
        }
        onExited: (code) => {
            waitingForPinentryTimer.stop()

            // If the user already backed out of the unlocking state,
            // ignore the late result instead of reopening overview.
            if (root.view !== "unlocking")
                return

            if (code === 0 && root.decryptSucceeded) {
                root.status = ""
                root.sessionLockState = "unlocked"
                root.view = "overview"
                root.overviewItemsAll = root._buildOverviewItems()
                requestQueryChange("")
                root.items = root._filteredOverviewItems()
                root.selectedIndex = root.items.length > 0 ? 0 : -1
                return
            }

            root.view = "list"
            root.items = root._filteredEntries()
            root.selectedIndex = Math.max(0, Math.min(root.listIndexBeforeUnlock, root.items.length - 1))
            root.sessionLockState = "locked"
            root.status = code === 2 ? "unlock_cancelled" : "unlock_failed"
            root.unlockError = ""
            clearStatusTimer.restart()
        }
    }

    function _buildOverviewItems() {
        var rows = []
        var orderedKeys = []

        function addIfPresent(key) {
            if (root.currentFields[key] === undefined || orderedKeys.indexOf(key) >= 0)
                return
            orderedKeys.push(key)
        }

        addIfPresent(root.autotypeField)
        addIfPresent("pass")
        addIfPresent("user")
        addIfPresent("username")
        addIfPresent("login")
        addIfPresent("email")
        addIfPresent("mail")
        addIfPresent(root.urlField)
        addIfPresent("comment")
        addIfPresent("comments")
        if (root.currentOtp) orderedKeys.push("__otp__")

        var keys = Object.keys(root.currentFields)
        var remainingKeys = []
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i]
            if (orderedKeys.indexOf(key) >= 0 || key === root.otpField)
                continue
            remainingKeys.push(key)
        }
        remainingKeys.sort(function(a, b) {
            return a.localeCompare(b)
        })
        for (var rk = 0; rk < remainingKeys.length; rk++) {
            orderedKeys.push(remainingKeys[rk])
        }

        for (var j = 0; j < orderedKeys.length; j++) {
            rows.push(_buildFieldRow(orderedKeys[j]))
        }

        return rows
    }

    function _buildFieldRow(key) {
        if (key === "__otp__") {
            return {
                title: "otp",
                subtitle: "OTP available",
                icon: "󰒱",
                category: "Pass",
                exec: "",
                rowKind: "field",
                fieldKey: "__otp__",
                fieldType: "otp",
                primaryAction: "copyOtp",
                secondaryAction: ""
            }
        }

        var value = root.currentFields[key] || ""
        var fieldType = _classifyField(key)
        return {
            title: key,
            subtitle: _fieldSubtitleFor(key, value),
            icon: fieldType === "pass" ? "󰌾" : fieldType === "url" ? "󰌷" : fieldType === "otp" ? "󰒱" : "󰋺",
            category: "Pass",
            exec: "",
            rowKind: "field",
            fieldKey: key,
            fieldType: fieldType,
            primaryAction: _primaryActionForField(key),
            secondaryAction: _secondaryActionForField(key)
        }
    }

    function _classifyField(key) {
        if (key === "pass" || key === "password") return "pass"
        if (root.usernameFields.indexOf(key) >= 0) return "user"
        if (key === root.urlField) return "url"
        if (key === root.autotypeField) return "autotype"
        if (key === "__otp__" || key === root.otpField || key === "otp" || key === "otp_uri") return "otp"
        return _shouldMaskField(key) ? "sensitive_generic" : "generic"
    }

    function _primaryActionForField(key) {
        var kind = _classifyField(key)
        if (kind === "pass") return "typePass"
        if (kind === "user") return "typeUser"
        if (kind === "url") return "typeField"
        if (kind === "autotype") return "autotype"
        if (kind === "otp") return "copyOtp"
        return "typeField"
    }

    function _secondaryActionForField(key) {
        var kind = _classifyField(key)
        if (kind === "pass") return "copyPass"
        if (kind === "user") return "copyUser"
        if (kind === "url") return "copyField"
        if (kind === "autotype") return ""
        if (kind === "otp") return "copyOtp"
        return "copyField"
    }

    function _shouldMaskField(key) {
        var lower = (key || "").toLowerCase()
        return lower === "pass"
            || lower === "password"
            || lower.indexOf("token") >= 0
            || lower.indexOf("secret") >= 0
            || lower === "apikey"
            || lower === "api_key"
            || lower === "client_secret"
            || lower === "private_key"
    }

    function _displayValueForField(key, value) {
        if (_classifyField(key) === "pass") return "••••••••"
        if (_classifyField(key) === "autotype") return _displayAutotypeSequence()
        return value
    }

    function _fieldSubtitleFor(key, value) {
        return _displayValueForField(key, value)
    }

    function _displayAutotypeSequence() {
        var seq = root.currentAutotype || (root.currentUsername ? "user :tab pass" : "pass")
        return seq.replace(/:tab/g, "Tab")
                  .replace(/:space/g, "Space")
                  .replace(/:enter/g, "Enter")
                  .replace(/:delay/g, "Delay")
                  .replace(/\s+/g, " → ")
    }

    function _activatePrimary(item) {
        if (!item) return
        if (item.rowKind === "field") {
            _executeFieldAction(item.fieldKey, item.primaryAction)
        }
    }

    function _activateSecondary(item) {
        if (!item || item.rowKind !== "field" || !item.secondaryAction) return
        _executeFieldAction(item.fieldKey, item.secondaryAction)
    }

    function _executeFieldAction(key, actionId) {
        switch (actionId) {
            case "autotype": _doAutotype(); break
            case "typePass": _doTypePass(); break
            case "copyPass": _doCopyPass(); break
            case "typeUser": _doTypeText(root.currentUsername, true); break
            case "copyUser": _doCopyField(root.currentUsername); break
            case "typeField": _doTypeText(root.currentFields[key] || "", true); break
            case "copyOtp":  _doCopyOtp(); break
            case "copyField": _doCopyField(root.currentFields[key] || ""); break
        }
    }

    function _executeAction(actionId) {
        switch (actionId) {
            case "autotype": _doAutotype(); break
            case "copyPass": _doCopyPass(); break
            case "typePass": _doTypePass(); break
            case "copyUser": _doCopyField(root.currentUsername); break
            case "typeUser": _doTypeText(root.currentUsername, true); break
            case "copyUrl": _doCopyField(root.currentUrl); break
            case "openUrl": _doOpenUrl(); break
            case "copyOtp": _doCopyOtp(); break
        }
    }

    function _doAutotype() {
        var seq = root.currentAutotype || (root.currentUsername ? "user :tab pass" : "pass")
        var words = seq.trim().split(/\s+/)
        var parts = []

        for (var i = 0; i < words.length; i++) {
            var w = words[i]
            var val = ""
            if      (w === ":tab")   parts.push("wtype -P Tab -p Tab && sleep " + (root.tabDelayMs / 1000))
            else if (w === ":space") parts.push("wtype ' '")
            else if (w === ":enter") parts.push("wtype -P Return -p Return")
            else if (w === ":delay") parts.push("sleep 1")
            else if (w === "pass" || w === "password")
                parts.push("wtype -d " + root.typeDelayMs + " -- " + JSON.stringify(root.currentPassword))
            else if (w === "user" || w === root.usernameField)
                parts.push("wtype -d " + root.typeDelayMs + " -- " + JSON.stringify(root.currentUsername))
            else {
                val = root.currentFields[w] || ""
                if (val) parts.push("wtype -d " + root.typeDelayMs + " -- " + JSON.stringify(val))
            }
        }

        if (parts.length === 0) return

        itemActivated({})
        autotypeTimer.cmd = "sleep " + (root.startDelayMs / 1000) + " && " + parts.join(" && ")
        autotypeTimer.start()
    }

    function _doCopyPass() {
        miscProc.command = ["wl-copy", "--", root.currentPassword]
        miscProc.running = false
        miscProc.running = true
        root.status = "copied"
        clearStatusTimer.restart()
        itemActivated({})
    }

    function _doTypePass() {
        var value = root.currentPassword
        root.status = "typed"
        clearStatusTimer.restart()
        autotypeTimer.cmd = "sleep " + (root.startDelayMs / 1000) + " && wtype -d " + root.typeDelayMs + " -- " + JSON.stringify(value)
        itemActivated({})
        autotypeTimer.start()
    }

    function _doCopyField(value) {
        miscProc.command = ["wl-copy", "--", value]
        miscProc.running = false
        miscProc.running = true
        root.status = "copied"
        clearStatusTimer.restart()
        itemActivated({})
    }

    function _doTypeText(value, close) {
        var snapshot = value
        root.status = "typed"
        clearStatusTimer.restart()
        autotypeTimer.cmd = "sleep " + (root.startDelayMs / 1000) + " && wtype -d " + root.typeDelayMs + " -- " + JSON.stringify(snapshot)
        if (close) itemActivated({})
        autotypeTimer.start()
    }

    function _doOpenUrl() {
        miscProc.command = ["xdg-open", root.currentUrl]
        miscProc.running = false
        miscProc.running = true
        itemActivated({})
    }

    function _doCopyOtp() {
        miscProc.command = ["zsh", "-c",
            "pass otp " + JSON.stringify(root.currentEntry)
            + " | tr -d '\\n' | wl-copy"]
        miscProc.running = false
        miscProc.running = true
        root.status = "copied"
        clearStatusTimer.restart()
        itemActivated({})
    }

    Process { id: miscProc }

    Timer {
        id: autotypeTimer
        property string cmd: ""
        interval: 700
        repeat: false
        onTriggered: {
            typeProc.command = ["zsh", "-c", cmd]
            typeProc.running = false
            typeProc.running = true
        }
    }

    Process { id: typeProc }

    Timer {
        id: waitingForPinentryTimer
        interval: 900
        repeat: false
        onTriggered: {
            if (root.view === "unlocking") root.status = "waiting_pinentry"
        }
    }

    Timer {
        id: clearStatusTimer
        interval: 2500
        repeat: false
        onTriggered: root.status = ""
    }

    Text {
        visible: root.status !== ""
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 8
        }
        text: root.status === "unlocking" ? "Unlocking entry…"
            : root.status === "waiting_pinentry" ? "Waiting for GPG pinentry…"
            : root.status === "copied" ? "Copied to clipboard"
            : root.status === "typed" ? "Typed into active window"
            : root.status === "unlock_cancelled" ? "Unlock cancelled"
            : root.status === "unlock_failed" ? "Entry could not be decrypted"
            : ""
        color: (root.status === "unlock_failed" || root.status === "unlock_cancelled") ? "#f38ba8" : "#89b4fa"
        font.pixelSize: 12
    }
}
