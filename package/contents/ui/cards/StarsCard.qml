import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../../code/GitHub.js" as GitHub
import "stars.js" as Stars

// Stars card: your recently starred repositories. Set `token` to use it.
ColumnLayout {
    id: card

    property string token: ""
    readonly property string cardId: "stars"
    readonly property bool fullWidth: true
    property var model: null
    property string status: ""

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    function reload() {
        if (card.token.length === 0) return;
        card.status = "loading";
        GitHub.fetchGraphQL(card.token, Stars.query(plasmoid.configuration.starsCount), {},
            function(data) { card.model = Stars.parse(data, Date.now()); card.status = ""; },
            function(msg) { card.status = msg; });
    }

    onTokenChanged: reload()
    Component.onCompleted: if (card.token.length > 0) reload()

    Connections {
        target: plasmoid.configuration
        function onStarsCountChanged() { card.reload(); }
    }

    PlasmaComponents.Label {
        text: "STARS"
        font: Kirigami.Theme.smallFont
        opacity: 0.5
    }

    // One block per starred repo; the whole block opens the repo when clicked.
    Repeater {
        model: card.model ? card.model.repos : []
        delegate: ColumnLayout {
            id: repoRow
            required property var modelData
            readonly property real indent: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing
            Layout.fillWidth: true
            spacing: 2

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Qt.openUrlExternally(repoRow.modelData.url) }

            // Line 1: repo icon + name (link colored) ........ starred X ago.
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Icon {
                    source: Qt.resolvedUrl("../../icons/stats/repo.svg")
                    isMask: true
                    color: Kirigami.Theme.textColor
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }
                PlasmaComponents.Label {
                    text: repoRow.modelData.name
                    font.bold: true
                    color: Kirigami.Theme.linkColor
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                PlasmaComponents.Label {
                    text: repoRow.modelData.starred
                    opacity: 0.6
                    font: Kirigami.Theme.smallFont
                }
            }

            // Line 2: description (hidden when empty).
            PlasmaComponents.Label {
                visible: repoRow.modelData.description.length > 0
                text: repoRow.modelData.description
                opacity: 0.7
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.leftMargin: repoRow.indent
            }

            // Meta line: language, license, stars, forks, issues, PRs.
            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: repoRow.indent
                spacing: Kirigami.Units.largeSpacing

                component Meta: Row {
                    property string iconName: ""
                    property string value: ""
                    spacing: Kirigami.Units.smallSpacing
                    Kirigami.Icon {
                        source: Qt.resolvedUrl("../../icons/stats/" + iconName + ".svg")
                        isMask: true
                        color: Kirigami.Theme.textColor
                        width: Kirigami.Units.iconSizes.small
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    PlasmaComponents.Label {
                        opacity: 0.8
                        text: value
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Language color-dot + name (hidden when the repo has no language).
                Row {
                    visible: repoRow.modelData.language !== null
                    spacing: Kirigami.Units.smallSpacing
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: repoRow.modelData.languageColor || "#888888"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    PlasmaComponents.Label {
                        opacity: 0.8
                        text: repoRow.modelData.language || ""
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // License (hidden when the repo has none).
                Meta {
                    visible: repoRow.modelData.license !== null
                    iconName: "law"
                    value: repoRow.modelData.license || ""
                }

                Meta { iconName: "star"; value: repoRow.modelData.starsText }
                Meta { iconName: "repo-forked"; value: repoRow.modelData.forksText }
                Meta { iconName: "issues"; value: repoRow.modelData.issuesText }
                Meta { iconName: "prs"; value: repoRow.modelData.prsText }
            }
        }
    }

    PlasmaComponents.Label {
        visible: card.model !== null && card.model.repos.length === 0 && card.status === ""
        opacity: 0.6
        text: "No starred repositories"
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
