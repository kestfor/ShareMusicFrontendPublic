import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/api_requests/header.dart';
import 'package:flutter_application_1/features/widgets/date.dart';
import 'package:flutter_application_1/features/widgets/track_pull_down_button.dart';
import 'package:flutter_application_1/features/widgets/tiles/track_tile.dart';
import 'package:flutter_application_1/icons/test_icons_icons.dart';

import '../../globals.dart';
import '../player.dart';
import '../utils.dart';
import 'album_screen.dart';
import 'track_bottom_context_menu.dart';
import 'context_menu_actions.dart';

class FadeAppBar extends StatelessWidget {
  final double scrollOffset;
  final String title;

  const FadeAppBar({super.key, required this.scrollOffset, required this.title});

  @override
  Widget build(BuildContext context) {
    final opacityText = (scrollOffset / MediaQuery.sizeOf(context).height * 2.85).clamp(0, 1).toDouble();
    final opacityAppbar = (scrollOffset / MediaQuery.sizeOf(context).height * 2.85).clamp(0, 1).toDouble();
    return SafeArea(
        top: false,
        child: Container(
          height: 100,
          color: Theme.of(context).canvasColor.withOpacity(opacityAppbar),
          child: SafeArea(
            child: AppBar(
              centerTitle: true,
              title: Text(title, style: TextStyle(color: Colors.white.withOpacity(opacityText))),
              backgroundColor: Colors.transparent,
              leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.keyboard_arrow_left_rounded),
              ),
              actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded))],
            ),
          ),
        ));
  }
}

class ArtistScreen extends StatefulWidget {
  final String artistId;

  const ArtistScreen({super.key, required this.artistId});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  late Future<Artist?> artistFuture;
  late ScrollController _scrollController;
  double _scrollControllerOffset = 0.0;

