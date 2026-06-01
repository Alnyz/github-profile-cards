import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../../code/GitHub.js" as GitHub
import "stats.js" as Stats

// Stats card. Set `token`; shows stars / commits / PRs / issues.
ColumnLayout {
    id: card

    property string token: ""
    readonly property string cardId: "stats"
    readonly property bool fullWidth: false
    property var model: null
    property string status: ""

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    function reload() {
        if (card.token.length === 0) return;
        card.status = "loading";
        GitHub.fetchGraphQL(card.token, Stats.query(), {},
            function(data) { card.model = Stats.parse(data); card.status = ""; },
            function(msg) { card.status = msg; });
    }

    onTokenChanged: reload()
    Component.onCompleted: if (card.token.length > 0) reload()

    PlasmaComponents.Label {
        text: "STATS"
        font: Kirigami.Theme.smallFont
        opacity: 0.5
    }

    GridLayout {
        visible: card.model !== null
        Layout.fillWidth: true
        columns: 2
        rowSpacing: Kirigami.Units.smallSpacing
        columnSpacing: Kirigami.Units.largeSpacing

        component Stat: RowLayout {
            property string value: ""
            property string label: ""
            spacing: Kirigami.Units.smallSpacing
            PlasmaComponents.Label { font.bold: true; text: value }
            PlasmaComponents.Label { opacity: 0.7; text: label }
        }

        Stat { value: card.model ? String(card.model.stars) : "0"; label: "stars" }
        Stat { value: card.model ? String(card.model.commits) : "0"; label: "commits" }
        Stat { value: card.model ? String(card.model.prs) : "0"; label: "PRs" }
        Stat { value: card.model ? String(card.model.issues) : "0"; label: "issues" }
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

    // Divider is drawn by CardHost at the row level (shared across side-by-side cards).
}
