import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/api_requests/header.dart';
import 'package:flutter_application_1/features/api_requests/sources/playlist_requests.dart';
import 'package:flutter_application_1/features/widgets/playlist/new_playlist_creation_screen.dart';
import 'package:flutter_application_1/features/widgets/playlist/playlist_screen.dart';
import 'package:flutter_application_1/features/widgets/tiles/playlist_tile.dart';

import '../../../globals.dart';
import '../playlist/playlist_bottom_context_menu.dart';

String uri = 'https://i.pinimg.com/originals/a4/b6/fc/a4b6fc000e66d3e07ebea1d9a9bffa33.jpg';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  List<int> _data = getPlaylistsId();

  static List<int> getPlaylistsId() {
    if (userData['playlists'].isEmpty) {
      return [];
    }
    List<int> res = [];
    for (var key in userData['playlists'].keys) {
      res.add(key);
    }
    return res;
  }

  @override
  void initState() {
    insertItemPlaylist = _insertSingleItem;
    deleteItemPlaylist = _removeSingleItem;
    super.initState();
  }

  @override
  void dispose() {
    insertItemPlaylist = null;
    deleteItemPlaylist = null;
    super.dispose();
  }

  InkWell getLikedSongsTile(context) {
    return InkWell(
      child: const PlaylistTile(
        name: 'Liked Songs',
        id: -1,
        leadingIcon: Icon(CupertinoIcons.heart_fill, color: Colors.grey, size: 40,),
      ),
      onTap: () {
        setState(() {
          Navigator.of(context)
              .push(CupertinoPageRoute(
                  builder: (context) => const PlaylistScreen(
                        playlistId: -1,
                      )));

        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    mainScreensContext['Library'] = context;

    return Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: AnimatedList(
              key: _listKey,
              shrinkWrap: true,
              initialItemCount: userData['playlists'].length + 2,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index, animation) {
                String name;
                int id;
                String? artUri;
                List<String> tracksId = [];
                if (index > 1) {
                  name = userData['playlists'][_data[index - 2]]['playlist_name'];
                  id = _data[index - 2];
                  artUri = userData['playlists'][_data[index - 2]]['art_uri'];
                } else {
                  name = '';
                  id = 1;
                  artUri = null;
                }
                return _buildItem(
                    Playlist(id: id, name: name, artUri: artUri, tracksId: tracksId), animation, index, context);
              }),
        ));
  }

  Widget getCreatePlaylistTile() {
    return InkWell(
      child: const PlaylistTile(
        name: 'New playlist',
        id: -2,
        leadingIcon: Icon(
          CupertinoIcons.add,
          color: Colors.grey,
          size: 40,
        ),
      ),
      onTap: () {
        setState(() {
          Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (context) => NewPlaylistCreationScreen()));

        });
      },
    );
  }

  Widget _buildItem(Playlist item, Animation<double> animation, int index, context) {
    return SizeTransition(
        sizeFactor: animation,
        child: InkWell(
          child: index == 0
              ? getCreatePlaylistTile()
              : index == 1
                  ? getLikedSongsTile(context)
                  : PlaylistTile(
                      name: item.name,
                      id: item.id,
                      artUri: item.artUri,
                    ),
          onLongPress: () {
            if (index > 1) {
              showModalBottomSheet(
                  enableDrag: false,
                  isDismissible: false,
                  useRootNavigator: true,
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (context) => BottomContextMenu(
                        playlist: Playlist(name: item.name, id: item.id, artUri: item.artUri, tracksId: item.tracksId),
                        onDelete: () {
                          _removeSingleItem(item, index, context);
                        },
                      ),
                  isScrollControlled: true);
            }
          },
          onTap: () {
            if (index > 1) {
              setState(() {
                Navigator.of(context)
                    .push(CupertinoPageRoute(
                        builder: (context) => PlaylistScreen(
                              playlistId: item.id,
                            )));
              });
            }
          },
        ));
  }

  void _insertSingleItem(Playlist currPlaylist) {
    _data = getPlaylistsId();
    _listKey.currentState?.insertItem(_data.length - 1);
  }

  void _removeSingleItem(Playlist currPlaylist, int removeIndex, context) {
    userData['playlists'].remove(currPlaylist.id);
    _data.removeAt(removeIndex - 2);
    deletePlaylist(userId: userData['id'], hash: userData['hash'], playlistId: currPlaylist.id);
    AnimatedRemovedItemBuilder builder = (context, animation) {
      return _buildItem(currPlaylist, animation, removeIndex, context);
    };
    _listKey.currentState?.removeItem(removeIndex, builder);
  }
}
