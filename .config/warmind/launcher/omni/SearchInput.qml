import QtQuick

// Search row: magnifier glyph, current query (or mode-specific
// placeholder), and a blinking caret. Hidden entirely in quickMode -
// the tile grid is its own input surface.
Item {
    id: input
    required property var omni

    visible: !omni.quickMode && !omni.launcherIconsMode && !omni.colorSchemeMode
    width: parent ? parent.width : 0
    readonly property real textLeft: omni.showSearchGlyph ? searchPrompt.x + searchPrompt.width + 10 : 0
    readonly property real textWidth: Math.max(0, width - textLeft)
    readonly property bool showingPlaceholder: omni.query.length === 0
    readonly property real contentHeight: showingPlaceholder
        ? placeholderText.implicitHeight
        : Math.max(queryEdit.implicitHeight, queryEdit.cursorRectangle.y + queryEdit.cursorRectangle.height)
    height: visible ? Math.max(38, contentHeight + 10) : 0

    Text {
        id: searchPrompt
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: Math.max(0, (input.height - height) / 2)
        text: input.omni.fileMode ? "󰉖"
              : input.omni.ghMode ? "󰊤"
              : input.omni.procMode ? "󰍛"
              : input.omni.themeMode ? "󰸌"
              : "󰍉"
        visible: input.omni.showSearchGlyph
        color: input.omni.seal
        font.family: input.omni.mono
        font.pixelSize: input.omni.searchGlyphSize * input.omni.fontScale
    }

    Text {
        id: placeholderText
        visible: input.showingPlaceholder
        anchors.left: parent.left
        anchors.leftMargin: input.textLeft
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 5
        text: {
            const o = input.omni;
            if (o.fileMode)  return "Type to search files · Projects / Downloads / Documents prioritized";
            if (o.ghMode)    return "Your PRs · type to search GitHub repos";
            if (o.procMode)  return "Type to filter processes by name, user, pid…";
            if (o.themeMode) return "Type to filter themes…";
            if (o.emojiMode) return "Type to search emoji · @group narrows families · #subgroup narrows icon sets";
            return "Type to search · @app filters · # linux · ? general · $ command · bind · tldr <cmd>";
        }
        color: input.omni.inkDeep
        opacity: 0.5
        wrapMode: Text.Wrap
        font.family: input.omni.mono
        font.pixelSize: 14 * input.omni.fontScale
        font.letterSpacing: 1
    }

    TextEdit {
        id: queryEdit
        visible: !input.showingPlaceholder
        readOnly: true
        selectByMouse: false
        anchors.left: parent.left
        anchors.leftMargin: input.textLeft
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 5
        text: input.omni.query
        color: input.omni.ink
        wrapMode: TextEdit.Wrap
        font.family: input.omni.mono
        font.pixelSize: 16 * input.omni.fontScale
        font.letterSpacing: 1
        textFormat: TextEdit.PlainText
        cursorPosition: input.omni.queryCursorPos
    }

    // Blinking caret riding the logical query cursor. Do not use
    // TextEdit.cursorRectangle here: this edit is read-only and receives
    // programmatic text replacements, so Qt can leave that visual cursor at
    // its previous layout position for a frame. positionToRectangle() is
    // computed from the authoritative queryCursorPos instead.
    readonly property rect logicalCursorRectangle: {
        // Make the layout binding explicitly depend on the rendered text as
        // well as the logical position.
        queryEdit.text.length
        return queryEdit.positionToRectangle(input.omni.queryCursorPos)
    }
    Rectangle {
        id: caret
        width: 2
        height: Math.max(18, input.logicalCursorRectangle.height)
        color: input.omni.seal
        x: input.showingPlaceholder
           ? input.textLeft + 2
           : input.textLeft + input.logicalCursorRectangle.x
        y: input.showingPlaceholder ? 7 : (5 + input.logicalCursorRectangle.y)
        visible: input.omni.visible_
        SequentialAnimation on opacity {
            running: input.omni.visible_
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: 0.2; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.2; to: 1; duration: 600; easing.type: Easing.InOutSine }
        }
    }
}
