import "dart:core";

import "package:flutter_application_1/features/utils.dart";
import "package:just_audio_background/just_audio_background.dart";

class AlbumImage {
  final String url;
  final int? height;
  final int? width;

  const AlbumImage({required this.url, required this.height, required this.width});

  factory AlbumImage.fromJson(Map<String, dynamic> json) {
    return AlbumImage(url: json["url"], height: json["height"], width: json["width"]);
  }

  static List<AlbumImage> fromJsonList(List<dynamic> jsonList) {
    List<AlbumImage> resImages = [];
    for (var item in jsonList) {
      resImages.add(AlbumImage.fromJson(item));
    }
    return resImages;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> res = {};
    res['url'] = url;
    res['height'] = height;
    res['width'] = width;
    return res;
  }
}

class BasicSimpleObject {
  final String id;
  late String name;
  final String type;
  final String uri;

  // final Map<dynamic, dynamic> external_urls;
  final String href;

  BasicSimpleObject(
      {required this.id,
      required this.name,
      this.type = 'base',
      required this.uri,
      // required this.external_urls,
      required this.href});

  factory BasicSimpleObject.fromJson(Map<String, dynamic> json) {
    return BasicSimpleObject(
        id: json["id"],
        name: json["name"],
        // type: json["type"],
        uri: json["uri"],
        // external_urls: json["external_urls"],
        href: json["href"]);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> res = {};
    res['id'] = id;
    res['name'] = name;
    res['type'] = type;
    res['uri'] = uri;
    res['href'] = href;
    return res;
  }
}

class SimpleArtist extends BasicSimpleObject {
  SimpleArtist(
      {required super.id,
      required super.name,
      super.type = 'SimpleArtist',
      required super.uri,
      // required super.external_urls,
      required super.href});

  factory SimpleArtist.fromJson(Map<String, dynamic> json) {
    return SimpleArtist(
        id: json["id"],
        name: json["name"],
        uri: json["uri"],
        // external_urls: json["external_urls"],
        href: json["href"]);
  }

  static List<SimpleArtist> fromJsonList(List<dynamic> jsonList) {
    List<SimpleArtist> resList = [];
    for (var artist in jsonList) {
      resList.add(SimpleArtist.fromJson(artist));
    }
    return resList;
  }
}

class FullArtist extends SimpleArtist {
  final Map<String, dynamic> followers;
  final List<dynamic> genres;
  final List<AlbumImage> images;
  final int popularity;

  FullArtist(
      {required super.id,
      required super.name,
      super.type = "FullArtist",
      required super.uri,
      // required super.external_urls,
      required super.href,
      required this.followers,
      required this.genres,
      required this.images,
      required this.popularity});

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> res = super.toJson();
    res.addAll({
      'followers': followers,
      'genres': genres,
      'images': List.generate(images.length, (index) => images[index].toJson()),
      'popularity': popularity
    });
    return res;
  }

  factory FullArtist.fromJson(Map<String, dynamic> json) {
    return FullArtist(
        id: json["id"],
        name: json["name"],
        uri: json["uri"],
        // external_urls: json["external_urls"],
        href: json['href'],
        followers: json['followers'],
        genres: json['genres'],
        images: AlbumImage.fromJsonList(json["images"]),
        popularity: json['popularity']);
  }

  static List<FullArtist> fromJsonList(List<dynamic> jsonList) {
    List<FullArtist> resList = [];
    for (var album in jsonList) {
      resList.add(FullArtist.fromJson(album));
    }
    return resList;
  }
}

class SimpleAlbum extends BasicSimpleObject {
  final String album_type;
  final int total_tracks;

  // final List<dynamic> availableMarkets;
  final List<AlbumImage> images;
  final String release_date;
  final String release_date_precision;
  List<SimpleArtist> artists;

