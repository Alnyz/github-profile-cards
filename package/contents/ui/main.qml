import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property string token: ""
    property string authError: ""

    Plasmoid.status: token.length > 0 ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus

    DeviceToken {
        id: deviceToken
        onGotToken: function(t) { root.token = t; root.authError = ""; }
        onFailed: function(msg) { root.authError = msg; }
    }

    function acquireToken() {
        root.authError = "";
        deviceToken.request();
    }

    Component.onCompleted: acquireToken()

    fullRepresentation: ColumnLayout {
        id: view

        // Width is derived from the heatmap's column count so it's known before any
        // fetch. cell/gap must match HeatmapCard's values.
        readonly property int cell: Math.round(Kirigami.Units.gridUnit * 0.62)
        readonly property int gap: Math.max(1, Math.round(cell * 0.14))
        function heatmapCols() {
            var p = plasmoid.configuration.heatmapPeriod;
            if (p === "week") return 3;
            if (p === "month") return 6;
            return 53;
        }
        readonly property int wantWidth: Math.max(Kirigami.Units.gridUnit * 16,
            heatmapCols() * (cell + gap) + Kirigami.Units.largeSpacing * 2)

        // Fix the size to the content (min == max) so the widget auto-fits its cards
        // instead of keeping a hand-resized geometry.
        Layout.minimumWidth: wantWidth
        Layout.preferredWidth: wantWidth
        Layout.maximumWidth: wantWidth
        Layout.minimumHeight: view.implicitHeight
        Layout.preferredHeight: view.implicitHeight
        Layout.maximumHeight: view.implicitHeight
        spacing: Kirigami.Units.smallSpacing

        // Shown until a gh token is available.
        ColumnLayout {
            visible: root.token.length === 0
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            // Loading (no error yet).
            RowLayout {
                visible: root.authError.length === 0
                spacing: Kirigami.Units.smallSpacing
                PlasmaComponents.BusyIndicator {
                    running: true
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                }
                PlasmaComponents.Label { text: "Reading your GitHub account from gh…"; opacity: 0.7 }
            }

            // Setup needed (gh missing or not logged in).
            ColumnLayout {
                visible: root.authError.length > 0
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label { text: "GitHub CLI required"; font.bold: true }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "This widget reads your GitHub account from the GitHub CLI (gh). Install it and log in, then click Retry:"
                }
                PlasmaComponents.Label { font.family: "monospace"; text: "1.  sudo pacman -S github-cli" }
                PlasmaComponents.Label { font.family: "monospace"; text: "2.  gh auth login" }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.55
                    font: Kirigami.Theme.smallFont
                    text: root.authError
                }
                PlasmaComponents.Button {
                    text: "Retry"
                    icon.name: "view-refresh"
                    onClicked: root.acquireToken()
                }
            }
        }

        CardHost {
            id: cardHost
            visible: root.token.length > 0
            Layout.fillWidth: true
            token: root.token
            cardIds: plasmoid.configuration.cards
            columnCount: plasmoid.configuration.columnCount
            refreshMinutes: plasmoid.configuration.refreshMinutes
        }

        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            PlasmaComponents.Button {
                text: "Refresh"
                icon.name: "view-refresh"
                enabled: root.token.length > 0
                onClicked: cardHost.reloadAll()
            }
        }
    }

    compactRepresentation: CompactRepresentation {
        onClicked: root.expanded = !root.expanded
    }
}
