import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/api_requests/header.dart' as api;
import 'package:flutter_application_1/features/utils.dart';
import 'package:flutter_application_1/features/widgets/artist_screen.dart';
import 'package:flutter_application_1/features/widgets/track_bottom_context_menu.dart';
import 'package:flutter_application_1/features/widgets/context_menu_actions.dart';
import 'package:flutter_application_1/features/widgets/tiles/album_tile.dart';
import 'package:flutter_application_1/features/widgets/tiles/artist_tile.dart';
import 'package:flutter_application_1/features/widgets/tiles/track_tile.dart' as widgets;
import 'package:flutter_application_1/icons/test_icons_icons.dart';
import 'package:flutter_application_1/queue_struct.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../globals.dart';
import '../../player.dart';
import '../album_screen.dart';
import '../track_pull_down_button.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _MusicMainScreenState();
}

class _MusicMainScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  late Future<Map<String, List<dynamic>>> searchResultAll;
  final controllerText = TextEditingController();
  late int albumsAmount;
  late List<int> albumsIndexes;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    searchResultAll = Future(() => {});
    albumsAmount = Random().nextInt(2) + 1;
    albumsIndexes = List.generate(albumsAmount, (index) => Random().nextInt(4) + 4);
    _tabController = TabController(length: 4, vsync: this);
  }

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        extendBody: true,
        body: SafeArea(
            child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.all(15),
                child: SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        Expanded(
                            child: TapRegion(
                          onTapOutside: (PointerDownEvent a) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          child: CupertinoSearchTextField(
                            onSuffixTap: () {
                              setState(() {
                                controllerText.clear();
                                searchResultAll = Future(() => {});
                              });
                            },
                            suffixInsets: const EdgeInsets.only(right: 20),
                            suffixIcon: const Icon(Icons.clear),
                            onChanged: (val) {
                              setState(() {
                                searchResultAll = val != "" ? api.search(val) : Future(() => {});
                              });
                            },
                            autofocus: true,
                            controller: controllerText,
                            style: theme.textTheme.bodyMedium,
                          ),
                        )),
                        SizedBox(
                            child: CupertinoButton(
                          child: const Text(
                            "cancel",
                            style: TextStyle(color: Color.fromARGB(255, 208, 46, 60)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ))
                      ],
                    ))),
            Expanded(
                child: FutureBuilder<dynamic>(
              future: searchResultAll,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Scaffold(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    body: const Center(
                        child: CircularProgressIndicator(
                      color: Colors.red,
                    )),
                  );
                }
                if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                  return Column(children: [
                    TabBar(
                      indicatorColor: const Color.fromARGB(255, 208, 46, 60),
                      indicatorWeight: 1.5,
                      isScrollable: true,
                      controller: _tabController,
                      labelColor: const Color.fromARGB(255, 208, 46, 60),
                      tabs: const <Widget>[
                        Tab(
                          text: "TOP RESULTS",
                        ),
                        Tab(
                          text: 'SONGS',
                        ),
                        Tab(
                          text: "ARTISTS",
                        ),
                        Tab(
                          text: 'ALBUMS',
                        )
                      ],
                    ),
                    Expanded(
                        child: TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        polymorphousList(snapshot.data, albumsAmount, albumsIndexes),
                        songsList(snapshot),
                        artistsList(snapshot),
                        albumsList(snapshot)
                      ],
                    ))
                  ]);
                } else if (snapshot.hasError) {
                  print(snapshot.error);
                  return Scaffold(
                      body: Center(
                          child: Column(children: [
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          "something went wrong",
                          style: Theme.of(context).textTheme.bodyLarge,
                        )),
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: IconButton(
                            onPressed: () {
                              setState(() {
                                searchResultAll = api.search(controllerText.text);
                              });
                            },
                            icon: const Icon(Icons.refresh)))
                  ])));
                } else {
                  return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: getHistory());
                }
              },
            )),
          ],
        )));
  }

  Widget getHistory() {
    List<dynamic> allItems = searchHistoryQueue.toList();
    if (allItems.isEmpty) {
      return ListView();
    }
    return SlidableAutoCloseBehavior(
        child: CupertinoScrollbar(
            child: ListView(
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                children: [
                      Padding(
                          padding: const EdgeInsets.all(0),
                          child: SizedBox(
                              height: 50,
                              child: Row(children: [
                                const Expanded(
                                    flex: 3,
                                    child: Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Text(
                                          'History',
                                          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                                        ))),
                                // Padding(padding: const EdgeInsets.only(right: 10), child: InkWell(
                                //     child: const
                                SizedBox(
                                    width: MediaQuery.of(context).size.width / 3.5,
                                    child: CupertinoButton(
                                      // color: Colors.white24,
                                      child: const Text(
                                        "clear",
                                        style: TextStyle(color: Color.fromARGB(255, 208, 46, 60)),
                                      ),
                                      onPressed: () {
                                        searchHistoryQueue = SearchingHistory(length: 20);
                                        setState(() {});
                                      },
                                    )),
                                // onTap: () async {
                                //   setState(() async {
                                //     await preferences!.remove('counter');
                                //   });
                              ])))
                    ] +
                    List.generate(allItems.length,
                        (index) => Padding(padding: const EdgeInsets.all(0), child: getNeededTile(allItems[index]))))));
  }

  Widget getNeededTile(item) {
    if (item is api.FullArtist) {
      api.FullArtist artist = item;
      return getArtistTile(context, artist, addToHistoryOnTap: false);
    } else if (item is api.SimpleAlbum) {
      api.SimpleAlbum album = item;
      return getAlbumTile(context, album, addToHistoryOnTap: false);
    } else {
      api.SimpleTrack currTrack = item;
      return getTrackTile(context, currTrack, addToHistoryOnTap: false);
    }
  }

  Widget contextMenu(
      {required context,
      required api.SimpleTrack currTrack,
      required Widget child,
      Color accentColor = const Color.fromARGB(255, 208, 46, 60)}) {
    return CupertinoContextMenu(
        enableHapticFeedback: true,
        actions: <Widget>[
          CupertinoContextMenuAction(
              trailingIcon: TestIcons.queue_last,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();

                addToQueueAction(
                    currTrack: currTrack, context: context, album: currTrack.album, artist: currTrack.artists[0]);
                showMessage(context, 'added to queue');
              },
              child: const Text("Add To Queue")),
          CupertinoContextMenuAction(
              trailingIcon: TestIcons.queue_first,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                playNextAction(
                    currTrack: currTrack, context: context, album: currTrack.album, artist: currTrack.artists[0]);
                showMessage(context, 'will be played next');
              },
              child: const Text("Play Next")),
          CupertinoContextMenuAction(
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Future.delayed(const Duration(milliseconds: 500));
              goToAlbumAction(albumId: currTrack.album.id, context: context);
            },
            trailingIcon: CupertinoIcons.music_albums_fill,
            child: const Text('Album'),
          ),
          CupertinoContextMenuAction(
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Future.delayed(const Duration(milliseconds: 500));
              showModalBottomSheet(
                  enableDrag: false,
                  useRootNavigator: true,
                  // enableDrag: false,
                  isDismissible: false,
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (context) => ArtistsOnTrack(
                      artistsId: List.generate(currTrack.artists.length, (index) => currTrack.artists[index].id)),
                  isScrollControlled: true);
            },
            trailingIcon: CupertinoIcons.person_2_fill,
            child: const Text('Artists'),
          ),
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            trailingIcon: CupertinoIcons.heart_fill,
            child: const Text('Like'),
          ),
        ],
        child: child);
  }

  Widget getTrackTile(context, api.SimpleTrack currTrack, {addToHistoryOnTap = true}) {
    return Slidable(
        closeOnScroll: true,
        key: UniqueKey(),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          dismissible: DismissiblePane(
            dismissThreshold: 0.8,
            closeOnCancel: true,
            confirmDismiss: () async {
              showMessage(context, "added to queue");
              playerWrapper.addToQueue(
                  metaData: PlayerWrapper.getMetaData(track: currTrack, album: currTrack.album),
                  context: context,
                  inSession: socket.connected);
              HapticFeedback.mediumImpact();
              return false;
            },
            onDismissed: () {},
          ),
          children: [
            CustomSlidableAction(
                autoClose: true,
                backgroundColor: const Color.fromARGB(255, 99, 87, 181),
                child: Align(
                    alignment: Alignment.center, child: Image.asset('assets/icon/last.png', height: 25, width: 25)),
                onPressed: (context) {
                  playerWrapper.addToQueue(
                      metaData: PlayerWrapper.getMetaData(track: currTrack, album: currTrack.album),
                      context: context,
                      inSession: socket.connected);
                  showMessage(context, "added to queue");
                  HapticFeedback.mediumImpact();
                }),
            CustomSlidableAction(
                autoClose: true,
                backgroundColor: const Color.fromARGB(255, 218, 124, 35),
                child: Align(
                    alignment: Alignment.center, child: Image.asset('assets/icon/first.png', height: 25, width: 25)),
                onPressed: (context) {
                  playerWrapper.addToQueue(
                      metaData: PlayerWrapper.getMetaData(track: currTrack, album: currTrack.album),
                      context: context,
                      toEnd: false,
                      inSession: socket.connected);
                  showMessage(context, "added to queue");
                  HapticFeedback.mediumImpact();
                })
          ],
        ),
        child: Container(
            width: MediaQuery.sizeOf(context).width,
            height: 73,
            decoration: const BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: Colors.white10, width: 0.5))),
            child: InkWell(
                onLongPress: () {
                  showModalBottomSheet(
                      enableDrag: false,
                      isDismissible: false,
                      useRootNavigator: true,
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) =>
                          BottomContextMenu(track: currTrack, album: currTrack.album, artists: currTrack.artists),
                      isScrollControlled: true);
                },
                onTap: () {
                  if (addToHistoryOnTap) {
                    searchHistoryQueue.push(item: currTrack, id: currTrack.id);
                  }
                  playerWrapper.turnOnTrack(
                      metaData: PlayerWrapper.getMetaData(track: currTrack, album: currTrack.album), context:
                  context, inSession: socket.connected);
                },
                child: widgets.TrackTile(
                  title: currTrack.name,
                  artist: "Song - ${allArtists(currTrack.artists)}",
                  artUri: currTrack.album.images[2].url,
                  trailing:
                      PullDownContextMenuButton(track: currTrack, album: currTrack.album, artists: currTrack.artists),
                  // trailingIconFunction: () {
                  // isNavigationBarVisible = false;
                  // notifyNavigationBar();
                  // showModalBottomSheet(
                  //     enableDrag: false,
                  //     isDismissible: false,
                  //     backgroundColor: Colors.transparent,
                  //     context: context,
                  //     builder: (context) => BottomContextMenu(
                  //         track: currTrack, album: currTrack.album, artists: currTrack.artists),
                  //     isScrollControlled: true);
                  // }
                ))));
  }

  Widget getArtistTile(context, api.FullArtist artist, {addToHistoryOnTap = true}) {
    return Container(
        decoration:
            const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: Colors.white10, width: 0.5))),
        child: InkWell(
          onTap: () {
            if (addToHistoryOnTap) {
              searchHistoryQueue.push(item: artist, id: artist.id);
            }
            Navigator.push(context, CupertinoPageRoute(builder: (context) => ArtistScreen(artistId: artist.id)))
                .then((value) => setState(() {}));
          },
          // PageTransition(
          //     child: ArtistScreen(artistId: artist.id),
          //     type: PageTransitionType.rightToLeft,
          //     duration: const Duration(milliseconds: 200),
          //     alignment: Alignment.center)),
          child: ArtistTile(
              artist: artist.name, id: artist.id, artUri: artist.images.isNotEmpty ? artist.images[2].url : null),
        ));
  }

  Widget getAlbumTile(context, final api.SimpleAlbum album, {addToHistoryOnTap = true}) {
    return InkWell(
        onTap: () async {
          if (addToHistoryOnTap) {
            searchHistoryQueue.push(item: album, id: album.id);
          }
          Navigator.push(context, CupertinoPageRoute(builder: (context) => AlbumScreen(albumId: album.id, overrideArtists: album.artists,)))
              .then((value) => setState(() {}));
          // PageTransition(
          //     child: AlbumScreen(albumId: album.id),
          //     type: PageTransitionType.rightToLeft,
          //     duration: const Duration(milliseconds: 200),
          //     alignment: Alignment.center));
        },
        child: AlbumTile(name: album.name, id: album.id, artUri: album.images[2].url));
  }

  void addItems(List<dynamic> from, List<dynamic> to, int amount) {
    for (int i = 0; i < amount; i++) {
      to.add(from[i]);
    }
  }

  Widget songsList(snapshot) {
    final tracksAmount = snapshot.data!['tracks'].length;
    return SlidableAutoCloseBehavior(
        child: CupertinoScrollbar(
            child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: tracksAmount,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  api.SimpleTrack currTrack = snapshot.data['tracks'][index];
                  return getTrackTile(context, currTrack);
                })));
  }

  Widget albumsList(snapshot) {
    final albumsAmount = snapshot.data!['albums'].length;
    return CupertinoScrollbar(
        child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: albumsAmount,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              api.SimpleAlbum album = snapshot.data!['albums'][index];
              return getAlbumTile(context, album);
            }));
  }

  Widget artistsList(snapshot) {
    final artistsAmount = snapshot.data!['artists'].length;
    return CupertinoScrollbar(
        child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: artistsAmount,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              api.FullArtist artist = snapshot.data!['artists'][index];
              return getArtistTile(context, artist);
            }));
  }

  Widget polymorphousList(data, albumsAmount, albumsIndexes) {
    const totalAmount = 20;
    final tracksAmount = data!['tracks'].length;
    List<api.FullArtist> artists = data!['artists'];
    List<dynamic> allItems = [];
    addItems(data!['tracks'], allItems, tracksAmount);
    bool inserted = false;
    for (int i = 0; i < allItems.length; i++) {
      if (artists[0].popularity >= allItems[i].popularity) {
        allItems.insert(i, artists[0]);
        inserted = true;
        break;
      }
    }
    if (!inserted) {
      allItems[totalAmount - 1] = artists[0];
    }
    for (int i = 0; i < albumsAmount; i++) {
      allItems.insert(albumsIndexes[i], data!['albums'][i]);
    }
    return SlidableAutoCloseBehavior(
        child: CupertinoScrollbar(
            child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: totalAmount,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  if (allItems[index] is api.FullArtist) {
                    api.FullArtist artist = allItems[index];
                    return getArtistTile(context, artist);
                  } else if (allItems[index] is api.SimpleAlbum) {
                    api.SimpleAlbum album = allItems[index];
                    return getAlbumTile(context, album);
                  } else {
                    api.SimpleTrack currTrack = allItems[index];
                    return getTrackTile(context, currTrack);
                  }
                })));
  }
}
