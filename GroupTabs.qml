import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var shell: null

  property var groups: ({})
  property var ids: []
  property var chromeProfiles: ({})

  readonly property string statePath: Quickshell.env("XDG_RUNTIME_DIR") + "/group-tabs.json"
  readonly property string chromeDir: Quickshell.env("HOME") + "/.config/google-chrome"

  function apply(text) {
    var state
    try {
      state = JSON.parse(text)
    } catch (error) {
      // caught hyprland mid-write
      retry.restart()
      return
    }

    var next = {}
    var nextIds = []
    for (var i = 0; i < state.groups.length; i++) {
      var id = String(state.groups[i].id)
      next[id] = state.groups[i]
      nextIds.push(id)
    }
    groups = next
    if (nextIds.join() !== ids.join()) ids = nextIds
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.apply(text())
  }

  Timer {
    id: retry
    interval: 40
    onTriggered: stateFile.reload()
  }

  Process {
    running: true
    command: ["jq", "-c", ".profile.info_cache | map_values(.name)", root.chromeDir + "/Local State"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.chromeProfiles = JSON.parse(text)
        } catch (error) {}
      }
    }
  }

  Variants {
    model: root.ids

    TabStrip {
      required property string modelData

      group: root.groups[modelData] || null
      chromeProfiles: root.chromeProfiles
      chromeDir: root.chromeDir
    }
  }
}
