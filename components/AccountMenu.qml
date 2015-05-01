import QtQuick 2.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem

Item {
    property var menuText
    property var menuIcon

    width: units.gu(41)
    height: units.gu(5)

    Column {
        width: parent.width
        height: parent.height

        Item {
            width: parent.width
            height: units.gu(1.5)
        }
        Row {
            width: parent.width
            spacing: units.gu(1)

            Icon {
                width: units.gu(2)
                height: units.gu(2)
                name: menuIcon
            }

            Label {
                text: menuText
            }
        }
        Item {
            width: parent.width
            height: units.gu(1.5)
        }
        ListItem.ThinDivider { }
    }
}
