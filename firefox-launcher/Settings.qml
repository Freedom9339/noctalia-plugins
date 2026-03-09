import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property string editIconColor: pluginApi?.pluginSettings?.iconColor ?? pluginApi?.manifest?.metadata?.defaultSettings?.iconColor ?? "none"

  spacing: Style.marginL

  NLabel {
    label: pluginApi?.tr("settings.iconColor.label") || "Icon Color"
    description: pluginApi?.tr("settings.iconColor.desc") || "Choose a theme color for the Firefox icon."
  }

  RowLayout {
    spacing: Style.marginM

    Repeater {
      model: Color.colorKeyModel

      Rectangle {
        required property var modelData
        required property int index

        width: 36
        height: 36
        radius: 18
        color: Color.resolveColorKey(modelData.key)
        border.color: root.editIconColor === modelData.key ? Color.mOnSurface : "transparent"
        border.width: root.editIconColor === modelData.key ? 3 : 0

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.editIconColor = modelData.key
        }
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) return;

    pluginApi.pluginSettings.iconColor = root.editIconColor;
    pluginApi.saveSettings();
    pluginApi.closePanel(root.screen);
  }
}
