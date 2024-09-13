import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/api_requests/header.dart' as api;
import 'package:flutter_application_1/features/api_requests/sources/objects.dart';
import 'package:flutter_application_1/features/widgets/date.dart';
import 'package:flutter_application_1/features/widgets/tiles/track_tile.dart' as widgets;
import 'package:flutter_application_1/features/widgets/track_bottom_context_menu.dart';
import 'package:flutter_application_1/features/widgets/track_pull_down_button.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../globals.dart';
import '../player.dart';
import '../utils.dart';
import 'artist_screen.dart';

class AlbumScreen extends StatefulWidget {
  final String albumId;
  final List<SimpleArtist>? overrideArtists;
  final String? overrideArtistsString;
  const AlbumScreen({super.key, required this.albumId, this.overrideArtists, this.overrideArtistsString});

  @override
  State<StatefulWidget> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late Future<List<api.FullArtist>?> artists;
  late Future<api.FullAlbum?> album;
  late Future<PaletteGenerator> background;

  @override
  Widget build(BuildContext context) {
    return futureAlbum(context);
  }

  @override
  void initState() {
    super.initState();
    getInfo();
  }

  static void overrideArtist(List<SimpleArtist> artist, FullAlbum album) {
    album.artists = artist;
  }

  void getInfo() async {
    album = api.getFullAlbum(widget.albumId);
    album.then((value) {
      if (value != null) {
        if (widget.overrideArtists != null) {
          overrideArtist(widget.overrideArtists!, value);
        } else if (widget.overrideArtistsString != null) {
          value.artists[0].name = widget.overrideArtistsString!;
        }
        background = PaletteGenerator.fromImageProvider(Image.network(value.images[2].url).image);
        artists = api.getArtists(List.generate(value.artists.length, (index) => value.artists[index].id));
      }
    }).onError((error, stackTrace) {
      artists = Future(() => []);
    });
  }

