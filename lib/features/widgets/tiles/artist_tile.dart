import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ArtistTile extends StatefulWidget {
  final String artist;
  final String id;
  final bool subtitle;
  final String? artUri;

  const ArtistTile({super.key, required this.artist, required this.id, this.artUri, this.subtitle = true});

  @override
  State<StatefulWidget> createState() => _ArtistState();
}

class _ArtistState extends State<ArtistTile> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(45), // fixed width and height
        child: widget.artUri != null
            ? CachedNetworkImage(
                fit: BoxFit.cover,
                height: 55,
                width: 55,
                imageUrl: widget.artUri!,
                fadeOutDuration: const Duration(milliseconds: 300),
                placeholder: (context, url) => const Icon(Icons.people_rounded, size: 55, color: Colors.white10),
                errorWidget: (context, url, error) => const Icon(Icons.people_rounded, size: 55, color: Colors.white10),
              )
            : const Icon(Icons.people_rounded, size: 55, color: Colors.white10),
      ),
      subtitle: widget.subtitle ? Text("Artist", style: Theme.of(context).textTheme.bodySmall) : null,
      title: Text(widget.artist, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
