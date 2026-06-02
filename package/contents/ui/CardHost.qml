import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Lays out the enabled cards in rows: full-width cards (heatmap, languages) take a
// row each, the rest pack into rows of `columnCount`. A divider spans each row.
ColumnLayout {
    id: host

    property string token: ""
    property var cardIds: []
    property int columnCount: 1
    property int refreshMinutes: 30

    spacing: Kirigami.Units.smallSpacing

    function capitalize(s) { return s.charAt(0).toUpperCase() + s.slice(1); }
    function isFullWidth(id) { return id === "heatmap" || id === "languages"; }

    // Group cardIds into rows (each row is an array of ids).
    function rows() {
        var out = [];
        var cur = [];
        var cols = Math.max(1, host.columnCount);
        for (var i = 0; i < host.cardIds.length; i++) {
            var id = host.cardIds[i];
            if (host.isFullWidth(id)) {
                if (cur.length > 0) { out.push(cur); cur = []; }
                out.push([id]);
            } else {
                cur.push(id);
                if (cur.length >= cols) { out.push(cur); cur = []; }
            }
        }
        if (cur.length > 0) out.push(cur);
        return out;
    }

    // Re-fetch every loaded card. They sit inside nested layouts, so walk the tree.
    function reloadAll() { host._reload(host); }
    function _reload(obj) {
        if (!obj || !obj.children) return;
        for (var i = 0; i < obj.children.length; i++) {
            var c = obj.children[i];
            if (c && c.item && typeof c.item.reload === "function") c.item.reload();
            host._reload(c);
        }
    }

    Timer {
        interval: Math.max(1, host.refreshMinutes) * 60000
        running: true
        repeat: true
        onTriggered: host.reloadAll()
    }

    Repeater {
        model: host.rows()
        delegate: ColumnLayout {
            id: rowItem
            required property var modelData   // array of card ids in this row
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                Repeater {
                    model: rowItem.modelData
                    delegate: Loader {
                        id: ld
                        required property var modelData   // a card id
                        source: "cards/" + host.capitalize(modelData) + "Card.qml"
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        onLoaded: ld.item.token = Qt.binding(function() { return host.token; })
                    }
                }
            }

            // Row divider.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Kirigami.Theme.textColor
                opacity: 0.1
            }
        }
    }
}
