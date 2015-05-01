function get_track(query) {
    search_songs(query);
}

function search_songs(query) {
    foundsongsModel.clear();
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var type = 'Songs';
            var method = 'getResultsFromSearch';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('getResultsFromSearch', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'type' : type, 'query' : query}
            }


            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    var result = JSON.parse(xhr.responseText)['result']['result'];
                    var len = objLength(result);
                    var i;
                    for (var i = 0; i < len; i++) {
                        var id = result[i]['SongID'];
                        var artistName = result[i]['ArtistName'];
                        var artistId = result[i]['ArtistID'];
                        var songName = result[i]['SongName'];
                        var albumName = result[i]['AlbumName'];
                        var albumId = result[i]['AlbumID'];
                        var trackNum = result[i]['TrackNum'];
                        var songImage = result[i]['CoverArtFilename'] ? result[i]['CoverArtFilename'] : "";
                        foundsongsModel.append({"title":songName, "artist_album":artistName + ' - ' + albumName, "name":artistName + ' - ' + songName, "id":id, "ii":i, "artistName" : artistName, "artistId" : artistId, "albumName" : albumName, "albumId": albumId, "trackNum": trackNum, "is_fav":0, "is_lib":0, "songImage":songImage});
                    }

                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

function get_song_link_ex_by_id(callback, id, title) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'getStreamKeyFromSongIDEx';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('getStreamKeyFromSongIDEx', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'type' : 0, 'prefetch' : false, 'songID' : id, 'country' : token['country'], 'mobile' : false}
            }

            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    var result = JSON.parse(xhr.responseText)['result'];
                    var fileToken = result["FileToken"];
                    callback(fileToken, title);
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        };
    });
}

function download(url, title, id) {
    single.title = title;
    single.download(url);
}

function link_ex(title, fileToken) {
    var name = encodeURIComponent(title);
    var url = "http://grooveshark.com/s/"+name+"/"+fileToken;

    Qt.openUrlExternally(url);
}

function download_song(id, title) {
    var url = get_song_url_by_id(function (url, title, id) {
        download(url, title, id);
    }, id, title);
}

function play_song(id, title, songtitle, artist_album, simage) {
    activityItem.opacity = 1;

    var url = get_song_url_by_id(function (url, title, id, songtitle, artist_album, streamServerID, streamKey) {
        play(url, title, id, songtitle, artist_album, simage);
        // mark song downloaded
        markSongDownloaded(streamKey, streamServerID, id);
        mainView.streamKey = streamKey;
        mainView.streamServerID = streamServerID;
    }, id, title, songtitle, artist_album, simage);
}

function play(url, title, id, songtitle, artist_album, songimage) {
    mainView.nowPlayingSong = {"id":id, "SongTitle":songtitle, "ArtistAlbum":artist_album, "SongImage":songimage};

    if (mainView.pausing_song == 0 && mainView.playing_song == 0) {
        playeropen.start();
        mainView.common_bmrgn = units.gu(7);
    }

    player.source = url;
    player.play();
    mainView.pausing_song = 0;
    mainView.playing_song = id;
    broadcastspage.playing_bcast = 0;

    track_title.text = songtitle;
    track_artist.text = artist_album;
    if (songimage && songimage != "") {
        track_image.source = "http://images.gs-cdn.net/static/albums/70_"+songimage;
    } else {
        track_image.source = "../graphics/70_album.png"
    }

    activityItem.opacity = 0;
}

function get_song_url_by_id(callback, id, title, songtitle, artist_album, songimage) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'getStreamKeyFromSongIDEx';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('getStreamKeyFromSongIDEx', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'type' : 0, 'prefetch' : false, 'songID' : id, 'country' : token['country'], 'mobile' : false}
            }

            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);

                    var j;
                    for (j in results) {
                        if (j == 'result') {
                            var ip = results[j]['ip'];
                            var streamKey = results[j]['streamKey'];
                            var url = 'http://'+ip+'/stream.php?streamKey='+streamKey;
                            var fileToken = results[j]['FileToken'];
                            var streamServerID = results[j]['streamServerID'];
                            callback(url, title, id, songtitle, artist_album, streamServerID, streamKey);
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        };
    });
}

function markSongDownloaded(streamKey, streamServerID, songID) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'markSongDownloadedEx';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('markSongDownloadedEx', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'type' : 0, 'prefetch' : false, "streamKey":streamKey,"streamServerID":streamServerID,"songID":songID, 'country' : token['country'], 'mobile' : false}
            }

            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    // Must be edit
                    //console.log(xhr.responseText);
                }
            };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        };
    });
}

// 30 seconds finished
function markStreamKeyOver30(streamKey, streamServerID, songID) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'markStreamKeyOver30Seconds';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('markStreamKeyOver30Seconds', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'type' : 0, 'prefetch' : false, "streamKey":streamKey,"streamServerID":streamServerID,"songID":songID, 'country' : token['country'], 'mobile' : false}
            }

            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    // Must be edit
                    //console.log(xhr.responseText);
                }
            };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        };
    });
}

// mark finished
function markSongFinished(streamKey, streamServerID, songID) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'markSongComplete';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('markSongComplete', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'type' : 0, 'prefetch' : false, "streamKey":streamKey,"streamServerID":streamServerID,"songID":songID, 'country' : token['country'], 'mobile' : false}
            }

            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    // Must be edit
                    //console.log(xhr.responseText);
                }
            };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        };
    });
}

function link_song_ex(id, title) {
    var url = get_song_link_ex_by_id(function (fileToken, title) {
        link_ex(title, fileToken);
    }, id, title);
}

