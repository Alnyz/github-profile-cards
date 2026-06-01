import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

// Draws weeks as columns of 7 day-squares.
// property weeks: array of arrays of { date, count, color, weekday }.
Row {
    id: grid

    property var weeks: []
    property int cell: Kirigami.Units.gridUnit * 0.9
    property int gap: Math.max(1, Math.round(cell * 0.14))
    property bool useAccent: false

    spacing: gap

    Repeater {
        model: grid.weeks
        delegate: Column {
            id: weekCol
            required property var modelData
            spacing: grid.gap
            Repeater {
                model: 7
                delegate: Rectangle {
                    required property int index
                    property var day: {
                        var col = weekCol.modelData;
                        for (var i = 0; i < col.length; i++) {
                            if (col[i].weekday === index) return col[i];
                        }
                        return null;
                    }
                    width: grid.cell
                    height: grid.cell
                    radius: Math.round(grid.cell * 0.2)
                    color: day === null
                        ? "transparent"
                        : (grid.useAccent && day.count > 0
                            ? Qt.tint(Kirigami.Theme.highlightColor,
                                      Qt.rgba(0, 0, 0, 1 - Math.min(1, day.count / 10) * 0.85))
                            : day.color)

                    HoverHandler { id: hover }
                    ToolTip.visible: hover.hovered && day !== null
                    ToolTip.text: day === null
                        ? ""
                        : (day.count + " contribution" + (day.count === 1 ? "" : "s") + " on " + day.date)
                }
            }
        }
    }
}
