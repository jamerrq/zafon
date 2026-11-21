import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "jamerrq.opencode-go"
  ipcTarget: "jamerrq.opencode-go"

  property double nowMs: Date.now()
  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color urgent: bar ? bar.urgent : Commons.Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.35)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool alarming: service.account && service.account.status === "ok" ? Model.behindPace(
    Model.normalizeWindow(service.account.weekly, "weekly", nowMs), nowMs) : false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    nowMs = Date.now()
    service.refresh()
  }

  function weeklyValue(account) {
    return account && account.weekly ? Number(account.weekly.percent) / 100 : 0
  }

  onOpenedChanged: if (opened) {
    nowMs = Date.now()
    if (!service.lastUpdated || (Date.now() - service.lastUpdated.getTime()) > service.refreshIntervalSec * 1000) root.refresh()
    Qt.callLater(function() { catcher.forceActiveFocus() })
  }

  Service {
    id: service
    settings: root.settings
  }

  Timer {
    interval: 30000
    repeat: true
    running: true
    onTriggered: root.nowMs = Date.now()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\u{F169D}"
    tooltipText: "Models Usage · click for details"
    active: root.alarming
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton || buttonCode === Qt.MiddleButton) root.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: catcher
    contentWidth: panel.fittedContentWidth(Style.space(430))
    contentHeight: panel.fittedContentHeight(body.implicitHeight, Style.space(650))

    PanelKeyCatcher {
      id: catcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTextKey: function(text) { if (text === "r" || text === "R") root.refresh() }
      onTabRequested: function(direction) { root.switchPanel(direction) }

      ScrollView {
        id: scroll
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: body.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        Binding {
          target: scroll.contentItem
          property: "interactive"
          value: body.implicitHeight > scroll.height
        }

        Column {
          id: body
          width: scroll.availableWidth
          spacing: Style.space(10)

          Text {
            width: parent.width
            text: "Updated " + (service.lastUpdated ? Qt.formatTime(service.lastUpdated, "HH:mm:ss") : "never") + " · " + (service.refreshing ? "Refreshing…" : "R to refresh")
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          PanelHero {
            width: parent.width
            title: "Models Usage"
            meta: ""
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconComponent: Component {
              Text {
                text: "\u{F169D}"
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
                color: root.foreground
              }
            }
          }

          Text {
            visible: service.freeResetAt !== ""
            width: parent.width
            text: "Free messages reset · " + Model.resetDateLabel(service.freeResetAt)
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Text {
            visible: service.lastError !== "" && service.account && service.account.status !== "free-tier"
            width: parent.width
            text: service.lastError
            color: root.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Text {
            visible: service.refreshing && !service.account
            width: parent.width
            text: "Loading usage…"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          PanelSeparator { width: parent.width; foreground: root.foreground }

          PanelSectionHeader {
            text: "TOKEN USAGE BY DAY"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Column {
            width: parent.width
            spacing: Style.space(6)
            visible: service.recentDays.length > 0

            Repeater {
              model: service.recentDays

              delegate: UsageBar {
                required property var modelData
                label: Model.dayShort(modelData.date)
                value: Model.dayTokens(modelData)
                max: Model.recentPeak(service.recentDays)
                valueText: Model.tokenCount(modelData.tokens) + " tok"
              }
            }
          }

          Text {
            visible: service.recentDays.length === 0 && !service.refreshing
            width: parent.width
            text: "No daily usage yet"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          PanelSeparator { width: parent.width; foreground: root.foreground }

          PanelSectionHeader {
            text: "TOKEN USAGE BY MODEL"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Column {
            width: parent.width
            spacing: Style.space(6)
            visible: service.models.length > 0

            Repeater {
              model: service.models

              delegate: UsageBar {
                required property var modelData
                label: modelData.model
                value: modelData.tokens
                max: service.models.length > 0 ? service.models[0].tokens : 1
                valueText: Model.tokenCount(modelData.tokens) + " tok"
              }
            }
          }

          Text {
            visible: service.models.length === 0 && !service.refreshing
            width: parent.width
            text: "No model usage yet"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }

  component UsageBar: Column {
    required property string label
    required property real value
    required property real max
    required property string valueText
    width: parent.width
    spacing: Style.space(3)

    Item {
      width: parent.width
      implicitHeight: Math.max(nameLabel.implicitHeight, amountLabel.implicitHeight)

      Text {
        id: nameLabel
        width: parent.width - Style.space(60)
        text: label
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }

      Text {
        id: amountLabel
        anchors.right: parent.right
        text: valueText
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }

    Rectangle {
      width: parent.width
      height: Style.space(5)
      radius: height / 2
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.22)

      Rectangle {
        width: parent.width * (max > 0 ? Math.min(1, value / max) : 0)
        height: parent.height
        radius: parent.radius
        color: root.foreground

        Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
      }
    }
  }

}
