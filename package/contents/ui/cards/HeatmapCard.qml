import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../../code/GitHub.js" as GitHub
import "heatmap.js" as Heatmap
import ".."   // for HeatmapGrid

// Heatmap card: fetches and draws the contribution calendar. Set `token` to use it.
ColumnLayout {
    id: card

    property string token: ""
    readonly property string cardId: "heatmap"
    readonly property bool fullWidth: true
    property var model: null
    property string status: ""        // "", "loading", or an error message

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    function periodDays() {
        var p = plasmoid.configuration.heatmapPeriod;
        if (p === "week") return 7;
        if (p === "month") return 30;
        return 0;   // "year" => omit the range (GitHub default last-year window)
    }

    function reload() {
        if (card.token.length === 0) return;
        card.status = "loading";
        var days = periodDays();
        var from = null, to = null;
        if (days > 0) {
            var now = new Date();
            to = now.toISOString();
            from = new Date(now.getTime() - days * 24 * 3600 * 1000).toISOString();
        }
        GitHub.fetchGraphQL(card.token, Heatmap.query(from, to), {},
            function(data) { card.model = Heatmap.parse(data); card.status = ""; },
            function(msg) { card.status = msg; });
    }

    onTokenChanged: reload()
    Component.onCompleted: if (card.token.length > 0) reload()

    Connections {
        target: plasmoid.configuration
        function onHeatmapPeriodChanged() { card.reload(); }
    }

    PlasmaComponents.Label {
        text: ("Contributions · " + plasmoid.configuration.heatmapPeriod).toUpperCase()
        font: Kirigami.Theme.smallFont
        opacity: 0.5
    }

    PlasmaComponents.Label {
        visible: card.model !== null
        opacity: 0.8
        text: card.model
            ? (card.model.total + " contributions in the last " + plasmoid.configuration.heatmapPeriod)
            : ""
    }

    HeatmapGrid {
        Layout.fillWidth: true
        visible: card.model !== null
        weeks: card.model ? card.model.weeks : []
        useAccent: plasmoid.configuration.heatmapUseAccent
        cell: Math.round(Kirigami.Units.gridUnit * 0.62)
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
