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
    id: playl

    property var active_menu : 0

    property var playlist_id
    property var playlist_name

    function playlist(id) {
        Scripts.get_playlist_by_id(id);
        get_fav();
        get_lib();
    }

    function get_fav() {
        Scripts.get_fav_songs(uid, 'playlist');
    }
    function get_lib() {
        Scripts.get_lib_songs(uid, 'playlist');
    }

    ListModel {
        id: playlistsongsModel
    }

    ListView {
        id:playlistsongs
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true

        property var finished : false

        model:playlistsongsModel
        delegate: ListItem.Empty {
            removable: true
            confirmRemoval: true
            onItemRemoved: Scripts.remove_song_from_playlist(playlist_id, id, playlist_name)
            width: parent.width
            height: songtitle.height + songartistalbum.height + detailed.height + units.gu(3)
            onClicked: {
                queueModel.clear();
                for (var i = 0; i < playlistsongsModel.count; i++) {
                    queueModel.append(playlistsongsModel.get(i));
                }
                current_song_index = index;
                current_list = 'queue';
                Scripts.play_song(id, name, title, artist_album, songImage);
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
                    width: parent.width - downButton.width - units.gu(4)
                    id: songtitle
                    text: title
                    color: playing_song == id ? '#F86F05' : UbuntuColors.darkGrey
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.pointSize: playing_song == id ? units.gu(1.8) : units.gu(1.6)
                }
                Text {
                    anchors.top: songtitle.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.bottomMargin: units.gu(1)
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    anchors.rightMargin: units.gu(2)
                    width: parent.width - downButton.width - units.gu(4)
                    color: UbuntuColors.darkGrey
                    id: songartistalbum
                    text: artist_album
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.pointSize: units.gu(1.2)
                }
                Rectangle {
                    id: detailed
                    visible: active_menu == id ? true : false
                    width: parent.width
                    height: active_menu == id ? units.gu(7) : 0
                    anchors.top: songartistalbum.bottom
                    anchors.topMargin: units.gu(1)
                    anchors.left: parent.left
                    color: "#191E28"
                    Rectangle {
                        id: downloadingstate
                        height: parent.height
                        width: active_download == id ? (parent.width/(100/single.progress)) : 0
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 0
                        color: "#F86F05"
                    }
                    Flickable {
                        id: flickableh

                        anchors.fill: parent
                        contentWidth: buttons.width;
                        contentHeight: flickableh.height

                        //onMovementStarted: detailed.color = "#705050"
                        //onMovementEnded: detailed.color = "#363636"
                        Item {
                            id: buttons
                            width: active_download == 0 ? downloadButton.width + externalButton.width + lyricsButton.width + artistButton.width + albumButton.width + favButton.width + pylButton.width + collectionButton.width + shareButton.width + buyButton.width + units.gu(36) + units.gu(6) : parent.width
                            height: parent.height
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(2)
                            Rectangle {
                                width: units.gu(5)
                                height: parent.height
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.leftMargin: active_download == 0 ? units.gu(1) : units.gu(1)
                                id: downloadButton
                                color: "transparent"
                                Icon {
                                    id: downloadIcon
                                    width: units.gu(3)
                                    height: units.gu(3)
                                    anchors.top: parent.top
                                    anchors.topMargin: units.gu(1.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    name: active_download == id ? "cancel" : "save"
                                    color: "#fff"
                                }
                                Label {
                                    id: downloadLabel
                                    text: active_download == id ? "Cancel" : "Download"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: units.gu(0.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    fontSize: "x-small"
                                    color: "#fff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (active_download == 0) {
                                            Scripts.download_song(id, name);
                                            active_download = id;
                                            downloading.visible = true;

                                            artistButton.visible = false;
                                            albumButton.visible = false;
                                            favButton.visible = false;
                                            collectionButton.visible = false;
                                            lyricsButton.visible = false;
                                            externalButton.visible = false;
                                            shareButton.visible = false;
                                            buyButton.visible = false;
                                            pylButton.visible = false;

                                            flickableh.contentWidth = detailed.width;
                                        } else if (active_download == id) {
                                            single.cancel();
                                            active_download = 0;
                                            downloading.visible = false;

                                            artistButton.visible = true;
                                            albumButton.visible = true;
                                            favButton.visible = true;
                                            collectionButton.visible = true;
                                            lyricsButton.visible = true;
                                            externalButton.visible = true;
                                            shareButton.visible = true;
                                            buyButton.visible = true;
                                            pylButton.visible = true;

                                            flickableh.contentWidth = buttons.width;
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                visible: false
                                width: units.gu(5)
                                height: parent.height
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.rightMargin: units.gu(3)
                                id: downloading
                                color: "transparent"
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: single.progress + "%"
                                    color: "#fff"
                                }
                            }
                            Rectangle {
                                width: units.gu(5)
                                height: parent.height
                                anchors.top: parent.top
                                anchors.left: downloadButton.right
                                anchors.leftMargin: units.gu(4)
                                id: artistButton
                                color: "transparent"
                                Icon {
                                    width: units.gu(3)
                                    height: units.gu(3)
                                    anchors.top: parent.top
                                    anchors.topMargin: units.gu(1.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: "../graphics/microphone.png"
                                    color: "#fff"
                                }
                                Label {
                                    text: "Artist"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: units.gu(0.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    fontSize: "x-small"
                                    color: "#fff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        artistPage.title = artistName;
                                        artistpage.artistId = artistId;
                                        artistpage.artist_albums(artistId);
                                        pagestack.push(artistPage);
                                    }
                                }
                            }
                            Rectangle {
                                width: units.gu(5)
                                height: parent.height
                                anchors.top: parent.top
                                anchors.left: artistButton.right
                                anchors.leftMargin: units.gu(4)
                                id: albumButton
                                color: "transparent"
                                Icon {
                                    width: units.gu(3)
                                    height: units.gu(3)
                                    anchors.top: parent.top
                                    anchors.topMargin: units.gu(1.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: "../graphics/cd.png"
                                    color: "#fff"
                                }
                                Label {
                                    text: "Album"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: units.gu(0.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    fontSize: "x-small"
                                    color: "#fff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        albumPage.title = albumName;
                                        albumpage.albumId = albumId;
                                        albumpage.album(albumId);
                                        pagestack.push(albumPage);
                                    }
                                }
                            }
                            Rectangle {
                                width: units.gu(5)
                                height: parent.height
                                anchors.top: parent.top
                                anchors.left: albumButton.right
                                anchors.leftMargin: units.gu(4)
                                id: favButton
                                color: "transparent"
                                Icon {
                                    width: units.gu(3)
                                    height: units.gu(3)
                                    anchors.top: parent.top
                                    anchors.topMargin: units.gu(1.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    name: "like"
                                    color: is_fav == 1 ? "#ff0000" : "#fff"
                                }
                                Label {
                                    text: "Favorite"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: units.gu(0.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    fontSize: "x-small"
                                    color: "#fff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (is_fav == 1) {
                                            Scripts.remove_from_fav(id, 'playlist');
                                        } else {
                                            Scripts.add_to_fav(id, 'playlist');
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                width: units.gu(5)
                                height: parent.height
                                anchors.top: parent.top
                                anchors.left: favButton.right
                                anchors.leftMargin: units.gu(4)
                                id: collectionButton
                                color: "transparent"
                                Icon {
                                    width: units.gu(3)
                                    height: units.gu(3)
                                    anchors.top: parent.top
                                    anchors.topMargin: units.gu(1.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    name: "tick"
                                    color: is_lib == 1 ? "#00ff00" : "#fff"
                                }
                                Label {
                                    text: "Collection"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: units.gu(0.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    fontSize: "x-small"
                                    color: "#fff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (is_lib == 1) {
                                            Scripts.remove_from_lib(id, albumId, artistId, uid, 'playlist');
                                        } else {
                                            var song_data = [{
                                                'songID' : id,
                                                'songName' : title,
                                                'artistName' : artistName,
                                                'artistID' : artistId,
                                                'albumName' : albumName,
                                                'albumID' : albumId,
                                                'track' : trackNum
                                                }];
                                            Scripts.add_to_lib(song_data, 'playlist');
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                width: units.gu(5)
                                height: parent.height
                                anchors.top: parent.top
                                anchors.left: collectionButton.right
                                anchors.leftMargin: units.gu(4)
                                id: pylButton
                                color: "transparent"
                                Icon {
                                    width: units.gu(3)
                                    height: units.gu(3)
                                    anchors.top: parent.top
                                    anchors.topMargin: units.gu(1.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    name: "media-playlist"
                                    color: "#fff"
                                }
                                Label {
                                    text: "Playlist"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: units.gu(0.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    fontSize: "x-small"
                                    color: "#fff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (mainView.is_logged == true) {
                                            pl_songId = id;
                                            Scripts.aget_playlists(mainView.uid);
                                            PopupUtils.open(addtoplaylistDialog, pagestack);
                                        } else {
                                            PopupUtils.open(loginDialog, mainView);
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                width: units.gu(5)
                                height: parent.height
                                anchors.top: parent.top
                                anchors.left: pylButton.right
                                anchors.leftMargin: units.gu(4)
                                id: lyricsButton
                                color: "transparent"
                                Icon {
                                    width: units.gu(3)
                                    height: units.gu(3)
                                    anchors.top: parent.top
                                    anchors.topMargin: units.gu(1.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: "../graphics/edit-select-all.svg"
                                    color: "#fff"
                                }
                                Label {
                                    text: "Lyrics"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: units.gu(0.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    fontSize: "x-small"
                                    color: "#fff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Scripts.getLyrics(artistName, title);
                                    }
                                }
                            }
                            Rectangle {
                                width: units.gu(5)
                                height: parent.height
                                anchors.top: parent.top
                                anchors.left: lyricsButton.right
                                anchors.leftMargin: units.gu(4)
                                id: externalButton
                                color: "transparent"
                                Icon {
                                    width: units.gu(3)
                                    height: units.gu(3)
                                    anchors.top: parent.top
                                    anchors.topMargin: units.gu(1.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    name: "external-link"
                                    color: "#fff"
                                }
                                Label {
                                    text: "External"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: units.gu(0.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    fontSize: "x-small"
                                    color: "#fff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Scripts.link_song_ex(id, title);
                                    }
                                }
                            }
                            Rectangle {
                                width: units.gu(5)
                                height: parent.height
                                anchors.top: parent.top
                                anchors.left: externalButton.right
                                anchors.leftMargin: units.gu(4)
                                id: shareButton
                                color: "transparent"
                                Icon {
                                    width: units.gu(3)
                                    height: units.gu(3)
                                    anchors.top: parent.top
                                    anchors.topMargin: units.gu(1.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    name: "share"
                                    color: "#fff"
                                }
                                Label {
                                    text: "Share"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: units.gu(0.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    fontSize: "x-small"
                                    color: "#fff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Scripts.share_song_ex(id, title);
                                    }
                                }
                            }
                            Rectangle {
                                width: units.gu(5)
                                height: parent.height
                                anchors.top: parent.top
                                anchors.left: shareButton.right
                                anchors.leftMargin: units.gu(4)
                                id: buyButton
                                color: "transparent"
                                Icon {
                                    width: units.gu(3)
                                    height: units.gu(3)
                                    anchors.top: parent.top
                                    anchors.topMargin: units.gu(1.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: "../graphics/buy.png"
                                    color: "#fff"
                                }
                                Label {
                                    text: "Buy"
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: units.gu(0.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    fontSize: "x-small"
                                    color: "#fff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Qt.openUrlExternally("scope://com.canonical.scopes.amazon?q="+artistName+" "+title);
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: units.gu(3)
                    height: songtitle.height + songartistalbum.height + units.gu(1)
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(2)
                    id: downButton
                    color: "transparent"
                    Icon {
                        width: units.gu(2.5)
                        height: units.gu(2.5)
                        anchors.verticalCenter: parent.verticalCenter
                        name: active_menu == id ? "up" : "down"
                        color: UbuntuColors.darkGrey
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (active_download == 0) {
                                    if (active_menu == id) {
                                        active_menu = 0;
                                        downloading.visible = false;

                                        artistButton.visible = true;
                                        albumButton.visible = true;
                                        favButton.visible = true;
                                        collectionButton.visible = true;
                                        lyricsButton.visible = true;
                                        externalButton.visible = true;
                                        shareButton.visible = true;
                                        buyButton.visible = true;

                                        flickableh.contentWidth = buttons.width;

                                    } else {
                                        active_menu = id;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        PullToRefresh {
            refreshing: playlistsongsModel.count == 0 && playlistsongs.finished == false
            onRefresh: playlist(playlist_id)
        }
    }
    Scrollbar {
        flickableItem: playlistsongs
    }

    Item {
        id: indicat
        anchors.centerIn: parent
        opacity: playlistsongsModel.count == 0 && playlistsongs.finished == false ? 1 : 0

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
        visible: playlistsongsModel.count == 0 && playlistsongs.finished == true ? true : false
        anchors.margins: units.gu(1)
        anchors.fill: parent

        Label {
            id: noitemtitle
            anchors.centerIn: parent
            fontSize: "large"
            text: i18n.tr("<b>Add songs to your playlist</b>")
        }
        Label {
            anchors.top: noitemtitle.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            fontSize: "normal"
            text: i18n.tr("A full playlist is much more fun.")
        }
    }
}
