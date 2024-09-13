import 'dart:async';
import 'dart:convert';

import 'package:flutter_application_1/features/api_requests/header.dart';
import 'package:flutter_application_1/globals.dart';
import 'package:http/http.dart' as http;

import 'objects.dart' as objects;

const localDomain = "http://10.0.2.2:8000";
const localDomain2 = "http://127.0.0.1:8000";
const globalDomain = "https://sharemusic.site";

const domain = globalDomain;
const apiUrl = "$domain/api/music_api";

Future<List<objects.SimpleTrack>> searchTracks(String query) async {
  final response = await http.get(Uri.parse('$apiUrl/search/tracks/$query'));
  List<objects.SimpleTrack> res = [];
  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    var items = jsonResponse["tracks"]["items"];
    for (var item in items) {
      res.add(objects.SimpleTrack.fromJson(item));
    }
  }
  return res;
}

Future<List<objects.FullArtist>> searchArtists(String query) async {
  final response = await http.get(Uri.parse('$apiUrl/search/artists/$query'));
  List<objects.FullArtist> res = [];
  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    var items = jsonResponse["artists"]["items"];
    for (var item in items) {
      res.add(objects.FullArtist.fromJson(item));
    }
  }
  return res;
}

Future<List<objects.SimpleAlbum>> searchAlbums(String query) async {
  final response = await http.get(Uri.parse('$apiUrl/search/albums/$query'));
  List<objects.SimpleAlbum> res = [];
  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    var items = jsonResponse["albums"]["items"];
    for (var item in items) {
      res.add(objects.SimpleAlbum.fromJson(item));
    }
  }
  return res;
}

// Future<List<objects.SimplePlaylist>> getPlaylists(String query) async {
//   final response = await http.get(Uri.parse('$apiUrl/search/playlists/$query'));
//   List<objects.SimplePlaylist> res = [];
//   if (response.statusCode == 200) {
//     var jsonResponse = json.decode(response.body);
//     var items = jsonResponse["playlists"]["items"];
//     for (var item in items) {
//       res.add(objects.SimplePlaylist.fromJson(item));
//     }
//   }
//   return res;
// }

Future<Map<String, List<dynamic>>> search(String query) async {
  final response = await http.get(Uri.parse('$apiUrl/search/$query'));
  Map<String, List<dynamic>> res = {};
  Map<String, dynamic> jsonResponse;
  if (response.statusCode == 200) {
    try {
      jsonResponse = json.decode(response.body);
    } catch (e) {
      return {};
    }
    for (String key in jsonResponse.keys) {
      if (key == 'albums') {
        res["albums"] = objects.SimpleAlbum.fromJsonList(jsonResponse[key]["items"]);
      } else if (key == 'artists') {
        res["artists"] = objects.FullArtist.fromJsonList(jsonResponse[key]["items"]);
      } else if (key == "tracks") {
        res["tracks"] = objects.SimpleTrack.fromJsonList(jsonResponse[key]["items"]);
        // } else if (key == 'playlists') {
        //   res["playlists"] = objects.SimplePlaylist.fromJsonList(jsonResponse[key]["items"]);
        // }
      }
    }
  }
  return res;
}

Future<Map<String, dynamic>> getTrackUrl(String trackId) async {
  final response = await http.get(Uri.parse("$apiUrl/tracks/$trackId"));
  if (response.statusCode == 200) {
    Map<String, dynamic> res = json.decode(response.body);
    return res;
  } else {
    return {};
  }
}

Future<Map<String, dynamic>> getAlbumTracks(List<ExtendedMediaItem> tracks) async {
  if (tracks.isEmpty) {
    return {};
  }
  List<Map<String, dynamic>> body = [];
  for (var item in tracks) {
    body.add({
      'id': item.trackId,
      "title": item.title,
      "artist": item.artist,
      "duration": (item.duration.inMilliseconds / 1000).round()
    });
  }
  final response = await http.post(Uri.parse("$apiUrl/tracks_from_album/"),
      body: jsonEncode(body), headers: {"Accept": "application/json", "content-type": "application/json"});
  if (response.statusCode == 200) {
    Map<String, dynamic> res = jsonDecode(response.body);
    return res;
  } else {
    return {};
  }
}

Future<Map<String, dynamic>> getTrackUrlByInfo(String id, String artist, String track, int duration) async {
  Map<String, dynamic> body = {"id": id, "title": track, 'artist': artist, "duration": duration};
  final response = await http.post(Uri.parse("$apiUrl/tracks/"),
      body: jsonEncode(body), headers: {"Accept": "application/json", "content-type": "application/json"});
  if (response.statusCode == 200) {
    Map<String, dynamic> res = jsonDecode(response.body);
    return res;
  } else {
    return {};
  }
}

