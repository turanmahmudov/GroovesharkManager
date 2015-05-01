import QtQuick 2.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Popups 1.0
import Ubuntu.DownloadManager 0.1
import Ubuntu.Content 0.1
import QtMultimedia 5.0
import "../js/scripts.js" as Scripts
import "../js/sha1func.js" as Func

Item {
    id: search

    Rectangle {
        width: units.gu(30)
        anchors.top: parent.top
        anchors.topMargin: units.gu(2)
        anchors.horizontalCenter: parent.horizontalCenter

        Label {
            id: queryLabel
            anchors.left: parent.left
            anchors.top: parent.top
            text: "Artist name, Song name:"
        }
        TextField {
            id: query
            width: parent.width
            anchors.left: parent.left
            anchors.top: queryLabel.bottom
            anchors.topMargin: units.gu(1)
        }

        Button {
            id:button
            width: parent.width
            anchors.top: query.bottom
            anchors.topMargin: units.gu(2)
            text: i18n.tr("Search")
            gradient: Gradient {
              GradientStop { position: 0.0; color: "#F99A33" }
              GradientStop { position: 1.0; color: "#F45400" }
            }
            onClicked: {
                foundsongspage.text = query.text;
                foundsongspage.resolve(query.text);
                pagestack.push(foundSongs);
            }
        }
    }
}
