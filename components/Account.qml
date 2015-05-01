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
    id: account

    function recent() {
        Scripts.userRecentListens(uid);
    }

    Flickable {
        id: flick
        clip: true
        width: parent.width
        height: parent.height
        contentWidth: parent.width
        contentHeight: accountitem.height + recentListens.height + units.gu(1)

        Column {
            width: parent.width

            Column {
                id: accountitem
                width: parent.width - units.gu(2)
                x: units.gu(1)
                y: units.gu(1)

                Row {
                    width: parent.width
                    spacing: units.gu(1)
                    Rectangle {
                        id: image
                        width: units.gu(10)
                        height: units.gu(10)
                        color: "transparent"
                        Image {
                            width: units.gu(10)
                            height: units.gu(10)
                            source: "http://images.gs-cdn.net/static/users/" + picture
                        }
                    }

                    Label {
                        id: headerLabel
                        text: fname
                        fontSize: "x-large"
                    }
                }

                Item {
                    width: parent.width
                    height: units.gu(1)
                }
            }

            ListItem.Header {
                text: i18n.tr("Recent listens")
            }

            ListModel {
                id: recentListensModel
            }

            Repeater {
                id:recentListens
                clip: true

                model:recentListensModel
                ListItem.Empty {
                    width: parent.width
                    height: songtitle.height + songartistalbum.height + units.gu(3)
                    MouseArea {
                        width: parent.width
                        height: songtitle.height + songartistalbum.height + units.gu(1)
                        onClicked: {
                            queueModel.clear();
                            for (var i = 0; i < recentListensModel.count; i++) {
                                queueModel.append(recentListensModel.get(i));
                            }
                            current_song_index = index;
                            current_list = 'queue';
                            Scripts.play_song(id, name, title, artist_album, songImage);
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
                            width: parent.width
                            id: songtitle
                            text: title
                            color: playing_song == id ? '#F86F05' : UbuntuColors.darkGrey
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font.pointSize: playing_song == id ? units.gu(1.6) : units.gu(1.4)
                        }
                        Text {
                            anchors.top: songtitle.bottom
                            anchors.topMargin: units.gu(1)
                            anchors.bottomMargin: units.gu(1)
                            anchors.left: parent.left
                            anchors.leftMargin: units.gu(2)
                            anchors.rightMargin: units.gu(2)
                            width: parent.width
                            color: UbuntuColors.darkGrey
                            id: songartistalbum
                            text: artist_album
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font.pointSize: units.gu(1.2)
                        }
                    }
                }
            }
        }
    }
}
