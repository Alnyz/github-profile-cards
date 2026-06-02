import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../../code/GitHub.js" as GitHub
import "languages.js" as Lang

// Languages card: a top-N language bar with a legend. Set `token` to use it.
ColumnLayout {
    id: card

    property string token: ""
    readonly property string cardId: "languages"
    readonly property bool fullWidth: true
    property var model: null
    property string status: ""

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    function reload() {
        if (card.token.length === 0) return;
        card.status = "loading";
        GitHub.fetchGraphQL(card.token, Lang.query(plasmoid.configuration.languagesIncludeForks), {},
            function(data) { card.model = Lang.parse(data, plasmoid.configuration.languagesCount); card.status = ""; },
            function(msg) { card.status = msg; });
    }

    onTokenChanged: reload()
    Component.onCompleted: if (card.token.length > 0) reload()

    Connections {
        target: plasmoid.configuration
        function onLanguagesIncludeForksChanged() { card.reload(); }
        function onLanguagesCountChanged() { card.reload(); }
    }

    PlasmaComponents.Label {
        text: "LANGUAGES"
        font: Kirigami.Theme.smallFont
        opacity: 0.5
    }

    // Proportional stacked bar.
    Item {
        visible: card.model !== null && card.model.langs.length > 0
        Layout.fillWidth: true
        implicitHeight: Kirigami.Units.gridUnit * 0.5
        Row {
            id: bar
            anchors.fill: parent
            Repeater {
                model: card.model ? card.model.langs : []
                delegate: Rectangle {
                    required property var modelData
                    width: bar.width * modelData.pct / 100
                    height: bar.height
                    color: modelData.color
                }
            }
        }
    }

    // Legend.
    Flow {
        visible: card.model !== null && card.model.langs.length > 0
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing
        Repeater {
            model: card.model ? card.model.langs : []
            delegate: RowLayout {
                required property var modelData
                spacing: Kirigami.Units.smallSpacing
                Rectangle { width: 8; height: 8; radius: 2; color: modelData.color }
                PlasmaComponents.Label {
                    opacity: 0.8
                    text: modelData.name + " " + Math.round(modelData.pct) + "%"
                }
            }
        }
    }

    PlasmaComponents.Label {
        visible: card.model !== null && card.model.langs.length === 0 && card.status === ""
        opacity: 0.6
        text: "No language data"
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
