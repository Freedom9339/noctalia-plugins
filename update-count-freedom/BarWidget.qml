import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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

  property string currentIconName: pluginApi?.pluginSettings?.currentIconName || pluginApi?.manifest?.metadata?.defaultSettings?.currentIconName
  property bool hideOnZero: pluginApi?.pluginSettings.hideOnZero || pluginApi?.manifest?.metadata.defaultSettings?.hideOnZero
  readonly property bool isVisible: (root.pluginApi?.mainInstance?.updateCount > 0) || !root.hideOnZero
  visible: root.isVisible
  // also set opacity to zero when invisible as we use opacity to hide the barWidgetLoader
  opacity: root.isVisible ? 1.0 : 0.0

  readonly property real contentWidth: isVertical ? root.capsuleHeight : layout.implicitWidth + Style.marginS * 2
  readonly property real contentHeight: isVertical ? layout.implicitHeight + Style.marginS * 2 : root.capsuleHeight

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

    Item {
      id: layout
      anchors.centerIn: parent

      implicitWidth: grid.implicitWidth
      implicitHeight: grid.implicitHeight

      GridLayout {
        id: grid
        columns: root.isVertical ? 1 : 2
        rowSpacing: Style.marginS
        columnSpacing: Style.marginS

        NIcon {
          Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
          icon: root.currentIconName
          color: root.hovered ? Color.mOnHover : Color.mOnSurface
        }

        NText {
          Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
          text: root.pluginApi?.mainInstance?.updateCount.toString()
          color: root.hovered ? Color.mOnHover : Color.mOnSurface
          pointSize: root.barFontSize
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: root.pluginApi?.mainInstance?.updateCount > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor

    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) {
        root.buildContextMenu();
        PanelService.showContextMenu(contextMenu, root, screen);
      } else if (root.pluginApi?.mainInstance?.updateCount > 0) {
        root.pluginApi?.mainInstance?.startDoSystemUpdate();
      }
    }

    onEntered: {
      root.hovered = true;
      buildTooltip();
    }

    onExited: {
      root.hovered = false;
      TooltipService.hide();
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: []

    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(screen);

      if (action === "update") {
        root.pluginApi?.mainInstance?.startDoSystemUpdate();
      } else if (action === "refresh") {
        root.pluginApi?.mainInstance?.startGetNumUpdates();
      } else if (action === "widget-settings") {
        BarService.openPluginSettings(screen, pluginApi.manifest);
      }
    }
  }

  function buildContextMenu() {
    const mainInst = root.pluginApi ? root.pluginApi.mainInstance : null;
    if (!mainInst) return;

    var items = [];
    var pacmanPkgs = mainInst.pacmanPackages || [];
    var aurPkgs = mainInst.aurPackages || [];
    var flatpakPkgs = mainInst.flatpakPackages || [];

    if (pacmanPkgs.length > 0) {
      items.push({ label: "Pacman (" + pacmanPkgs.length + ")", icon: "package", enabled: false });
      for (var i = 0; i < pacmanPkgs.length; i++) {
        items.push({ label: "  " + pacmanPkgs[i], action: "pkg", icon: "point" });
      }
    }

    if (aurPkgs.length > 0) {
      items.push({ label: "AUR (" + aurPkgs.length + ")", icon: "package", enabled: false });
      for (var i = 0; i < aurPkgs.length; i++) {
        items.push({ label: "  " + aurPkgs[i], action: "pkg", icon: "point" });
      }
    }

    if (flatpakPkgs.length > 0) {
      items.push({ label: "Flatpak (" + flatpakPkgs.length + ")", icon: "package", enabled: false });
      for (var i = 0; i < flatpakPkgs.length; i++) {
        items.push({ label: "  " + flatpakPkgs[i], action: "pkg", icon: "point" });
      }
    }

    if (items.length === 0) {
      items.push({ label: pluginApi?.tr("tooltip.noUpdatesAvailable") || "No updates detected", icon: "circle-check", enabled: false });
    }

    items.push({ label: "", enabled: false, visible: false }); // spacer
    if (mainInst.updateCount > 0) {
      items.push({ label: pluginApi?.tr("contextMenu.updateAll") || "Update All", action: "update", icon: "download" });
    }
    items.push({ label: pluginApi?.tr("contextMenu.refresh") || "Refresh", action: "refresh", icon: "refresh" });
    items.push({ label: I18n.tr("actions.widget-settings"), action: "widget-settings", icon: "palette" });

    contextMenu.model = items;
  }

  function buildTooltip() {
    const mainInst = root.pluginApi ? root.pluginApi.mainInstance : null
    const updateCount = mainInst ? mainInst.updateCount : 0

    if (updateCount === 0) {
      TooltipService.show(root, pluginApi?.tr("tooltip.noUpdatesAvailable"), BarService.getTooltipDirection(root.screenName));
    } else {
      var pacman = 0;
      var aur = 0;
      var flatpak = 0;
      if (mainInst) {
        pacman = mainInst.pacmanCount || 0;
        aur = mainInst.aurCount || 0;
        flatpak = mainInst.flatpakCount || 0;
      }
      var lines = [];
      if (pacman > 0) lines.push("Pacman: " + pacman);
      if (aur > 0) lines.push("AUR: " + aur);
      if (flatpak > 0) lines.push("Flatpak: " + flatpak);
      var detail = lines.length > 0 ? lines.join("\n") : (updateCount + " updates available");
      TooltipService.show(root, detail, BarService.getTooltipDirection(root.screenName));
    }
  }
}
