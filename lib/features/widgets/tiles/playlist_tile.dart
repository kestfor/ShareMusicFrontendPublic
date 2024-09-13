import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class _PlaylistTileState extends State<PlaylistTile> {
  Widget leading({double size = 80}) {
    return Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
            width: size,
            height: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15), // fixed width and height
              child: widget.artUri != null
                  ? CachedNetworkImage(
                      height: size,
                      width: size,
                      fit: BoxFit.cover,
                      imageUrl: widget.artUri!,
                      fadeOutDuration: const Duration(milliseconds: 300),
                      placeholder: (context, url) => Icon(Icons.album_rounded, size: size, color: Colors.white10),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.album_rounded, size: size, color: Colors.white10),
                    )
                  : widget.leadingIcon ?? Icon(Icons.album_rounded, size: size, color: Colors.white10),
            )));
  }

  Widget title({required String title}) {
    return Flexible(
        child: Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 100,
        child: Row(
          children: [
            leading(),
            title(title: widget.name),
          ],
        ));
  }
}

class PlaylistTile extends StatefulWidget {
  final String name;
  final int id;
  final String? artUri;
  final Icon? leadingIcon;

  @override
  State<StatefulWidget> createState() => _PlaylistTileState();

  const PlaylistTile({super.key, required this.name, required this.id, this.artUri, this.leadingIcon});
}
