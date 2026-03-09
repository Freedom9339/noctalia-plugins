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

  NComboBox {
    label: pluginApi?.tr("settings.iconColor.label") || "Icon Color"
    description: pluginApi?.tr("settings.iconColor.desc") || "Choose a theme color for the Firefox icon."
    model: Color.colorKeyModel
    currentKey: root.editIconColor
    onSelected: key => root.editIconColor = key
    minimumWidth: 200
  }

  function saveSettings() {
    if (!pluginApi) return;

    pluginApi.pluginSettings.iconColor = root.editIconColor;
    pluginApi.saveSettings();
    pluginApi.closePanel(root.screen);
  }
}
