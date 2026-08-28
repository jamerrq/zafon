// Arch logo in place of the Omarchy logo on the bar menu button.
//
// This is a custom user bar module (`{ "id": "arch", "type": "qml" }` in
// shell.json) rather than a clone of omarchy.menu. Cloning that plugin would
// fork its 54KB Menu.qml just to change one glyph and freeze it at this
// version; this only replaces the button, so the menu itself keeps getting
// upstream updates.
//
// Behaviour matches the stock omarchy.menu widget (and the old waybar
// custom/omarchy module): left opens the Omarchy menu, right opens a terminal.

import QtQuick

Item {
  id: root

  property var bar
  property string moduleName
  property var settings

  // U+F08C7 (nf-md-arch). Written as a codepoint rather than the literal
  // character so the file survives any non-UTF-8 tooling that touches it.
  readonly property string glyph: String.fromCodePoint(0xF08C7)

  implicitWidth: root.bar && root.bar.vertical ? root.bar.barSize : label.implicitWidth + 15
  implicitHeight: root.bar && root.bar.vertical ? label.implicitHeight + 15 : (root.bar ? root.bar.barSize : 26)

  Text {
    id: label
    anchors.centerIn: parent
    text: root.glyph
    color: root.bar ? root.bar.foreground : "white"
    font.family: root.bar ? root.bar.fontFamily : "monospace"
    font.pixelSize: 15
    renderType: Text.NativeRendering
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onEntered: if (root.bar) root.bar.showTooltip(root, "Omarchy Menu\n\nSuper + Alt + Space")
    onExited: if (root.bar) root.bar.hideTooltip(root)

    onPressed: function (mouse) {
      if (!root.bar) return
      if (mouse.button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
    }
  }
}
