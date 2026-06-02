import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Panel representation: just the GitHub mark; click opens the popup.
MouseArea {
    id: compact
    Layout.minimumWidth: Kirigami.Units.iconSizes.smallMedium

    Kirigami.Icon {
        anchors.fill: parent
        // Bundled GitHub mark, recolored to the panel theme (isMask flattens it to the
        // current text color). Self-contained so it works on "Get New Widgets" installs,
        // where install.sh never runs to seed the icon theme.
        source: Qt.resolvedUrl("../icons/github.svg")
        isMask: true
        color: Kirigami.Theme.textColor
    }
}
