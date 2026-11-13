import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Commons as Commons

// One group's strip. It sits on the bottom layer, right where hyprland keeps its own
// (see-through) bar, so floating and fullscreen windows cover it like any other window.
PanelWindow {
  id: strip

  property var group: null
  property var chromeProfiles: ({})
  property string chromeDir: ""

  // the last good group, so the strip keeps its place while it is being torn down
  property var shownGroup: null
  onGroupChanged: if (group) shownGroup = group

  readonly property var tabs: shownGroup ? shownGroup.tabs : []
  readonly property real tabWidth: tabs.length > 0 ? width / tabs.length : width
  readonly property int currentIndex: {
    for (var i = 0; i < tabs.length; i++) if (tabs[i].current) return i
    return 0
  }
  readonly property bool focused: !!shownGroup && shownGroup.focused

  readonly property color ink: Commons.Color.foreground
  readonly property color accent: Commons.Color.accent
  readonly property color accentCool: hueShifted(accent, -0.035, 0.86)
  readonly property color accentWarm: hueShifted(accent, 0.14, 1.0)
  readonly property int textSize: Math.round(15 * Style.fontScale)

  function hueShifted(base, shift, lightness) {
    return Qt.hsla((base.hslHue + shift + 1) % 1, base.hslSaturation, Math.min(1, base.hslLightness * lightness), 1)
  }

  function profileOf(tab) {
    for (var i = 0; i < tab.tags.length; i++) {
      var match = tab.tags[i].match(/^browser:(.+?)\*?$/)
      if (match) return match[1]
    }
    return ""
  }

  function cleanTitle(tab) {
    return tab.title.replace(/ - (Google Chrome|Chromium)$/, "")
  }

  function appIcon(tab) {
    var entry = DesktopEntries.heuristicLookup(tab.class)
    return entry && entry.icon ? Quickshell.iconPath(entry.icon, true) : ""
  }

  // the tile animates to its new spot while this surface jumps, so sit out the move
  property bool settled: false
  readonly property string placement: shownGroup ? [shownGroup.monitor, shownGroup.x, shownGroup.y, shownGroup.width].join() : ""
  onPlacementChanged: {
    settled = false
    settle.restart()
  }

  Timer {
    id: settle
    interval: 220
    onTriggered: strip.settled = true
  }

  screen: {
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++) {
      if (shownGroup && screens[i].name === shownGroup.monitor) return screens[i]
    }
    return screens[0]
  }

  color: "transparent"
  WlrLayershell.namespace: "eduardo-group-tabs"
  WlrLayershell.layer: WlrLayer.Bottom
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: true
    left: true
  }
  margins {
    top: shownGroup ? shownGroup.y : 0
    left: shownGroup ? shownGroup.x : 0
  }
  implicitWidth: shownGroup ? shownGroup.width : 1
  implicitHeight: shownGroup ? shownGroup.height : 1

  // clicks belong to hyprland's bar underneath
  mask: Region {}

  Item {
    id: content

    anchors.fill: parent
    clip: true
    opacity: strip.settled ? 1 : 0

    Behavior on opacity {
      enabled: strip.settled
      NumberAnimation { duration: Style.duration(160); easing.type: Easing.OutCubic }
    }

    // taller than the strip so only the top corners end up rounded
    Rectangle {
      width: parent.width
      height: parent.height + radius
      radius: 12
      color: Qt.rgba(Commons.Color.background.r, Commons.Color.background.g, Commons.Color.background.b, 0.8)
      border.width: 1
      border.color: Qt.rgba(strip.ink.r, strip.ink.g, strip.ink.b, 0.1)
    }

    Shape {
      id: glow

      x: strip.currentIndex * strip.tabWidth
      width: strip.tabWidth
      height: parent.height
      opacity: strip.focused ? 1 : 0.35
      preferredRendererType: Shape.CurveRenderer

      Behavior on x {
        NumberAnimation { duration: Style.duration(200); easing.type: Easing.OutCubic }
      }

      ShapePath {
        strokeWidth: -1
        fillGradient: RadialGradient {
          centerX: glow.width / 2
          centerY: glow.height * 1.25
          focalX: centerX
          focalY: centerY
          centerRadius: glow.width * 0.42
          GradientStop { position: 0; color: Qt.rgba(strip.accent.r, strip.accent.g, strip.accent.b, 0.5) }
          GradientStop { position: 1; color: Qt.rgba(strip.accent.r, strip.accent.g, strip.accent.b, 0) }
        }
        PathRectangle { width: glow.width; height: glow.height }
      }
    }

    Repeater {
      model: strip.tabs

      Item {
        id: tab

        required property var modelData
        required property int index

        readonly property string profile: strip.profileOf(modelData)
        readonly property string who: profile ? (strip.chromeProfiles[profile] || profile) : ""
        readonly property string picture: profile
          ? "file://" + strip.chromeDir + "/" + encodeURIComponent(profile) + "/Google%20Profile%20Picture.png"
          : strip.appIcon(modelData)
        readonly property color tone: modelData.current
          ? Qt.lighter(strip.ink, 1.25)
          : Qt.rgba(strip.ink.r, strip.ink.g, strip.ink.b, 0.62)

        x: index * strip.tabWidth
        width: strip.tabWidth
        height: content.height

        Rectangle {
          visible: tab.index > 0
          width: 1
          height: parent.height - 22
          anchors.verticalCenter: parent.verticalCenter
          color: Qt.rgba(strip.ink.r, strip.ink.g, strip.ink.b, 0.14)
        }

        Row {
          id: label

          readonly property real room: tab.width - 36

          anchors.centerIn: parent
          spacing: 10

          ClippingRectangle {
            visible: tab.picture !== ""
            width: 22
            height: 22
            radius: tab.profile ? 11 : 5
            color: "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Image {
              anchors.fill: parent
              source: tab.picture
              sourceSize: Qt.size(44, 44)
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
            }
          }

          Text {
            id: who

            visible: tab.who !== ""
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: tab.who
            color: tab.tone
            font.family: "Adwaita Sans"
            font.pixelSize: strip.textSize
            font.weight: Font.Bold
          }

          Rectangle {
            visible: who.visible
            width: 1
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            color: tab.tone
            opacity: 0.3
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, Math.max(40, label.room - (who.visible ? who.width + 21 : 0) - (tab.picture !== "" ? 32 : 0)))
            textFormat: Text.PlainText
            text: strip.cleanTitle(tab.modelData)
            elide: Text.ElideRight
            color: tab.tone
            font.family: "Adwaita Sans"
            font.pixelSize: strip.textSize
            font.weight: tab.modelData.current ? Font.Medium : Font.Normal
          }
        }
      }
    }

    Rectangle {
      x: strip.currentIndex * strip.tabWidth + strip.tabWidth * 0.18
      width: strip.tabWidth * 0.64
      height: 3
      anchors.bottom: parent.bottom
      radius: 2
      opacity: strip.focused ? 1 : 0.4

      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: strip.accentCool }
        GradientStop { position: 0.5; color: strip.accent }
        GradientStop { position: 1; color: strip.accentWarm }
      }

      Behavior on x {
        NumberAnimation { duration: Style.duration(200); easing.type: Easing.OutCubic }
      }
    }
  }
}