  _scrollListener() {
    setState(() {
      _scrollControllerOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    artistFuture = getArtistPage(widget.artistId);
  }

  Widget contextMenu(
      {required context,
      required SimpleTrack currTrack,
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
                    currTrack: currTrack,
                    context: context,
                    album: currTrack.album,
                    artist: allArtists(currTrack.artists));
                showMessage(context, 'added to queue');
              },
              child: const Text("Add to queue")),
          CupertinoContextMenuAction(
              trailingIcon: TestIcons.queue_first,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                playNextAction(
                    currTrack: currTrack,
                    context: context,
                    album: currTrack.album,
                    artist: allArtists(currTrack.artists));
                showMessage(context, 'will be played next');
              },
              child: const Text("Play next")),
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
              // isNavigationBarVisible = false;
              // notifyNavigationBar();
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
        child: Material(child: SizedBox(height: 73, width: MediaQuery.sizeOf(context).width, child: child)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: artistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.red)));
          } else if (snapshot.data == null || snapshot.hasError) {
            return const Scaffold(body: Center(child: Text("something went wrong")));
          } else {
            int blockOfTopTracks = min(snapshot.data!.topTracks.length, 3);
            List<SimpleAlbum> albums = [];
            List<SimpleAlbum> singles = [];
            for (var item in snapshot.data!.albums) {
              if (item.album_type == 'album') {
                albums.add(item);
              } else if (item.album_type == 'single') {
                singles.add(item);
              }
            }
            return Stack(children: [
              Container(
                  child: Scaffold(
                      extendBodyBehindAppBar: true,
                      body: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const RangeMaintainingScrollPhysics(),
                          padding: const EdgeInsets.only(top: 0),
                          child: Column(children: [
                            Stack(
                              children: [
                                CachedNetworkImage(
                                    fit: BoxFit.cover,
                                    fadeOutDuration: const Duration(milliseconds: 100),
                                    fadeInDuration: const Duration(milliseconds: 100),
                                    placeholder: (context, url) => Icon(CupertinoIcons.person_alt,
                                        size: MediaQuery.sizeOf(context).width, color: Colors.white10),
                                    errorWidget: (context, url, error) => Icon(CupertinoIcons.person_alt,
                                        size: MediaQuery.sizeOf(context).width, color: Colors.white10),
                                    imageUrl: snapshot.data!.artist.images.isNotEmpty
                                        ? snapshot.data!.artist.images[0].url
                                        : '1',
                                    width: MediaQuery.sizeOf(context).width,
                                    height: MediaQuery.sizeOf(context).width),
                                Container(
                                    alignment: Alignment.bottomLeft,
                                    height: MediaQuery.sizeOf(context).width,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 10, bottom: 10),
                                      child: Text(snapshot.data!.artist.name,
                                          style: const TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold,
                                              shadows: [Shadow(color: Colors.black, blurRadius: 30)])),
                                    )),
                              ],
                            ),
                            blockOfTopTracks == 0 ? Container() : topTracks(snapshot, blockOfTopTracks),
                            albumsList(context, snapshot, albums, "Albums"),
                            albumsList(context, snapshot, singles, "Singles & EPs"),
                            const SizedBox(height: 120)
                          ]),
                        ),
                      )),
              PreferredSize(
                  preferredSize: Size(MediaQuery.of(context).size.width, 20),
                  child: FadeAppBar(
                    title: snapshot.data!.artist.name,
                    scrollOffset: _scrollControllerOffset,
                  ))
            ]);
          }
        });
  }

  Widget topTracks(snapshot, int blockOfTopTracks) {
    return Column(children: [
      Container(
          alignment: Alignment.bottomLeft,
          child: const Padding(
              padding: EdgeInsets.all(10),
              child: Text("Top Songs",
                  textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)))),
      SizedBox(
          height: 70 + blockOfTopTracks * 50,
          width: MediaQuery.sizeOf(context).width,
          child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(0),
              itemCount: (snapshot.data!.topTracks.length / blockOfTopTracks).floor(),
              itemBuilder: (context, index) {
                return SizedBox(
                    width: MediaQuery.sizeOf(context).width,
                    height: 150,
                    child: Column(children: [
                      for (int i = 0; i < blockOfTopTracks; i++)
                        modifiedTrackTile(track: snapshot.data!.topTracks[index * blockOfTopTracks + i])
                    ]));
              }))
    ]);
  }

  Widget modifiedTrackTile({required SimpleTrack track}) {
    return InkWell(
        onLongPress: () {
          showModalBottomSheet(
              enableDrag: false,
              isDismissible: false,
              useRootNavigator: true,
              backgroundColor: Colors.transparent,
              context: context,
              builder: (context) => BottomContextMenu(track: track, album: track.album, artists: track.artists),
              isScrollControlled: true);
        },
        onTap: () {
          playerWrapper.turnOnTrack(
              metaData: PlayerWrapper.getMetaData(track: track, album: track.album), context: context, inSession:
          socket.connected);
        },
        child: TrackTile(
          title: track.name,
          artist: track.album.name,
          artUri: track.album.images[0].url,
          trailing: PullDownContextMenuButton(track: track, album: track.album, artists: track.artists),
          // trailingIconFunction: () {
          //   isNavigationBarVisible = false;
          //   notifyNavigationBar();
          //   showModalBottomSheet(
          //       enableDrag: false,
          //       isDismissible: false,
          //       backgroundColor: Colors.transparent,
          //       context: context,
          //       builder: (context) => BottomContextMenu(track: track, album: track.album, artists: track.artists),
          //       isScrollControlled: true);
          // }
        ));
  }

  Widget albumsList(context, snapshot, albums, String categoryTitle) {
    if (albums.length == 0) {
      return const Column();
    }
    var theme = Theme.of(context);
    return Column(children: [
      Container(
          alignment: Alignment.bottomLeft,
          child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(categoryTitle,
                  textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)))),
      SizedBox(
          height: 270,
          width: MediaQuery.sizeOf(context).width,
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: albums.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return InkWell(
                    onTap: () {
                      Navigator.push(
                          context, CupertinoPageRoute(builder: (context) => AlbumScreen(albumId: albums[index].id, overrideArtists: albums[index].artists)));
                      //   PageTransition(
                      //       child: AlbumScreen(albumId: albums[index].id),
                      //       type: PageTransitionType.fade,
                      //       duration: const Duration(milliseconds: 400),
                      //       alignment: Alignment.center),
                      // );
                    },
                    child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SizedBox(
                              child: ClipRRect(
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            child: CachedNetworkImage(
                                fadeOutDuration: const Duration(milliseconds: 100),
                                fadeInDuration: const Duration(milliseconds: 100),
                                placeholder: (context, url) => Icon(Icons.album_rounded,
                                    size: MediaQuery.sizeOf(context).width / 2, color: Colors.white10),
                                errorWidget: (context, url, error) => Icon(Icons.album_rounded,
                                    size: MediaQuery.sizeOf(context).width / 2, color: Colors.white10),
                                fit: BoxFit.fitWidth,
                                imageUrl: albums[index].images[1].url,
                                width: MediaQuery.sizeOf(context).width / 2,
                                height: MediaQuery.sizeOf(context).width / 2),
                          )),
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                              child: SizedBox(
                                  width: MediaQuery.sizeOf(context).width / 2,
                                  child: Text(albums[index].name,
                                      style: theme.textTheme.labelLarge, overflow: TextOverflow.ellipsis))),
                          Padding(
                            padding: const EdgeInsets.all(0),
                            child: SizedBox(
                              width: MediaQuery.sizeOf(context).width / 2,
                              child: Text(Date.fromString(albums[index].release_date).year.toString(),
                                  style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          )
                        ])));
              }))
    ]);
  }
}