  SimpleAlbum(
      {required super.id,
      required super.name,
      super.type = "SimpleAlbum",
      required super.uri,
      // required super.external_urls,
      required super.href,
      required this.album_type,
      required this.total_tracks,
      // required this.availableMarkets,
      required this.images,
      required this.release_date,
      required this.release_date_precision,
      required this.artists});

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> res = super.toJson();
    res.addAll({
      'album_type': album_type,
      'total_tracks': total_tracks,
      'images': List.generate(images.length, (index) => images[index].toJson()),
      'release_date': release_date,
      'release_date_precision': release_date_precision,
      'artists': List.generate(artists.length, (index) => artists[index].toJson())
    });
    return res;
  }

  factory SimpleAlbum.fromJson(Map<String, dynamic> json) {
    return SimpleAlbum(
        id: json["id"],
        name: json["name"],
        uri: json["uri"],
        // external_urls: json["external_urls"],
        href: json["href"],
        album_type: json["album_type"],
        total_tracks: json["total_tracks"],
        // availableMarkets: json["available_markets"],
        images: AlbumImage.fromJsonList(json["images"]),
        release_date: json["release_date"],
        release_date_precision: json["release_date_precision"],
        artists: SimpleArtist.fromJsonList(json["artists"]));
  }

  static List<SimpleAlbum> fromJsonList(List<dynamic> jsonList) {
    List<SimpleAlbum> resList = [];
    for (var album in jsonList) {
      resList.add(SimpleAlbum.fromJson(album));
    }
    return resList;
  }
}

// class PlaylistOwner {
//   final String displayName;
//   final Map<String, dynamic> external_urls;
//   final String href;
//   final String id;
//   final String type;
//   final String uri;
//
//   const PlaylistOwner(
//       {required this.displayName,
//       required this.external_urls,
//       required this.href,
//       required this.id,
//       this.type = "playlist",
//       required this.uri});
//
//   factory PlaylistOwner.fromJson(Map<String, dynamic> json) {
//     return PlaylistOwner(
//         displayName: json["display_name"],
//         external_urls: json["external_urls"],
//         href: json["href"],
//         id: json["id"],
//         uri: json["uri"]);
//   }
// }

// class SimplePlaylist extends BasicSimpleObject {
//   final bool collaborative;
//   final String description;
//   final List<AlbumImage> images;
//   final PlaylistOwner owner;
//   final bool? public;
//   final String snapshotId;
//   final Map<String, dynamic> tracks;
//
//   const SimplePlaylist(
//       {required super.id,
//       required super.name,
//       required super.type,
//       required super.uri,
//       required super.external_urls,
//       required super.href,
//       required this.collaborative,
//       required this.description,
//       required this.images,
//       required this.owner,
//       required this.public,
//       required this.snapshotId,
//       required this.tracks});
//
//   factory SimplePlaylist.fromJson(Map<String, dynamic> json) {
//     return SimplePlaylist(
//         id: json["id"],
//         name: json["name"],
//         type: json["type"],
//         uri: json["uri"],
//         external_urls: json["external_urls"],
//         href: json["href"],
//         collaborative: json['collaborative'],
//         description: json["description"],
//         images: AlbumImage.fromJsonList(json["images"]),
//         owner: PlaylistOwner.fromJson(json["owner"]),
//         public: json["public"],
//         snapshotId: json["snapshot_id"],
//         tracks: json["tracks"]);
//   }
// }

class SimplifiedTrack extends BasicSimpleObject {
  final List<SimpleArtist> artists;

  // final int disc_number;
  final int duration_ms;
  final bool explicit;

  // final bool isLocal;
  // final int track_number;

  // final String? previewUrl;

  SimplifiedTrack({
    required super.id,
    required super.name,
    super.type = "SimplifiedTrack",
    required super.uri,
    // required super.external_urls,
    required super.href,
    // required this.track_number,
    // required this.previewUrl,
    // required this.isLocal,
    required this.explicit,
    required this.duration_ms,
    // required this.disc_number,
    required this.artists,
  });

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> res = super.toJson();
    res.addAll({
      // 'disc_number': disc_number,
      'duration_ms': duration_ms,
      'explicit': explicit,
      // 'track_number': track_number,
      'artists': List.generate(artists.length, (index) => artists[index].toJson())
    });
    return res;
  }

  factory SimplifiedTrack.fromJson(Map<String, dynamic> json) {
    return SimplifiedTrack(
        id: json["id"],
        name: json["name"],
        // type: json["type"],
        uri: json["uri"],
        // external_urls: json["external_urls"],
        href: json["href"],
        artists: SimpleArtist.fromJsonList(json["artists"]),
        // disc_number: json["disc_number"],
        duration_ms: json["duration_ms"],
        explicit: json["explicit"]);
    // isLocal: json["is_local"],
    // previewUrl: json["preview_url"],
    // track_number: json["track_number"])
  }

  static List<SimplifiedTrack> fromJsonList(List<dynamic> jsonList) {
    List<SimplifiedTrack> resList = [];
    for (var track in jsonList) {
      resList.add(SimplifiedTrack.fromJson(track));
    }
    return resList;
  }
}

