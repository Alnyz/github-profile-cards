import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Panel representation: just the GitHub mark; click opens the popup.
MouseArea {
    id: compact
    Layout.minimumWidth: Kirigami.Units.iconSizes.smallMedium

    Kirigami.Icon {
        anchors.fill: parent
        source: "github"
    }
}
