import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/api_requests/sources/objects.dart';
import 'package:flutter_application_1/features/widgets/context_menu_actions.dart';
import 'package:flutter_application_1/features/widgets/tiles/playlist_tile.dart';
import 'package:palette_generator/palette_generator.dart';

import '../app.dart';
import '../globals.dart';
import 'api_requests/sources/api_request.dart';
import 'api_requests/sources/playlist_requests.dart';

bool isDark(Color color) {
  double greyScale = 0.299 * color.red + 0.587 * color.green + 0.114 * color.blue;
  return greyScale <= 128;
}

String allArtists(List<SimpleArtist> artists) {
  return List.generate(artists.length, (index) => artists[index].name).join(', ');
}

String allArtistsId(List<SimpleArtist> artists) {
  var res = List.generate(artists.length, (index) => artists[index].id).join(':');
  return res;
}

Future<List<Color>> getTwoPrimaryColors(String url) async {
  try {
    final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(Image.network(url).image);
    List<Color> res = [];
    for (var item in paletteGenerator.paletteColors) {
      res.add(item.color);
      if (res.length == 2) {
        return res;
      }
    }
    if (res.length == 1) {
      res.add(Colors.black12);
      return res;
    }
    return [Colors.black12, Colors.black];
  } catch (e) {
    return [Colors.black12, Colors.black];
  }
}

List<Color> getPrimaryColors(Iterable<Color> colors) {
  List<Color> res = [];
  for (var color in colors) {
    res.add(color);
    if (res.length == 2) {
      return res;
    }
  }
  if (res.length == 1) {
    res.add(Colors.black12);
    return res;
  }
  return [Colors.black, Colors.black12];
}

bool hasTextOverflow(String text, TextStyle style, TextScaler scaler,
    {double minWidth = 0, double maxWidth = double.infinity, int maxLines = 1}) {
  final TextPainter textPainter = TextPainter(
    textScaler: scaler,
    text: TextSpan(text: text, style: style),
    maxLines: maxLines,
    textDirection: TextDirection.ltr,
  )..layout(minWidth: minWidth, maxWidth: maxWidth);
  return textPainter.didExceedMaxLines;
}

int levenshteinDistance(String s1, String s2) {
  int n = s1.length;
  int m = s2.length;
  if (n < m) {
    return levenshteinDistance(s2, s1);
  }
  List<int> prevRow = List.generate(m, (index) => index);
  for (int i = 0; i < n; i++) {
    List<int> row = List.filled(m, i);
    for (int j = 0; j < m; j++) {
      final insertionCost = 1 + prevRow[j];
      final deletionCost = 1 + row[j - 1];
      final substitutionCost = (s1[i - 1] == s2[j - 1] ? 0 : 1) + prevRow[j - 1];
      final val = min<int>(min<int>(insertionCost, deletionCost), substitutionCost);
      row[j] = val;
    }
    prevRow = row;
  }
  return prevRow[m];
}

void sortByLevenshteinDistance(String pattern, List<BasicSimpleObject> items) {
  Map<String, int> distances = {};
  for (var item in items) {
    distances[item.id] = levenshteinDistance(pattern, item.name);
  }
  items.sort((a, b) => distances[a.id]!.compareTo(distances[b.id]!));
}

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

Future<Map<String, dynamic>> getServerData(int userId) async {
  Map<String, dynamic> res = {'playlists': [], 'likedTracks': []};
  try {
    List<dynamic>? playlists = await getUserPlaylists(userId: userId);
    if (playlists != null) {
      res['playlists'] = playlists;
    }
    List<String>? liked = await getLikedTracks(userId: userId.toString());
    if (liked != null) {
      res['likedTracks'] = liked;
    }
  } catch (e) {
    print(e);
  }
  return res;
}

Widget toAppFuture() {
  return FutureBuilder(
      future: getServerData(int.parse(userData['id'])),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.red,
              ),
            ),
          );
        } else {
          userData['likedTracks'] = snapshot.data!['likedTracks'];
          userData['playlists'] = {};
          likedTracks = Set.from(userData['likedTracks']);
          for (var item in snapshot.data!['playlists']) {
            userData['playlists'][item['playlist_id']] = item;
          }
          return const ShareMusicApp();
        }
      });
}

Widget listOfPlaylists({required List<Playlist> playlists, required Function(int) onTap}) {
  return Scaffold(
      body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.white10, Colors.white54])),
          child: Scaffold(
              appBar: AppBar(
                centerTitle: true,
                backgroundColor: Colors.transparent,
                title: const Text(
                  "Choose playlist",
                  style: TextStyle(fontSize: 30),
                ),
              ),
              backgroundColor: Colors.transparent,
              body: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  return InkWell(
                      onTap: () {
                        onTap(index);
                      },
                      child: PlaylistTile(
                          id: playlists[index].id, name: playlists[index].name, artUri: playlists[index].artUri));
                },
              ))));
}

Future<void> addTrackToPlaylistFunction(
    {required context, required SimplifiedTrack track, required SimpleAlbum album}) async {
  List<int> ids = [];
  for (var key in userData['playlists'].keys) {
    ids.add(key);
  }
  List<Playlist> playlists = List.generate(ids.length, (index) {
    List<dynamic>? tracks = userData['playlists'][ids[index]]['tracks_id'];
    List<String> tracksId = [];
    if (tracks != null) {
      for (var id in tracksId) {
        tracksId.add(id.toString());
      }
    }
    return Playlist(
        id: ids[index],
        name: userData['playlists'][ids[index]]['playlist_name'],
        artUri: userData['playlists'][ids[index]]['art_uri'],
        tracksId: tracksId);
  });
  await Future.delayed(const Duration(milliseconds: 300), () {
    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
        builder: (context) => listOfPlaylists(
            playlists: playlists,
            onTap: (index) async {
              try {
                await addToPlaylistAction(
                    context: context, track: track, playlistId: playlists[index].id, album: album);
                showMessage(context, 'added to ${userData['playlists'][playlists[index].id]['playlist_name']}');
              } catch (e) {
                showMessage(context, 'something went wrong');
              }
              await Future.delayed(const Duration(milliseconds: 300), () {
                Navigator.of(context, rootNavigator: true).pop();
              });
            })));
  });
}
