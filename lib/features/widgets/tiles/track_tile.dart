import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class TrackTile extends StatefulWidget {
  final String title;
  final String artist;
  final String? artUri;
  final String? leadingText;
  final Widget? trailing;
  final Function()? trailingIconFunction;

  const TrackTile(
      {required this.title,
      required this.artist,
      this.artUri,
      this.leadingText,
      super.key,
      this.trailingIconFunction,
      this.trailing});

  @override
  State<TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> {
  Widget withArt(BuildContext context) {
    var theme = Theme.of(context);
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(5), // fixed width and height
        child: CachedNetworkImage(
          imageUrl: widget.artUri!,
          fadeOutDuration: const Duration(milliseconds: 400),
          placeholder: (context, url) => const Icon(Icons.album_rounded, size: 45, color: Colors.white10),
          errorWidget: (context, url, error) => const Icon(Icons.album_rounded, size: 45, color: Colors.white10),
        ),
      ),
      title: Text(widget.title, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
      subtitle: Text(widget.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
      trailing: widget.trailing ??
          IconButton(
            onPressed: () => widget.trailingIconFunction != null ? widget.trailingIconFunction!() : null,
            icon: const Icon(Icons.more_vert_rounded),
            color: theme.iconTheme.color,
          ),
    );
  }

  Widget withoutArt(BuildContext context) {
    var theme = Theme.of(context);
    return ListTile(
        key: widget.key,
        minLeadingWidth: 20,
        leading: Text(
          widget.leadingText!,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
        dense: true,
        title: Text(widget.title,
            overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20)),
        // subtitle: Text(widget.artist,
        //     style: theme.textTheme.bodySmall),
        trailing: widget.trailing ??
            IconButton(
              onPressed: () => widget.trailingIconFunction != null ? widget.trailingIconFunction!() : null,
              icon: const Icon(Icons.more_vert_rounded),
              color: theme.iconTheme.color,
            ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.artUri == null && widget.leadingText == null) {
      throw Exception("artUri or leadingText should be initialized");
    } else {
      if (widget.artUri != null) {
        return withArt(context);
      } else {
        return withoutArt(context);
      }
    }
  }
}