  Widget futureArtistsLists(context, api.FullAlbum album) {
    List<String> ids = List.generate(album.artists.length, (index) => album.artists[index].id);
    List<String> names = List.generate(album.artists.length, (index) => album.artists[index].name);
    return FutureBuilder(
        future: artists,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return list(names, ids, []);
          } else if (snapshot.data == null || snapshot.hasError) {
            return list(names, ids, []);
          } else {
            List<String> uris = List.generate(snapshot.data!.length, (index) => snapshot.data![index].images[2].url);
            return list(names, ids, uris);
          }
        });
  }

  Widget list(final names, final ids, final List<String> uris) {
    return ListView.builder(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.only(right: 20, top: 20, bottom: 20),
        shrinkWrap: true,
        itemCount: names.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return InkWell(
              onTap: ids[index] != "0LyfQWJT6nXafLPZqxe9Of"
                  ? () {
                      Navigator.push(context,
                          CupertinoPageRoute(builder: (BuildContext context) => ArtistScreen(artistId: ids[index])));
                      // PageTransition(
                      //     child: ArtistScreen(artistId: ids[index]),
                      //     type: PageTransitionType.fade,
                      //     duration: const Duration(milliseconds: 200),
                      //     alignment: Alignment.center));
                    }
                  : () {},
              child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: ListTile(
                      leading: uris.isEmpty
                          ? const Icon(Icons.people_rounded, size: 55, color: Colors.white10)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(45),
                              // fixed width and height
                              child: CachedNetworkImage(
                                fit: BoxFit.cover,
                                height: 45,
                                width: 45,
                                imageUrl: uris[index],
                                fadeOutDuration: const Duration(milliseconds: 300),
                                placeholder: (context, url) =>
                                    const Icon(Icons.people_rounded, size: 45, color: Colors.white10),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.people_rounded, size: 45, color: Colors.white10),
                              ),
                            ),
                      title: Text(names[index],
                          style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 15)))));
        });
  }

  Widget futureAlbum(context) {
    return FutureBuilder(
        future: album,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.red)));
          } else if (snapshot.data == null) {
            return const Scaffold(body: Center(child: Text("something went wrong")));
          } else {
            return getAlbum(album: snapshot.data!, context: context);
          }
        });
  }

  // void prepareTracks(api.FullAlbum album) {
  //   for (var item in album.tracks) {
  //     tracks.add(api.MinimalMetaData(
  //         artistId: item.artists[0].id,
  //         albumId: album.id,
  //         trackId: item.id,
  //         title: item.name,
  //         artist: item.artists[0].name,
  //         artUri: Uri.parse(album.images[0].url),
  //         duration_ms: item.duration_ms));
  //   }
  // }

  bool isDark(Color color) {
    double greyScale = 0.299 * color.red + 0.587 * color.green + 0.114 * color.blue;
    return greyScale <= 128;
  }

  List<Color> getPrimaryColors(Iterable<Color> colors) {
    List<Color> res = [];
    for (var color in colors) {
      if (isDark(color)) {
        res.add(color);
      }
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

  Widget getAlbum({required api.FullAlbum album, required context}) {
    var size = MediaQuery.of(context).size;
    String copyrights = "";
    for (var item in album.copyrights) {
      copyrights += item["text"] + '\n';
    }
    List<api.SimpleArtist> artists = album.artists;
    int amountTracks = album.tracks.length;
    String trackInfo = amountTracks == 1 ? 'song' : "songs";
    String date = Date.fromString(album.release_date).toString();
    var theme = Theme.of(context);
    return Scaffold(
        body: FutureBuilder<PaletteGenerator>(
            future: background,
            builder: (BuildContext context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const Center(child: CircularProgressIndicator(color: Colors.red));
                default:
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    List<Color> backgroundColor = getPrimaryColors(snapshot.data!.colors);
                    return SlidableAutoCloseBehavior(
                        child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.bottomLeft, end: Alignment.topRight, colors: backgroundColor)),
                      child: Scaffold(
                          backgroundColor: Colors.transparent,
                          extendBodyBehindAppBar: false,
                          appBar: AppBar(
                            shadowColor: Colors.black26,
                            backgroundColor: Colors.transparent,
                            leading: IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.keyboard_arrow_left_rounded),
                            ),
                            actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz))],
                          ),
                          body: CupertinoScrollbar(
                              child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 150),
                                  child: Column(children: [
                                    Stack(
                                      children: [
                                        // shadow
                                        Padding(
                                          padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
                                          child: Container(
                                            width: size.width - 100,
                                            height: size.width - 100,
                                            decoration: BoxDecoration(boxShadow: [
                                              BoxShadow(
                                                  color: theme.shadowColor,
                                                  blurRadius: 50,
                                                  spreadRadius: 5,
                                                  offset: const Offset(-10, 40))
                                            ], borderRadius: BorderRadius.circular(20)),
                                          ),
                                        ),
                                        // picture
                                        Padding(
                                          padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(15.0),
                                            child: CachedNetworkImage(
                                              imageUrl: album.images[0].url,
                                              fadeOutDuration: const Duration(milliseconds: 200),
                                              fadeInDuration: const Duration(milliseconds: 200),
                                              placeholder: (context, url) => Icon(Icons.album_rounded,
                                                  color: Colors.white12, size: (size.width - 60)),
                                              errorWidget: (context, url, error) => Icon(Icons.error_outline,
                                                  color: Colors.white12, size: (size.width - 60)),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    // album & artist Name
                                    Padding(
                                      padding: const EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 20),
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  List<String>.from(album.genres).join(", "),
                                                  style: theme.textTheme.bodySmall,
                                                ),
                                                SizedBox(
                                                    width: size.width - 50,
                                                    child: Text(album.name,
                                                        textAlign: TextAlign.center,
                                                        style: GoogleFonts.ubuntu(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w400, shadows: [const Shadow(color: Colors.black, blurRadius: 5, offset: Offset(2, 2))]))
                                                ),
                                                InkWell(
                                                    onTap: artists[0].name != "Various Artists"
                                                        ? () {
                                                            String artistId = artists[0].id;
                                                            Navigator.push(
                                                                context,
                                                                CupertinoPageRoute(
                                                                    builder: (context) =>
                                                                        ArtistScreen(artistId: artistId))
                                                                // PageTransition(
                                                                //     child: res,
                                                                //     type: PageTransitionType.fade,
                                                                //     duration: const Duration(milliseconds: 400),
                                                                //     alignment: Alignment.center),
                                                                );
                                                          }
                                                        : () {},
                                                    child: Padding(
                                                        padding: const EdgeInsets.only(top: 10),
                                                        child: Text(
                                                          artists[0].name,
                                                          maxLines: 2,
                                                          textAlign: TextAlign.center,
                                                          style: GoogleFonts.ubuntu(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w400, shadows: [const Shadow(color: Colors.black, blurRadius: 5, offset: Offset(2, 2))]),
                                                        ))),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(right: 5),
                                              child: TextButton(
                                                style: ButtonStyle(
                                                    backgroundColor:
                                                        const MaterialStatePropertyAll<Color>(Colors.white),
                                                    fixedSize: MaterialStatePropertyAll(Size(size.width / 2.5, 50)),
                                                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                        RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10.0)))),
                                                onPressed: () {
                                                  playerWrapper.turnOnPlaylist(
                                                      tracksMetaData: List.generate(
                                                          album.tracks.length,
                                                          (index) => PlayerWrapper.getMetaData(
                                                              track: album.tracks[index], album: album)),
                                                      context: context);
                                                },
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(CupertinoIcons.play_fill, color: backgroundColor[0]),
                                                    Text("Play", style: TextStyle(color: backgroundColor[0]))
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 5),
                                              child: TextButton(
                                                style: ButtonStyle(
                                                    backgroundColor:
                                                        const MaterialStatePropertyAll<Color>(Colors.white),
                                                    fixedSize: MaterialStatePropertyAll(Size(size.width / 2.5, 50)),
                                                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                        RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10.0)))),
                                                onPressed: () {
                                                  playerWrapper.turnOnPlaylist(
                                                      shuffle: true,
                                                      tracksMetaData: List.generate(
                                                          album.tracks.length,
                                                          (index) => PlayerWrapper.getMetaData(
                                                              track: album.tracks[index], album: album)),
                                                      context: context);
                                                },
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(CupertinoIcons.shuffle, color: backgroundColor[0]),
                                                    Text("Shuffle", style: TextStyle(color: backgroundColor[0]))
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        )),
                                    ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        scrollDirection: Axis.vertical,
                                        itemCount: amountTracks,
                                        physics: const BouncingScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          String artists = '';
                                          for (var item in album.tracks[index].artists) {
                                            artists += '${item.name}, ';
                                          }
                                          artists = artists.substring(0, artists.length - 2);
                                          api.SimplifiedTrack currTrack = album.tracks[index];
                                          return Slidable(
                                              closeOnScroll: true,
                                              key: UniqueKey(),
                                              startActionPane: ActionPane(
                                                motion: const DrawerMotion(),
                                                dismissible: DismissiblePane(
                                                  dismissThreshold: 0.8,
                                                  closeOnCancel: true,
                                                  confirmDismiss: () async {
                                                    showMessage(context, "added to queue");
                                                    playerWrapper.addToQueue(
                                                        inSession: socket.connected,
                                                        context: context,
                                                        metaData:
                                                            PlayerWrapper.getMetaData(track: currTrack, album: album));
                                                    HapticFeedback.mediumImpact();
                                                    return false;
                                                  },
                                                  onDismissed: () {},
                                                ),
                                                children: [
                                                  CustomSlidableAction(
                                                      autoClose: true,
                                                      backgroundColor: const Color.fromARGB(255, 99, 87, 181),
                                                      child: Center(
                                                          child: Image.asset('assets/icon/last.png',
                                                              height: 25, width: 25)),
                                                      onPressed: (context) {
                                                        print(socket.connected);
                                                        playerWrapper.addToQueue(
                                                            inSession: socket.connected,
                                                            context: context,
                                                            metaData: PlayerWrapper.getMetaData(
                                                                track: currTrack, album: album));
                                                        showMessage(context, "added to queue");
                                                        HapticFeedback.mediumImpact();
                                                      }),
                                                  CustomSlidableAction(
                                                      autoClose: true,
                                                      backgroundColor: const Color.fromARGB(255, 218, 124, 35),
                                                      child: Center(
                                                          child: Image.asset('assets/icon/first.png',
                                                              height: 25, width: 25)),
                                                      onPressed: (context) {
                                                        playerWrapper.addToQueue(
                                                            inSession: socket.connected,
                                                            toEnd: false,
                                                            context: context,
                                                            metaData: PlayerWrapper.getMetaData(
                                                                track: currTrack, album: album));
                                                        showMessage(context, "added to queue");
                                                        HapticFeedback.mediumImpact();
                                                      })
                                                ],
                                              ),
                                              child: InkWell(
                                                  onLongPress: () {
                                                    showModalBottomSheet(
                                                        enableDrag: false,
                                                        // enableDrag: false,
                                                        isDismissible: false,
                                                        useRootNavigator: true,
                                                        backgroundColor: Colors.transparent,
                                                        context: context,
                                                        builder: (context) => BottomContextMenu(
                                                            track: currTrack, album: album, artists: currTrack.artists),
                                                        isScrollControlled: true);
                                                  },
                                                  onTap: () {
                                                    if (playerWrapper.player.playing) {
                                                      playerWrapper.player.stop();
                                                    }
                                                    playerWrapper.turnOnPlaylist(
                                                        tracksMetaData: List.generate(
                                                            album.tracks.length - index,
                                                            (currIndex) => PlayerWrapper.getMetaData(
                                                                track: album.tracks[currIndex + index], album: album)),
                                                        context: context);
                                                    // widget.miniPlayer();
                                                  },
                                                  child: widgets.TrackTile(
                                                    title: album.tracks[index].name,
                                                    artist: artists,
                                                    leadingText: (index + 1).toString(),
                                                    trailing: PullDownContextMenuButton(
                                                      track: album.tracks[index],
                                                      album: album,
                                                      artists: album.tracks[index].artists,
                                                    ),
                                                    // trailingIconFunction: () {
                                                    //   showModalBottomSheet(
                                                    //     useRootNavigator: true,
                                                    //       enableDrag: false,
                                                    //       isDismissible: false,
                                                    //       backgroundColor: Colors.transparent,
                                                    //       context: context,
                                                    //       builder: (context) => BottomContextMenu(
                                                    //           track: currTrack, album: album, artists: currTrack.artists),
                                                    //       isScrollControlled: true);
                                                    // },
                                                  )));
                                        }),
                                    futureArtistsLists(context, album),
                                    Padding(
                                        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
                                        child: SizedBox(
                                            width: size.width,
                                            child: Text('$date\n$amountTracks $trackInfo\n$copyrights',
                                                textAlign: TextAlign.left, style: theme.textTheme.labelSmall))),
                                  ])))),
                    ));
                  }
              }
            }));
  }
}
