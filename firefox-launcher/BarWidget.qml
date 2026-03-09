import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property bool hovered: false

  // Bar positioning properties
  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real barHeight: Style.getBarHeightForScreen(screenName)
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  property string iconColorName: pluginApi?.pluginSettings?.iconColor || pluginApi?.manifest?.metadata?.defaultSettings?.iconColor || "mOnSurface"

  function resolveColor(name) {
    switch (name) {
      case "mPrimary":     return Color.mPrimary;
      case "mOnPrimary":   return Color.mOnPrimary;
      case "mSecondary":   return Color.mSecondary;
      case "mOnSecondary": return Color.mOnSecondary;
      case "mOnSurface":   return Color.mOnSurface;
      default:             return Color.mOnSurface;
    }
  }

  readonly property real contentWidth: isVertical ? root.capsuleHeight : iconItem.implicitWidth + Style.marginS * 2
  readonly property real contentHeight: isVertical ? iconItem.implicitHeight + Style.marginS * 2 : root.capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  //
  // ------ Widget ------
  //
  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: root.hovered ? Color.mHover : Style.capsuleColor
    radius: Style.radiusM
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    NIcon {
      id: iconItem
      anchors.centerIn: parent
      icon: "brand-firefox"
      color: root.hovered ? Color.mOnHover : root.resolveColor(root.iconColorName)
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: function (mouse) {
      if (mouse.button === Qt.RightButton) {
        contextMenu.visible = !contextMenu.visible;
      } else {
        root.pluginApi?.mainInstance?.launchFirefox();
      }
    }

    onEntered: {
      root.hovered = true;
      TooltipService.show(root, "Firefox", BarService.getTooltipDirection(root.screenName));
    }

    onExited: {
      root.hovered = false;
      TooltipService.hide();
    }
  }

  PopupWindow {
    id: contextMenu
    anchor.window: root.QsWindow.window
    anchor.rect.x: root.mapToItem(null, 0, 0).x
    anchor.rect.y: root.mapToItem(null, 0, 0).y
    anchor.rect.width: root.width
    anchor.rect.height: root.height
    anchor.edges: root.barPosition === "bottom" ? Edges.Top : Edges.Bottom
    anchor.gravity: root.barPosition === "bottom" ? Edges.Top : Edges.Bottom
    visible: false
    color: "transparent"
    width: menuColumn.implicitWidth
    height: menuColumn.implicitHeight

    onVisibleChanged: {
      if (!visible) return;
      // Close when clicking outside
    }

    Rectangle {
      anchors.fill: parent
      color: Style.capsuleColor
      radius: Style.radiusM
      border.color: Style.capsuleBorderColor
      border.width: Style.capsuleBorderWidth

      ColumnLayout {
        id: menuColumn
        anchors.fill: parent
        spacing: 0

        Repeater {
          model: [
            { label: "New Window",         action: function() { root.pluginApi?.mainInstance?.launchNewWindow(); } },
            { label: "New Private Window", action: function() { root.pluginApi?.mainInstance?.launchPrivateWindow(); } },
            { label: "Settings",           action: function() { root.pluginApi?.mainInstance?.openSettings(); } }
          ]

          Rectangle {
            required property var modelData
            required property int index

            Layout.fillWidth: true
            Layout.preferredHeight: menuItemText.implicitHeight + Style.marginM * 2
            Layout.preferredWidth: menuItemText.implicitWidth + Style.marginL * 2
            color: menuItemMouse.containsMouse ? Color.mHover : "transparent"
            radius: Style.radiusM

            NText {
              id: menuItemText
              anchors.centerIn: parent
              anchors.leftMargin: Style.marginL
              anchors.rightMargin: Style.marginL
              text: modelData.label
              color: menuItemMouse.containsMouse ? Color.mOnHover : Color.mOnSurface
            }

            MouseArea {
              id: menuItemMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                modelData.action();
                contextMenu.visible = false;
              }
            }
          }
        }
      }
    }
  }
}
