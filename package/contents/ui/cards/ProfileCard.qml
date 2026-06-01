import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KAddons
import "../../code/GitHub.js" as GitHub
import "profile.js" as Profile

// Profile card. Set `token`; fetches and renders the viewer's profile.
ColumnLayout {
    id: card

    property string token: ""
    readonly property string cardId: "profile"
    readonly property bool fullWidth: false
    property var model: null
    property string status: ""

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    function reload() {
        if (card.token.length === 0) return;
        card.status = "loading";
        GitHub.fetchGraphQL(card.token, Profile.query(), {},
            function(data) { card.model = Profile.parse(data); card.status = ""; },
            function(msg) { card.status = msg; });
    }

    onTokenChanged: reload()
    Component.onCompleted: if (card.token.length > 0) reload()

    PlasmaComponents.Label {
        text: "PROFILE"
        font: Kirigami.Theme.smallFont
        opacity: 0.5
    }

    RowLayout {
        visible: card.model !== null
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        KAddons.Avatar {
            visible: plasmoid.configuration.profileShowAvatar
            implicitWidth: Kirigami.Units.iconSizes.large
            implicitHeight: Kirigami.Units.iconSizes.large
            name: card.model ? card.model.name : ""
            source: card.model ? card.model.avatarUrl : ""
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            PlasmaComponents.Label {
                visible: plasmoid.configuration.profileShowName
                font.bold: true
                text: card.model ? card.model.name : ""
            }
            PlasmaComponents.Label {
                visible: plasmoid.configuration.profileShowLogin
                opacity: 0.7
                text: card.model ? ("@" + card.model.login) : ""
            }
            PlasmaComponents.Label {
                visible: plasmoid.configuration.profileShowBio && card.model && card.model.bio.length > 0
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.8
                text: card.model ? card.model.bio : ""
            }
            PlasmaComponents.Label {
                opacity: 0.7
                visible: plasmoid.configuration.profileShowFollowers
                    || plasmoid.configuration.profileShowFollowing
                    || plasmoid.configuration.profileShowRepos
                text: {
                    if (!card.model) return "";
                    var parts = [];
                    if (plasmoid.configuration.profileShowFollowers) parts.push(card.model.followers + " followers");
                    if (plasmoid.configuration.profileShowFollowing) parts.push(card.model.following + " following");
                    if (plasmoid.configuration.profileShowRepos) parts.push(card.model.repos + " repos");
                    return parts.join(" · ");
                }
            }
        }
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
