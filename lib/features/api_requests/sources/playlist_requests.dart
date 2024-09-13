import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_request.dart';

enum UpdateAction { deletePlaylist, deleteTrack, addTrack, rename, changeArt }

final Map<UpdateAction, String> actions = {
  UpdateAction.deletePlaylist: "delete_playlist",
  UpdateAction.deleteTrack: "delete_track",
  UpdateAction.addTrack: 'add_track',
  UpdateAction.rename: 'rename',
  UpdateAction.changeArt: 'change_art'
};

Future<List<dynamic>?> getUserPlaylists({required int userId}) async {
  final response = await http.get(Uri.parse("$apiUrl/playlists/$userId"));
  print(response.statusCode);
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return null;
  }
}

Future<Map<String, dynamic>?> createPlaylist(
    {required String name, required String userId, required String hash, String? artUri}) async {
  final response = await http.post(Uri.parse("$apiUrl/playlists/update/"),
      body: jsonEncode({
        'action': 'create_playlist',
        'user_id': userId,
        'hash': hash,
        'data': {'name': name, 'art_uri': artUri}
      }),
      headers: {"Accept": "application/json", "content-type": "application/json"});
  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    return jsonResponse;
  } else {
    return null;
  }
}

Future<bool> deletePlaylist({required String userId, required String hash, required int playlistId}) async {
  return await _updatePlaylist(
      action: UpdateAction.deletePlaylist, userId: userId, hash: hash, data: {'playlist_id': playlistId});
}

Future<bool> deleteTrack(
    {required String userId, required String hash, required int playlistId, required String trackId}) async {
  return await _updatePlaylist(
      action: UpdateAction.deleteTrack,
      userId: userId,
      hash: hash,
      data: {'playlist_id': playlistId, 'track_id': trackId});
}

Future<bool> addTrack(
    {required String userId, required String hash, required int playlistId, required String trackId}) async {
  return await _updatePlaylist(
      action: UpdateAction.addTrack,
      userId: userId,
      hash: hash,
      data: {'playlist_id': playlistId, 'track_id': trackId});
}

Future<bool> renamePlaylist(
    {required String userId, required String hash, required int playlistId, required String name}) async {
  return await _updatePlaylist(
      action: UpdateAction.rename,
      userId: userId,
      hash: hash,
      data: {'playlist_id': playlistId, 'name': name});
}

Future<bool> changeArt(
    {required String userId, required String hash, required int playlistId, required String artUri}) async {
  return await _updatePlaylist(
      action: UpdateAction.changeArt,
      userId: userId,
      hash: hash,
      data: {'playlist_id': playlistId, 'art_uri': artUri});
}

Future<bool> _updatePlaylist(
    {required UpdateAction action,
    required String userId,
    required String hash,
    required Map<String, dynamic> data}) async {
  final response = await http.post(Uri.parse("$apiUrl/playlists/update/"),
      body: jsonEncode({'action': actions[action], 'user_id': userId, 'hash': hash, 'data': data}),
      headers: {"Accept": "application/json", "content-type": "application/json"});
  if (response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}
