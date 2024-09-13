import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/api_requests/header.dart';

import '../../../globals.dart';

class BottomContextMenu extends StatefulWidget {
  final Playlist playlist;
  final Function() onDelete;
  final Color accentColor;

  const BottomContextMenu(
      {super.key,
      required this.playlist,
      required this.onDelete,
      this.accentColor = const Color.fromARGB(255, 208, 46, 60)});

  @override
  State<StatefulWidget> createState() => _BottomContextMenuState();
}

class _BottomContextMenuState extends State<BottomContextMenu> {
  final List<String> actionTitles = const ['Delete'];
  late List<Icon> actionIcons = [
    Icon(
      CupertinoIcons.delete,
      color: widget.accentColor,
    )
  ];

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

  Widget deletePlaylistTile(context) {
    return functionalTile(
        context: context,
        index: 0,
        function: () {
          widget.onDelete();
        });
  }

  Widget playlistTile(context) {
    return Container(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
        child: ListTile(
          leading: widget.playlist.artUri == null
              ? const Icon(Icons.album_rounded, size: 45, color: Colors.white10)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(5), // fixed width and height
                  child: CachedNetworkImage(
                    imageUrl: widget.playlist.artUri!,
                    fadeOutDuration: const Duration(milliseconds: 300),
                    placeholder: (context, url) => const Icon(Icons.album_rounded, size: 45, color: Colors.white10),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.album_rounded, size: 45, color: Colors.white10),
                  ),
                ),
          title: Text(
            widget.playlist.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
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
            initialChildSize: 0.3,
            minChildSize: 0.2,
            builder: (_, controller) => Container(
                decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 28, 27, 27),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
                child: ListView(physics: const BouncingScrollPhysics(), controller: controller, children: [
                  playlistTile(mainScreensContext[currScreen]),
                  deletePlaylistTile(mainScreensContext[currScreen])
                ]))));
  }
}
