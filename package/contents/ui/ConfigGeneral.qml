import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    property alias cfg_refreshMinutes: refreshSpin.value
    property alias cfg_columnCount: columnSpin.value

    SpinBox {
        id: refreshSpin
        Kirigami.FormData.label: "Refresh every (minutes):"
        from: 1
        to: 1440
    }

    SpinBox {
        id: columnSpin
        Kirigami.FormData.label: "Columns:"
        from: 1
        to: 4
    }
}
