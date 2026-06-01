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

        // Data-independent width: the configured period fixes the heatmap's column
        // count synchronously (before any fetch), so a fresh add is sized right and
        // the grid never overflows. `cell`/`gap` MUST match HeatmapCard's values.
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

        // Data-independent height: each enabled card contributes a stable nominal
        // height (independent of async-loaded content), so a fresh add is tall enough
        // and cards never overflow the bottom. Over-estimates slightly (extra bottom
        // space) rather than clipping. NOTE: per-card height knowledge is coupled here;
        // a later refactor can have each card report its own preferred height.
        function cardHeight(id) {
            var gu = Kirigami.Units.gridUnit;
            if (id === "heatmap")   return 7 * (cell + gap) + gu * 3;
            if (id === "profile")   return gu * 7;
            if (id === "stats")     return gu * 4;
            if (id === "languages") return gu * 5;
            return gu * 3;
        }
        // Full-width cards (heatmap, languages) span all columns → one per row.
        // Narrow cards (profile, stats) pack into rows of `columnCount`; each row
        // counts once at its tallest member. Mirrors how CardHost's GridLayout flows.
        function isFullWidthCard(id) { return id === "heatmap" || id === "languages"; }
        readonly property int wantHeight: {
            var ids = plasmoid.configuration.cards;
            var cols = Math.max(1, plasmoid.configuration.columnCount);
            var ls = Kirigami.Units.largeSpacing;
            var h = Kirigami.Units.gridUnit * 3;   // refresh row + outer spacings
            var rowMax = 0, rowCount = 0;
            for (var i = 0; i < ids.length; i++) {
                var ch = cardHeight(ids[i]);
                if (isFullWidthCard(ids[i])) {
                    if (rowCount > 0) { h += rowMax + ls; rowMax = 0; rowCount = 0; }
                    h += ch + ls;
                } else {
                    if (ch > rowMax) rowMax = ch;
                    rowCount++;
                    if (rowCount >= cols) { h += rowMax + ls; rowMax = 0; rowCount = 0; }
                }
            }
            if (rowCount > 0) h += rowMax + ls;
            return h;
        }

        // Pin the size to the computed content size (min == preferred == max) so the
        // applet always auto-fits and can't retain a stale stored/hand-resized geometry.
        // This intentionally disables manual resizing — the widget sizes to its cards.
        Layout.minimumWidth: wantWidth
        Layout.preferredWidth: wantWidth
        Layout.maximumWidth: wantWidth
        Layout.minimumHeight: wantHeight
        Layout.preferredHeight: wantHeight
        Layout.maximumHeight: wantHeight
        spacing: Kirigami.Units.smallSpacing

        // Auth prompt when no token yet. This widget reads the account strictly from
        // the GitHub CLI (gh); show clear setup steps if it isn't installed/logged in.
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
