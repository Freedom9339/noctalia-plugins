import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property string iconColor: pluginApi?.pluginSettings?.iconColor || pluginApi?.manifest?.metadata?.defaultSettings?.iconColor || "none"

  readonly property var colorOptions: [
    { name: "none",      label: "None",      color: Color.mOnSurface },
    { name: "primary",   label: "Primary",   color: Color.mPrimary },
    { name: "secondary", label: "Secondary", color: Color.mSecondary },
    { name: "tertiary",  label: "Tertiary",  color: Color.mTertiary },
    { name: "error",     label: "Error",     color: Color.mError },
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
      color: Color.resolveColorKey(root.iconColor)
    }
  }

  function saveSettings() {
    if (!pluginApi) return;

    pluginApi.pluginSettings.iconColor = root.iconColor;
    pluginApi.saveSettings();
    pluginApi.closePanel(root.screen);
  }
}