Future<objects.FullAlbum?> getFullAlbum(String albumId, {bool force = false}) async {
  if (!force) {
    dynamic cachedAlbum = cachedItems["albums"]?[albumId];
    if (cachedAlbum != null) {
      // await Future.delayed(const Duration(milliseconds: 500));
      return cachedAlbum;
    }
  }
  final response = await http.get(Uri.parse("$apiUrl/albums/$albumId"));
  if (response.statusCode == 200) {
    var res = objects.FullAlbum.fromJson(jsonDecode(response.body));
    cachedItems['albums'] = res;
    return res;
  } else {
    return null;
  }
}

Future<objects.Artist?> getArtistPage(String artistId, {bool force = false}) async {
  if (!force) {
    dynamic cachedArtistPage = cachedItems["artistPages"]?[artistId];
    if (cachedArtistPage != null &&
        DateTime.now().difference(cachedItems['artistPages']!.getCacheTime(artistId)!) < cacheTimeOut) {
      return cachedArtistPage;
    }
  }
  final response = await http.get(Uri.parse("$apiUrl/full_artist/$artistId"));
  if (response.statusCode == 200) {
    var res = objects.Artist.fromJson(jsonDecode(response.body));
    cachedItems['artistPages'] = res;
    return res;
  } else {
    return null;
  }
}

Future<List<objects.FullArtist>?> getArtists(List<String> artistIds, {bool force = false}) async {
  print(artistIds);
  if (artistIds.isEmpty) {
    return [];
  }
  List<String> notCached = force ? artistIds : [];

  if (!force) {
    for (var item in artistIds) {
      objects.FullArtist? cachedItem = cachedItems['artists']?[item];
      if (cachedItem == null) {
        notCached.add(item);
      }
    }
  }

  if (notCached.isEmpty) {
    return List.generate(artistIds.length, (index) => cachedItems['artists']?[artistIds[index]]);
  }
  final response = await http.post(Uri.parse("$apiUrl/artists/"),
      body: jsonEncode(notCached), headers: {"Accept": "application/json", "content-type": "application/json"});
  if (response.statusCode == 200) {
    List<objects.FullArtist> newValues = FullArtist.fromJsonList(jsonDecode(response.body));
    List<objects.FullArtist> res = [];
    for (int i = 0; i < artistIds.length; i++) {
      int ind = notCached.indexOf(artistIds[i]);
      if (ind == -1) {
        res.add(cachedItems['artists']?[artistIds[i]]);
      } else {
        res.add(newValues[ind]);
      }
    }
    for (var item in newValues) {
      cachedItems['artists'] = item;
    }
    return res;
  } else {
    return null;
  }
}

Future<bool> like({required String trackId}) async {
  final response = await http.post(Uri.parse("$apiUrl/like/"),
      body: jsonEncode({
        "user_id": int.parse(userData['id']),
        "track_id": trackId,
        "hash": userData['hash'],
      }),
      headers: {"Accept": "application/json", "content-type": "application/json"});
  if (response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}

Future<bool> unlike({required String trackId}) async {
  final response = await http.post(Uri.parse("$apiUrl/unlike/"),
      body: jsonEncode({
        "user_id": int.parse(userData['id']),
        "track_id": trackId,
        "hash": userData['hash'],
      }),
      headers: {"Accept": "application/json", "content-type": "application/json"});
  if (response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}

Future<List<String>?> getLikedTracks({required String userId}) async {
  final response = await http.get(Uri.parse("$apiUrl/liked_tracks/$userId"),
      headers: {"Accept": "application/json", "content-type": "application/json"});
  if (response.statusCode == 200) {
    List<dynamic> res = json.decode(response.body);
    return List.generate(res.length, (index) => res[index].toString());
  } else {
    return null;
  }
}

Future<List<objects.SimpleTrack>?> getTracksData({required List<String> trackIds}) async {
  if (trackIds.isEmpty) {
    return [];
  }
  final response = await http.post(Uri.parse("$apiUrl/tracks_data/"),
      body: jsonEncode(trackIds), headers: {"Accept": "application/json", "content-type": "application/json"});
  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    return SimpleTrack.fromJsonList(jsonResponse);
  } else {
    return null;
  }
}

Future<List<Map<String, dynamic>>?> getRawTracksData({required List<String> trackIds}) async {
  if (trackIds.isEmpty) {
    return [];
  }
  final response = await http.post(Uri.parse("$apiUrl/tracks_data/"),
      body: jsonEncode(trackIds), headers: {"Accept": "application/json", "content-type": "application/json"});
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    return null;
  }
}

// void main() {
//   getTracksData(trackIds: ['1l0wPhFZP1kWkZNQrrYrGy']).then((value) => print(value));
// }
