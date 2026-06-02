import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KAddons
import "../../code/GitHub.js" as GitHub
import "profile.js" as Profile

// Profile card: fetches and shows the viewer's profile. Set `token` to use it.
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

    // "Joined 8 years ago" style relative label from an ISO date.
    function joinedAgo(iso) {
        if (!iso) return "";
        var ms = new Date().getTime() - new Date(iso).getTime();
        var days = Math.floor(ms / 86400000);
        var years = Math.floor(days / 365);
        if (years >= 1) return "Joined " + years + " year" + (years === 1 ? "" : "s") + " ago";
        var months = Math.floor(days / 30);
        if (months >= 1) return "Joined " + months + " month" + (months === 1 ? "" : "s") + " ago";
        return "Joined " + Math.max(0, days) + " day" + (days === 1 ? "" : "s") + " ago";
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
                visible: plasmoid.configuration.profileShowName || plasmoid.configuration.profileShowLogin
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                textFormat: Text.StyledText
                text: {
                    if (!card.model) return "";
                    var showName = plasmoid.configuration.profileShowName;
                    var showLogin = plasmoid.configuration.profileShowLogin;
                    if (showName && showLogin) return "<b>" + card.model.name + "</b> (@" + card.model.login + ")";
                    if (showName) return "<b>" + card.model.name + "</b>";
                    if (showLogin) return "@" + card.model.login;
                    return "";
                }
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
            PlasmaComponents.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.7
                visible: (plasmoid.configuration.profileShowCompany && card.model && card.model.company.length > 0)
                    || (plasmoid.configuration.profileShowLocation && card.model && card.model.location.length > 0)
                text: {
                    if (!card.model) return "";
                    var parts = [];
                    if (plasmoid.configuration.profileShowCompany && card.model.company.length > 0) parts.push(card.model.company);
                    if (plasmoid.configuration.profileShowLocation && card.model.location.length > 0) parts.push(card.model.location);
                    return parts.join(" · ");
                }
            }
            PlasmaComponents.Label {
                opacity: 0.7
                visible: plasmoid.configuration.profileShowJoined && card.model && card.model.joined.length > 0
                text: (card.model && card.model.joined.length > 0) ? card.joinedAgo(card.model.joined) : ""
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

    // The row divider is drawn by CardHost.
}