class SimpleTrack extends SimplifiedTrack {
  final SimpleAlbum album;

  // final Map<String, dynamic> externalIds;
  final int popularity;

  SimpleTrack({
    required super.id,
    required super.name,
    super.type = 'SimpleTrack',
    required super.uri,
    // required super.external_urls,
    required super.href,
    required super.artists,
    // required super.disc_number,
    required super.duration_ms,
    required super.explicit,
    // required super.isLocal,
    // required super.previewUrl,
    // required super.track_number,
    required this.album,
    required this.popularity,
    // required this.externalIds,
  });

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> res = super.toJson();
    res.addAll({
      'album': album.toJson(),
      'popularity': popularity,
    });
    return res;
  }

  factory SimpleTrack.fromJson(Map<String, dynamic> json) {
    return SimpleTrack(
      id: json["id"],
      name: json["name"],
      // type: json["type"],
      uri: json["uri"],
      // external_urls: json["external_urls"],
      href: json["href"],
      album: SimpleAlbum.fromJson(json["album"]),
      artists: SimpleArtist.fromJsonList(json["artists"]),
      // availableMarkets: json["available_markets"],
      // disc_number: json["disc_number"],
      duration_ms: json["duration_ms"],
      explicit: json["explicit"],
      // externalIds: json["external_ids"],
      // isLocal: json["is_local"],
      popularity: json["popularity"],
      // previewUrl: json["preview_url"],
      // track_number: json["track_number"]
    );
  }

  factory SimpleTrack.fromSimplified(SimplifiedTrack track, SimpleAlbum album) {
    return SimpleTrack(
        id: track.id,
        name: track.name,
        uri: track.uri,
        href: track.href,
        artists: track.artists,
        duration_ms: track.duration_ms,
        explicit: track.explicit,
        album: album,
        popularity: 100);
  }

  static List<SimpleTrack> fromJsonList(List<dynamic> jsonList) {
    List<SimpleTrack> resList = [];
    for (var track in jsonList) {
      resList.add(SimpleTrack.fromJson(track));
    }
    return resList;
  }
}

class FullAlbum extends SimpleAlbum {
  final List<dynamic> copyrights;

  // final Map<String, dynamic> externalIDs;
  final List<dynamic> genres;
  final String label;
  final int popularity;
  final List<SimplifiedTrack> tracks;

  FullAlbum(
      {required super.id,
      required super.name,
      super.type = "FullAlbum",
      required super.uri,
      // required super.external_urls,
      required super.href,
      required super.album_type,
      required super.total_tracks,
      // required super.availableMarkets,
      required super.images,
      required super.release_date,
      required super.release_date_precision,
      required super.artists,
      // required this.restrictions,
      required this.copyrights,
      // required this.externalIDs,
      required this.genres,
      required this.label,
      required this.popularity,
      required this.tracks});

  @override
  Map<String, dynamic> toJson() {
    var res = super.toJson();
    res.addAll({
      'copyrights': copyrights,
      'genres': genres,
      'label': label,
      'popularity': popularity,
      'tracks': {"items": List.generate(tracks.length, (index) => tracks[index].toJson())}
    });
    return res;
  }

  factory FullAlbum.fromJson(Map<String, dynamic> json) {
    return FullAlbum(
        album_type: json["album_type"],
        total_tracks: json["total_tracks"],
        // availableMarkets: json["available_markets"],
        // external_urls: json["external_urls"],
        href: json["href"],
        id: json["id"],
        images: AlbumImage.fromJsonList(json["images"]),
        name: json["name"],
        release_date: json["release_date"],
        release_date_precision: json["release_date_precision"],
        // restrictions: json["restrictions"],
        uri: json["uri"],
        artists: SimpleArtist.fromJsonList(json["artists"]),
        copyrights: json["copyrights"],
        // externalIDs: json["external_ids"],
        genres: json["genres"],
        label: json["label"],
        popularity: json["popularity"],
        tracks: SimplifiedTrack.fromJsonList(json["tracks"]["items"]));
  }
}

class Artist {
  late final id;
  final String type = "ArtistPage";
  final FullArtist artist;
  final List<SimpleAlbum> albums;
  final List<SimpleTrack> topTracks;

  Artist({required this.artist, required this.albums, required this.topTracks}) {
    id = artist.id;
  }

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
        artist: FullArtist.fromJson(json["artist"]),
        albums: SimpleAlbum.fromJsonList(json["albums"]),
        topTracks: SimpleTrack.fromJsonList(json["top_tracks"]));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      "artist": artist.toJson(),
      'albums': List.generate(albums.length, (index) => albums[index].toJson()),
      "top_tracks": List.generate(topTracks.length, (index) => topTracks[index].toJson())
    };
  }
}

