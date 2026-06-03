import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../../code/GitHub.js" as GitHub
import "achievements.js" as Achievements

// Achievements card: synthesized S/A/B/C rank medals from your stats. Set `token` to use it.
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

    // One row per achievement; the configured count slices the (already sorted) list.
    Repeater {
        model: card.model ? card.model.achievements.slice(0, plasmoid.configuration.achievementsCount) : []
        delegate: RowLayout {
            id: row
            required property var modelData
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            // Rank-tinted octicon.
            Kirigami.Icon {
                source: Qt.resolvedUrl("../../icons/stats/" + row.modelData.icon + ".svg")
                isMask: true
                color: row.modelData.rankColor
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                Layout.alignment: Qt.AlignTop
            }

            // Rank pill: the letter on its rank color.
            Rectangle {
                radius: 3
                color: row.modelData.rankColor
                implicitWidth: Kirigami.Units.gridUnit
                implicitHeight: Math.round(Kirigami.Units.gridUnit * 0.85)
                Layout.alignment: Qt.AlignTop
                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    text: row.modelData.rank
                    color: "white"
                    font.bold: true
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }

            // Title + description.
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                PlasmaComponents.Label {
                    text: row.modelData.title
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                PlasmaComponents.Label {
                    text: row.modelData.description
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
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
