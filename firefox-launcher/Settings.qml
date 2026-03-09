import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property string iconColor: pluginApi?.pluginSettings?.iconColor || pluginApi?.manifest?.metadata?.defaultSettings?.iconColor || "mOnSurface"

  readonly property var colorOptions: [
    { name: "mPrimary",     label: "Primary",      color: Color.mPrimary },
    { name: "mOnPrimary",   label: "On Primary",   color: Color.mOnPrimary },
    { name: "mSecondary",   label: "Secondary",    color: Color.mSecondary },
    { name: "mOnSecondary", label: "On Secondary", color: Color.mOnSecondary },
    { name: "mOnSurface",   label: "On Surface",   color: Color.mOnSurface },
  ]

  spacing: Style.marginL

  NLabel {
    label: pluginApi?.tr("settings.iconColor.label")
    description: pluginApi?.tr("settings.iconColor.desc")
  }

  RowLayout {
    spacing: Style.marginM

    Repeater {
      model: root.colorOptions

      Rectangle {
        required property var modelData
        required property int index

        width: 48
        height: 48
        radius: Style.radiusM
        color: modelData.color
        border.color: root.iconColor === modelData.name ? Color.mPrimary : "transparent"
        border.width: root.iconColor === modelData.name ? 3 : 0

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.iconColor = parent.modelData.name
        }
      }
    }
  }

  RowLayout {
    spacing: Style.marginM

    NText {
      text: root.iconColor
      color: Settings.data.colorSchemes.darkMode ? Color.mPrimary : Color.mOnPrimary
    }

    NIcon {
      icon: "brand-firefox"
      color: root.colorOptions.find(function (o) { return o.name === root.iconColor; })?.color || Color.mOnSurface
    }
  }

  function saveSettings() {
    if (!pluginApi) return;

    pluginApi.pluginSettings.iconColor = root.iconColor;
    pluginApi.saveSettings();
    pluginApi.closePanel(root.screen);
  }
}