// Share
function share_song_ex(id, title) {
    var url = get_song_link_ex_by_id(function (fileToken, title) {
        share_ex(title, fileToken);
    }, id, title);
}
function share_ex(title, fileToken) {
    var name = encodeURIComponent(title);
    var url = "http://grooveshark.com/s/"+name+"/"+fileToken;

    PopupUtils.open(shareDialog, pagestack, {"contentType" : ContentType.Links, "path" : url});
}

function pause_song(id) {
    player.pause();
    mainView.pausing_song = id;
}

function unpause_song(id) {
    player.play();
    mainView.pausing_song = 0;
}

function playNextSong() {
    if (mainView.current_list == 'queue') {
        mainView.playNextSong();
    }
}

function playPrevSong() {
    if (mainView.current_list == 'queue') {
        mainView.playPrevSong();
    }
}

function generate_guid() {
    var d = new Date().getTime();
    var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = (d + Math.random()*16)%16 | 0;
        d = Math.floor(d/16);
        return (c=='x' ? r : (r&0x7|0x8)).toString(16);
    });
    return uuid;
}

function get_token_data(callback) {
    var url = 'http://grooveshark.com/preload.php?&getCommunicationToken=1&hash=%2F';

    var xhr = new XMLHttpRequest();
    xhr.open('GET', url, true);
    xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
            // Must be edit
            var response = xhr.responseText;

            var token_data_json = response.match(/window.tokenData = (.*);/)[1];
            if (!token_data_json) {
                show_error('Token data not found!');
            } else {
                var token_data = JSON.parse(token_data_json);
                var comm_token = token_data['getCommunicationToken'];
                var comm_token_ttl = Math.round((new Date()).getTime() / 1000);
                var config = token_data['getGSConfig'];
                var country = config['country'];
                var session = config['sessionID'];

                var token = {
                    comm_token : comm_token,
                    comm_token_ttl : comm_token_ttl,
                    country : country,
                    session : session
                };
                callback(token);
            }
        }
    }
    // send
    xhr.send();
}

function create_token(method, comm_token, type) {
    var salt = "gooeyFlubber";
    if (type == "htmlshark") {
        salt = "nuggetsOfBaller";
    }
    var rnd = get_random_hex_chars(6);
    var plain = [method, comm_token, salt, rnd].join(':');
    var hash = Func.sha1(plain);

    var result = rnd + hash;
    return result;
}

