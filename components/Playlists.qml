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
    id: playls

    property var active_menu : 0
    property var playing_bcast : 0

    function get_playlists(user_id) {
        Scripts.get_playlists(user_id);
    }

    Item {
        id: playlistTools
        height: createplbutton.height
        width: parent.width

        ListItem.Standard {
            id: createplbutton
            text: "Create playlist"
            iconName: "add"
            iconFrame: false
            onClicked: {
                mainView.pl_songId = '';
                PopupUtils.open(createPlaylistDialog, pagestack);
            }
        }
    }

    ListModel {
        id: playlistsModel
    }

    ListView {
        id:playlists
        anchors.top: playlistTools.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true

        property var finished : false

        model:playlistsModel
        delegate: ListItem.Empty {
            width: parent.width
            height: pltitle.height + units.gu(5)
            removable: true
            confirmRemoval: true
            onItemRemoved: Scripts.delete_playlist(id, pl_name);
            Item {
                id: delegateitem
                anchors.fill: parent
                width: parent.width
                Rectangle {
                    id: image
                    height: units.gu(5)
                    width: units.gu(5)
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    color: "transparent"
                    Image {
                        width: parent.width
                        height: parent.height
                        source: "http://images.gs-cdn.net/static/playlists/70_" + pl_picture
                    }
                }
                Text {
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(2.5)
                    anchors.left: image.right
                    anchors.leftMargin: units.gu(2)
                    anchors.rightMargin: units.gu(2)
                    width: parent.width
                    id: pltitle
                    text: pl_name
                    color: UbuntuColors.darkGrey
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.pointSize: units.gu(1.5)
                }
            }
            onClicked: {
                playlistPage.title = pl_name;
                pagestack.push(playlistPage);
                playlistpage.playlist_id = id;
                playlistpage.playlist_name = pl_name;
                playlistpage.playlist(id);
            }
        }
    }
    Scrollbar {
        flickableItem: playlists
    }

    Item {
        id: indicat
        anchors.centerIn: parent
        opacity: playlistsModel.count == 0 && playlists.finished == false ? 1 : 0

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

    Item {
        id: noitem
        visible: playlistsModel.count == 0 && playlists.finished == true ? true : false
        anchors.margins: units.gu(1)
        anchors.fill: parent

        Label {
            id: noitemtitle
            anchors.centerIn: parent
            fontSize: "large"
            text: i18n.tr("<b>Playlists are awesome</b>")
        }
        Label {
            anchors.top: noitemtitle.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            fontSize: "normal"
            text: i18n.tr("You should make one, and share it with your friends.")
        }
    }
}
