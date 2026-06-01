import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "configure"
        source: "ConfigGeneral.qml"
    }
    ConfigCategory {
        name: "Cards"
        icon: "view-list-details"
        source: "ConfigCards.qml"
    }
}
