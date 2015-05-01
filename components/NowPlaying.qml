import QtQuick 2.0
import Ubuntu.Components 1.1
import QtMultimedia 5.0
import Ubuntu.Components.Popups 1.0
import Ubuntu.Content 0.1
import "../js/scripts.js" as Scripts
import "../js/sha1func.js" as Func

Item {
    id: nowPlaying

    property var np_id : queueModel.count > 0 ? queueModel.get(current_song_index).id : ''
    property var np_title : queueModel.count > 0 ? queueModel.get(current_song_index).title : ''
    property var np_name : queueModel.count > 0 ? queueModel.get(current_song_index).name : ''
    property var np_artistName : queueModel.count > 0 ? queueModel.get(current_song_index).artistName : ''
    property var np_artistId : queueModel.count > 0 ? queueModel.get(current_song_index).artistId : ''
    property var np_albumName : queueModel.count > 0 ? queueModel.get(current_song_index).albumName : ''
    property var np_albumId : queueModel.count > 0 ? queueModel.get(current_song_index).albumId : ''
    property var np_is_fav : queueModel.count > 0 ? queueModel.get(current_song_index).is_fav : ''
    property var np_is_lib : queueModel.count > 0 ? queueModel.get(current_song_index).is_lib : ''
    property var np_trackNum : queueModel.count > 0 ? queueModel.get(current_song_index).trackNum : ''

    function durationToString(duration) {
        var minutes = Math.floor((duration/1000) / 60);
        var seconds = Math.floor((duration/1000)) % 60;
        // Make sure that we never see "NaN:NaN"
        if (minutes.toString() == 'NaN')
            minutes = 0;
        if (seconds.toString() == 'NaN')
            seconds = 0;
        return minutes + ":" + (seconds<10 ? "0"+seconds : seconds);
    }

    Connections {
        target: single

        onFinished: {
            console.log("bitdi")
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

    Item {
        id: covertArtBackground
        width: parent.width
        height: parent.width > parent.height ? parent.height - units.gu(18) : parent.width - units.gu(2)

        Rectangle {
            id: coverImage
            width: parent.width
            height: parent.height
            color: "transparent"

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                clip: true
                source: nowPlayingSong.SongImage ? "http://images.gs-cdn.net/static/albums/"+nowPlayingSong.SongImage :
                                                   "../graphics/500_album.png"
            }
        }

        Rectangle {
            id: labelsBackground
            anchors.bottom: parent.bottom
            color: "#191E28"
            height: songTitle.lineCount === 1 ? units.gu(10) : units.gu(13)
            opacity: 0.8
            width: parent.width
        }

        Column {
            id: labels
            spacing: units.gu(1)
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                right: parent.right
                rightMargin: units.gu(2)
                top: labelsBackground.top
                topMargin: songTitle.lineCount === 1 ? units.gu(2) : units.gu(1.5)
            }

            Label {
                id: songTitle
                anchors {
                    left: parent.left
                    leftMargin: units.gu(1)
                    right: parent.right
                    rightMargin: units.gu(1)
                }
                color: "#ffffff"
                elide: Text.ElideRight
                fontSize: "x-large"
                maximumLineCount: 2
                text: nowPlayingSong.SongTitle
                wrapMode: Text.WordWrap
            }

            Label {
                id: songArtistAlbum
                anchors {
                    left: parent.left
                    leftMargin: units.gu(1)
                    right: parent.right
                    rightMargin: units.gu(1)
                }
                color: "#ffffff"
                elide: Text.ElideRight
                fontSize: "small"
                text: nowPlayingSong.ArtistAlbum
            }
        }

        /* Detect cover art swipe */
        MouseArea {
            anchors.fill: parent
            property string direction: "None"
            property real lastX: -1

            onPressed: lastX = mouse.x

            onReleased: {
                var diff = mouse.x - lastX
                if (Math.abs(diff) < units.gu(4)) {
                    return;
                } else if (diff < 0) {
                    Scripts.playNextSong()
                } else if (diff > 0) {
                    Scripts.playPrevSong()
                }
            }
        }
    }

    Rectangle {
        id: toolbarBackground
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            top: covertArtBackground.bottom
        }
        color: "#191E28"
    }

    Rectangle {
        id: detailed
        visible: true
        width: parent.width
        height: units.gu(7)
        anchors.top: covertArtBackground.bottom
        anchors.left: parent.left
        color: "#191E28"
        Rectangle {
            id: downloadingstate
            height: parent.height
            width: active_download == np_id ?
                       (parent.width/(100/single.progress)) :
                       0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            color: "#F86F05"
        }
        Flickable {
            id: flickableh

            anchors.fill: parent
            contentWidth: buttons.width;
            contentHeight: flickableh.height
            Item {
                id: buttons
                width: active_download == 0 ?
                           downloadButton.width + externalButton.width + lyricsButton.width + artistButton.width + albumButton.width + favButton.width + collectionButton.width + pylButton.width + shareButton.width + buyButton.width + units.gu(36) + units.gu(6) :
                           parent.width
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
                        name: active_download == np_id ? "cancel" : "save"
                        color: "#fff"
                    }
                    Label {
                        id: downloadLabel
                        text: active_download == np_id ? "Cancel" : "Download"
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
                                Scripts.download_song(np_id, np_name);
                                active_download = np_id;
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
                            } else if (active_download == np_id) {
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
                            artistPage.title = np_artistName;
                            artistpage.artistId = np_artistId;
                            artistpage.artist_albums(np_artistId);
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
                            albumPage.title = np_albumName;
                            albumpage.albumId = np_albumId;
                            albumpage.album(np_albumId);
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
                        color: np_is_fav == 1 ? "#ff0000" : "#fff"
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
                            if (np_is_fav == 1) {
                                Scripts.remove_from_fav(np_id, 'queue');
                            } else {
                                Scripts.add_to_fav(np_id, 'queue');
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
                        color: np_is_lib == 1 ? "#00ff00" : "#fff"
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
                            if (np_is_lib == 1) {
                                Scripts.remove_from_lib(np_id, np_albumId, np_artistId, uid, 'queue');
                            } else {
                                var song_data = [{
                                    'songID' : np_id,
                                    'songName' : np_title,
                                    'artistName' : np_artistName,
                                    'artistID' : np_artistId,
                                    'albumName' : np_albumName,
                                    'albumID' : np_albumId,
                                    'track' : np_trackNum
                                    }];
                                Scripts.add_to_lib(song_data, 'queue');
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
                                pl_songId = np_id;
                                Scripts.aget_playlists(mainView.uid);
                                // TODO : popup must be stay in center
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
                            Scripts.getLyrics(np_artistName, np_title);
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
                            Scripts.link_song_ex(np_id, np_title);
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
                            Scripts.share_song_ex(np_id, np_title);
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
                            Qt.openUrlExternally("scope://com.canonical.scopes.amazon?q="+np_artistName+" "+np_title);
                        }
                    }
                }
            }
        }
    }

    Item {
        id: toolbarContainer
        anchors.left: parent.left
        anchors.leftMargin: units.gu(3)
        anchors.right: parent.right
        anchors.rightMargin: units.gu(3)
        anchors.top: detailed.bottom
        height: units.gu(2)
        width: parent.width

        Label {
            id: toolbarPositionLabel
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: units.gu(1.4)
            color: "#ffffff"
            fontSize: "small"
            height: parent.height
            horizontalAlignment: Text.AlignHCenter
            text: durationToString(player.position)
            verticalAlignment: Text.AlignVCenter
            width: units.gu(3)
        }

        Rectangle {
            id: progressSlider
            anchors.left: toolbarPositionLabel.right
            anchors.leftMargin: units.gu(2)
            anchors.top: parent.top
            anchors.topMargin: units.gu(2.2)
            height: units.gu(0.5)
            width: 0
            color: "#F86F05"
        }

        Rectangle {
            id: progressSliderBack
            anchors.left: toolbarPositionLabel.right
            anchors.leftMargin: units.gu(2)
            anchors.right: toolbarDurationLabel.left
            anchors.rightMargin: units.gu(2)
            anchors.top: parent.top
            anchors.topMargin: units.gu(2.2)
            height: units.gu(0.5)
            color: "#fff"
            opacity: 0.1

            Connections {
                target: player
                onPositionChanged: {
                    progressSlider.width = progressSliderBack.width*(player.position/player.duration);

                    toolbarPositionLabel.text = durationToString(player.position)
                    toolbarDurationLabel.text = durationToString(player.duration)
                }
                onStopped: {
                    toolbarPositionLabel.text = durationToString(0);
                    toolbarDurationLabel.text = durationToString(0);
                }
            }
        }

        /* Duration label */
        Label {
            id: toolbarDurationLabel
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: units.gu(1.4)
            color: "#ffffff"
            fontSize: "small"
            height: parent.height
            horizontalAlignment: Text.AlignHCenter
            text: durationToString(player.duration)
            verticalAlignment: Text.AlignVCenter
            width: units.gu(3)
        }
    }

    /* Full toolbar */
    Rectangle {
        id: musicToolbarFullContainer
        anchors.bottom: parent.bottom
        color: "#191E28"
        height: units.gu(7)
        width: parent.width

        /* Repeat button */
        MouseArea {
            id: nowPlayingRepeatButton
            anchors.right: nowPlayingPreviousButton.left
            anchors.rightMargin: units.gu(1)
            anchors.verticalCenter: nowPlayingPlayButton.verticalCenter
            height: units.gu(6)
            opacity: repeatSong ? 1 : .4
            width: height
            onClicked: repeatSong = !repeatSong

            Icon {
                id: repeatIcon
                height: units.gu(3)
                width: height
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                color: "white"
                name: "media-playlist-repeat"
                opacity: repeatSong ? 1 : .4
            }
        }

        /* Previous button */
        MouseArea {
            id: nowPlayingPreviousButton
            anchors.right: nowPlayingPlayButton.left
            anchors.rightMargin: units.gu(1)
            anchors.verticalCenter: nowPlayingPlayButton.verticalCenter
            height: units.gu(6)
            opacity: 1
            width: height
            onClicked: Scripts.playPrevSong()

            Icon {
                id: nowPlayingPreviousIndicator
                height: units.gu(3)
                width: height
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                color: "white"
                name: "media-skip-backward"
                opacity: 1
            }
        }

        /* Play/Pause button */
        MouseArea {
            id: nowPlayingPlayButton
            anchors.centerIn: parent
            height: units.gu(6)
            width: height
            onClicked: {
                if (player.playbackState === MediaPlayer.PlayingState) {
                    Scripts.pause_song(playing_song);
                } else {
                    Scripts.unpause_song(playing_song);
                }
            }

            Icon {
                id: nowPlayingPlayIndicator
                height: units.gu(5)
                width: height
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 1
                color: "white"
                name: player.playbackState === MediaPlayer.PlayingState ?
                          "media-playback-pause" :
                          "media-playback-start"
            }
        }

        /* Next button */
        MouseArea {
            id: nowPlayingNextButton
            anchors.left: nowPlayingPlayButton.right
            anchors.leftMargin: units.gu(1)
            anchors.verticalCenter: nowPlayingPlayButton.verticalCenter
            height: units.gu(6)
            opacity: 1
            width: height
            onClicked: Scripts.playNextSong()

            Icon {
                id: nowPlayingNextIndicator
                height: units.gu(3)
                width: height
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                color: "white"
                name: "media-skip-forward"
                opacity: 1
            }
        }

        /* Shuffle button */
        MouseArea {
            id: nowPlayingShuffleButton
            anchors.left: nowPlayingNextButton.right
            anchors.leftMargin: units.gu(1)
            anchors.verticalCenter: nowPlayingPlayButton.verticalCenter
            height: units.gu(6)
            opacity: shuffleSongs ? 1 : .4
            width: height
            onClicked: shuffleSongs = !shuffleSongs

            Icon {
                id: shuffleIcon
                height: units.gu(3)
                width: height
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                color: "white"
                name: "media-playlist-shuffle"
                opacity: shuffleSongs ? 1 : .4
            }
        }
    }
}
