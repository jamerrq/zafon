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
    tooltipText: "OpenCode Go usage · click for details"
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
            title: "OpenCode"
            meta: service.account && service.account.status === "ok" ? service.account.label : "Free tier"
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
            visible: service.account && service.account.status === "ok"
            text: "LIMIT WINDOWS"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          AccountCard {
            visible: service.account && service.account.status === "ok"
            width: body.width
            account: service.account
          }

          Item {
            width: parent.width
            implicitHeight: Math.max(usageHeader.implicitHeight, usageValue.implicitHeight)

            PanelSectionHeader {
              id: usageHeader
              text: "RECENT USAGE"
              foreground: root.foreground
              fontFamily: root.fontFamily
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: usageValue
              visible: service.recentDays.length > 0
              text: Model.tokenCount(Model.recentTotal(service.recentDays)) + " TOKENS"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              anchors.right: parent.right
              anchors.rightMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Row {
            width: parent.width
            spacing: Style.space(4)

            Repeater {
              model: service.recentDays

              delegate: Column {
                required property var modelData
                width: (body.width - Style.space(24)) / 7

                Text {
                  width: parent.width
                  text: Model.tokenCount(modelData.tokens)
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  horizontalAlignment: Text.AlignHCenter
                }

                Item {
                  width: parent.width
                  height: Style.space(28)

                  Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Style.space(10)
                    height: parent.height * Model.dayTokens(modelData) / Math.max(1, Model.recentPeak(service.recentDays))
                    color: root.foreground
                  }
                }

                Text {
                  width: parent.width
                  text: Model.dayLabel(modelData.date)
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  horizontalAlignment: Text.AlignHCenter
                }
              }
            }
          }
        }
      }
    }
  }

  component AccountCard: Column {
    id: card
    required property var account
    readonly property var windows: [
      { key: "rolling", label: "5h", dollars: 12 },
      { key: "weekly", label: "Weekly", dollars: 30 },
      { key: "monthly", label: "Monthly", dollars: 60 }
    ]
    spacing: Style.space(6)

    RowLayout {
      width: parent.width

      Text {
        Layout.fillWidth: true
        text: card.account ? card.account.label : "Go"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: true
        elide: Text.ElideRight
      }
    }

    Repeater {
      model: card.windows

      delegate: Column {
        id: windowRow
        required property var modelData
        width: card.width
        spacing: Style.space(2)
        readonly property var w: Model.normalizeWindow(card.account ? card.account[modelData.key] : null, modelData.key, root.nowMs)

        RowLayout {
          width: parent.width

          Text {
            Layout.preferredWidth: Style.space(58)
            text: modelData.label
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Item { Layout.fillWidth: true }

          Text {
            Layout.fillWidth: true
            text: windowRow.w
              ? Model.percent(windowRow.w.percent) + " · $" + (windowRow.w.limitDollars || modelData.dollars)
              : (card.account && card.account.status && card.account.status !== "ok" ? card.account.status : "—")
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
          }
        }

        Rectangle {
          width: parent.width
          height: Style.space(5)
          radius: height / 2
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.22)

          Rectangle {
            width: parent.width * (windowRow.w ? windowRow.w.percent : 0)
            height: parent.height
            radius: parent.radius
            color: modelData.key === "weekly" && Model.behindPace(windowRow.w, root.nowMs) ? root.urgent : root.foreground

            Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 60 } }
          }
        }

        Text {
          visible: !!windowRow.w
          width: parent.width
          text: windowRow.w ? "resets " + Model.countdown(windowRow.w.resetMs, root.nowMs) : ""
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }

    RowLayout {
      id: paceRow
      width: card.width
      visible: !!paceRow.weekly && paceRow.weekly.resetMs > 0
      readonly property var weekly: Model.normalizeWindow(card.account ? card.account.weekly : null, "weekly", root.nowMs)

      Text {
        Layout.fillWidth: true
        text: paceRow.weekly ? Model.paceText(paceRow.weekly, root.nowMs) : ""
        color: Model.behindPace(paceRow.weekly, root.nowMs) ? root.urgent : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Text {
        visible: !!paceRow.weekly
        text: paceRow.weekly ? "Expected " + Model.percent(1 - Model.expectedRemaining(paceRow.weekly, root.nowMs)) + " used" : ""
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    PanelSeparator { width: parent.width; foreground: root.foreground }
  }
}
