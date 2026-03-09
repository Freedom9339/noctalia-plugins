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

  property string iconColorName: pluginApi?.pluginSettings?.iconColor ?? pluginApi?.manifest?.metadata?.defaultSettings?.iconColor ?? "none"
  readonly property color iconColor: Color.resolveColorKey(iconColorName)

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
      color: root.hovered ? Color.mOnHover : root.iconColor
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": "New Window",
        "action": "new-window",
        "icon": "browser"
      },
      {
        "label": "New Private Window",
        "action": "private-window",
        "icon": "eye-off"
      },
      {
        "label": "Settings",
        "action": "firefox-settings",
        "icon": "settings"
      },
      {
        "label": I18n.tr("actions.widget-settings"),
        "action": "widget-settings",
        "icon": "palette"
      }
    ]

    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(screen);

      if (action === "new-window") {
        root.pluginApi?.mainInstance?.launchNewWindow();
      } else if (action === "private-window") {
        root.pluginApi?.mainInstance?.launchPrivateWindow();
      } else if (action === "firefox-settings") {
        root.pluginApi?.mainInstance?.openSettings();
      } else if (action === "widget-settings") {
        BarService.openPluginSettings(screen, pluginApi.manifest);
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen);
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
}
