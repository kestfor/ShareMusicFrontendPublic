import 'dart:convert';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/cache.dart';
import 'package:flutter_application_1/features/player.dart';
import 'package:flutter_application_1/features/utils.dart';
import 'package:flutter_application_1/queue_struct.dart';
import 'package:flutter_application_1/tab_navigator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:marquee/marquee.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/widgets/main_screens/player_full_screen.dart';
import 'globals.dart';

class ShareMusicApp extends StatefulWidget {
  const ShareMusicApp({super.key});

  @override
  State<StatefulWidget> createState() => _ShareMusicAppState();
}

class _ShareMusicAppState extends State<ShareMusicApp> with WidgetsBindingObserver {
  String _currentPage = "Search";
  List<String> pageKeys = ["Home", "Search", "Library"];
  final Map<String, GlobalKey<NavigatorState>> _navigatorKeys = {
    "Home": GlobalKey<NavigatorState>(),
    "Search": GlobalKey<NavigatorState>(),
    "Library": GlobalKey<NavigatorState>(),
  };
  int _selectedIndex = 1;
  SharedPreferences? preferences;

  void _selectTab(String tabItem, int index) {
    if (tabItem == _currentPage) {
      _navigatorKeys[tabItem]!.currentState!.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _currentPage = pageKeys[index];
        _selectedIndex = index;
        currScreen = _currentPage;
      });
    }
  }

  void notify() {
    setState(() {});
  }

  @override
  void initState() {
    notifyNavigationBar = notify;
    WidgetsBinding.instance.addObserver(this);
    initializePreference().whenComplete(() {
      setState(() {
        readCachedData();
        readCachedHistory();
      });
    });
    super.initState();
  }

  Future<void> saveAllData() async {
    await Future.wait([saveUserData(), saveCachedHistory(), saveCachedData()]);
    print("all data saved");
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> initializePreference() async {
    preferences = await SharedPreferences.getInstance();
  }

  Future<void> readCachedHistory() async {
    String? historyData = preferences?.getString('history');
    if (historyData == null) {
      searchHistoryQueue = SearchingHistory();
    } else {
      Map<String, dynamic> json = jsonDecode(historyData);
      searchHistoryQueue = SearchingHistory.fromJson(json);
    }
  }

  Future<void> saveCachedHistory() async {
    await preferences?.setString('history', jsonEncode(searchHistoryQueue.toJson()));
  }

  Future<void> readCachedData() async {
    String? data = preferences?.getString('serverData');
    if (data == null) {
      cachedItems = Cache();
    } else {
      Map<String, dynamic> json = jsonDecode(data);
      cachedItems = Cache.fromJson(json);
    }
  }

  Future<void> saveUserData() async {
    var toSave = {};
    for (var key in userData['playlists'].keys) {
      toSave[key.toString()] = userData['playlists'][key];
    }
    userData['playlists'] = toSave;
    await phoneStorage.write(key: "user_data", value: jsonEncode(userData));
  }

  Future<void> readUserData() async {
    final String? res = await phoneStorage.read(key: "user_data");
    if (res != null){
      userData = jsonDecode(res);
      var converted = {};
      for (var key in userData['playlists'].keys) {
        converted[int.parse(key)] = userData['playlists'][key];
      }
      userData['playlists'] = converted;
      // await getServerData(int.parse(userData['id']));
    }
  }

  // Future<void> getServerData(int userId) async {
  //   List<dynamic>? playlists = await getUserPlaylists(userId: userId);
  //   if (playlists != null) {
  //     for (var item in playlists) {
  //       userData['playlists'][item['playlist_id']] = item;
  //     }
  //   }
  //   List<String>? liked = await getLikedTracks(userId: userId.toString());
  //   if (liked != null) {
  //     likedTracks.addAll(liked);
  //   }
  // }

  Future<void> saveCachedData() async {
    await preferences?.setString('serverData', jsonEncode(cachedItems.toJson()));
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    
    // await saveCachedHistory();
    // await saveCachedHistory();
    await playerWrapper.player.dispose();
    return await saveAllData().then((value) => AppExitResponse.exit);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        //Execute the code when user come back the app.
        //readUserData();

        //TODO ебанутые memory leak
        // readCachedHistory();
        // readCachedData();


        break;
      case AppLifecycleState.paused:
        saveUserData();

        //TODO ебанутые memory leak
        saveCachedHistory();
        saveCachedData();
        print('data saved');
        //Execute the code when user leave the app
        break;
      case AppLifecycleState.detached:
        await saveAllData();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    mainScreensContext['Global'] = context;
    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInCurrentTab = !await _navigatorKeys[_currentPage]!.currentState!.maybePop();
        if (isFirstRouteInCurrentTab) {
          if (_currentPage != "Search") {
            _selectTab("Search", 1);
            return false;
          }
        }
        // let system handle back button if we're on the first route
        return isFirstRouteInCurrentTab;
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(children: <Widget>[
          _buildOffstageNavigator("Home"),
          _buildOffstageNavigator("Search"),
          _buildOffstageNavigator("Library"),
        ]),
        bottomNavigationBar: Visibility(
            maintainState: true,
            visible: isNavigationBarVisible,
            child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Colors.white12, width: 2),
                      left: BorderSide(color: Colors.white12, width: 1),
                      right: BorderSide(color: Colors.white12, width: 1)),
                  gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color.fromARGB(50, 0, 0, 0), Color.fromARGB(50, 50, 50, 50)]
                      // stops: [
                      //   0.1,
                      //   0.4,
                      //   0.6,
                      //   0.9,
                      // ],
                      // colors: [Color.fromARGB(50, 200, 151, 2), Color.fromARGB(50, 255, 20, 0), Color.fromARGB(50, 63, 81, 181), Color.fromARGB(50, 0, 150, 136)],
                      ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                ),
                child: ClipRRect(
                    clipBehavior: Clip.antiAlias,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                    child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 12.0,
                          sigmaY: 12.0,
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          miniPlayer(context: context),
                          BottomNavigationBar(
                            type: BottomNavigationBarType.fixed,
                            onTap: (int index) {
                              _selectTab(pageKeys[index], index);
                            },
                            currentIndex: _selectedIndex,
                            selectedItemColor: const Color.fromARGB(255, 208, 46, 60),
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            items: const <BottomNavigationBarItem>[
                              BottomNavigationBarItem(
                                activeIcon: Icon(
                                  Icons.home,
                                  color: Color.fromARGB(255, 208, 46, 60),
                                ),
                                icon: Icon(Icons.home_outlined),
                                label: "Home",
                              ),
                              BottomNavigationBarItem(
                                activeIcon: Icon(Icons.search_rounded, color: Color.fromARGB(255, 208, 46, 60)),
                                icon: Icon(Icons.search_outlined),
                                label: 'Search',
                              ),
                              BottomNavigationBarItem(
                                activeIcon: Icon(Icons.album, color: Color.fromARGB(255, 208, 46, 60)),
                                icon: Icon(Icons.album_outlined),
                                label: 'Library',
                              ),
                            ],
                          )
                        ]))))),
      ),
    );
  }

  Widget miniPlayer({context}) {
    return StreamBuilder<SequenceState?>(
        stream: playerWrapper.player.sequenceStateStream,
        builder: (context, snapshot) {
          final state = snapshot.data;
          if (state?.sequence.isEmpty ?? true) {
            return const SizedBox();
          }
          final metadata = state?.currentSource!.tag as MediaItem;
          bool hasOverflow = hasTextOverflow(
              metadata.title, Theme.of(context).textTheme.titleMedium!, MediaQuery.of(context).textScaler,
              maxWidth: MediaQuery.of(context).size.width);
          return InkWell(
            onTap: () {
              showModalBottomSheet(
                  isDismissible: false,
                  useRootNavigator: true,
                  context: context,
                  builder: (context) => AudioPlayerScreen(),
                  isScrollControlled: true);
            },
            child: Container(
                child: ListTile(
                    visualDensity: VisualDensity.compact,
                    leading: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      child: CachedNetworkImage(
                        imageUrl: metadata.artUri!.toString(),
                        fadeOutDuration: const Duration(milliseconds: 1),
                        placeholder: (context, url) => const Icon(Icons.album_rounded, size: 50, color: Colors.white10),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.album_rounded, size: 50, color: Colors.white10),
                      ),
                    ),
                    // title: Container(
                    //   color: Colors.red,
                    //   height: 20,
                    //   child: hasOverflow
                    //       ? Marquee(
                    //           style: Theme.of(context).textTheme.titleMedium,
                    //           text: metadata.title,
                    //           startAfter: const Duration(seconds: 3),
                    //           velocity: 25,
                    //           blankSpace: 10,
                    //           pauseAfterRound: const Duration(seconds: 5))
                    //       : Text(
                    //           metadata.title,
                    //           style: Theme.of(context).textTheme.titleMedium,
                    //         ),
                    // ),
                    title: SizedBox(
                        height: 20,
                        child: AutoSizeText(metadata.title,
                            maxLines: 1,
                            minFontSize: 15,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflowReplacement: Marquee(
                                style: Theme.of(context).textTheme.titleMedium,
                                text: metadata.title,
                                startAfter: const Duration(seconds: 3),
                                velocity: 25,
                                blankSpace: 10,
                                pauseAfterRound: const Duration(seconds: 5)))),
                    subtitle: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(metadata.artist!.split(', ')[0], overflow: TextOverflow.ellipsis),
                    ),
                    trailing: StreamBuilder<PlayerState>(
                      stream: playerWrapper.player.playerStateStream,
                      builder: (context, snapshot) {
                        final playerState = snapshot.data;
                        final processionState = playerState?.processingState;
                        final playing = playerState?.playing;
                        if (!(playing ?? false)) {
                          return IconButton(
                              padding: const EdgeInsets.only(left: 10, right: 10),
                              onPressed: () {
                                playerWrapper.play(inSession: socket.connected);
                              },
                              icon: const Icon(Icons.play_arrow_rounded),
                              color: Colors.white,
                              iconSize: 40);
                        } else if (processionState != ProcessingState.completed) {
                          return IconButton(
                              padding: const EdgeInsets.only(left: 10, right: 10),
                              onPressed: () {
                                playerWrapper.pause(inSession: socket.connected);
                              },
                              icon: const Icon(Icons.pause_rounded),
                              color: Colors.white,
                              iconSize: 40);
                        }
                        return const Icon(Icons.play_arrow_rounded, size: 40, color: Colors.white);
                      },
                    ))),
          );
        });
  }

  Widget _buildOffstageNavigator(String tabItem) {
    return Offstage(
      offstage: _currentPage != tabItem,
      child: TabNavigator(
        navigatorKey: _navigatorKeys[tabItem]!,
        tabItem: tabItem,
      ),
    );
  }
}

//if you want love if you w
