import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/api_requests/sources/playlist_requests.dart';
import 'package:flutter_application_1/features/player.dart';
import 'package:flutter_application_1/features/utils.dart';
import 'package:flutter_application_1/features/widgets/context_menu_actions.dart';
import 'package:flutter_application_1/features/widgets/tiles/track_tile.dart';
import 'package:flutter_application_1/features/widgets/track_pull_down_button.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../globals.dart';
import '../../api_requests/header.dart';
import '../track_bottom_context_menu.dart';

String uri = 'https://i.pinimg.com/originals/a4/b6/fc/a4b6fc000e66d3e07ebea1d9a9bffa33.jpg';

class PlaylistScreen extends StatefulWidget {
  final int playlistId;

  const PlaylistScreen({super.key, required this.playlistId});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late final Playlist _playlist;
  late final Future<List<SimpleTrack>?> tracks;
  late List<SimpleTrack> _data;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    insertItemTrack = _insertSingleItem;
    deleteItemTrack = _removeSingleItem;
    // mainScreensNotify["Library"] = notify;
    if (widget.playlistId == -1) {
      List<dynamic> tracksId = userData['likedTracks'];
      String name = 'Liked songs';
      _playlist = Playlist(
          id: widget.playlistId,
          name: name,
          tracksId: List.generate(tracksId.length, (index) => tracksId[index].toString()),
          artUri: uri);
    } else {
      String name = userData['playlists'][widget.playlistId]['playlist_name'];
      String? artUri = userData['playlists'][widget.playlistId]['art_uri'];
      List<dynamic> tracksId = userData['playlists'][widget.playlistId]['tracks_id']?? [];
      _playlist = Playlist(
          id: widget.playlistId,
          name: name,
          artUri: artUri,
          tracksId: List.generate(tracksId.length, (index) => tracksId[index].toString()));
    }
    tracks = getTracksData(trackIds: _playlist.tracksId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: tracks,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator(
                color: Colors.red,
              )),
            );
          } else if (snapshot.data == null || snapshot.hasError) {
            return const Scaffold(body: Center(child: Text("something went wrong")));
          } else {
            _data = snapshot.data!;
            return Scaffold(
              extendBody: true,
              extendBodyBehindAppBar: false,
              appBar: AppBar(
                shadowColor: Colors.black26,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.keyboard_arrow_left_rounded),
                ),
                actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz))],
              ),
              body: CupertinoScrollbar(
                  child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 150),
                child: Column(
                  children: [
                    playlistArt(_playlist.artUri, context),
                    playlistName(_playlist.name, context),
                    buttons(context, allTracks: _data),
                    futureTracks(_data),
                  ],
                ),
              )),
            );
          }
        });
  }

  Widget playlistArt(artUri, context) {
    var size = MediaQuery.of(context).size;
    var theme = Theme.of(context);
    return Stack(
      children: [
        // shadow
        Padding(
          padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
          child: Container(
            width: size.width - 100,
            height: size.width - 100,
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(color: theme.shadowColor, blurRadius: 50, spreadRadius: 5, offset: const Offset(-10, 40))
            ], borderRadius: BorderRadius.circular(20)),
          ),
        ),
        // picture
        Padding(
          padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
          child: artUri != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: CachedNetworkImage(
                    imageUrl: artUri,
                    width: MediaQuery.of(context).size.width - 50,
                    height: MediaQuery.of(context).size.width - 50,
                    fit: BoxFit.cover,
                    fadeOutDuration: const Duration(milliseconds: 200),
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (context, url) =>
                        Icon(Icons.album_rounded, color: Colors.white12, size: (size.width - 60)),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.album_rounded, color: Colors.white12, size: (size.width - 60)),
                  ),
                )
              : Icon(Icons.album_rounded, color: Colors.white12, size: (size.width - 60)),
        )
      ],
    );
  }

  Widget playlistName(String name, context) {
    var size = MediaQuery.of(context).size;
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 20),
      child: Container(
          alignment: Alignment.center,
          width: size.width - 50,
          child: Text(name, textAlign: TextAlign.center, style: theme.textTheme.titleLarge)),
    );
  }

  Widget slidable(
      {required child, required int index, required currTrack, required album, required artists, required allTracks}) {
    return Slidable(
        direction: Axis.horizontal,
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
                  inSession: socket.connected,
                  context: context,
                  metaData: PlayerWrapper.getMetaData(track: currTrack, album: album));
              HapticFeedback.mediumImpact();
              return false;
            },
            onDismissed: () {},
          ),
          children: [
            CustomSlidableAction(
                autoClose: true,
                backgroundColor: const Color.fromARGB(255, 99, 87, 181),
                child: Center(child: Image.asset('assets/icon/last.png', height: 25, width: 25)),
                onPressed: (context) {
                  playerWrapper.addToQueue(
                      inSession: socket.connected,
                      context: context,
                      metaData: PlayerWrapper.getMetaData(track: currTrack, album: album));
                  showMessage(context, "added to queue");
                  HapticFeedback.mediumImpact();
                }),
            CustomSlidableAction(
                autoClose: true,
                backgroundColor: const Color.fromARGB(255, 218, 124, 35),
                child: Center(child: Image.asset('assets/icon/first.png', height: 25, width: 25)),
                onPressed: (context) {
                  playerWrapper.addToQueue(
                      inSession: socket.connected,
                      context: context,
                      metaData: PlayerWrapper.getMetaData(track: currTrack, album: album),
                      toEnd: false);
                  showMessage(context, "added to queue");
                  HapticFeedback.mediumImpact();
                })
          ],
        ),
        child: InkWell(
            onLongPress: () {
              showModalBottomSheet(
                  enableDrag: false,
                  // enableDrag: false,
                  isDismissible: false,
                  useRootNavigator: true,
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (context) => BottomContextMenu(
                      track: currTrack,
                      album: album,
                      artists: currTrack.artists,
                      deleteAction: true,
                      onDelete: () async {
                        await Future.delayed(const Duration(milliseconds: 300));
                        _removeSingleItem(currTrack, index);
                      }),
                  isScrollControlled: true);
            },
            onTap: () {
              if (playerWrapper.player.playing) {
                playerWrapper.player.stop();
              }
              playerWrapper.turnOnPlaylist(
                  tracksMetaData: List.generate(
                      allTracks.length,
                      (currIndex) => PlayerWrapper.getMetaData(
                          track: allTracks[(currIndex + index) % allTracks.length], album: allTracks[(index + currIndex) % allTracks.length].album)),
                  context: context);
              // widget.miniPlayer();
            },
            child: child));
  }

  Widget buttons(context, {required allTracks}) {
    return Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: CupertinoButton(color: Colors.grey, child: const Icon(CupertinoIcons.play_fill), onPressed: () {
                playerWrapper.turnOnPlaylist(
                            tracksMetaData: List.generate(
                                allTracks.length,
                                    (index) => PlayerWrapper.getMetaData(
                                    track: allTracks[index], album: allTracks[index].album)),
                            context: context);
              },)),
              // child: TextButton(
              //   style: ButtonStyle(
              //       backgroundColor:
              //       const MaterialStatePropertyAll<Color>(Colors.white),
              //       fixedSize: MaterialStatePropertyAll(Size(MediaQuery.of(context).size.width  / 2.5, 50)),
              //       shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              //           RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(10.0)))),
              //   onPressed: () {
              //     playerWrapper.turnOnPlaylist(
              //         tracksMetaData: List.generate(
              //             allTracks.length,
              //                 (index) => PlayerWrapper.getMetaData(
              //                 track: allTracks[index], album: allTracks[index].album)),
              //         context: context);
              //   },
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Icon(CupertinoIcons.play_fill),
              //       Text("Play"),
              //     ],
              //   ),
              // ),
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: CupertinoButton(color: Colors.grey, child: Icon(CupertinoIcons.shuffle), onPressed: () {
                playerWrapper.turnOnPlaylist(
                            shuffle: true,
                            tracksMetaData: List.generate(
                                allTracks.length,
                                    (index) => PlayerWrapper.getMetaData(
                                    track: allTracks[index], album: allTracks[index].album)),
                            context: context);
              },)
              // child: TextButton(
              //   style: ButtonStyle(
              //       backgroundColor:
              //       const MaterialStatePropertyAll<Color>(Colors.white),
              //       fixedSize: MaterialStatePropertyAll(Size(MediaQuery.of(context).size.width / 2.5, 50)),
              //       shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              //           RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(10.0)))),
              //   onPressed: () {
              //     playerWrapper.turnOnPlaylist(
              //         shuffle: true,
              //         tracksMetaData: List.generate(
              //             allTracks.length,
              //                 (index) => PlayerWrapper.getMetaData(
              //                 track: allTracks[index], album: allTracks[index])),
              //         context: context);
              //   },
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Icon(CupertinoIcons.shuffle),
              //       Text("Shuffle")
              //     ],
              //   ),
              // ),
            )
          ],
        ));
  }

  Widget futureTracks(tracks) {
    return AnimatedList(
        key: _listKey,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.vertical,
        initialItemCount: tracks.length,
        itemBuilder: (context, index, animation) {
          return _buildItem(tracks[index], animation, index);
        });
  }

  Widget _buildItem(SimpleTrack item, Animation<double> animation, int index) {
    return SizeTransition(
        sizeFactor: animation,
        child: slidable(
            allTracks: _data,
            currTrack: item,
            album: item.album,
            artists: item.artists,
            child: TrackTile(
                trailing: PullDownContextMenuButton(
                  deleteAction: true,
                  onDelete: () {
                    _removeSingleItem(item, index);
                  },
                  track: item,
                  artists: item.artists,
                  album: item.album,
                ),
                artUri: item.album.images[0].url,
                title: item.name,
                artist: allArtists(item.artists)),
            index: index));
  }

  void _insertSingleItem(SimpleTrack currTrack) {
    _data.add(currTrack);
    _listKey.currentState?.insertItem(_data.length - 1);
  }

  // void _insertMultipleItems() {
  //   final items = ['Pig', 'Chichen', 'Dog'];
  //   int insertIndex = 2;
  //   _data.insertAll(insertIndex, items);
  //   // This is a bit of a hack because currentState doesn't have
  //   // an insertAll() method.
  //   for (int offset = 0; offset < items.length; offset++) {
  //     _listKey.currentState.insertItem(insertIndex + offset);
  //   }
  // }

  void _removeSingleItem(SimpleTrack currTrack, int? removeIndex) {
    if (widget.playlistId == -1) {
      if (removeIndex == null) {
        for (int i = 0; i < _data.length; i++) {
          if (_data[i].id == currTrack.id) {
            removeIndex = i;
            break;
          }
        }
      }
      if (removeIndex == null) {
        return;
      }
      _data.removeAt(removeIndex);
      unlikeSongAction(context: context, trackId: currTrack.id);
    } else if (removeIndex != null) {
      userData['playlists'][widget.playlistId]['tracks_id'].remove(currTrack.id);
      _data.removeAt(removeIndex);
      deleteTrack(userId: userData['id'], hash: userData['hash'], playlistId: widget.playlistId, trackId: currTrack.id);
    }
    if (removeIndex == null) {
      return;
    }
    AnimatedRemovedItemBuilder builder = (context, animation) {
      return _buildItem(currTrack, animation, removeIndex!);
    };
    _listKey.currentState?.removeItem(removeIndex, builder);
  }
}
