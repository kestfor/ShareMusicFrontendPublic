
import 'package:flutter_application_1/cache.dart';
import 'package:flutter_application_1/features/api_requests/header.dart' as api;
import 'package:flutter_application_1/features/player.dart';
import 'package:flutter_application_1/features/widgets/playlist/playlists_manager.dart';
import 'package:flutter_application_1/queue_struct.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart';

// для обновления плейлистов присваиваются на этапе init очищаются при dispose
late Function? insertItemPlaylist;
late Function? deleteItemPlaylist;
late Function? insertItemTrack;
late Function? deleteItemTrack;
//

bool isNavigationBarVisible = true;

late Function notifyNavigationBar;

SearchingHistory searchHistoryQueue = SearchingHistory(length: 40);

String currScreen = 'Search';

Map<String, dynamic> mainScreensContext = {'Home': null, 'Search': null, "Library": null, 'Global': null};

Map<String, Function()?> mainScreensNotify = {
  'Home': null,
  'Search': null,
  "Library": null,
  'Global': null,
};

const phoneStorage = FlutterSecureStorage();

late Function? colorRefresh;

Map<String, dynamic> userData = {};

PlaylistsManager playlistsManager = PlaylistsManager(userData);

Set<String> likedTracks = {};

Cache cachedItems = Cache();
Duration cacheTimeOut = const Duration(minutes: 5);

String roomId = "";

const domain = api.domain;

// Socket socket = io(
//     testUrl,
//     OptionBuilder().setPath("/ws/").setQuery({
//       "user_id": "553945148",
//       "hash":
//       "16366c8ec94d472b1e7ddee0aaf09e27d62f4b6cc9806c281454bb3fe490bab0"
//     }).build());

//TODO убрать отсюда инициализацию
Socket socket = io(api.domain, OptionBuilder().setTransports(["websocket"]).build());

PlayerWrapper playerWrapper = PlayerWrapper(socket: socket);