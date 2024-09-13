import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/api_requests/header.dart';
import 'package:flutter_application_1/features/player.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../globals.dart';
import '../../icons/test_icons_icons.dart';
import '../utils.dart';
import 'context_menu_actions.dart';

class PullDownContextMenuButton extends StatelessWidget {
  final SimplifiedTrack track;
  final List<SimpleArtist> artists;
  final SimpleAlbum album;
  final Color? accentColor;
  final bool deleteAction;
  final Function()? onDelete;

  const PullDownContextMenuButton(
      {super.key,
      required this.track,
      required this.artists,
      required this.album,
      this.deleteAction = false,
      this.onDelete,
      this.accentColor = const Color.fromARGB(255, 208, 46, 60)});

  final List<String> actionTitles = const [
    'Add to playlist',
    'Add to queue',
    'Play next',
    'Album',
    'Artists',
    'Like',
    'Unlike',
    "Delete"
  ];
  final List<IconData> actionIcons = const [
    CupertinoIcons.add_circled,
    TestIcons.queue_last,
    TestIcons.queue_first,
    CupertinoIcons.music_albums_fill,
    CupertinoIcons.person_2_fill,
    CupertinoIcons.heart,
    CupertinoIcons.heart_fill,
    CupertinoIcons.delete
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

  @override
  Widget build(BuildContext context) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuHeader(
          leading: Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5), // fixed width and height
              child: CachedNetworkImage(
                imageUrl: album.images[0].url,
                fadeOutDuration: const Duration(milliseconds: 200),
                placeholder: (context, url) => const Icon(Icons.album_rounded, size: 45, color: Colors.white10),
                errorWidget: (context, url, error) => const Icon(Icons.album_rounded, size: 45, color: Colors.white10),
              ),
            ),
            const Align(
              alignment: Alignment.center,
              child: Icon(
                Icons.play_arrow_rounded,
                size: 40,
                color: Color.fromARGB(155, 255, 255, 255),
              ),
            )
          ]),
          title: track.name,
          subtitle: allArtists(track.artists),
          onTap: () {
            playerWrapper.turnOnTrack(
                metaData: PlayerWrapper.getMetaData(track: track, album: album), context: context);
          },
        ),
        PullDownMenuItem(
          icon: actionIcons[0],
          iconColor: accentColor,
          title: actionTitles[0],
          onTap: () async {
              await addTrackToPlaylistFunction(context: context, track: track, album: album);
              if (insertItemTrack != null) {
                insertItemTrack!(SimpleTrack.fromSimplified(track, album));
            }
          },
        ),
        PullDownMenuItem(
          icon: actionIcons[1],
          iconColor: accentColor,
          title: actionTitles[1],
          onTap: () {
            addToQueueAction(currTrack: track, context: context, album: album, artist: artists[0]);
            showMessage(context, 'added to queue');
          },
        ),
        PullDownMenuItem(
          iconColor: accentColor,
          icon: actionIcons[2],
          title: actionTitles[2],
          onTap: () {
            playNextAction(currTrack: track, context: context, album: album, artist: artists[0]);
            showMessage(context, 'will be played next');
          },
        ),
        PullDownMenuItem(
          iconColor: accentColor,
          icon: actionIcons[3],
          title: actionTitles[3],
          onTap: () {
            goToAlbumAction(albumId: album.id, context: context, artists: artists);
          },
        ),
        PullDownMenuItem(
            iconColor: accentColor,
            icon: actionIcons[4],
            title: actionTitles[4],
            onTap: () {
              // isNavigationBarVisible = false;
              // notifyNavigationBar();
              showModalBottomSheet(
                  enableDrag: false,
                  useRootNavigator: true,
                  isDismissible: false,
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (context) =>
                      ArtistsOnTrack(artistsId: List.generate(artists.length, (index) => artists[index].id)),
                  isScrollControlled: true);
            }),
        deleteAction
            ? PullDownMenuItem(
                iconColor: accentColor,
                icon: actionIcons[7],
                title: actionTitles[7],
                onTap: () {
                  onDelete!();
                },
              )
            : !likedTracks.contains(track.id)
                ? PullDownMenuItem(
                    iconColor: accentColor,
                    icon: actionIcons[5],
                    title: actionTitles[5],
                    onTap: () async {
                      try {
                        await likeSongAction(context: context, trackId: track.id);
                        if (insertItemTrack != null) {
                          insertItemTrack!(SimpleTrack.fromSimplified(track, album));
                        }
                        showMessage(context, 'added to liked songs');
                      } catch (e) {
                        showMessage(context, 'something went wrong');
                      }
                    },
                  )
                : PullDownMenuItem(
                    iconColor: accentColor,
                    icon: actionIcons[6],
                    title: actionTitles[6],
                    onTap: () async {
                      try {
                        await unlikeSongAction(context: context, trackId: track.id);
                        if (deleteItemTrack != null) {
                          deleteItemTrack!(SimpleTrack.fromSimplified(track, album), null);
                        }
                        showMessage(context, 'deleted from liked songs');
                      } catch (e) {
                        print(e);
                        showMessage(context, 'something went wrong');
                      }
                    },
                  )
      ],
      buttonBuilder: (context, showMenu) => CupertinoButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        child: const Icon(
          Icons.more_vert_rounded,
          color: Colors.white,
        ),
      ),
    );
  }
}
