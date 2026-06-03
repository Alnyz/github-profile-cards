import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../../code/GitHub.js" as GitHub
import "achievements.js" as Achievements
import "medals.js" as Medals

// Achievements card: synthesized rank medals from your stats, rendered as a grid of
// medallions (gauge ring + recolored glyph + value pill), à la lowlighter/metrics.
// Set `token` to use it.
ColumnLayout {
    id: card

    property string token: ""
    readonly property string cardId: "achievements"
    readonly property bool fullWidth: true
    property var model: null
    property string status: ""

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

    PlasmaComponents.Label {
        text: "ACHIEVEMENTS"
        font: Kirigami.Theme.smallFont
        opacity: 0.5
    }

    // Wrapping grid of medal cells. The query always fetches everything and parse()
    // returns the full sorted list (locked last), so the count is a display-only slice
    // that updates reactively — no reload on achievementsCount.
    Flow {
        Layout.fillWidth: true
        visible: card.model !== null && card.model.achievements.length > 0
        spacing: Kirigami.Units.largeSpacing

        Repeater {
            model: card.model ? card.model.achievements.slice(0, plasmoid.configuration.achievementsCount) : []
            delegate: Column {
                id: cell
                required property var modelData
                readonly property color gaugeC: cell.modelData.gaugeColor
                readonly property real medalSize: Kirigami.Units.iconSizes.large // ~44px
                width: Kirigami.Units.gridUnit * 5
                spacing: 2

                // Prefix ("Master"/"Super"/"Great") — height always reserved so medals align.
                PlasmaComponents.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: Kirigami.Units.gridUnit * 0.85
                    text: cell.modelData.prefix
                    color: cell.modelData.titleColor
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    horizontalAlignment: Text.AlignHCenter
                }

                // Title in the rank color.
                PlasmaComponents.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cell.modelData.title
                    color: cell.modelData.titleColor
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                // Medallion: gauge ring + progress arc + recolored glyph + value pill.
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: cell.medalSize
                    height: cell.medalSize + Kirigami.Units.gridUnit * 0.4 // room for the straddling pill

                    Shape {
                        id: gauge
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: cell.medalSize
                        height: cell.medalSize
                        readonly property real r: cell.medalSize / 2 - Kirigami.Units.gridUnit * 0.25
                        readonly property real cxy: cell.medalSize / 2

                        // Faint base ring.
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: Qt.rgba(cell.gaugeC.r, cell.gaugeC.g, cell.gaugeC.b, 0.25)
                            strokeWidth: Kirigami.Units.gridUnit * 0.25
                            capStyle: ShapePath.FlatCap
                            PathAngleArc {
                                centerX: gauge.cxy; centerY: gauge.cxy
                                radiusX: gauge.r; radiusY: gauge.r
                                startAngle: 0; sweepAngle: 360
                            }
                        }
                        // Progress arc toward the next rank (hidden when progress is 0).
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: cell.modelData.progress > 0 ? cell.gaugeC : "transparent"
                            strokeWidth: Kirigami.Units.gridUnit * 0.25
                            capStyle: ShapePath.RoundCap
                            PathAngleArc {
                                centerX: gauge.cxy; centerY: gauge.cxy
                                radiusX: gauge.r; radiusY: gauge.r
                                startAngle: -90; sweepAngle: 360 * cell.modelData.progress
                            }
                        }
                    }

                    // Recolored glyph, sized to sit inside the ring.
                    Image {
                        anchors.centerIn: gauge
                        width: cell.medalSize * 0.62
                        height: width
                        smooth: true
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(width, height)
                        source: "data:image/svg+xml;base64," + Qt.btoa(
                            Medals.medalSvg(cell.modelData.id, cell.modelData.glyphPrimary, cell.modelData.glyphSecondary))
                    }

                    // Value pill straddling the bottom of the ring.
                    Rectangle {
                        anchors.horizontalCenter: gauge.horizontalCenter
                        anchors.verticalCenter: gauge.bottom
                        radius: height / 2
                        height: valueLabel.implicitHeight + 2
                        width: valueLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                        color: Qt.rgba(cell.gaugeC.r, cell.gaugeC.g, cell.gaugeC.b, 0.15)
                        border.color: cell.modelData.gaugeColor
                        border.width: 1
                        PlasmaComponents.Label {
                            id: valueLabel
                            anchors.centerIn: parent
                            text: cell.modelData.value
                            color: cell.modelData.gaugeColor
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
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
