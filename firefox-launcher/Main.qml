import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var pluginApi: null

  function launchFirefox() {
    firefoxProc.command = ["firefox"];
    firefoxProc.running = true;
  }

  function launchNewWindow() {
    newWindowProc.command = ["firefox", "--new-window"];
    newWindowProc.running = true;
  }

  function launchPrivateWindow() {
    privateWindowProc.command = ["firefox", "--private-window"];
    privateWindowProc.running = true;
  }

  function openSettings() {
    settingsProc.command = ["firefox", "--preferences"];
    settingsProc.running = true;
  }

  Process {
    id: firefoxProc
  }

  Process {
    id: newWindowProc
  }

  Process {
    id: privateWindowProc
  }

  Process {
    id: settingsProc
  }
}
