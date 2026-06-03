import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../../code/GitHub.js" as GitHub
import "achievements.js" as Achievements
import "medals.js" as Medals

// Achievements card: synthesized rank medals from your stats, modeled on lowlighter/metrics.
// Two display modes (config: achievementsMode): "simple" = a wrapping grid of medallions,
// "detailed" = a list of medallion + title + description. Set `token` to use it.
ColumnLayout {
    id: card

    property string token: ""
    readonly property string cardId: "achievements"
    readonly property bool fullWidth: true
    property var model: null
    property string status: ""

    // The query always fetches everything and parse() returns the full sorted list (locked
    // last), so the count is a display-only slice that updates reactively — no reload on it.
    readonly property var shownAchievements: card.model
        ? card.model.achievements.slice(0, plasmoid.configuration.achievementsCount) : []
    readonly property string mode: plasmoid.configuration.achievementsMode

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    function reload() {
        if (card.token.length === 0) return;
        card.status = "loading";
        GitHub.fetchGraphQL(card.token, Achievements.query(), {},
            function(data) { card.model = Achievements.parse(data, Date.now()); card.status = ""; },
            function(msg) { card.status = msg; });
    }

    onTokenChanged: reload()
    Component.onCompleted: if (card.token.length > 0) reload()

    // A medallion: gauge ring + progress arc + recolored glyph, with an optional value pill.
    // Shared by both display modes.
    component Medallion: Item {
        id: med
        property color gaugeColor: "#888888"
        property real progress: 0
        property string glyphId: ""
        property string glyphPrimary: "#888888"
        property string glyphSecondary: "#aaaaaa"
        property string value: ""
        property bool showValue: true
        readonly property real medalSize: Kirigami.Units.iconSizes.large

        implicitWidth: medalSize
        implicitHeight: medalSize + (showValue ? Kirigami.Units.gridUnit * 0.75 : 0)

        Shape {
            id: ring
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: med.medalSize
            height: med.medalSize
            antialiasing: true
            layer.enabled: true
            layer.samples: 8
            readonly property real r: med.medalSize / 2 - Kirigami.Units.gridUnit * 0.25
            readonly property real cxy: med.medalSize / 2

            // Faint base ring.
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.rgba(med.gaugeColor.r, med.gaugeColor.g, med.gaugeColor.b, 0.25)
                strokeWidth: Kirigami.Units.gridUnit * 0.25
                capStyle: ShapePath.FlatCap
                PathAngleArc {
                    centerX: ring.cxy; centerY: ring.cxy
                    radiusX: ring.r; radiusY: ring.r
                    startAngle: 0; sweepAngle: 360
                }
            }
            // Progress arc toward the next rank (hidden when progress is 0).
            ShapePath {
                fillColor: "transparent"
                strokeColor: med.progress > 0 ? med.gaugeColor : "transparent"
                strokeWidth: Kirigami.Units.gridUnit * 0.25
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: ring.cxy; centerY: ring.cxy
                    radiusX: ring.r; radiusY: ring.r
                    startAngle: -90; sweepAngle: 360 * med.progress
                }
            }
        }

        // Recolored glyph, sized to sit inside the ring.
        Image {
            anchors.centerIn: ring
            width: med.medalSize * 0.62
            height: width
            smooth: true
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(width, height)
            source: "data:image/svg+xml;base64," + Qt.btoa(
                Medals.medalSvg(med.glyphId, med.glyphPrimary, med.glyphSecondary))
        }

        // Value pill straddling just below the ring (simple mode only).
        Rectangle {
            visible: med.showValue
            anchors.horizontalCenter: ring.horizontalCenter
            anchors.verticalCenter: ring.bottom
            anchors.verticalCenterOffset: Kirigami.Units.smallSpacing
            radius: height / 2
            height: pillLabel.implicitHeight + 2
            width: pillLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
            color: Qt.rgba(med.gaugeColor.r, med.gaugeColor.g, med.gaugeColor.b, 0.15)
            border.color: med.gaugeColor
            border.width: 1
            PlasmaComponents.Label {
                id: pillLabel
                anchors.centerIn: parent
                text: med.value
                color: med.gaugeColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }
    }

    PlasmaComponents.Label {
        text: "ACHIEVEMENTS"
        font: Kirigami.Theme.smallFont
        opacity: 0.5
    }

    // --- Simple mode: a wrapping grid of medal cells ---
    Flow {
        Layout.fillWidth: true
        visible: card.mode !== "detailed" && card.shownAchievements.length > 0
        spacing: Kirigami.Units.largeSpacing

        Repeater {
            model: card.mode !== "detailed" ? card.shownAchievements : []
            delegate: Column {
                id: cell
                required property var modelData
                width: Kirigami.Units.gridUnit * 5
                spacing: 2

                // Prefix line — fixed-height Item reserves the line even when empty (C/locked),
                // so all titles + medals align.
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: cell.width
                    height: Kirigami.Units.gridUnit
                    PlasmaComponents.Label {
                        anchors.centerIn: parent
                        text: cell.modelData.prefix
                        color: cell.modelData.titleColor
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                PlasmaComponents.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cell.modelData.title
                    color: cell.modelData.titleColor
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Medallion {
                    anchors.horizontalCenter: parent.horizontalCenter
                    gaugeColor: cell.modelData.gaugeColor
                    progress: cell.modelData.progress
                    glyphId: cell.modelData.id
                    glyphPrimary: cell.modelData.glyphPrimary
                    glyphSecondary: cell.modelData.glyphSecondary
                    value: cell.modelData.value
                    showValue: true
                }
            }
        }
    }

    // --- Detailed mode: a list of medallion + title + description ---
    ColumnLayout {
        Layout.fillWidth: true
        visible: card.mode === "detailed" && card.shownAchievements.length > 0
        spacing: Kirigami.Units.smallSpacing

        Repeater {
            model: card.mode === "detailed" ? card.shownAchievements : []
            delegate: RowLayout {
                id: drow
                required property var modelData
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                Medallion {
                    Layout.alignment: Qt.AlignVCenter
                    gaugeColor: drow.modelData.gaugeColor
                    progress: drow.modelData.progress
                    glyphId: drow.modelData.id
                    glyphPrimary: drow.modelData.glyphPrimary
                    glyphSecondary: drow.modelData.glyphSecondary
                    showValue: false
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0
                    PlasmaComponents.Label {
                        text: drow.modelData.prefix.length > 0
                            ? drow.modelData.prefix + " " + drow.modelData.title
                            : drow.modelData.title
                        color: drow.modelData.titleColor
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    PlasmaComponents.Label {
                        text: drow.modelData.description
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    PlasmaComponents.Label {
        visible: card.model !== null && card.model.achievements.length === 0 && card.status === ""
        opacity: 0.6
        text: "No achievements yet"
    }

    RowLayout {
        visible: card.status === "loading"
        spacing: Kirigami.Units.smallSpacing
        PlasmaComponents.BusyIndicator {
            running: card.status === "loading"
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
        }
        PlasmaComponents.Label { text: "Loading…"; opacity: 0.6 }
    }

    PlasmaComponents.Label {
        visible: card.status !== "" && card.status !== "loading"
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Kirigami.Theme.negativeTextColor
        text: card.status
    }

    // The row divider is drawn by CardHost.
}
