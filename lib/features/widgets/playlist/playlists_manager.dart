import "package:flutter_application_1/features/api_requests/sources/objects.dart";

class PlaylistsManager {

  static const String playlistUserMapKey = "playlists";
  late List<Playlist> list;
  late Map<String, dynamic> userMapReference;


  PlaylistsManager(Map<String, dynamic> userMap) {
    userMapReference = userMap;
    if (userMapReference.containsKey(playlistUserMapKey)) {
      list = userMapReference[playlistUserMapKey];
    } else {
      list = [];
    }
  }

  void addPlaylist(Playlist newPlaylist) {
    list.add(newPlaylist);
  }

  void removePlaylistAt(int index) {
    list.removeAt(index);
  }

  void removePlaylist(Playlist playlist) {
    list.remove(playlist);
  }

  //saves playlists into userMap dict
  void saveData() {
    userMapReference[playlistUserMapKey] = list;
  }

  bool isEmpty() {
    return list.isEmpty;
  }

}