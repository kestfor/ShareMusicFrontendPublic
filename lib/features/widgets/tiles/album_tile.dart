import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AlbumTile extends StatefulWidget {
  final String name;
  final String id;
  final String? artUri;

  const AlbumTile({super.key, required this.name, required this.id, this.artUri});

  @override
  State<StatefulWidget> createState() => _AlbumState();
}

class _AlbumState extends State<AlbumTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration:
            const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: Colors.white10, width: 0.5))),
        child: ListTile(
          subtitle: Text("Album", style: Theme.of(context).textTheme.bodySmall),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(45), // fixed width and height
            child: widget.artUri != null
                ? CachedNetworkImage(
                    height: 55,
                    width: 55,
                    imageUrl: widget.artUri!,
                    fadeOutDuration: const Duration(milliseconds: 300),
                    placeholder: (context, url) => const Icon(Icons.album_rounded, size: 55, color: Colors.white10),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.album_rounded, size: 55, color: Colors.white10),
                  )
                : const Icon(Icons.album_rounded, size: 55, color: Colors.white10),
          ),
          title: Text(widget.name, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
        ));
  }
}
