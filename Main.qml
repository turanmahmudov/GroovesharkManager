import QtQuick 2.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.DownloadManager 0.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Content 0.1
import QtMultimedia 5.4
import QtQuick.LocalStorage 2.0
import "components"
import "js/scripts.js" as Scripts
import "js/sha1func.js" as Func

MainView {
    id: mainView
    objectName: "mainView"

    applicationName: "com.ubuntu.developer.turan.mahmudov.musicdownloader"

    automaticOrientation: true

    // Removes the old toolbar and enables new features of the new header.
    useDeprecatedToolbar: false

    anchorToKeyboard: true

    focus: true

    width: units.gu(50)
    height: units.gu(75)

    //backgroundColor: "#2C2C2C" //"#EDEDED"
    //headerColor: "#2c2c2c"

    actions: [
        Action {
            id: searchAction
            text: i18n.tr("Search")
            iconName: "search"
            onTriggered: {
                pagestack.push(searchPage);
            }
        },
        Action {
            id: accountAction
            text: is_logged ? i18n.tr("Profile") : i18n.tr("Sign in")
            iconName: "contact"
            onTriggered: {
                pagestack.clear();
                pagestack.push(tabs);
                if (is_logged) {
                    pagestack.push(accountPage);
                    accountpage.recent();
                } else {
                    pagestack.push(loginPage);
                }
            }
        },
        Action {
            id: collectionAction
            text: i18n.tr("Collection")
            iconName: "tick"
            onTriggered: {
                pagestack.clear();
                pagestack.push(tabs);
                pagestack.push(collectionsPage);
                collectionspage.get_lib();
            }
        },
        Action {
            id: favoritesAction
            text: i18n.tr("Favorites")
            iconName: "like"
            onTriggered: {
                pagestack.clear();
                pagestack.push(tabs);
                pagestack.push(favoritesPage);
                favoritespage.get_fav();
            }
        },
        Action {
            id: playlistsAction
            text: i18n.tr("Playlists")
            iconName: "media-playlist"
            onTriggered: {
                pagestack.clear();
                pagestack.push(tabs);
                pagestack.push(playlistsPage);
                playlistspage.get_playlists(uid);
            }
        },
        Action {
            id: logoutAction
            text: i18n.tr("Sign out")
            iconName: "lock"
            onTriggered: {
                Scripts.logout();
            }
        }
    ]

    property var contentTransfer;
    property list<ContentItem> transferItemList

    property var contentShare;
    property list<ContentItem> shareItemList

    property var playing_song : 0
    property var pausing_song : 0
    property var current_song_index
    property var current_list
    property var common_bmrgn : 0
    property var active_download : 0

    // Lyrics
    property var lyric_title
    property var lyric_text

    // Account
    property bool is_logged : false
    property var uid : ''
    property var fname : ''
    property var picture : '70_user.png'

    property var pl_songId : ''

    // Now playing
    property var nowPlayingSong : {"id":"", "SongTitle":"", "ArtistAlbum":"", "SongImage":""}

    property bool repeatSong : false
    property bool shuffleSongs : false

    // First run
    property var firstRun : getKey("firstRun")

    // 30 seconds
    property bool thirtyseconds : false

    // Song
    property var streamKey : ''
    property var streamServerID : ''

    // DB
    function _getGroovesharkDB() {
        return LocalStorage.openDatabaseSync("GroovesharkManager", "1.0", "Grooveshark Manager Database", 2048)
    }

    function initializeUser() {
        var user = _getGroovesharkDB();
        user.transaction(
                    function(tx) {
                        tx.executeSql('CREATE TABLE IF NOT EXISTS user(key TEXT UNIQUE, value TEXT)');
                    });
    }
    // This function is used to write a key into the database
    function setKey(key, value) {
        var db = _getGroovesharkDB();
        db.transaction(function(tx) {
            var rs = tx.executeSql('INSERT OR REPLACE INTO user VALUES (?,?);', [key,""+value]);
            if (rs.rowsAffected == 0) {
                throw "Error updating key";
            } else {
                //console.log("User record updated:"+key+" = "+value);
            }
        });
    }
    // This function is used to retrieve a key from the database
    function getKey(key) {
        var db = _getGroovesharkDB();
        var returnValue = undefined;

        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT value FROM user WHERE key=?;', [key]);
            if (rs.rows.length > 0)
              returnValue = rs.rows.item(0).value;
        })

        return returnValue;
    }
    // This function is used to delete a key from the database
    function deleteKey(key) {
        var db = _getGroovesharkDB();

        db.transaction(function(tx) {
            var rs = tx.executeSql('DELETE FROM user WHERE key=?;', [key]);
        })
    }

    // Home
    function home() {
        pagestack.clear();
        pagestack.push(tabs);

        if (firstRun != "1") {
            var comp = Qt.createComponent("components/Walkthrough/FirstRunWalkthrough.qml")
            var walkthrough = comp.createObject(pagestack, {});
            pagestack.push(walkthrough)
        }

        initializeUser();

        var uname = getKey("username");
        var pass = getKey("password");
        if (typeof uname !== "undefined" && typeof pass !== "undefined" && !is_logged) {
            Scripts.login(uname, pass);
        } else {
            homeWithoutLogin();
        }
    }

    function homeWithoutLogin() {
        popularsongspage.popular();
        broadcastspage.get_top_broadcasts_combined();
    }

    // Login dialog when login required
    Component {
        id: loginDialog

        Dialog {
            id: loginDialogue
            text: i18n.tr("You need to sign in to perform this action.")

            Button {
                text: i18n.tr("Close")
                color: "#F86F05"
                onClicked: {
                    PopupUtils.close(loginDialogue)
                }
            }
        }
    }

    // Error
    Component {
        id: errorDialog

        Dialog {
            id: errorDialogue
            text: i18n.tr("An error occured")

            Button {
                text: i18n.tr("Close")
                color: "#F86F05"
                onClicked: {
                    PopupUtils.close(errorDialogue)
                }
            }
        }
    }

    // Lyrics Dialog
    Component {
        id: lyricDialog

        Dialog {
            id: lyricDialogue
            title: lyric_title

            Flickable {
                id: flickable
                width: parent.width
                height: units.gu(35)
                clip: true
                contentHeight: lyricColumn.height

                Column {
                    id: lyricColumn
                    width: parent.width

                    Text {
                        width: parent.width
                        text: mainView.lyric_text
                        wrapMode: Text.WordWrap
                        font.pointSize: units.gu(1.32)
                    }
                }
            }

            Button {
                text: i18n.tr("Close")
                color: "#F86F05"
                onClicked: {
                    PopupUtils.close(lyricDialogue)
                }
            }
        }
    }

    // Add to playlists
    ListModel {
        id: aplayModel
    }
    Component {
        id: addtoplaylistDialog

        Popover {
            id: addtoplaylistDialogue
            Item {
                id: addtoplaylistLayout
                width: parent.width
                height: aplay.contentHeight > width ? width : aplay.contentHeight + units.gu(6)
                anchors {
                    left: parent.left
                    top: parent.top
                }

                Item {
                    id: playlistTools
                    height: createplbutton.height
                    width: parent.width

                    ListItem.Standard {
                        id: createplbutton
                        text: i18n.tr("Create playlist")
                        onClicked: {
                            PopupUtils.open(createPlaylistDialog, pagestack);
                            PopupUtils.close(addtoplaylistDialogue);
                        }
                    }
                }

                ListView {
                    id:aplay
                    anchors.top: playlistTools.bottom
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    clip: true

                    model:aplayModel
                    delegate: ListItem.Empty {
                        width: parent.width
                        height: pltitle.height + units.gu(3)
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
                                width: parent.width
                                id: pltitle
                                text: name
                                color: UbuntuColors.darkGrey
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                font.pointSize: units.gu(1.4)
                            }
                        }
                        onClicked: {
                            Scripts.add_song_to_playlist(id, mainView.pl_songId);
                            PopupUtils.close(addtoplaylistDialogue);
                            mainView.pl_songId = '';
                        }
                    }
                }
                Scrollbar {
                    flickableItem: aplay
                }
            }
        }
    }

    // Create playlist dialog
    Component {
        id: createPlaylistDialog

        Dialog {
            id: createPlaylistDialogue
            title: i18n.tr("Create playlist")

            Flickable {
                id: flickable
                width: parent.width
                height: units.gu(25)
                clip: true
                contentHeight: crtplylst.height

                Column {
                    id: crtplylst
                    width: parent.width

                    Label {
                        id: nameLabel
                        anchors.left: parent.left
                        anchors.top: parent.top
                        text: i18n.tr("Name:")
                    }
                    TextField {
                        id: name
                        width: parent.width
                        anchors.left: parent.left
                        anchors.top: nameLabel.bottom
                        anchors.topMargin: units.gu(1)
                    }
                    Label {
                        id: descLabel
                        anchors.left: parent.left
                        anchors.top: name.bottom
                        anchors.topMargin: units.gu(2)
                        text: i18n.tr("Description:")
                    }
                    TextArea {
                        id: desc
                        width: parent.width
                        anchors.left: parent.left
                        anchors.top: descLabel.bottom
                        anchors.topMargin: units.gu(1)
                    }
                }
            }

            Button {
                text: i18n.tr("Cancel")
                onClicked: {
                    PopupUtils.close(createPlaylistDialogue)
                }
            }

            Button {
                text: i18n.tr("Create")
                color: "#F86F05"
                onClicked: {
                    Scripts.create_playlist(name.text, desc.text, mainView.pl_songId);
                    PopupUtils.close(createPlaylistDialogue);
                }
            }
        }
    }

    // Rename downloaded song
    Component {
        id: transferComponent
        ContentItem { }
    }
    // Transfer downloaded song to Music app
    Component {
        id: downloadDialog
        ContentDownloadDialog { }
    }

    // Share
    Component {
        id: shareComponent
        ContentItem { }
    }
    // Share
    Component {
        id: shareDialog
        ContentShareDialog { }
    }

    Connections {
        target: ContentHub
        onExportRequested: {
            console.log("export requested");
        }
        onImportRequested: {
            console.log("import requested");
        }
    }

    Item {
        id: activityItem
        z: 100000
        anchors.centerIn: parent
        opacity: 0

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

    // Queue
    ListModel {
        id: queueModel
    }
    function playNextSong() {
        if (shuffleSongs) {
            current_song_index = getShuffleIndex();
        }

        var id = queueModel.get(current_song_index+1).id;
        var title = queueModel.get(current_song_index+1).name;
        var songname = queueModel.get(current_song_index+1).title;
        var artist_album = queueModel.get(current_song_index+1).artist_album;
        var songimage = queueModel.get(current_song_index+1).songImage;

        current_song_index = current_song_index+1;
        Scripts.play_song(id, title, songname, artist_album, songimage);
    }
    function playPrevSong() {
        if (shuffleSongs) {
            current_song_index = getShuffleIndex();
        }

        var id = queueModel.get(current_song_index-1).id;
        var title = queueModel.get(current_song_index-1).name;
        var songname = queueModel.get(current_song_index-1).title;
        var artist_album = queueModel.get(current_song_index-1).artist_album;
        var songimage = queueModel.get(current_song_index-1).songImage;

        current_song_index = current_song_index-1;
        Scripts.play_song(id, title, songname, artist_album, songimage);
    }
    function getShuffleIndex() {
        var newIndex;

        var now = new Date();
        var seed = now.getSeconds();

        do {
            newIndex = (Math.floor((queueModel.count)
                                   * Math.random(seed)));
        } while (newIndex === current_song_index && queueModel.count > 1)

        return newIndex;
    }
    function doRepeatSong() {
        var id = queueModel.get(current_song_index).id;
        var title = queueModel.get(current_song_index).name;
        var songname = queueModel.get(current_song_index).title;
        var artist_album = queueModel.get(current_song_index).artist_album;
        var songimage = queueModel.get(current_song_index).songImage;

        current_song_index = current_song_index;
        Scripts.play_song(id, title, songname, artist_album, songimage);
    }

    // Player
    Rectangle {
        id: playerr
        z: 100000
        visible: pagestack.currentPage.title !== i18n.tr("Now playing")
        width: parent.width
        height: units.gu(7)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(-7)
        color: "#191E28"
        Image {
            anchors.left: parent.left
            anchors.leftMargin: units.gu(1)
            anchors.top: parent.top
            anchors.topMargin: units.gu(1)
            height: source ? units.gu(5) : 0
            width: source ? height : 0
            id: track_image
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (playing_song != 'broadcast' && pagestack.currentPage.title !== i18n.tr("Queue")) {
                        pagestack.push(nowPlayingPage);
                    }
                }
            }
        }
        Text {
            id: track_title
            color: "white"
            font.bold: true
            font.pointSize: units.gu(1.3)
            anchors.top: parent.top
            anchors.topMargin: units.gu(1)
            anchors.left: track_image.source != "" ? track_image.right : parent.left
            anchors.leftMargin: units.gu(1)
            width: parent.width-controlsrow.width-units.gu(7)
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: 1
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (playing_song != 'broadcast' && pagestack.currentPage.title !== i18n.tr("Queue")) {
                        pagestack.push(nowPlayingPage);
                    }
                }
            }
        }
        Text {
            id: track_artist
            color: "white"
            font.pointSize: units.gu(1)
            anchors.top: track_title.bottom
            anchors.topMargin: units.gu(0.5)
            anchors.left: track_image.source != "" ? track_image.right : parent.left
            anchors.leftMargin: units.gu(1)
            width: parent.width-controlsrow.width-units.gu(7)
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: 1
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (playing_song != 'broadcast' && pagestack.currentPage.title !== i18n.tr("Queue")) {
                        pagestack.push(nowPlayingPage);
                    }
                }
            }
        }

        Rectangle {
            id: playingstate
            height: units.gu(0.3)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            color: "#F86F05"
            z: 100003
        }

        Rectangle {
            id: playingstatebuffer
            visible: false
            height: units.gu(0.3)
            width: mainView.width*player.bufferProgress
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            color: "#ffffff"
            z: 100002
        }

        Row {
            id: controlsrow
            z: 100000
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0
            Rectangle {
                z: 100000
                visible: playing_song == 'broadcast' ? false : true
                width: units.gu(3.5)
                height: playerr.height
                color: "transparent"
                Icon {
                    name: "media-skip-backward"
                    color: "#fff"
                    width: units.gu(2.5)
                    height: width
                    anchors.centerIn: parent
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                         Scripts.playPrevSong();
                    }
                }
            }
            Rectangle {
                z: 100000
                width: units.gu(3.5)
                height: playerr.height
                color: "transparent"
                Icon {
                    id: play_button
                    name: player.playbackState === MediaPlayer.PlayingState ? "media-playback-pause" : "media-playback-start"
                    color: "#fff"
                    width: units.gu(2.5)
                    height: width
                    anchors.centerIn: parent
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (player.playbackState === MediaPlayer.PlayingState) {
                            Scripts.pause_song(playing_song);
                        } else {
                            Scripts.unpause_song(playing_song);
                        }
                    }
                }
            }
            Rectangle {
                z: 100000
                visible: playing_song == 'broadcast' ? false : true
                width: units.gu(3.5)
                height: playerr.height
                color: "transparent"
                Icon {
                    name: "media-skip-forward"
                    color: "#fff"
                    width: units.gu(2.5)
                    height: width
                    anchors.centerIn: parent
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Scripts.playNextSong();
                    }
                }
            }
        }
    }
    NumberAnimation { id: playeropen; target: playerr; property: "anchors.bottomMargin"; duration: 200; from: units.gu(-7); to: 0; }

    SingleDownload {
        id: single
        property var title
        onDownloadIdChanged: {
        }
        onFinished: {
            // Path to move file
            var pathArray = path.split("/");
            var newpath = "";
            for (var i = 1; i < pathArray.length-1; i++) {
                newpath = newpath + "/" + pathArray[i];
            }

            // File
            var filename = single.title + ".mp3";
            filename = filename.replace("/", "_");
            filename = filename.replace("?", "_");

            mainView.contentTransfer = [];
            mainView.transferItemList = [transferComponent.createObject(mainView, {"url": path}) ]
            mainView.contentTransfer.items = mainView.transferItemList;
            mainView.contentTransfer.state = ContentTransfer.Charged;

            var importItems = mainView.contentTransfer.items;

            importItems[0].move(newpath, filename);

            mainView.active_download = 0

            PopupUtils.open(downloadDialog, pagestack, {"contentType" : ContentType.Music, "downloadId" : single.downloadId, "path" : newpath+"/"+filename})

        }
    }

    Audio {
        id: player
        onVolumeChanged: {  }
        onSourceChanged: {  }
        onStopped: {
            if(status == Audio.EndOfMedia) {
                // mark finished
                thirtyseconds = false;
                Scripts.markSongFinished(streamKey, streamServerID, playing_song);

                playingstate.width = 0;
                if (repeatSong) {
                    doRepeatSong();
                } else {
                    Scripts.playNextSong();
                }
            }
        }
        onPositionChanged: {
            playingstate.width=mainView.width*(position/duration);
            // mark 30 seconds
            if (position > "30000" && thirtyseconds == false) {
                thirtyseconds = true;
                Scripts.markStreamKeyOver30(streamKey, streamServerID, playing_song);
            }
        }
        onBufferProgressChanged: { }
        onPlaybackStateChanged: { }
    }

    PageStack {
        id: pagestack
        Component.onCompleted: home()

        Tabs {
            id: tabs
            Tab {
                title: i18n.tr("Popular")
                page: Page {
                    id: popularSongsPage
                    visible: true
                    head.actions: is_logged ? [searchAction, accountAction, collectionAction, favoritesAction, playlistsAction, logoutAction] : [searchAction, accountAction]

                    /*Rectangle {
                        z: -5
                        anchors.fill: parent
                        color: "#F5F5F5"
                    }*/

                    PopularSongs {
                        id:popularsongspage
                        anchors.fill:parent
                        anchors.bottomMargin: common_bmrgn
                    }
                }
            }

            Tab {
                title: i18n.tr("Broadcasts")
                page: Page {
                    id: broadcastsPage
                    visible: true
                    head.actions: is_logged ? [searchAction, accountAction, collectionAction, favoritesAction, playlistsAction, logoutAction] : [searchAction, accountAction]

                    Broadcasts {
                        id:broadcastspage
                        anchors.fill:parent
                        anchors.bottomMargin: common_bmrgn
                    }
                }
            }

            Tab {
                title: i18n.tr("About")
                page: Page {
                    id: aboutPage
                    visible: true
                    head.actions: is_logged ? [searchAction, accountAction, collectionAction, favoritesAction, playlistsAction, logoutAction] : [searchAction, accountAction]

                    About {
                        id:aboutpage
                        anchors.fill:parent
                        anchors.bottomMargin: common_bmrgn
                    }
                }
            }
        }

        Page {
            id: searchPage
            title: i18n.tr("Search")
            visible: false

            Search {
                id: searchpage
                anchors.fill: parent
                anchors.bottomMargin: common_bmrgn
            }
        }

        Page {
            id: foundSongs
            title: i18n.tr("Search results")
            visible: false

            FoundSongs {
                id:foundsongspage
                anchors.fill:parent
                anchors.bottomMargin: common_bmrgn
            }
        }

        Page {
            id: albumPage
            visible: false
            head.actions: is_logged ? [searchAction, accountAction, collectionAction, favoritesAction, playlistsAction, logoutAction] : [searchAction, accountAction]

            AlbumPage {
                id:albumpage
                anchors.fill:parent
                anchors.bottomMargin: common_bmrgn
            }
        }

        Page {
            id: artistPage
            visible: false
            head.actions: is_logged ? [searchAction, accountAction, collectionAction, favoritesAction, playlistsAction, logoutAction] : [searchAction, accountAction]

            head {
                sections {
                    model: ["Albums", "Songs"]
                    onSelectedIndexChanged: {
                        artistpage.secCh(artistPage.head.sections.selectedIndex)
                    }
                }
            }

            ArtistPage {
                id:artistpage
                anchors.fill:parent
                anchors.bottomMargin: common_bmrgn
            }
        }

        Page {
            id: loginPage
            title: i18n.tr("Sign in")
            visible: false
            head.actions: [searchAction]

            Login {
                id:loginpage
                anchors.fill:parent
                anchors.bottomMargin: common_bmrgn
            }
        }

        Page {
            id: accountPage
            title: i18n.tr("Profile")
            visible: false
            head.actions: is_logged ? [searchAction, collectionAction, favoritesAction, playlistsAction, logoutAction] : [searchAction]

            Account {
                id:accountpage
                anchors.fill:parent
                anchors.bottomMargin: common_bmrgn
            }
        }

        Page {
            id: collectionsPage
            title: i18n.tr("Collection")
            visible: false
            head.actions: is_logged ? [searchAction, accountAction, favoritesAction, playlistsAction, logoutAction] : [searchAction, accountAction]

            Collections {
                id:collectionspage
                anchors.fill:parent
                anchors.bottomMargin: common_bmrgn
            }
        }

        Page {
            id: favoritesPage
            title: i18n.tr("Favorites")
            visible: false
            head.actions: is_logged ? [searchAction, accountAction, collectionAction, playlistsAction, logoutAction] : [searchAction, accountAction]

            Favorites {
                id:favoritespage
                anchors.fill:parent
                anchors.bottomMargin: common_bmrgn
            }
        }

        Page {
            id: playlistsPage
            title: i18n.tr("Playlists")
            visible: false
            head.actions: is_logged ? [searchAction, accountAction, collectionAction, favoritesAction, logoutAction] : [searchAction, accountAction]

            Playlists {
                id:playlistspage
                anchors.fill:parent
                anchors.bottomMargin: common_bmrgn
            }
        }

        Page {
            id: playlistPage
            title: i18n.tr("Playlist")
            visible: false
            head.actions: is_logged ? [searchAction, accountAction, collectionAction, favoritesAction, playlistsAction, logoutAction] : [searchAction, accountAction]

            Playlist {
                id:playlistpage
                anchors.fill:parent
                anchors.bottomMargin: common_bmrgn
            }
        }

        Page {
            id: nowPlayingPage
            title: i18n.tr("Now playing")
            visible: false
            head.actions: [
                Action {
                    id: gotoQueueAction
                    iconName: "view-list-symbolic"
                    onTriggered: {
                        pagestack.push(queuePage);
                    }
                }
            ]

            NowPlaying {
                id: nowplayingpage
                anchors.fill: parent
            }
        }

        Page {
            id: queuePage
            title: i18n.tr("Queue")
            visible: false
            head.actions: [
                Action {
                    id: clearQueueAction
                    iconName: "delete"
                    onTriggered: {
                        queueModel.clear();

                        mainView.common_bmrgn = units.gu(0);
                        playerr.anchors.bottomMargin = units.gu(-7);

                        player.stop();
                        mainView.pausing_song = 0;
                        mainView.playing_song = 0;

                        track_title.text = '';
                        track_artist.text = '';
                        track_image.source = '';

                        pagestack.clear();
                        pagestack.push(tabs);
                    }
                }
            ]

            QueuePage {
                id: queuepage
                anchors.fill: parent
                anchors.bottomMargin: common_bmrgn
            }
        }
    }
}

