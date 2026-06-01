import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Cards config: enable/disable, reorder, and per-card options.
// cfg_cards is the ordered StringList of enabled card ids.
//
// CRITICAL: every cfg_ alias target id (pAvatar, langCount, heatmapAccent, …) MUST
// live at the page ROOT scope, NOT inside a Repeater delegate. Ids declared inside a
// Repeater/Component delegate are invisible to root-scope `property alias` and cause a
// hard load failure ("Invalid alias reference"). So the Repeater renders ONLY the
// enable/reorder rows (which use page functions, no aliases), and the option controls
// are fixed root-level sections shown via `visible: page.isEnabled(...)`.
ColumnLayout {
    id: page
    spacing: Kirigami.Units.largeSpacing

    // --- config bindings (ALL cfg_ alias targets are root-scope controls below) ---
    property var cfg_cards: []
    property string cfg_heatmapPeriod: "year"
    property alias cfg_heatmapUseAccent: heatmapAccent.checked
    property alias cfg_languagesCount: langCount.value
    property alias cfg_languagesIncludeForks: langForks.checked
    property alias cfg_profileShowAvatar: pAvatar.checked
    property alias cfg_profileShowName: pName.checked
    property alias cfg_profileShowLogin: pLogin.checked
    property alias cfg_profileShowBio: pBio.checked
    property alias cfg_profileShowFollowers: pFollowers.checked
    property alias cfg_profileShowFollowing: pFollowing.checked
    property alias cfg_profileShowRepos: pRepos.checked

    // All known cards, canonical order. id must match cards/<Cap>Card.qml.
    readonly property var registry: [
        { id: "profile",   label: "Profile" },
        { id: "stats",     label: "Stats" },
        { id: "languages", label: "Languages" },
        { id: "heatmap",   label: "Contribution heatmap" }
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

    // --- enable / reorder list (NO cfg_ aliases inside; only page.* calls) ---
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

    // --- per-card option sections at ROOT scope; visible only when enabled ---

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
}
