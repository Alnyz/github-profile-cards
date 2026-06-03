import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Cards settings: enable/disable, reorder, and per-card options. cfg_cards holds the
// ordered list of enabled card ids. A cfg_ alias can only target a root-scope id (not
// one inside a Repeater delegate), so the per-card options live in the fixed sections
// below rather than in the reorder list.
ColumnLayout {
    id: page
    spacing: Kirigami.Units.largeSpacing

    property var cfg_cards: []
    property string cfg_heatmapPeriod: "year"
    property alias cfg_heatmapUseAccent: heatmapAccent.checked
    property alias cfg_languagesCount: langCount.value
    property alias cfg_languagesIncludeForks: langForks.checked
    property alias cfg_starsCount: starsCount.value
    property alias cfg_profileShowAvatar: pAvatar.checked
    property alias cfg_profileShowName: pName.checked
    property alias cfg_profileShowLogin: pLogin.checked
    property alias cfg_profileShowBio: pBio.checked
    property alias cfg_profileShowFollowers: pFollowers.checked
    property alias cfg_profileShowFollowing: pFollowing.checked
    property alias cfg_profileShowRepos: pRepos.checked
    property alias cfg_profileShowCompany: pCompany.checked
    property alias cfg_profileShowLocation: pLocation.checked
    property alias cfg_profileShowJoined: pJoined.checked

    // All known cards, canonical order. id must match cards/<Cap>Card.qml.
    readonly property var registry: [
        { id: "profile",   label: "Profile" },
        { id: "stats",     label: "Stats" },
        { id: "languages", label: "Languages" },
        { id: "heatmap",   label: "Contribution heatmap" },
        { id: "stars",     label: "Stars (recently starred)" }
    ]

    function isEnabled(id) { return page.cfg_cards.indexOf(id) >= 0; }

    function setEnabled(id, on) {
        var list = page.cfg_cards.slice();
        var idx = list.indexOf(id);
        if (on && idx < 0) list.push(id);
        else if (!on && idx >= 0) list.splice(idx, 1);
        page.cfg_cards = list;
    }

    function move(id, delta) {
        var list = page.cfg_cards.slice();
        var idx = list.indexOf(id);
        if (idx < 0) return;
        var to = idx + delta;
        if (to < 0 || to >= list.length) return;
        var tmp = list[idx]; list[idx] = list[to]; list[to] = tmp;
        page.cfg_cards = list;
    }

    // Display order: enabled cards first (in cfg_cards order), then disabled (registry order).
    function displayList() {
        var out = [];
        for (var i = 0; i < page.cfg_cards.length; i++) {
            var id = page.cfg_cards[i];
            for (var r = 0; r < page.registry.length; r++) {
                if (page.registry[r].id === id) { out.push(page.registry[r]); break; }
            }
        }
        for (var s = 0; s < page.registry.length; s++) {
            if (page.cfg_cards.indexOf(page.registry[s].id) < 0) out.push(page.registry[s]);
        }
        return out;
    }

    Kirigami.Heading { level: 3; text: "Cards" }
    Label {
        text: "Enable, reorder, and configure each card."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    // Enable / reorder list.
    Repeater {
        model: page.displayList()
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            CheckBox {
                checked: page.isEnabled(modelData.id)
                onToggled: page.setEnabled(modelData.id, checked)
            }
            Label { text: modelData.label; Layout.fillWidth: true }
            Button {
                icon.name: "go-up"
                enabled: page.isEnabled(modelData.id)
                onClicked: page.move(modelData.id, -1)
            }
            Button {
                icon.name: "go-down"
                enabled: page.isEnabled(modelData.id)
                onClicked: page.move(modelData.id, 1)
            }
        }
    }

    Kirigami.Separator { Layout.fillWidth: true }

    // Per-card options, shown when the card is enabled.

    // Profile
    ColumnLayout {
        Layout.fillWidth: true
        visible: page.isEnabled("profile")
        Label { text: "Profile fields"; font.bold: true }
        GridLayout {
            columns: 2
            CheckBox { id: pAvatar; text: "Avatar" }
            CheckBox { id: pName; text: "Name" }
            CheckBox { id: pLogin; text: "Login" }
            CheckBox { id: pBio; text: "Bio" }
            CheckBox { id: pFollowers; text: "Followers" }
            CheckBox { id: pFollowing; text: "Following" }
            CheckBox { id: pRepos; text: "Repos" }
            CheckBox { id: pCompany; text: "Company" }
            CheckBox { id: pLocation; text: "Location" }
            CheckBox { id: pJoined; text: "Joined date" }
        }
    }

    // Languages
    ColumnLayout {
        Layout.fillWidth: true
        visible: page.isEnabled("languages")
        Label { text: "Languages"; font.bold: true }
        RowLayout {
            Label { text: "Top languages:" }
            SpinBox { id: langCount; from: 1; to: 10 }
        }
        CheckBox { id: langForks; text: "Include forks" }
    }

    // Heatmap
    ColumnLayout {
        Layout.fillWidth: true
        visible: page.isEnabled("heatmap")
        Label { text: "Heatmap"; font.bold: true }
        RowLayout {
            Label { text: "Period:" }
            ComboBox {
                id: heatmapPeriodCombo
                model: [ { text: "Last week", val: "week" },
                         { text: "Last month", val: "month" },
                         { text: "Last year", val: "year" } ]
                textRole: "text"
                valueRole: "val"
                currentIndex: page.cfg_heatmapPeriod === "week" ? 0
                    : (page.cfg_heatmapPeriod === "month" ? 1 : 2)
                onActivated: page.cfg_heatmapPeriod = currentValue
            }
        }
        CheckBox { id: heatmapAccent; text: "Use Plasma accent instead of GitHub greens" }
    }

    // Stars
    ColumnLayout {
        Layout.fillWidth: true
        visible: page.isEnabled("stars")
        Label { text: "Stars"; font.bold: true }
        RowLayout {
            Label { text: "Repositories to show:" }
            SpinBox { id: starsCount; from: 1; to: 5 }
        }
    }
}
