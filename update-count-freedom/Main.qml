import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var pluginApi: null

  readonly property string updaterJson: (pluginApi?.pluginDir ?? "") + "/updaterConfigs.json"
  readonly property int minutesToMillis: 60_000

  readonly property int updateIntervalMinutes: pluginApi?.pluginSettings.updateIntervalMinutes || pluginApi?.manifest?.metadata.defaultSettings?.updateIntervalMinutes || 30
  readonly property string updateTerminalCommand: pluginApi?.pluginSettings.updateTerminalCommand || pluginApi?.manifest?.metadata.defaultSettings?.updateTerminalCommand || ""

  property int updateCount: 0
  property int pacmanCount: 0
  property int aurCount: 0
  property int flatpakCount: 0
  property var pacmanPackages: []
  property var aurPackages: []
  property var flatpakPackages: []
  property var updater: null
  property var customUpdater: ({
    name: "custom",
    cmdGetNumUpdates:  pluginApi?.pluginSettings.customCmdGetNumUpdates || "",
    cmdDoSystemUpdate: pluginApi?.pluginSettings.customCmdDoSystemUpdate || ""
  })

  //
  // ------ Initialization ------
  //
  property var updaters: []
  property int checkIndex: 0
  property var current: null

  FileView {
    id: updaterFile
    path: root.updaterJson

    onLoaded: {
      try {
        root.updaters = JSON.parse(updaterFile.text());
        root.runAllCmdChecks();
      } catch (e) {
        Logger.e("UpdateCount", "JSON Error in", root.updaterJson, ":", e);
      }
    }
  }

  function runAllCmdChecks() {
    if (!root.updaters || root.updaters.length === 0) {
      return;
    }

    root.checkIndex = 0;
    root.checkNext();
  }

  function checkNext() {
    if (root.checkIndex >= root.updaters.length) {
      startGetNumUpdates();
      return;
    }

    root.current = root.updaters[root.checkIndex++];
    cmdCheckProc.command = ["sh", "-c", root.current.cmdCheck];
    cmdCheckProc.running = true;
  }

  Process {
    id: cmdCheckProc

    onExited: function (exitCode, exitStatus) {
      if (exitCode === 0) {
        root.updater = root.current
        Logger.i("UpdateCount", `Initialization finished. Detected updater: ${root.updater.name}.`);
        root.startGetNumUpdates()
      } else {
        root.checkNext();
      }
    }
  }

  //
  // ------ Get number of updates ------
  //
  Timer {
    id: timerGetNumUpdates

    interval: root.updateIntervalMinutes * root.minutesToMillis
    running: true
    repeat: true
    onTriggered: root.startGetNumUpdates()
  }

  function startGetNumUpdates() {
    const cmd = root.customUpdater.cmdGetNumUpdates || root.updater.cmdGetNumUpdates || "exit 1"
    getNumUpdates.command = ["sh", "-c", cmd]
    getNumUpdates.running = true;
  }

  function startGetIndividualCounts() {
    const updaterName = root.updater ? root.updater.name : "";
    var aurCmd = "true";
    if (updaterName === "yay") {
      aurCmd = "yay -Qua 2>/dev/null";
    } else if (updaterName === "paru") {
      aurCmd = "paru -Qua 2>/dev/null";
    }
    const combinedCmd = 'echo "---PACMAN---" && checkupdates 2>/dev/null; echo "---AUR---" && ' + aurCmd + '; echo "---FLATPAK---" && flatpak remote-ls --updates 2>/dev/null; echo "---END---"';
    getIndividualCounts.command = ["sh", "-c", combinedCmd];
    getIndividualCounts.running = true;
  }

  Process {
    id: getNumUpdates

    stdout: StdioCollector {
      onStreamFinished: {
        var count = parseInt(text.trim());
        root.updateCount = isNaN(count) ? -1 : count;
        if (root.updateCount >= 0) {
          Logger.i("UpdateCount", `Updates available: ${root.updateCount}`);
        } else {
          Logger.e("UpdateCount", `getNumUpdates return '${text.trim()}' cannot be parsed into int`);
        }
        // Fetch individual counts after main count finishes to avoid checkupdates race
        root.startGetIndividualCounts();
      }
    }
  }

  Process {
    id: getIndividualCounts
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.trim().split("\n");
        var section = "";
        var pacmanPkgs = [];
        var aurPkgs = [];
        var flatpakPkgs = [];

        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim();
          if (line === "---PACMAN---") { section = "pacman"; continue; }
          if (line === "---AUR---") { section = "aur"; continue; }
          if (line === "---FLATPAK---") { section = "flatpak"; continue; }
          if (line === "---END---") { break; }
          if (line === "") continue;

          // Extract just the package name (first column)
          var pkgName = line.split(/\s+/)[0];
          if (!pkgName) continue;

          if (section === "pacman") pacmanPkgs.push(pkgName);
          else if (section === "aur") aurPkgs.push(pkgName);
          else if (section === "flatpak") flatpakPkgs.push(pkgName);
        }

        root.pacmanCount = pacmanPkgs.length;
        root.aurCount = aurPkgs.length;
        root.flatpakCount = flatpakPkgs.length;
        root.pacmanPackages = pacmanPkgs;
        root.aurPackages = aurPkgs;
        root.flatpakPackages = flatpakPkgs;

        Logger.i("UpdateCount", `Individual counts - Pacman: ${root.pacmanCount}, AUR: ${root.aurCount}, Flatpak: ${root.flatpakCount}`);
      }
    }
  }

  //
  // ------ Start update ------
  //
  function startDoSystemUpdate() {
    const updateCmd = root.customUpdater.cmdDoSystemUpdate || root.updater.cmdDoSystemUpdate || "echo 'No update cmd found.'"
    const ipcCmd = "qs -c noctalia-shell ipc call plugin:update-count-freedom check"
    const combinedCmd = updateCmd + " && " + ipcCmd

    const term = root.updateTerminalCommand.trim();
    const fullCmd = (term.indexOf("{}") !== -1) ? term.replace("{}", combinedCmd) : term + " " + combinedCmd;

    doSystemUpdate.command = ["sh", "-c", fullCmd]
    doSystemUpdate.running = true;

    Logger.i("UpdateCount", `Executed update command: ${fullCmd}`);
  }

  Process {
    id: doSystemUpdate

    onExited: function (exitCode, exitStatus) {
      root.startGetNumUpdates();
    }
  }

  //
  // ------ IPC ------
  //
  IpcHandler {
    target: "plugin:update-count-freedom"

    function check(): void {
      root.startGetNumUpdates()
    }

    function run(): void {
      root.startDoSystemUpdate()
    }
  }
}
