import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/api_requests/header.dart';
import 'package:flutter_application_1/icons/test_icons_icons.dart';

import '../../globals.dart';
import '../utils.dart';
import 'context_menu_actions.dart';

class BottomContextMenu extends StatefulWidget {
  final SimplifiedTrack track;
  final List<SimpleArtist> artists;
  final SimpleAlbum album;
  final Color? accentColor;
  final bool deleteAction;
  final Function()? onDelete;

  const BottomContextMenu(
      {super.key,
      required this.track,
      required this.album,
      required this.artists,
      this.deleteAction = false,
      this.onDelete,
      this.accentColor = const Color.fromARGB(255, 208, 46, 60)});

  @override
  State<StatefulWidget> createState() => _BottomContextMenuState();
}

class _BottomContextMenuState extends State<BottomContextMenu> {
  final List<String> actionTitles = const [
    'Add to playlist',
    'Add To Queue',
    'Play Next',
    'Album',
    'Artists',
    'Like',
    'Unlike',
    'Delete'
  ];
  late List<Icon> actionIcons = [
    Icon(
      CupertinoIcons.add_circled,
      color: widget.accentColor,
    ),
    Icon(TestIcons.queue_last, color: widget.accentColor),
    Icon(TestIcons.queue_first, color: widget.accentColor),
    Icon(CupertinoIcons.music_albums_fill, color: widget.accentColor),
    Icon(CupertinoIcons.person_2_fill, color: widget.accentColor),
    Icon(CupertinoIcons.heart, color: widget.accentColor),
    Icon(CupertinoIcons.heart_fill, color: widget.accentColor),
    Icon(
      CupertinoIcons.delete,
      color: widget.accentColor,
    )
  ];

  void showMessage(context, String message) {
    var theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 600),
        backgroundColor: theme.dialogBackgroundColor,
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        )));
  }

  Widget functionalTile({required context, required int index, required Function() function}) {
    return Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
            onTap: () {
              Navigator.of(context, rootNavigator: true).pop();
              function();
            },
            child: ListTile(leading: actionIcons[index], minLeadingWidth: 5, title: Text(actionTitles[index]))));
  }

  Widget addToPlaylistTile(context) {
    return functionalTile(
        context: context,
        index: 0,
        function: () async {
          await addTrackToPlaylistFunction(context: context, track: widget.track, album: widget.album);
          if (insertItemTrack != null) {
            insertItemTrack!(SimpleTrack.fromSimplified(widget.track, widget.album));
          }
        });
  }

  Widget addToQueueTile(context) {
    return functionalTile(
        context: context,
        index: 1,
        function: () {
          addToQueueAction(
              currTrack: widget.track, context: context, album: widget.album, artist: allArtists(widget.artists));
          showMessage(context, 'added to queue');
        });
  }

  Widget playNextTile(context) {
    return functionalTile(
        context: context,
        index: 2,
        function: () {
          playNextAction(
              currTrack: widget.track, context: context, album: widget.album, artist: allArtists(widget.artists));
          showMessage(context, 'will be played next');
        });
  }

  Widget goToAlbumTile(context) {
    return functionalTile(
        context: context,
        index: 3,
        function: () {
          goToAlbumAction(albumId: widget.album.id, context: context, artists: widget.artists);
        });
  }

  Widget showArtistTile(context) {
    return functionalTile(
        context: context,
        index: 4,
        function: () {
          showModalBottomSheet(
              enableDrag: false,
              isDismissible: false,
              useRootNavigator: true,
              backgroundColor: Colors.transparent,
              context: context,
              builder: (context) =>
                  ArtistsOnTrack(artistsId: List.generate(widget.artists.length, (index) => widget.artists[index].id)),
              isScrollControlled: true);
        });
  }

  Widget deleteSongTile(context) {
    return functionalTile(
        context: context,
        index: 7,
        function: () {
          widget.onDelete!();
        });
  }

  Widget likeSongTile(context) {
    return functionalTile(
        context: context,
        index: 5,
        function: () async {
          try {
            await likeSongAction(context: context, trackId: widget.track.id);
            if (insertItemTrack != null) {
              insertItemTrack!(SimpleTrack.fromSimplified(widget.track, widget.album));
            }
            showMessage(context, 'added to liked songs');
          } catch (e) {
            showMessage(context, 'something went wrong');
          }
        });
  }

  Widget unlikeSongTile(context) {
    return functionalTile(
        context: context,
        index: 6,
        function: () async {
          try {
            await unlikeSongAction(context: context, trackId: widget.track.id);
            if (deleteItemTrack != null) {
              deleteItemTrack!(SimpleTrack.fromSimplified(widget.track, widget.album), null);
            }
            showMessage(context, 'deleted from liked songs');
          } catch (e) {
            showMessage(context, 'something went wrong');
          }
        });
  }

  Widget trackTile(context) {
    return Container(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(5), // fixed width and height
            child: CachedNetworkImage(
              imageUrl: widget.album.images[2].url,
              fadeOutDuration: const Duration(milliseconds: 300),
              placeholder: (context, url) => const Icon(Icons.album_rounded, size: 45, color: Colors.white10),
              errorWidget: (context, url, error) => const Icon(Icons.album_rounded, size: 45, color: Colors.white10),
            ),
          ),
          title: Text(
            widget.track.name,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          isThreeLine: true,
          subtitle: InkWell(
            child: Text(
              '${widget.artists[0].name}\n${widget.album.name}',
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
              style: TextStyle(color: widget.accentColor),
            ),
            onTap: () {
              Navigator.of(context, rootNavigator: true).pop();
              goToArtistAction(artistId: widget.artists[0].id, context: context);
            },
          ),
        ));
  }

  Widget makeDismissible({required Widget child, required context}) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 200));
        },
        child: GestureDetector(onTap: () {}, child: child),
      );

  @override
  Widget build(BuildContext context) {
    double indent = (MediaQuery.of(context).size.width - 40) / 2;
    return makeDismissible(
        context: context,
        child: DraggableScrollableSheet(
            maxChildSize: 0.7,
            initialChildSize: 0.6,
            minChildSize: 0.2,
            builder: (_, controller) => Container(
                decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 28, 27, 27),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
                child: ListView(physics: const BouncingScrollPhysics(), controller: controller, children: [
                  // Padding(
                  //     padding: const EdgeInsets.only(top: 5),
                  //     child: Divider(
                  //       indent: indent,
                  //       endIndent: indent,
                  //       color: Colors.white,
                  //       thickness: 3,
                  //     )),
                  trackTile(mainScreensContext[currScreen]),
                  addToPlaylistTile(mainScreensContext[currScreen]),
                  addToQueueTile(mainScreensContext[currScreen]),
                  playNextTile(mainScreensContext[currScreen]),
                  goToAlbumTile(mainScreensContext[currScreen]),
                  showArtistTile(mainScreensContext[currScreen]),
                  widget.deleteAction
                      ? deleteSongTile(context)
                      : likedTracks.contains(widget.track.id)
                          ? unlikeSongTile(mainScreensContext[currScreen])
                          : likeSongTile(mainScreensContext[currScreen])
                ]))));
  }
}
