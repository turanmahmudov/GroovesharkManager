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
    id: broadcs

    property var active_menu : 0
    property var playing_bcast : 0

    function broadcast(id, title, tagName) {
        Scripts.get_mobile_broadcast_url(id, title, tagName);
    }

    function get_top_broadcasts_combined() {
        Scripts.get_top_broadcasts_combined();
    }

    function get_top_broadcasts(genre) {
        Scripts.get_top_broadcasts(genre);
    }

    function refresh_broadcast() {
        Scripts.refresh_broadcast(playing_bcast);
    }

    Timer {
         interval: 30000
         running: mainView.pausing_song == 0 && mainView.playing_song == 'broadcast'
         repeat: true
         onTriggered: refresh_broadcast()
     }

    Item {
        id: genreSelector
        height: genre.height
        width: parent.width

        ListItem.ItemSelector {
            id: genre
            model: genresModel
            expanded: false
            colourImage: false
            delegate: genreDelegate
            width: parent.width
            containerHeight: units.gu(25)
            anchors {
                top: parent.top
                left: parent.left
            }
            onDelegateClicked: {
                if (index == 0) {
                    get_top_broadcasts_combined();
                } else {
                    var genre_id = genresModel.get(index).genre_id;
                    var genre = 'bcast_genre_' + genre_id;
                    get_top_broadcasts(genre);
                }
            }
        }

        ListModel {
            id: genresModel
            ListElement { name: "All genres"; }
            ListElement { name: "Ambient"; genre_id: '75'; }
            ListElement { name: "Electronic"; genre_id: '156'; }
            ListElement { name: "Dance"; genre_id: '814'; }
            ListElement { name: "Indie Rock"; genre_id: '3773'; }
            ListElement { name: "Folk Music"; genre_id: '7120'; }
            ListElement { name: "Reggae"; genre_id: '160'; }
            ListElement { name: "Ska"; genre_id: '100'; }
            ListElement { name: "Pop Punk"; genre_id: '7227'; }
            ListElement { name: "Rock"; genre_id: '2856'; }
            ListElement { name: "Country"; genre_id: '1933'; }
            ListElement { name: "Rap"; genre_id: '1748'; }
            ListElement { name: "R&B"; genre_id: '7614'; }
            ListElement { name: "Classical"; genre_id: '750'; }
            ListElement { name: "World"; genre_id: '313'; }
            ListElement { name: "90's"; genre_id: '10'; }
            ListElement { name: "80's"; genre_id: '424'; }
            ListElement { name: "70's"; genre_id: '2360'; }
            ListElement { name: "60's"; genre_id: '7512'; }
        }
        Component {
            id: genreDelegate
            OptionSelectorDelegate { text: name; }
        }
    }

    ListModel {
        id: broadcastsModel
    }

    ListView {
        id:broadcasts
        anchors.top: genreSelector.bottom
        anchors.topMargin: units.gu(1)
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true

        model:broadcastsModel
        delegate: ListItem.Empty {
            width: parent.width
            height: bcasttitle.height + bcastdetails.height + units.gu(3)
            MouseArea {
                width: parent.width
                height: bcasttitle.height + bcastdetails.height + units.gu(1)
                onClicked: {
                    broadcast(id, title, tagName);
                }
            }
            Item {
                id: delegateitem
                anchors.fill: parent
                width: parent.width
                Text {
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    anchors.rightMargin: units.gu(2)
                    width: parent.width - units.gu(4)
                    id: bcasttitle
                    text: title
                    color: playing_bcast == id ? '#F86F05' : UbuntuColors.darkGrey
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.pointSize: playing_bcast == id ? units.gu(1.5) : units.gu(1.3)
                    font.bold: true
                }
                Text {
                    anchors.top: bcasttitle.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.bottomMargin: units.gu(1)
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    anchors.rightMargin: units.gu(2)
                    width: parent.width - units.gu(4)
                    color: UbuntuColors.darkGrey
                    id: bcastdetails
                    text: "by " + ownerName + " • " + listenersCount + " listeners" + " • " + tagName
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.pointSize: units.gu(1.2)
                }
            }
        }
    }
    Scrollbar {
        flickableItem: broadcasts
    }

    Item {
        id: indicat
        anchors.centerIn: parent
        opacity: broadcastsModel.count != 0 ? 0 : 1

        Behavior on opacity {
            UbuntuNumberAnimation {
                duration: UbuntuAnimation.SlowDuration
            }
        }

        ActivityIndicator {
            id: activity
            running: true
        }
    }
}
