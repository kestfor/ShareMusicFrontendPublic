import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../globals.dart';

class Queue extends StatefulWidget {
  const Queue({super.key});

  @override
  State<StatefulWidget> createState() => _QueueState();
}

class _QueueState extends State<Queue> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: AppBar(
        //   leading: IconButton(
        //     onPressed: () {
        //       Navigator.pop(context);
        //     },
        //     icon: const Icon(Icons.keyboard_arrow_down_rounded),
        //   ),
        // ),
        backgroundColor: Colors.transparent,
        body: StreamBuilder(
            stream: playerWrapper.player.sequenceStateStream,
            builder: (context, snapshot) {
              if (snapshot.data != null) {
                int offset = snapshot.data!.sequence.indexOf(snapshot.data!.currentSource!) + 1;
                var nowPlaying = snapshot.data!.sequence[offset - 1].tag as MediaItem;
                var theme = Theme.of(context);
                return Column(children: [
                  // Padding(
                  //     padding: const EdgeInsets.all(15),
                  //     child: Container(
                  //         alignment: Alignment.bottomLeft,
                  //         child: const Text(
                  //           "Now Playing",
                  //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  //           textAlign: TextAlign.left,
                  //         ))),
                  ListTile(
                    visualDensity: VisualDensity.standard,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      // fixed width and height
                      child: CachedNetworkImage(
                        imageUrl: nowPlaying.artUri.toString(),
                        fadeOutDuration: const Duration(milliseconds: 400),
                        placeholder: (context, url) => const Icon(Icons.album_rounded, size: 45, color: Colors.white10),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.album_rounded, size: 45, color: Colors.white10),
                      ),
                    ),
                    title: Text(nowPlaying.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
                    subtitle: Text(nowPlaying.artist!,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                  ),
                  // Padding(
                  //     padding: const EdgeInsets.only(top: 5),
                  //     child: Divider(
                  //       indent: 20,
                  //       endIndent: 20,
                  //       color: Colors.grey,
                  //       thickness: 1,
                  //     )),
                  // ])),
                  // Container(
                  //     child: Column(children: [
                  //   Padding(
                  //       padding: const EdgeInsets.all(15),
                  //       child: Container(
                  //           alignment: Alignment.bottomLeft,
                  //           child: const Text(
                  //             "Next in Queue",
                  //             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  //             textAlign: TextAlign.left,
                  //           ))),
                  SizedBox(
                      height: MediaQuery.of(context).size.width - 100,
                      width: MediaQuery.of(context).size.width - 20,
                      child: ReorderableListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          onReorderStart: (val) => HapticFeedback.mediumImpact(),
                          onReorder: (int oldIndex, int newIndex) {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            playerWrapper.moveTrack(
                                oldIndex: offset + oldIndex, newIndex: offset + newIndex, inSession: socket.connected);
                          },
                          itemCount: min<int>(snapshot.data!.sequence.length - offset, 50),
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context1, index) {
                            var tag = snapshot.data!.sequence[index + offset].tag as MediaItem;
                            return InkWell(
                                key: Key('${tag.id}${index + offset}${snapshot.data!.sequence.length - offset}'),
                                onTap: () {
                                  playerWrapper.player.seek(const Duration(), index: index + offset);
                                  if (!playerWrapper.player.playing) {
                                    playerWrapper.play(inSession: socket.connected);
                                  }
                                },
                                child: DraggableSongListTile(
                                    offset: offset,
                                    amount: snapshot.data!.sequence.length - offset,
                                    id: tag.id,
                                    title: tag.title,
                                    artist: tag.artist!,
                                    artUri: tag.artUri.toString(),
                                    index: index + offset));
                          }))
                ]);
              } else {
                return const Column();
              }
            }));
  }
}

class DraggableSongListTile extends StatefulWidget {
  final String artUri;
  final String title;
  final String artist;
  final int index;
  final int amount;
  final String id;
  final int offset;

  const DraggableSongListTile(
      {required this.title,
      required this.artist,
      required this.artUri,
      required this.offset,
      required this.index,
      super.key,
      required this.id,
      required this.amount});

  @override
  State<StatefulWidget> createState() => _DraggableSongListTile();
}

class _DraggableSongListTile extends State<DraggableSongListTile> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Dismissible(
        key: Key('${widget.id}${widget.index}${widget.amount}'),
        direction: DismissDirection.endToStart,
        onDismissed: (DismissDirection direction) async {
          await playerWrapper.remove(index: widget.index, inSession: socket.connected);
          HapticFeedback.mediumImpact();
        },
        background: const ColoredBox(
          color: Color.fromARGB(255, 195, 77, 77),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(CupertinoIcons.trash, color: Colors.white),
            ),
          ),
        ),
        child: ListTile(
          visualDensity: VisualDensity.compact,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10.0), // fixed width and height
            child: CachedNetworkImage(
              imageUrl: widget.artUri,
              fadeOutDuration: const Duration(milliseconds: 400),
              placeholder: (context, url) => const Icon(Icons.album_rounded, size: 20, color: Colors.white10),
              errorWidget: (context, url, error) => const Icon(Icons.album_rounded, size: 20, color: Colors.white10),
            ),
          ),
          title: Text(widget.title, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
          subtitle: Text(widget.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
          trailing: ReorderableDragStartListener(
            index: widget.index - widget.offset,
            child: const Icon(Icons.drag_handle_rounded),
          ),
        ));
  }
}