function get_random_hex_chars(length) {
    var chars = ['a', 'b', 'c', 'd', 'e', 'f', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    var text = '';
    for( var i=0; i < length; i++ ) {
        text += chars[Math.floor(Math.random() * chars.length)];
    }
    return text;

}

function to_obj(str) {
    //var myObject = '[' + str + ']';
    //return myObject;
    return '[' + str + ']';
}

function popular_songs() {
    popularsongsModel.clear();
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var type = 'daily';
            var method = 'popularGetSongs';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('popularGetSongs', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'type' : type}
            }


            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    var results = JSON.parse(xhr.responseText);

                    var j;
                    for (j in results) {
                        if (j == 'result') {
                            var k;
                            for (k in results[j]) {
                                if (k == 'Songs') {
                                    var i;
                                    var ii = 0;
                                    for (i in results[j][k]) {
                                        var id = results[j][k][i]['SongID'];
                                        var artistName = results[j][k][i]['ArtistName'];
                                        var artistId = results[j][k][i]['ArtistID'];
                                        var songName = results[j][k][i]['Name'];
                                        var albumName = results[j][k][i]['AlbumName'];
                                        var albumId = results[j][k][i]['AlbumID'];
                                        var trackNum = results[j][k][i]['TrackNum'];
                                        var songImage = results[j][k][i]['CoverArtFilename'] ? results[j][k][i]['CoverArtFilename'] : "";
                                        popularsongsModel.append({"title":songName, "artist_album":artistName + ' - ' + albumName, "name":artistName + ' - ' + songName, "id":id, "ii":ii, "artistName" : artistName, "artistId" : artistId, "albumName" : albumName, "albumId": albumId, "trackNum": trackNum, "is_fav":0, "is_lib":0, "songImage":songImage});
                                        ii++;
                                    }
                                }
                            }
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

function objLength(obj){
  var i=0;
  for (var x in obj){
    if(obj.hasOwnProperty(x)){
      i++;
    }
  }
  return i;
}

function nFormatter(num) {
    if (num >= 1000000000) {
        return (num / 1000000000).toFixed(1).replace(/\.0$/, '') + 'G';
    }
    if (num >= 1000000) {
        return (num / 1000000).toFixed(1).replace(/\.0$/, '') + 'M';
    }
    if (num >= 1000) {
        return (num / 1000).toFixed(1).replace(/\.0$/, '') + 'K';
    }
    return num + '';

}

function nl2br (str, is_xhtml) {
  var breakTag = (is_xhtml || typeof is_xhtml === 'undefined') ? '<br ' + '/>' : '<br>'; // Adjust comment to avoid issue on phpjs.org display

  return (str + '').replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n)/g, '$1' + breakTag + '$2');
}

function getLyrics(artist, song) {
    activityItem.opacity = 1;
    var url = "http://api.chartlyrics.com/apiv1.asmx/SearchLyricDirect?artist=" + artist + "&song=" + song;

    var xhr = new XMLHttpRequest();
    xhr.open('GET', url);
    xhr.onreadystatechange = function() {
        if (xhr.readyState == 4) {
            activityItem.opacity = 0;
            if (xhr.status == 200) {
                var root = xhr.responseText;
                var lyric = root.split("<Lyric>");
                lyric = lyric[1].split("</Lyric>");
                lyric = lyric[0];
                mainView.lyric_text = lyric;
                mainView.lyric_title = artist + " - " + song;
                PopupUtils.open(lyricDialog, mainView, {"lyric_text" : lyric, "lyric_title" : artist + " - " + song});
            }
        }
    };

    xhr.send();
}

function album_songs(albumId) {
    albumsongsModel.clear();
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var type = albumId;
            var method = 'albumGetAllSongs';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('albumGetAllSongs', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'albumID' : type}
            }


            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);
                    var result = results["result"];

                    var len = objLength(result);
                    for (var i = 0; i < len; i++) {
                        var id = result[i]['SongID'];
                        var artistName = result[i]['ArtistName'];
                        var artistId = result[i]['ArtistID'];
                        var songName = result[i]['Name'];
                        var albumName = result[i]['AlbumName'];
                        var albumId = result[i]['AlbumID'];
                        var trackNum = result[i]['TrackNum'];
                        var songImage = result[i]['CoverArtFilename'] ? result[i]['CoverArtFilename'] : "";
                        albumsongsModel.append({"title":songName, "artist_album":artistName + ' - ' + albumName, "name":artistName + ' - ' + songName, "id":id, "ii":i, "artistName" : artistName, "artistId" : artistId, "albumName" : albumName, "albumId": albumId, "trackNum": trackNum, "is_fav":0, "is_lib":0, "songImage":songImage});
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

function artist_albums(artistId) {
    artistalbumsModel.clear();
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var type = artistId;
            var method = 'artistGetAllAlbums';
            var data = {
                'header' : {
                  'client' : 'htmlshark',
                  'clientRevision' : '20130520',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('artistGetAllAlbums', token['comm_token'], "htmlshark"),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'artistID' : type}
            }


            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);
                    var result = results["result"]['albums'];

                    var len = objLength(result);
                    for (var i = 0; i < len; i++) {
                        if ((result[i]['ReleaseType'] == "1" || result[i]['ReleaseType'] == "2" || result[i]['ReleaseType'] == "3" || result[i]['ReleaseType'] == "0")) {
                            var id = result[i]['AlbumID'];
                            var artistId = result[i]['ArtistID'];
                            var albumName = result[i]['Name'];
                            var albumCover = result[i]['CoverArtFilename'];
                            if (!albumCover) {
                                albumCover = '500_album.png'
                            }
                            var albumCoverUrl = 'http://images.gs-cdn.net/static/albums/' + albumCover;
                            var albumYear = result[i]['Year'];
                            artistalbumsModel.append({"id":id, "title" : albumName, "artistId" : artistId, "albumCover" : albumCoverUrl, "year":albumYear});
                        }
                    }
                    var n;
                    var j;
                    for (n=0; n < artistalbums.count; n++) {
                        for (j=n+1; j < artistalbums.count; j++)
                        {
                            if (artistalbums.model.get(n).year < artistalbums.model.get(j).year)
                            {
                                artistalbums.model.move(j, n, 1);
                                n=0;
                            }
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

function artist_songs(artistId) {
    artistsongsModel.clear();
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var type = artistId;
            var method = 'artistGetArtistSongs';
            var data = {
                'header' : {
                  'client' : 'htmlshark',
                  'clientRevision' : '20130520',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('artistGetArtistSongs', token['comm_token'], "htmlshark"),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'artistID' : type}
            }


            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);
                    var result = results["result"];

                    var len = objLength(result);
                    for (var i = 0; i < len; i++) {
                        var id = result[i]['SongID'];
                        var artistName = result[i]['ArtistName'];
                        var artistId = result[i]['ArtistID'];
                        var songName = result[i]['Name'];
                        var albumName = result[i]['AlbumName'];
                        var albumId = result[i]['AlbumID'];
                        var trackNum = result[i]['TrackNum'];
                        var songImage = result[i]['CoverArtFilename'] ? result[i]['CoverArtFilename'] : "";
                        artistsongsModel.append({"title":songName, "artist_album":artistName + ' - ' + albumName, "name":artistName + ' - ' + songName, "id":id, "ii":i, "artistName" : artistName, "artistId" : artistId, "albumName" : albumName, "albumId": albumId, "trackNum": trackNum, "is_fav":0, "is_lib":0, "songImage":songImage});
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

// Broadcasts
function get_top_broadcasts_combined() {
    broadcastsModel.clear();
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'getTopBroadcastsCombined';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('getTopBroadcastsCombined', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {}
            }


            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    var results = JSON.parse(xhr.responseText);

                    var j;
                    for (j in results) {
                        if (j == 'result') {
                            var i;
                            for (i in results[j]) {
                                var id = results[j][i]['id'];
                                var name = results[j][i]['n'];
                                var l;
                                for (l in results[j][i]) {
                                    if (l == 't') {
                                        var tagName = results[j][i][l]['n'];
                                    }
                                }
                                var listenersCount = nFormatter(results[j][i]['subscribers_count']);
                                var ownerName = results[j][i]['users'][0]['FName'];
                                broadcastsModel.append({"id":id, "title":name, "tagName":tagName, "listenersCount":listenersCount, "ownerName":ownerName});
                            }
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
            xhr.setRequestHeader("Accept", "application/json");

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}
function get_top_broadcasts(genre) {
    broadcastsModel.clear();
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'getTopBroadcasts';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('getTopBroadcasts', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {"manateeTags":[genre]}
            }


            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    var results = JSON.parse(xhr.responseText);

                    var j;
                    for (j in results) {
                        if (j == 'result') {
                            var k;
                            for (k in results[j]) {
                                if (k == genre) {
                                    var i;
                                    for (i in results[j][k]) {
                                        var id = results[j][k][i]['id'];
                                        var name = results[j][k][i]['n'];
                                        var l;
                                        for (l in results[j][k][i]) {
                                            if (l == 't') {
                                                var tagName = results[j][k][i][l]['n'];
                                            }
                                        }
                                        var listenersCount = nFormatter(results[j][k][i]['subscribers_count']);
                                        var ownerName = results[j][k][i]['users'][0]['FName'];
                                        broadcastsModel.append({"id":id, "title":name, "tagName":tagName, "listenersCount":listenersCount, "ownerName":ownerName});
                                    }
                                }
                            }
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}
function get_mobile_broadcast_url(broadcast_id, title, tagName) {
    //artistsongsModel.clear();
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'getMobileBroadcastURL';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('getMobileBroadcastURL', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {"broadcastID":broadcast_id}
            }


            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);

                    var j;
                    for (j in results) {
                        if (j == 'result') {
                            if (results[j] == false) {
                                get_mobile_broadcast_url(broadcast_id, title, tagName);
                            } else {
                                var url = results[j]['url'];
                                var key = results[j]['key'];

                                var last_url = url + '?sid=' + key;
                                if (mainView.pausing_song == 0 && mainView.playing_song == 0) {
                                    playeropen.start();
                                    mainView.common_bmrgn = units.gu(7);
                                }

                                player.source = last_url;
                                player.play();
                                mainView.pausing_song = 0;
                                mainView.playing_song = 'broadcast';
                                broadcastspage.playing_bcast = broadcast_id;

                                track_title.text = title;
                                track_artist.text = '';
                                track_image.source = '';
                                refresh_broadcast(broadcast_id);
                            }
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}
function refresh_broadcast(broadcast_id) {
    //artistsongsModel.clear();
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'broadcastStatusPoll';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('broadcastStatusPoll', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {"broadcastID":broadcast_id}
            }


            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    var results = JSON.parse(xhr.responseText);

                    var j;
                    for (j in results) {
                        if (j == 'result') {
                            if (mainView.pausing_song == 0 && mainView.playing_song == 'broadcast') {
                                track_artist.text = results[j]['activeSong']['ArtistName'] + " - " + results[j]['activeSong']['SongName'];
                            }
                        }
                    }

                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

// Login & Account
function login(username, password) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'authenticateUser';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('authenticateUser', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {"username":username, "password":password}
            }


            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    var results = JSON.parse(xhr.responseText);
                    //var results = xhr.responseText;

                    var j;
                    for (j in results) {
                        if (j == 'result') {
                            var result = results[j];

                            if (result['userID'] != '') {
                                setKey("username", username);
                                setKey("password", password);
                                setKey("Email", result['Email']);
                                setKey("userID", result['userID']);
                                setKey("FName", result['FName']);
                                setKey("LName", result['LName']);
                                setKey("authToken", result['authToken']);
                                setKey("Sex", result['Sex']);
                                setKey("TSDOB", result['TSDOB']);
                                setKey("Country", result['Country']);
                                setKey("Picture", result['Picture']);

                                mainView.uid = result['userID'];
                                mainView.fname = result['FName'];
                                mainView.picture = result['Picture'];
                                mainView.is_logged = true;

                                home();
                                homeWithoutLogin();
                            } else {
                                homeWithoutLogin();

                                console.log("Wrong credentials");
                            }
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

function logout() {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'logoutUser';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('logoutUser', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {"userID":getKey("userID")}
            }


            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);
                    var result = results["result"];
                    if (result == null) {
                        setKey("username", '');
                        setKey("password", '');
                        setKey("Email", '');
                        setKey("userID", '');
                        setKey("FName", '');
                        setKey("LName", '');
                        setKey("authToken", '');
                        setKey("Sex", '');
                        setKey("TSDOB", '');
                        setKey("Country", '');
                        setKey("Picture", '');

                        mainView.is_logged = false;
                        mainView.uid = '';

                        home();
                    } else {
                        console.log("Failed to logout");
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

// Favorites
function add_to_fav(song_id, page) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'favorite';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('favorite', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'what': 'Song', 'ID': song_id}
            }


            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);
                    if (typeof results['result'] != 'undefined') {
                        var result = results["result"];
                        if (result["success"] == true) {
                            if (page == 'popular') {
                                for (var j=0; j<popularsongsModel.count; j++) {
                                    if (popularsongsModel.get(j).id == song_id) {
                                        popularsongsModel.get(j).is_fav = 1;
                                    }
                                }
                            } else if (page == 'search') {
                                for (var j=0; j<foundsongsModel.count; j++) {
                                    if (foundsongsModel.get(j).id == song_id) {
                                        foundsongsModel.get(j).is_fav = 1;
                                    }
                                }
                            } else if (page == 'album') {
                                for (var j=0; j<albumsongsModel.count; j++) {
                                    if (albumsongsModel.get(j).id == song_id) {
                                        albumsongsModel.get(j).is_fav = 1;
                                    }
                                }
                            } else if (page == 'artist') {
                                for (var j=0; j<artistsongsModel.count; j++) {
                                    if (artistsongsModel.get(j).id == song_id) {
                                        artistsongsModel.get(j).is_fav = 1;
                                    }
                                }
                            } else if (page == 'collection') {
                                for (var j=0; j<collectionsModel.count; j++) {
                                    if (collectionsModel.get(j).id == song_id) {
                                        collectionsModel.get(j).is_fav = 1;
                                    }
                                }
                            } else if (page == 'playlist') {
                                for (var j=0; j<playlistsongsModel.count; j++) {
                                    if (playlistsongsModel.get(j).id == song_id) {
                                        playlistsongsModel.get(j).is_fav = 1;
                                    }
                                }
                            } else if (page == 'queue') {
                                for (var j=0; j<queueModel.count; j++) {
                                    if (queueModel.get(j).id == song_id) {
                                        queueModel.get(j).is_fav = 1;
                                    }
                                }
                            }
                        }
                    }
                    if (results["fault"]) {
                        if (is_logged == true) {
                            PopupUtils.open(errorDialog, mainView);
                        } else {
                            PopupUtils.open(loginDialog, mainView);
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

function remove_from_fav(song_id, page) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'unfavorite';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('unfavorite', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'what': 'Song', 'ID': song_id}
            }


            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);
                    var result = results["result"];
                    if (result["success"] == true) {
                        if (page == 'popular') {
                            for (var j=0; j<popularsongsModel.count; j++) {
                                if (popularsongsModel.get(j).id == song_id) {
                                    popularsongsModel.get(j).is_fav = 0;
                                }
                            }
                        } else if (page == 'search') {
                            for (var j=0; j<foundsongsModel.count; j++) {
                                if (foundsongsModel.get(j).id == song_id) {
                                    foundsongsModel.get(j).is_fav = 0;
                                }
                            }
                        } else if (page == 'album') {
                            for (var j=0; j<albumsongsModel.count; j++) {
                                if (albumsongsModel.get(j).id == song_id) {
                                    albumsongsModel.get(j).is_fav = 0;
                                }
                            }
                        } else if (page == 'artist') {
                            for (var j=0; j<artistsongsModel.count; j++) {
                                if (artistsongsModel.get(j).id == song_id) {
                                    artistsongsModel.get(j).is_fav = 0;
                                }
                            }
                        } else if (page == 'collection') {
                            for (var j=0; j<collectionsModel.count; j++) {
                                if (collectionsModel.get(j).id == song_id) {
                                    collectionsModel.get(j).is_fav = 0;
                                }
                            }
                        } else if (page == 'favorites') {
                            for (var j=0; j<favoritesModel.count; j++) {
                                if (favoritesModel.get(j).id == song_id) {
                                    favoritesModel.remove(j);
                                }
                            }
                        } else if (page == 'playlist') {
                            for (var j=0; j<playlistsongsModel.count; j++) {
                                if (playlistsongsModel.get(j).id == song_id) {
                                    playlistsongsModel.get(j).is_fav = 0;
                                }
                            }
                        } else if (page == 'queue') {
                            for (var j=0; j<queueModel.count; j++) {
                                if (queueModel.get(j).id == song_id) {
                                    queueModel.get(j).is_fav = 0;
                                }
                            }
                        }
                    }

                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

function get_fav_songs(user_id, page) {
    if (is_logged == false) {
        return false;
    }

    if (page == 'favorites') {
        favorites.finished = false;
    }

    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'getFavorites';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('getFavorites', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'ofWhat': 'Songs', 'userID': user_id}
            }

            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit

                    if (page == 'favorites') {
                        favoritesModel.clear();
                        favorites.finished = true;
                    }

                    var results = JSON.parse(xhr.responseText);
                    //var results = xhr.responseText;

                    var j;
                    for (j in results) {
                        if (j == 'result') {
                            var result = results[j];
                        }
                    }

                    var len = objLength(result);
                    for (var i = 0; i < len; i++) {
                        if (page == 'popular') {
                            for (var j=0; j<popularsongsModel.count; j++) {
                                if (popularsongsModel.get(j).id == result[i]['SongID']) {
                                    popularsongsModel.get(j).is_fav = 1;
                                }
                            }
                        } else if (page == 'search') {
                            for (var j=0; j<foundsongsModel.count; j++) {
                                if (foundsongsModel.get(j).id == result[i]['SongID']) {
                                    foundsongsModel.get(j).is_fav = 1;
                                }
                            }
                        } else if (page == 'album') {
                            for (var j=0; j<albumsongsModel.count; j++) {
                                if (albumsongsModel.get(j).id == result[i]['SongID']) {
                                    albumsongsModel.get(j).is_fav = 1;
                                }
                            }
                        } else if (page == 'artist') {
                            for (var j=0; j<artistsongsModel.count; j++) {
                                if (artistsongsModel.get(j).id == result[i]['SongID']) {
                                    artistsongsModel.get(j).is_fav = 1;
                                }
                            }
                        } else if (page == 'collection') {
                            for (var j=0; j<collectionsModel.count; j++) {
                                if (collectionsModel.get(j).id == result[i]['SongID']) {
                                    collectionsModel.get(j).is_fav = 1;
                                }
                            }
                        } else if (page == 'playlist') {
                            for (var j=0; j<playlistsongsModel.count; j++) {
                                if (playlistsongsModel.get(j).id == result[i]['SongID']) {
                                    playlistsongsModel.get(j).is_fav = 1;
                                }
                            }
                        } else if (page == 'queue') {
                            for (var j=0; j<queueModel.count; j++) {
                                if (queueModel.get(j).id == result[i]['SongID']) {
                                    queueModel.get(j).is_fav = 1;
                                }
                            }
                        } else if (page == 'favorites') {
                            var id = result[i]['SongID'];
                            var artistName = result[i]['ArtistName'];
                            var artistId = result[i]['ArtistID'];
                            var songName = result[i]['Name'];
                            var albumName = result[i]['AlbumName'];
                            var albumId = result[i]['AlbumID'];
                            var trackNum = result[i]['TrackNum'];
                            var songImage = result[i]['CoverArtFilename'] ? result[i]['CoverArtFilename'] : "";
                            favoritesModel.append({"title":songName, "artist_album":artistName + ' - ' + albumName, "name":artistName + ' - ' + songName, "id":id, "ii":i, "artistName" : artistName, "artistId" : artistId, "albumName" : albumName, "albumId": albumId, "trackNum": trackNum, "is_fav":1, "is_lib":0, "songImage":songImage});
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
            xhr.setRequestHeader("Accept", "application/json");

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

// Library
function add_to_lib(song, page) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'userAddSongsToLibrary';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('userAddSongsToLibrary', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'songs': song}
            }


            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);
                    var result = results["result"]['Timestamps'];
                    if (result["affectedRows"] == 1 && result['insertedSongIDs'].length > 0) {
                        if (page == 'popular') {
                            for (var j=0; j<popularsongsModel.count; j++) {
                                if (popularsongsModel.get(j).id == song[0]['songID']) {
                                    popularsongsModel.get(j).is_lib = 1;
                                }
                            }
                        } else if (page == 'search') {
                            for (var j=0; j<foundsongsModel.count; j++) {
                                if (foundsongsModel.get(j).id == song[0]['songID']) {
                                    foundsongsModel.get(j).is_lib = 1;
                                }
                            }
                        } else if (page == 'album') {
                            for (var j=0; j<albumsongsModel.count; j++) {
                                if (albumsongsModel.get(j).id == song[0]['songID']) {
                                    albumsongsModel.get(j).is_lib = 1;
                                }
                            }
                        } else if (page == 'artist') {
                            for (var j=0; j<artistsongsModel.count; j++) {
                                if (artistsongsModel.get(j).id == song[0]['songID']) {
                                    artistsongsModel.get(j).is_lib = 1;
                                }
                            }
                        } else if (page == 'favorites') {
                            for (var j=0; j<favoritesModel.count; j++) {
                                if (favoritesModel.get(j).id == song[0]['songID']) {
                                    favoritesModel.get(j).is_lib = 1;
                                }
                            }
                        } else if (page == 'playlist') {
                            for (var j=0; j<playlistsongsModel.count; j++) {
                                if (playlistsongsModel.get(j).id == song[0]['songID']) {
                                    playlistsongsModel.get(j).is_lib = 1;
                                }
                            }
                        } else if (page == 'queue') {
                            for (var j=0; j<queueModel.count; j++) {
                                if (queueModel.get(j).id == song[0]['songID']) {
                                    queueModel.get(j).is_lib = 1;
                                }
                            }
                        }
                    } else {
                        if (is_logged == true) {
                            PopupUtils.open(errorDialog, mainView);
                        } else {
                            PopupUtils.open(loginDialog, mainView);
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

function remove_from_lib(song_id, album_id, artist_id, user_id, page) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'userRemoveSongsFromLibrary';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('userRemoveSongsFromLibrary', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {"userID":user_id,"songIDs":[song_id],"albumIDs":[album_id],"artistIDs":[artist_id]}
            }


            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);
                    var result = results["result"]['Timestamps'];
                    if (result["oldTSModified"] && result['newTSModified']) {
                        if (page == 'popular') {
                            for (var j=0; j<popularsongsModel.count; j++) {
                                if (popularsongsModel.get(j).id == song_id) {
                                    popularsongsModel.get(j).is_lib = 0;
                                }
                            }
                        } else if (page == 'search') {
                            for (var j=0; j<foundsongsModel.count; j++) {
                                if (foundsongsModel.get(j).id == song_id) {
                                    foundsongsModel.get(j).is_lib = 0;
                                }
                            }
                        } else if (page == 'album') {
                            for (var j=0; j<albumsongsModel.count; j++) {
                                if (albumsongsModel.get(j).id == song_id) {
                                    albumsongsModel.get(j).is_lib = 0;
                                }
                            }
                        } else if (page == 'artist') {
                            for (var j=0; j<artistsongsModel.count; j++) {
                                if (artistsongsModel.get(j).id == song_id) {
                                    artistsongsModel.get(j).is_lib = 0;
                                }
                            }
                        } else if (page == 'collection') {
                            for (var j=0; j<collectionsModel.count; j++) {
                                if (collectionsModel.get(j).id == song_id) {
                                    collectionsModel.remove(j);
                                }
                            }
                        } else if (page == 'favorites') {
                            for (var j=0; j<favoritesModel.count; j++) {
                                if (favoritesModel.get(j).id == song_id) {
                                    favoritesModel.get(j).is_lib = 0;
                                }
                            }
                        } else if (page == 'playlist') {
                            for (var j=0; j<playlistsongsModel.count; j++) {
                                if (playlistsongsModel.get(j).id == song_id) {
                                    playlistsongsModel.get(j).is_lib = 0;
                                }
                            }
                        } else if (page == 'queue') {
                            for (var j=0; j<queueModel.count; j++) {
                                if (queueModel.get(j).id == song_id) {
                                    queueModel.get(j).is_lib = 0;
                                }
                            }
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

function get_lib_songs(user_id, page) {
    if (is_logged == false) {
        return false;
    }

    if (page == 'collection') {
        collections.finished = false;
    }

    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'userGetSongsInLibrary';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('userGetSongsInLibrary', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'userID': user_id, 'page': "0"}
            }

            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit

                    if (page == 'collection') {
                        collectionsModel.clear();
                        collections.finished = true;
                    }

                    var results = JSON.parse(xhr.responseText);
                    //var results = xhr.responseText;

                    var j;
                    for (j in results) {
                        if (j == 'result') {
                            var k;
                            for (k in results[j]) {
                                if (k == 'Songs') {
                                    var result = results[j][k];
                                }
                            }
                        }
                    }

                    var len = objLength(result);
                    for (var i = 0; i < len; i++) {
                        if (page == 'popular') {
                            for (var j=0; j<popularsongsModel.count; j++) {
                                if (popularsongsModel.get(j).id == result[i]['SongID']) {
                                    popularsongsModel.get(j).is_lib = 1;
                                }
                            }
                        } else if (page == 'search') {
                            for (var j=0; j<foundsongsModel.count; j++) {
                                if (foundsongsModel.get(j).id == result[i]['SongID']) {
                                    foundsongsModel.get(j).is_lib = 1;
                                }
                            }
                        } else if (page == 'album') {
                            for (var j=0; j<albumsongsModel.count; j++) {
                                if (albumsongsModel.get(j).id == result[i]['SongID']) {
                                    albumsongsModel.get(j).is_lib = 1;
                                }
                            }
                        } else if (page == 'artist') {
                            for (var j=0; j<artistsongsModel.count; j++) {
                                if (artistsongsModel.get(j).id == result[i]['SongID']) {
                                    artistsongsModel.get(j).is_lib = 1;
                                }
                            }
                        } else if (page == 'playlist') {
                            for (var j=0; j<playlistsongsModel.count; j++) {
                                if (playlistsongsModel.get(j).id == result[i]['SongID']) {
                                    playlistsongsModel.get(j).is_lib = 1;
                                }
                            }
                        } else if (page == 'queue') {
                            for (var j=0; j<queueModel.count; j++) {
                                if (queueModel.get(j).id == result[i]['SongID']) {
                                    queueModel.get(j).is_lib = 1;
                                }
                            }
                        } else if (page == 'collection') {
                            var id = result[i]['SongID'];
                            var artistName = result[i]['ArtistName'];
                            var artistId = result[i]['ArtistID'];
                            var songName = result[i]['Name'];
                            var albumName = result[i]['AlbumName'];
                            var albumId = result[i]['AlbumID'];
                            var trackNum = result[i]['TrackNum'];
                            var songImage = result[i]['CoverArtFilename'] ? result[i]['CoverArtFilename'] : "";
                            collectionsModel.append({"title":songName, "artist_album":artistName + ' - ' + albumName, "name":artistName + ' - ' + songName, "id":id, "ii":i, "artistName" : artistName, "artistId" : artistId, "albumName" : albumName, "albumId": albumId, "trackNum": trackNum, "is_fav":0, "is_lib":1, "songImage":songImage});
                        } else if (page == 'favorites') {
                            for (var j=0; j<favoritesModel.count; j++) {
                                if (favoritesModel.get(j).id == result[i]['SongID']) {
                                    favoritesModel.get(j).is_lib = 1;
                                }
                            }
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

// Create playlist
function create_playlist(playlist_name, playlist_desc, playlist_songs) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'createPlaylistEx';
            var data = {
                'header' : {
                  'client' : 'htmlshark',
                  'clientRevision' : '20130520',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('createPlaylistEx', token['comm_token'], "htmlshark"),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {"playlistName":playlist_name,"songIDs":[playlist_songs],"playlistAbout":playlist_desc}
            }


            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);

                    if (results["result"]) {
                        playlistspage.get_playlists(uid);
                        console.log(results['result']);
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

// Add song to playlist
function add_song_to_playlist(playlist_id, song_id) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'playlistAddSongToExistingEx';
            var data = {
                'header' : {
                  'client' : 'htmlshark',
                  'clientRevision' : '20130520',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('playlistAddSongToExistingEx', token['comm_token'], "htmlshark"),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {"playlistID":playlist_id,"songID":song_id}
            }


            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);

                    if (results["result"] == '1') {
                        console.log("Song added to playlist");
                    } else {
                        if (is_logged == true) {
                            PopupUtils.open(errorDialog, mainView);
                        } else {
                            PopupUtils.open(loginDialog, mainView);
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

function get_playlists(user_id) {
    playlists.finished = false;
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'userGetPlaylists';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('userGetPlaylists', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'userID': user_id}
            }

            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit

                    playlistsModel.clear();
                    playlists.finished = true;

                    var results = JSON.parse(xhr.responseText);

                    var j;
                    for (j in results) {
                        if (j == 'result') {
                            var k;
                            for (k in results[j]) {
                                if (k == 'Playlists') {
                                    var result = results[j][k];
                                }
                            }
                        }
                    }

                    var len = objLength(result);
                    for (var i = 0; i < len; i++) {
                        var playlistId = result[i]['PlaylistID'];
                        var name = result[i]['Name'];
                        var picture = result[i]['Picture'];
                        if (!picture) {
                            picture = 'playlist.png';
                        }
                        playlistsModel.append({"id":playlistId, "pl_name":name, "pl_picture":picture});
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

function get_playlist_by_id(id) {
    playlistsongs.finished = false;
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'getPlaylistByID';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('getPlaylistByID', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'playlistID': id}
            }

            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit

                    playlistsongsModel.clear();
                    playlistsongs.finished = false;

                    var results = JSON.parse(xhr.responseText);

                    var j;
                    for (j in results) {
                        if (j == 'result') {
                            var k;
                            for (k in results[j]) {
                                if (k == 'Songs') {
                                    var result = results[j][k];
                                }
                            }
                        }
                    }

                    var len = objLength(result);
                    for (var i = 0; i < len; i++) {
                        var id = result[i]['SongID'];
                        var artistName = result[i]['ArtistName'];
                        var artistId = result[i]['ArtistID'];
                        var songName = result[i]['Name'];
                        var albumName = result[i]['AlbumName'];
                        var albumId = result[i]['AlbumID'];
                        var trackNum = result[i]['TrackNum'];
                        var songImage = result[i]['CoverArtFilename'] ? result[i]['CoverArtFilename'] : "";
                        playlistsongsModel.append({"title":songName, "artist_album":artistName + ' - ' + albumName, "name":artistName + ' - ' + songName, "id":id, "ii":i, "artistName" : artistName, "artistId" : artistId, "albumName" : albumName, "albumId": albumId, "trackNum": trackNum, "is_fav":0, "is_lib":0, "songImage":songImage});
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}


function aget_playlists(user_id) {
    aplayModel.clear();
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'userGetPlaylists';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('userGetPlaylists', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'userID': user_id}
            }

            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //mainView.is_logged = 0;
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);

                    var j;
                    for (j in results) {
                        if (j == 'result') {
                            var k;
                            for (k in results[j]) {
                                if (k == 'Playlists') {
                                    var result = results[j][k];
                                }
                            }
                        }
                    }

                    var len = objLength(result);
                    for (var i = 0; i < len; i++) {
                        var playlistId = result[i]['PlaylistID'];
                        var name = result[i]['Name'];
                        var picture = result[i]['Picture'];
                        aplayModel.append({"id":playlistId, "name":name, "picture":picture});
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

// Remove song from playlist
function remove_song_from_playlist(playlist_id, song_id, playlist_name) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'overwritePlaylistEx';

            var songs_array = [];
            for (var k = 0; k < playlistsongsModel.count; k++) {
                songs_array.push(playlistsongsModel.get(k).id);
            }
            var ind = songs_array.indexOf(song_id);
            if (ind > -1) {
                songs_array.splice(ind, 1);
            }

            var data = {
                'header' : {
                  'client' : 'htmlshark',
                  'clientRevision' : '20130520',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('overwritePlaylistEx', token['comm_token'], "htmlshark"),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {"playlistID":playlist_id,"playlistName":playlist_name,"songIDs":songs_array}
            }


            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);

                    if (results["result"] == '1') {
                        console.log("Song removed from playlist");
                    } else {
                        if (is_logged == true) {
                            PopupUtils.open(errorDialog, mainView);
                        } else {
                            PopupUtils.open(loginDialog, mainView);
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

// Delete playlist
function delete_playlist(playlist_id, playlist_name) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'deletePlaylist';
            var data = {
                'header' : {
                  'client' : 'htmlshark',
                  'clientRevision' : '20130520',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('deletePlaylist', token['comm_token'], "htmlshark"),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {"playlistID":playlist_id,"name":playlist_name}
            }


            var url = 'https://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4)
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);

                    if (results["result"] == '1') {
                        console.log("Playlist deleted");
                    } else {
                        if (is_logged == true) {
                            PopupUtils.open(errorDialog, mainView);
                        } else {
                            PopupUtils.open(loginDialog, mainView);
                        }
                    }
                };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        }
    });
}

function userRecentListens(userID) {
    var token = get_token_data(function (token) {
        var uuid = generate_guid().toUpperCase();

        if (token['comm_token']) {
            var method = 'getUserRecentListens';
            var data = {
                'header' : {
                  'client' : 'mobileshark',
                  'clientRevision' : '20120830',
                  'country' : token['country'],
                  'privacy' : 0,
                  'token' : create_token('getUserRecentListens', token['comm_token']),
                  'session' : token['session'],
                  'uuid' : uuid
                },
                'method' : method,
                'parameters' : {'type' : 0, 'prefetch' : false, "userID":userID, 'country' : token['country'], 'mobile' : false}
            }

            var url = 'http://grooveshark.com/more.php?' + method;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', url, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    // Must be edit
                    //console.log(xhr.responseText);
                    var results = JSON.parse(xhr.responseText);

                    var j;
                    for (j in results) {
                        if (j == 'result') {
                            var i;
                            var ii = 0;
                            for (i in results[j]) {
                                if (ii < 5) {
                                    //console.log(JSON.stringify(results[j][i]))
                                    var id = results[j][i]['sid'];
                                    var artistName = results[j][i]['ar'];
                                    var artistId = results[j][i]['arid'];
                                    var songName = results[j][i]['s'];
                                    var albumName = results[j][i]['al'];
                                    var albumId = results[j][i]['alid'];
                                    var songImage = results[j][i]['i'] != 'album.png' ? results[j][i]['i'] : "";
                                    recentListensModel.append({"title":songName, "artist_album":artistName + ' - ' + albumName, "name":artistName + ' - ' + songName, "id":id, "ii":ii, "artistName" : artistName, "artistId" : artistId, "albumName" : albumName, "albumId": albumId, "is_fav":0, "is_lib":0, "songImage":songImage});

                                }
                                ii++;
                            }
                        }
                    }
                }
            };
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');

            // send the collected data as JSON
            xhr.send(JSON.stringify(data));
        };
    });
}
