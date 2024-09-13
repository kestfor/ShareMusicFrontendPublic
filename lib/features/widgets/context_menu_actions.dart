import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/api_requests/header.dart';
import 'package:flutter_application_1/features/api_requests/sources/playlist_requests.dart';
import 'package:flutter_application_1/features/player.dart';
import 'package:flutter_application_1/features/utils.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../globals.dart';
import 'album_screen.dart';
import 'artist_screen.dart';

void goToArtistAction({required artistId, required context}) {
  Navigator.push(context, CupertinoPageRoute(builder: (context) => ArtistScreen(artistId: artistId)));
  SystemSound.play(SystemSoundType.click);
}

void goToAlbumAction({required albumId, required context, artists}) {
  Navigator.push(context, CupertinoPageRoute(builder: (context) => AlbumScreen(albumId: albumId, overrideArtists: artists,)));
  SystemSound.play(SystemSoundType.click);
}

void playNextAction({required currTrack, required context, required album, required artist}) {
  playerWrapper.addToQueue(
      inSession: socket.connected,
      toEnd: false,
      metaData: PlayerWrapper.getMetaData(track: currTrack, album: album),
      context: context);
}

void addToQueueAction({required currTrack, required context, required album, required artist}) {
  playerWrapper.addToQueue(
      inSession: socket.connected,
      metaData: PlayerWrapper.getMetaData(track: currTrack, album: album),
      context: context);
}

Future<void> likeSongAction({required context, required String trackId}) async {
  bool res = await like(trackId: trackId);
  if (res) {
    likedTracks.add(trackId);
    userData['likedTracks'].add(trackId);
  } else {
    throw (Error);
  }
}

Future<void> addToPlaylistAction({required context, required SimplifiedTrack track , required int playlistId, required SimpleAlbum album}) async {
  bool res = await addTrack(userId: userData['id'], hash: userData['hash'], playlistId: playlistId, trackId: track.id);
  if (res) {
    if (userData['playlists'][playlistId]['tracks_id'] == null || userData['playlists'][playlistId]['tracks_id'].isEmpty) {
      userData['playlists'][playlistId]['tracks_id'] = [];
      changeArtAction(context: context, artUri: album.images[0].url, playlistId: playlistId);
    }
    userData['playlists'][playlistId]['tracks_id'].add(track.id);

    // showMessage(context, 'added to ${userData['playlists'][playlistId]['playlist_name']}');
  } else {
    throw (Error);
    // showMessage(context, 'something went wrong');
  }
}

void changeArtAction({required context, required String artUri, required playlistId}) async {
  bool res = await changeArt(userId: userData['id'], hash: userData['hash'], playlistId: playlistId, artUri: artUri);
  if (res) {
    userData['playlists'][playlistId]['art_uri'] = artUri;
  } else {
    showMessage(context, 'something went wrong');
  }
}

Future<void> unlikeSongAction({required context, required String trackId}) async {
  bool res = await unlike(trackId: trackId);
  if (res) {
    likedTracks.remove(trackId);
    userData['likedTracks'].remove(trackId);
    // showMessage(context, "deleted from liked songs");
  } else {
    print(res);
    throw (Error);
    // showMessage(context, "something went wrong");
  }
}

class ArtistsOnTrack extends StatefulWidget {
  final List<String> artistsId;
  late Function()? onTapOptional;

  ArtistsOnTrack({super.key, required this.artistsId, this.onTapOptional}) {
    onTapOptional = onTapOptional ?? () {};
  }

  @override
  State<StatefulWidget> createState() => _ArtistsOnTrackState();
}

class _ArtistsOnTrackState extends State<ArtistsOnTrack> {
  late Future<List<FullArtist>?> artists;

  @override
  void initState() {
    super.initState();
    artists = getArtists(widget.artistsId);
  }

  Widget futureArtists(context) {
    artists = getArtists(widget.artistsId);
    return FutureBuilder(
        future: artists,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return sheet(child: const Center(child: CircularProgressIndicator(color: Colors.red)), context: context);
          } else if (snapshot.data == null || snapshot.hasError) {
            return sheet(child: const Center(child: Text("something went wrong")), context: context);
          } else {
            return artistsList(artists: snapshot.data!, context: context);
          }
        });
  }

  Widget makeDismissible({required Widget child, required context}) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 200));
        },
        child: GestureDetector(onTap: () {}, child: child),
      );

  Widget sheet({context, required child}) {
    return makeDismissible(
        context: context,
        child: DraggableScrollableSheet(
            maxChildSize: 0.5,
            initialChildSize: getInitialSize(widget.artistsId.length),
            minChildSize: 0.2,
            builder: (_, controller) => Container(
                decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 28, 27, 27),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
                child: child)));
  }

  double getInitialSize(int amount) {
    if (amount >= 3 && amount <= 5) {
      return amount / 10;
    } else {
      if (amount > 5) {
        return 0.5;
      } else {
        return 0.3;
      }
    }
  }

  Widget artistsList({required context, required List<FullArtist> artists}) {
    return makeDismissible(
        context: context,
        child: DraggableScrollableSheet(
            maxChildSize: 0.5,
            initialChildSize: getInitialSize(artists.length),
            minChildSize: 0.2,
            builder: (_, controller) => Container(
                decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 28, 27, 27),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
                child: ListView(
                    controller: controller,
                    physics: const BouncingScrollPhysics(),
                    children: [const Padding(padding: EdgeInsets.all(5))] +
                        List.generate(
                            artists.length,
                            (index) => Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: InkWell(
                                          onTap: () async {
                                            Navigator.of(context, rootNavigator: true).pop();
                                            await widget.onTapOptional!();
                                            goToArtistAction(
                                                artistId: artists[index].id, context: mainScreensContext[currScreen]);
                                          },
                                          child: ListTile(
                                              leading: artists[index].images.isEmpty ? const Icon(Icons.people_rounded, size: 55, color: Colors.white10) :ClipRRect(
                                                borderRadius: BorderRadius.circular(45),
                                                // fixed width and height
                                                child: CachedNetworkImage(
                                                  fit: BoxFit.cover,
                                                  height: 55,
                                                  width: 55,
                                                  imageUrl: artists[index].images[2].url,
                                                  fadeOutDuration: const Duration(milliseconds: 300),
                                                  placeholder: (context, url) =>
                                                      const Icon(Icons.people_rounded, size: 55, color: Colors.white10),
                                                  errorWidget: (context, url, error) =>
                                                      const Icon(Icons.people_rounded, size: 55, color: Colors.white10),
                                                ),
                                              ),
                                              title: Text(artists[index].name,
                                                  style: GoogleFonts.roboto(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w400,
                                                      fontSize: 20))))),
                                ))))));
  }

  @override
  Widget build(BuildContext context) {
    return futureArtists(context);
  }
}