class ExtendedMediaItem extends MediaItem {
  Map<String, String>? headers;
  final String trackId;
  final String artistId;
  final String albumId;
  String? fileUrl;
  List<dynamic> images;
  @override
  final Duration duration;
  @override
  final String artist;
  @override
  final Uri artUri;

  ExtendedMediaItem({
    required super.title,
    required this.images,
    required this.artist,
    required this.artUri,
    this.fileUrl,
    required this.duration,
    required this.trackId,
    required this.artistId,
    required this.albumId,
    required super.id,
    this.headers
  });


  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artUri': artUri.toString(),
      'images': images,
      'artist': artist,
      'fileUrl': fileUrl,
      'duration': duration.inMilliseconds,
      'trackId': trackId,
      'artistId': artistId,
      'albumId': albumId,
      'id': id,
      "headers": headers
    };
  }

  factory ExtendedMediaItem.fromJson({required Map<String, dynamic> json}) {
    return ExtendedMediaItem(
        title: json['title'],
        artUri: Uri.parse(json['artUri']),
        images: json['images'],
        artist: json['artist'],
        fileUrl: json['fileUrl'],
        duration: Duration(milliseconds: json['duration']),
        trackId: json['trackId'],
        artistId: json["artistId"],
        albumId: json["albumId"],
        headers: json['headers'],
        id: json['id']);
  }

  factory ExtendedMediaItem.fromSimpleTrack({required SimpleTrack track}) {
    return ExtendedMediaItem(
        title: track.name,
        artUri: Uri.parse(track.album.images[0].url),
        images: List.generate(track.album.images.length, (index) => track.album.images[index].url),
        artist: allArtists(track.artists),
        duration: Duration(milliseconds: track.duration_ms),
        trackId: track.id,
        artistId: allArtistsId(track.artists),
        albumId: track.album.id,
        id: track.id);
  }

  factory ExtendedMediaItem.fromSimplifiedObjects({required SimplifiedTrack track, required SimpleAlbum album}) {
    return ExtendedMediaItem(
        title: track.name,
        artUri: Uri.parse(album.images[0].url),
        images: List.generate(album.images.length, (index) => album.images[index].url),
        artist: allArtists(track.artists),
        duration: Duration(milliseconds: track.duration_ms),
        trackId: track.id,
        artistId: allArtistsId(track.artists),
        albumId: album.id,
        id: track.id);
  }
}

enum PlaylistType {
  likedTracks,
  createPlaylist,
  userPlaylist,
  //TODO systemPlaylist
}

class Playlist {
  final int id;
  final String name;
  final String? artUri;
  final List<String> tracksId;

  Playlist({required this.id, required this.name, this.artUri, required this.tracksId});

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
        id: json['playlist_id'],
        name: json['playlist_name'],
        artUri: json['art_uri'],
        tracksId: List.generate(json['tracks_id'].length, (index) => json['tracks_id'][index].toString()));
  }

  Map<String, dynamic> toJson() {
    return {'playlist_id': id, 'playlist_name': name, 'art_uri': artUri, 'tracks_id': tracksId};
  }
}

class User {
  final int userId;
  final String? username;
  final String? photoUrl;
  final String? firstName;
  final String? lastName;

  User({required this.userId, this.username, this.photoUrl, this.firstName, this.lastName});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        userId: json['user_id'],
        username: json['username'],
        photoUrl: json['photo_url'],
        firstName: json['first_name'],
        lastName: json['last_name']);
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'photo_url': photoUrl,
      'first_name': firstName,
      'last_name': lastName
    };
  }
}

enum RelationType { friends, firstUserRequest, secondUserRequest, noRelation, notImplemented }

class UsersRelation {
  late RelationType type;
  final int firstUserId;
  final int secondUserId;

  UsersRelation({required String relType, required this.firstUserId, required this.secondUserId}) {
    switch (relType) {
      case 'friends':
        type = RelationType.friends;
        break;
      case 'first_user_request':
        type = RelationType.firstUserRequest;
        break;
      case 'second_user_request':
        type = RelationType.secondUserRequest;
        break;
      case 'no relation':
        type = RelationType.noRelation;
        break;
      default:
        type = RelationType.notImplemented;
        break;
    }
  }
}
