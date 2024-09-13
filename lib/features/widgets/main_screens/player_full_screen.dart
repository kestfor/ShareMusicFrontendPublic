import "dart:convert";
import "dart:ui";

import "package:audio_video_progress_bar/audio_video_progress_bar.dart";
import "package:auto_size_text/auto_size_text.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:carousel_slider/carousel_slider.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_application_1/features/api_requests/header.dart";
import "package:flutter_application_1/features/lyrics.dart";
import "package:flutter_application_1/features/utils.dart";
import "package:flutter_application_1/features/widgets/album_screen.dart";
import "package:flutter_application_1/features/widgets/context_menu_actions.dart";
import 'package:flutter_application_1/features/widgets/queue_screen.dart';
import "package:google_fonts/google_fonts.dart";
import "package:http/http.dart";
import 'package:http/http.dart' as http;
import "package:just_audio/just_audio.dart";
import "package:marquee/marquee.dart";
import "package:palette_generator/palette_generator.dart";
import 'package:rxdart/rxdart.dart';
import "package:scrollable_positioned_list/scrollable_positioned_list.dart";
import "package:volume_controller/volume_controller.dart";

import "../../../globals.dart";
import '../artist_screen.dart';

class VolumeControllerWidget extends StatefulWidget {
  const VolumeControllerWidget({super.key});

  @override
  State<VolumeControllerWidget> createState() => _VolumeControllerWidgetState();
}

class _VolumeControllerWidgetState extends State<VolumeControllerWidget> {
  double setVolumeValue = 0;
  double height = 8;

  @override
  void initState() {
    super.initState(); // To get current device volume
    VolumeController().showSystemUI = false;
    VolumeController().getVolume().then((volume) => setVolumeValue = volume ?? 0.0);
    // Listen to system volume change
    VolumeController().listener((volume) {
      setState(() =>
          // set is value in listener value
          setVolumeValue = volume);
    });
  }

  @override
  void dispose() {
    VolumeController().removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProgressBar(
      barHeight: height,
      timeLabelLocation: TimeLabelLocation.none,
      thumbCanPaintOutsideBar: false,
      thumbGlowRadius: 10,
      baseBarColor: Colors.grey[600],
      bufferedBarColor: Colors.grey,
      progressBarColor: Colors.white,
      thumbColor: setVolumeValue == 0 ? Colors.grey[600] : Colors.white,
      thumbRadius: 2,
      progress: Duration(milliseconds: (setVolumeValue * 100).round()),
      // buffered: positionData?.bufferedPosition ?? Duration.zero,
      total: const Duration(milliseconds: 100),
      onDragStart: (details) {
        setState(() {
          height = 15;
          HapticFeedback.mediumImpact();
        });
      },
      onDragUpdate: (details) {
        setVolumeValue = details.timeStamp.inMilliseconds / 100;
        VolumeController().setVolume(setVolumeValue);
      },
      onDragEnd: () {
        setState(() {
          height = 8;
        });
      },
      onSeek: (value) {
        setVolumeValue = value.inMilliseconds / 100;
        VolumeController().setVolume(setVolumeValue);
      },
    );

    // return SliderTheme(data: SliderThemeData(
    //   trackHeight: height,
    //   trackShape: const RoundedRectSliderTrackShape(),
    //   overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
    //   thumbShape: RoundSliderThumbShape(enabledThumbRadius: setVolumeValue == 0 ? 3 : height / 2 + 1, elevation: 0, pressedElevation: 0),
    // ), child: Slider(
    //   inactiveColor: Colors.grey[600],
    //   activeColor: Colors.white,
    //   thumbColor: setVolumeValue == 0 ? Colors.grey[600] : Colors.white,
    //   min: 0,
    //   max: 1,
    //   onChangeStart: (value) {
    //     setState(() {
    //       HapticFeedback.mediumImpact();
    //       height = 15;
    //     });
    //   },
    //   onChangeEnd: (value) {
    //     setState(() {
    //       height = 6;
    //     });
    //   },
    //   onChanged: (double value) {
    //     setVolumeValue = value;
    //     //TODO посмотреть че будет если сделать await
    //     FlutterVolumeControllerWidget.setVolume(setVolumeValue);
    //     setState(() {});
    //   },
    //   value: setVolumeValue,
    // ));
  }
}

enum AnimatedWidgetForm {
  queue,
  art,
  lyrics,
}

int findCurrLyrPart(Duration currPosition, List<SyncedLyricsEntry> lyrics) {
  for (int i = 0; i < lyrics.length; i++) {
    if (lyrics[i].end - currPosition > const Duration()) {
      return i;
    }
  }
  return -1;
}

late Widget _myAnimatedWidget;
late AnimatedWidgetForm _myAnimatedWidgetForm;
late AnimatedWidgetForm _previousForm;
late Function _switch;
int? currLyrInd;
late List<Widget> lyrWidgetList;
double progressBarHeight = 6;

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  const PositionData(
    this.position,
    this.bufferedPosition,
    this.duration,
  );
}

// class MediaMetaData extends StatefulWidget {
//   final CarouselController carouselController;
//   final Function() updateFunc;
//
//   const MediaMetaData({super.key, required this.carouselController, required this.updateFunc});
//
//   @override
//   State<MediaMetaData> createState() => _MediaMetaDataState();
// }

// class _MediaMetaDataState extends State<MediaMetaData> {
//
//   void refresh() {
//     setState(() {
//       if (_myAnimatedWidgetForm == AnimatedWidgetForm.art) {
//         _myAnimatedWidgetForm = AnimatedWidgetForm.queue;
//       } else {
//         _myAnimatedWidgetForm = AnimatedWidgetForm.art;
//       }
//     });
//   }
//
//   @override
//   void initState() {
//     _myAnimatedWidgetForm = AnimatedWidgetForm.art;
//     _switch = refresh;
//     super.initState();
//   }
//
// }

class AudioPlayerScreen extends StatefulWidget {
  late final CarouselController carouselController;

  AudioPlayerScreen({super.key}) {
    carouselController = CarouselController();
  }

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> with SingleTickerProviderStateMixin {
  Future<List<Color>> trackBackground = Future(() => [Colors.black12, Colors.black]);
  final ItemScrollController _scrollController = ItemScrollController();
  static String lyricsApiUrl = "https://lrclib.net/api";
  late Future<Response> lyrics;
  late Lyrics? lyrObj;
  bool hasLyrics = false;

  late AnimationController _animationController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  Widget carousel({required context, required metadata, required stream, lyrics}) {
    return CarouselSlider.builder(
      itemCount: stream.sequence.length,
      itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
        if (itemIndex == playerWrapper.player.currentIndex && lyrics != null) {
          return Stack(
            children: [
              art(artUri: stream.sequence.elementAt(itemIndex).tag.artUri.toString(), context: context),
              lyrics,
            ],
          );
        }
        return art(artUri: stream.sequence.elementAt(itemIndex).tag.artUri.toString(), context: context);
      },
      carouselController: widget.carouselController,
      options: CarouselOptions(
        enableInfiniteScroll: false,
        enlargeFactor: 0.5,
        autoPlay: false,
        height: MediaQuery.of(context).size.width,
        initialPage: stream.currentIndex,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
        onPageChanged: (int index, CarouselPageChangedReason? reason) {
          if (reason == CarouselPageChangedReason.manual) {
            playerWrapper.seek(position: const Duration(), index: index);
            hasLyrics = false;
            _updateLyrics;
          }
        },
      ),
    );
  }

  Widget art({required artUri, required context}) {
    var theme = Theme.of(context);
    return Padding(
        padding: const EdgeInsets.only(bottom: 30, top: 10, left: 0, right: 0),
        child: DecoratedBox(
          decoration: BoxDecoration(boxShadow: const [
            BoxShadow(
                blurStyle: BlurStyle.normal,
                color: Colors.black54,
                blurRadius: 10,
                spreadRadius: 5,
                offset: Offset(-10, 10)),
          ], borderRadius: BorderRadius.circular(10)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: artUri,
              fit: BoxFit.cover,
              placeholder: (context, artUri) =>
                  Icon(Icons.album_rounded, size: MediaQuery.of(context).size.width - 40, color: Colors.white10),
              errorWidget: (context, artUri, error) =>
                  Icon(Icons.album_rounded, size: MediaQuery.of(context).size.width - 40, color: Colors.white10),
            ),
          ),
        ));
  }

  Widget metaDataWidget(BuildContext context, ExtendedMediaItem metaData, SequenceState stream) {
    var artistsId = metaData.artistId.split(':');
    var artists = metaData.artist.split(', ');
    switch (_myAnimatedWidgetForm) {
      case AnimatedWidgetForm.art:
        _myAnimatedWidget = carousel(context: context, metadata: metaData, stream: stream);
        break;
      case AnimatedWidgetForm.queue:
        _myAnimatedWidget = const Queue();
        break;
      case AnimatedWidgetForm.lyrics:
        _myAnimatedWidget = carousel(context: context, metadata: metaData, stream: stream, lyrics: lyricsWidget());
        break;
    }
    return Column(children: [
      SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width,
          child: AnimatedSwitcher(
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            duration: const Duration(milliseconds: 400),
            child: _myAnimatedWidget,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          )),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10, left: 20),
                  child: SizedBox(
                      height: 30,
                      width: MediaQuery.of(context).size.width - 100,
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          await Future.delayed(const Duration(milliseconds: 300));
                          Navigator.push(
                              mainScreensContext[currScreen],
                              CupertinoPageRoute(
                                  builder: (context) => AlbumScreen(
                                        albumId: metaData.albumId,
                                        overrideArtistsString: artists[0],
                                      )));
                        },
                        child: AutoSizeText(
                          metaData.title,
                          style: GoogleFonts.roboto(fontSize: 25, fontWeight: FontWeight.w400),
                          minFontSize: 25,
                          overflowReplacement: Marquee(
                              velocity: 25,
                              blankSpace: 40,
                              startAfter: const Duration(seconds: 5),
                              pauseAfterRound: const Duration(seconds: 5),
                              text: metaData.title,
                              style: GoogleFonts.roboto(fontSize: 25, fontWeight: FontWeight.w400)),
                        ),
                      )))),
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 20),
                  child: SizedBox(
                      height: 25,
                      width: MediaQuery.of(context).size.width - 100,
                      child: InkWell(
                          onTap: artistsId.length > 1
                              ? () {
                                  showModalBottomSheet(
                                      enableDrag: false,
                                      isDismissible: false,
                                      useRootNavigator: true,
                                      backgroundColor: Colors.transparent,
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (context) => ArtistsOnTrack(
                                          artistsId: artistsId,
                                          onTapOptional: () async {
                                            Navigator.of(mainScreensContext['Global']).pop();
                                            await Future.delayed(const Duration(milliseconds: 300));
                                          }));
                                }
                              : () async {
                                  Navigator.pop(context);
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  Navigator.push(mainScreensContext[currScreen],
                                      CupertinoPageRoute(builder: (context) => ArtistScreen(artistId: artistsId[0])));
                                },
                          child: AutoSizeText(
                            metaData.artist,
                            style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w400, color: Colors.grey),
                            minFontSize: 20,
                            textAlign: TextAlign.left,
                            overflowReplacement: Marquee(
                                velocity: 25,
                                blankSpace: 40,
                                startAfter: const Duration(seconds: 5),
                                pauseAfterRound: const Duration(seconds: 5),
                                text: metaData.artist,
                                style:
                                    GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w400, color: Colors.grey)),
                          ))))),
        ]),
        likedTracks.contains(metaData.trackId)
            ? Padding(
                padding: const EdgeInsets.only(right: 10, left: 10),
                child: IconButton(
                    icon: const Icon(
                      CupertinoIcons.heart_fill,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        //TODO update playlist screen
                        likedTracks.remove(metaData.trackId);
                        userData['likedTracks'].remove(metaData.trackId);
                        unlike(trackId: metaData.trackId).then((value) {
                          if (value == true) {
                            showMessage(context, 'deleted from liked tracks');
                          } else {
                            showMessage(context, 'something went wrong');
                            likedTracks.add(metaData.trackId);
                            userData['likedTracks'].add(metaData.trackId);
                          }
                        });
                      });
                    }))
            : Padding(
                padding: const EdgeInsets.only(right: 10, left: 10),
                child: IconButton(
                    onPressed: () {
                      setState(() {
                        //TODO update playlist screen
                        likedTracks.add(metaData.trackId);
                        userData['likedTracks'].add(metaData.trackId);
                        like(trackId: metaData.trackId).then((value) {
                          if (value == true) {
                            showMessage(context, 'added to liked tracks');
                          } else {
                            showMessage(context, 'something went wrong');
                            likedTracks.remove(metaData.trackId);
                            userData['likedTracks'].remove(metaData.trackId);
                          }
                        });
                      });
                    },
                    icon: const Icon(
                      CupertinoIcons.heart,
                      color: Colors.white,
                      size: 30,
                    )))
      ])
    ]);
  }

  Widget MediaMetaData(BuildContext context) {
    return StreamBuilder<SequenceState?>(
      stream: playerWrapper.player.sequenceStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state?.sequence.isEmpty ?? true) {
          return const SizedBox();
        }
        final metadata = state?.currentSource!.tag as ExtendedMediaItem;
        return metaDataWidget(context, metadata, state!);
      },
    );
  }

  void refreshColor() async {
    setState(() {
      _updateColor();
    });
  }

  void refreshLyrics() async {
    setState(() {
      _updateLyrics();
    });
  }

  CarouselController get carouselController => widget.carouselController;

  Stream<PositionData> get _positionDataStream => Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
      playerWrapper.player.positionStream,
      playerWrapper.player.bufferedPositionStream,
      playerWrapper.player.durationStream,
      (position, bufferedPosition, duration) => PositionData(position, bufferedPosition, duration ?? Duration.zero));

  static bool isDark(Color color) {
    double greyScale = 0.299 * color.red + 0.587 * color.green + 0.114 * color.blue;
    return greyScale <= 128;
  }

  Future<List<Color>> getTwoPrimaryColors(ImageProvider imageProvider) async {
    final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider);
    List<Color> res = [];
    for (var item in paletteGenerator.paletteColors) {
      if (isDark(item.color)) {
        res.add(item.color);
      }
      if (res.length == 2) {
        return res;
      }
    }
    if (res.length == 1) {
      res.add(Colors.black12);
      return res;
    }
    return [Colors.black12, Colors.black];
  }

  Future<void> _updateLyrics() async {
    setState(() {
      ExtendedMediaItem metadata = playerWrapper.player.sequenceState!.currentSource!.tag as ExtendedMediaItem;
      lyrics = http.get(Uri.parse("$lyricsApiUrl/search?q=${metadata.artist} ${metadata.title}"));
      currLyrInd = null;
      lyrObj = null;
      hasLyrics = false;
      lyrics.then((value) => setState(() {
            if (value.statusCode == 200) {
              ExtendedMediaItem metadata = playerWrapper.player.sequenceState!.currentSource!.tag as ExtendedMediaItem;
              dynamic finded = findMatchedDurationLyrics(
                  jsonDecode(value.body), playerWrapper.player.duration!.inSeconds, metadata.artist, metadata.title);
              if (finded != null) {
                lyrObj = Lyrics.fromJson(finded);
                lyrWidgetList = List.generate(lyrObj!.syncedLyrics!.length, (index) => getNonHighlighted(index));
                hasLyrics = true;
                // if (_scrollController.isAttached) {
                //   _scrollController.scrollTo(
                //       alignment: 0.4, index: currLyrInd!, duration: Duration(milliseconds: 400));
                // }
              }
            }
          }));
    });
  }

  void changeArtQueue() {
    setState(() {
      if (_myAnimatedWidgetForm == AnimatedWidgetForm.art || _myAnimatedWidgetForm == AnimatedWidgetForm.lyrics) {
        _previousForm = _myAnimatedWidgetForm;
        _myAnimatedWidgetForm = AnimatedWidgetForm.queue;
      } else {
        var tmp = _myAnimatedWidgetForm;
        _myAnimatedWidgetForm = _previousForm;
        _previousForm = _myAnimatedWidgetForm;
        if (_scrollController.isAttached) {
          _scrollController.scrollTo(alignment: 0.4, index: currLyrInd!, duration: Duration(milliseconds: 400));
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _updateLyrics();
    _myAnimatedWidgetForm = AnimatedWidgetForm.art;
    _previousForm = _myAnimatedWidgetForm;
    _switch = changeArtQueue;

    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    // _topAlignmentAnimation = TweenSequence<Alignment>(
    //   [
    //     TweenSequenceItem<Alignment>(
    //         tween: Tween<Alignment>(begin: Alignment.topLeft, end: Alignment.centerLeft), weight: 2),
    //     TweenSequenceItem<Alignment>(
    //         tween: Tween<Alignment>(begin: Alignment.centerLeft, end: Alignment.topLeft), weight: 2),
    //     TweenSequenceItem<Alignment>(
    //         tween: Tween<Alignment>(begin: Alignment.topLeft, end: Alignment.topRight), weight: 2),
    //     TweenSequenceItem<Alignment>(
    //         tween: Tween<Alignment>(begin: Alignment.topRight, end: Alignment.centerRight), weight: 2),
    //     TweenSequenceItem<Alignment>(
    //         tween: Tween<Alignment>(begin: Alignment.centerRight, end: Alignment.topRight), weight: 2),
    //     TweenSequenceItem<Alignment>(
    //         tween: Tween<Alignment>(begin: Alignment.topRight, end: Alignment.topLeft), weight: 2),
    //   ],
    // ).animate(_animationController);
    //
    // _bottomAlignmentAnimation = TweenSequence<Alignment>(
    //   [
    //     TweenSequenceItem<Alignment>(
    //         tween: Tween<Alignment>(begin: Alignment.bottomRight, end: Alignment.centerRight), weight: 2),
    //     TweenSequenceItem<Alignment>(
    //         tween: Tween<Alignment>(begin: Alignment.centerRight, end: Alignment.bottomRight), weight: 2),
    //     TweenSequenceItem<Alignment>(
    //         tween: Tween<Alignment>(begin: Alignment.bottomRight, end: Alignment.bottomLeft), weight: 2),
    //     TweenSequenceItem<Alignment>(
    //         tween: Tween<Alignment>(begin: Alignment.bottomLeft, end: Alignment.centerLeft), weight: 2),
    //     TweenSequenceItem<Alignment>(
    //         tween: Tween<Alignment>(begin: Alignment.centerLeft, end: Alignment.bottomLeft), weight: 2),
    //     TweenSequenceItem<Alignment>(
    //         tween: Tween<Alignment>(begin: Alignment.bottomLeft, end: Alignment.bottomRight), weight: 2),
    //   ],
    // ).animate(_animationController);
    //
    // _animationController.repeat();

    playerWrapper.player.currentIndexStream.listen((int? ind) async {
      if (ind != null) {
        _updateLyrics();
        try {
          if (_myAnimatedWidgetForm == AnimatedWidgetForm.lyrics) {
            _myAnimatedWidgetForm = AnimatedWidgetForm.art;
          }
          await carouselController.animateToPage(
              curve: Curves.ease, playerWrapper.player.currentIndex!, duration: const Duration(milliseconds: 300));
        } catch (e) {
          print(e);
        }
        refreshColor();
      }
    });
    colorRefresh = refreshColor;
    ExtendedMediaItem metadata = playerWrapper.player.sequenceState!.currentSource!.tag as ExtendedMediaItem;
    trackBackground = getTwoPrimaryColors(Image.network(metadata.images[2].toString()).image);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> _updateColor() async {
    ExtendedMediaItem metadata = playerWrapper.player.sequenceState!.currentSource!.tag as ExtendedMediaItem;
    trackBackground = getTwoPrimaryColors(Image.network(metadata.images[2].toString()).image);
  }

  //
  // @override
  // void setState(VoidCallback fn) {
  //   ExtendedMediaItem metadata = playerWrapper.player.sequenceState!.currentSource!.tag as ExtendedMediaItem;
  //   trackBackground = getTwoPrimaryColors(Image.network(metadata.images[2].toString()).image);
  //   super.setState(fn);
  // }

  @override
  Widget build(BuildContext context) {
    // ExtendedMediaItem metadata = playerWrapper.player.sequenceState!.currentSource!.tag as ExtendedMediaItem;
    // trackBackground = getTwoPrimaryColors(Image.network(metadata.images[2].toString()).image);
    return DraggableScrollableSheet(
        initialChildSize: 1,
        minChildSize: 0.25,
        builder: (_, controller) => FutureBuilder<List<Color>>(
            future: trackBackground,
            builder: (context, snapshot) {
              List<Color> background = snapshot.data == null || snapshot.data!.isEmpty
                  ? [Colors.black12, Colors.black]
                  : [snapshot.data![0], snapshot.data![1]];
              return SafeArea(
                  bottom: false,
                  child: Scaffold(
                      resizeToAvoidBottomInset: true,
                      extendBodyBehindAppBar: true,
                      appBar: AppBar(
                        toolbarHeight: 100,
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        leading: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz))],
                      ),
                      body: AnimatedBuilder(
                        builder: (context, _) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 1000),
                            padding: const EdgeInsets.all(0),
                            height: double.infinity,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                              colors: background,
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            )),
                            child: SingleChildScrollView(
                                child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 100),
                                MediaMetaData(context),
                                Padding(
                                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                                    child: StreamBuilder<PositionData>(
                                      stream: _positionDataStream,
                                      builder: (context, snapshot) {
                                        final positionData = snapshot.data;
                                        return ProgressBar(
                                          barHeight: progressBarHeight,
                                          timeLabelLocation: TimeLabelLocation.sides,
                                          thumbCanPaintOutsideBar: false,
                                          thumbGlowRadius: 2,
                                          baseBarColor: Colors.grey[600],
                                          bufferedBarColor: Colors.grey,
                                          progressBarColor: Colors.white,
                                          thumbColor: Colors.white,
                                          thumbRadius: 2,
                                          progress: positionData?.position ?? Duration.zero,
                                          // buffered: positionData?.bufferedPosition ?? Duration.zero,
                                          total: positionData?.duration ?? Duration.zero,
                                          onDragStart: (details) {
                                            setState(() {
                                              progressBarHeight = 15;
                                              HapticFeedback.mediumImpact();
                                            });
                                          },
                                          onDragEnd: () {
                                            setState(() {
                                              progressBarHeight = 6;
                                            });
                                          },
                                          onSeek: (Duration? duration) {
                                            playerWrapper.seek(position: duration!, inSession: socket.connected);
                                            if (lyrObj != null) {
                                              int newInd = findCurrLyrPart(duration!, lyrObj!.syncedLyrics!);
                                              if (_scrollController.isAttached) {
                                                _scrollController.scrollTo(
                                                    alignment: 0.4,
                                                    index: newInd,
                                                    duration: const Duration(milliseconds: 400));
                                              }
                                              if (currLyrInd != null) {
                                                lyrWidgetList[currLyrInd!] = getNonHighlighted(currLyrInd!);
                                              }
                                              if (newInd >= 0 && newInd < lyrWidgetList.length) {
                                                lyrWidgetList[newInd] = getHighlighted(newInd);
                                                currLyrInd = newInd;
                                              }
                                            }
                                          },
                                        );
                                      },
                                    )),
                                Controls(
                                  updateFunc: _updateLyrics,
                                  audioPlayer: playerWrapper.player,
                                  carouselController: carouselController,
                                ),
                                const Padding(
                                    padding: EdgeInsets.only(left: 30, right: 30, top: 10), child: VolumeControllerWidget()),
                                hasLyrics
                                    ? Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: CupertinoButton(
                                          onPressed: () {
                                            _onLyricsButtonPressed();
                                          },
                                          child: Text("lyrics",
                                              style: GoogleFonts.lilitaOne(
                                                  fontWeight: FontWeight.w500, fontSize: 20, color: Colors.white)),
                                        ))
                                    : const SizedBox(),
                                // Padding(
                                //     padding: const EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 0),
                                //     child: lyricsWidget()),
                              ],
                            )),
                          );
                        },
                        animation: _animationController,
                      )));
            }));
  }

  bool oneOfArtistIn(List<String> artistsToSearch, String item) {
    for (var artist in artistsToSearch) {
      if (item.contains(artist.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  dynamic findMatchedDurationLyrics(List<dynamic> lyrics, int trackDuration, String artist, String name) {
    name = name.substring(0, name.contains('(') ? name.indexOf('(') : null);
    int returnIndex = -1;
    List<String> artists = artist.split(', ');
    for (int i = 0; i < lyrics.length; i++) {
      if (lyrics[i]['syncedLyrics'] != null &&
          (lyrics[i]['duration'] - trackDuration).abs() < 5 &&
          oneOfArtistIn(artists, lyrics[i]['artistName'].toLowerCase()) &&
          lyrics[i]['trackName'].toLowerCase().contains(name.toLowerCase())) {
        returnIndex = i;
      }
    }
    if (returnIndex != -1) {
      return lyrics[returnIndex];
    }
  }

  _onLyricsButtonPressed() {
    switch (_myAnimatedWidgetForm) {
      case AnimatedWidgetForm.queue:
        setState(() {
          _myAnimatedWidgetForm = AnimatedWidgetForm.art;
        });
        setState(() {
          _myAnimatedWidgetForm = AnimatedWidgetForm.lyrics;
          if (_scrollController.isAttached) {
            _scrollController.scrollTo(alignment: 0.4, index: currLyrInd!, duration: Duration(milliseconds: 400));
          }
        });
        break;
      case AnimatedWidgetForm.lyrics:
        setState(() {
          _myAnimatedWidgetForm = AnimatedWidgetForm.art;
        });
        break;
      case AnimatedWidgetForm.art:
        setState(() {
          _myAnimatedWidgetForm = AnimatedWidgetForm.lyrics;
          if (_scrollController.isAttached) {
            _scrollController.scrollTo(alignment: 0.4, index: currLyrInd!, duration: Duration(milliseconds: 400));
          }
        });
        break;
    }
  }

  Widget getHighlighted(index) {
    return InkWell(
        onTap: () {
          playerWrapper.seek(position: lyrObj!.syncedLyrics![index].start);
          _scrollController.scrollTo(alignment: 0.4, index: index, duration: Duration(milliseconds: 400));
          // if (newInd < currLyrInd!) {
          //   clearLyricsColorUntil(newIndex: newInd, oldIndex: currLyrInd!);
          // } else if (newInd > currLyrInd!) {
          //   fillLyricsWithColorUntil(lastIndex: newInd, firstIndex: currLyrInd!);
          // }
          // lyrWidgetList[currLyrInd!] = getNonHighlighted(currLyrInd!);
          // lyrWidgetList[index - 1] = getHighlighted(index - 1);
          // currLyrInd = index;
        },
        child: Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 15, left: 10, right: 10),
            child: Text(
              lyrObj!.syncedLyrics![index!].lyrics,
              style: GoogleFonts.lilitaOne(
                  fontWeight: FontWeight.w500,
                  fontSize: 25,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, blurRadius: 30)]),
              textAlign: TextAlign.center,
            )));
  }

  Widget getNonHighlighted(index) {
    return InkWell(
        onTap: () {
          _scrollController.scrollTo(alignment: 0.4, index: index, duration: Duration(milliseconds: 400));
          playerWrapper.seek(position: lyrObj!.syncedLyrics![index].start);
          // if (currLyrInd != null && newInd < currLyrInd!) {
          //   clearLyricsColorUntil(newIndex: newInd, oldIndex: currLyrInd!);
          // } else if (currLyrInd != null && newInd > currLyrInd!) {
          //   fillLyricsWithColorUntil(lastIndex: newInd + 1, firstIndex: currLyrInd!);
          // }
          lyrWidgetList[currLyrInd!] = getNonHighlighted(currLyrInd!);
          lyrWidgetList[index] = getHighlighted(index);
          currLyrInd = index;
        },
        child: Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 15, left: 10, right: 10),
            child: Text(
              lyrObj!.syncedLyrics![index].lyrics,
              style: GoogleFonts.lilitaOne(
                  shadows: [Shadow(color: Colors.black, blurRadius: 30)],
                  fontWeight: FontWeight.w500,
                  fontSize: 25,
                  color: Color.fromARGB(255, 139, 139, 139)),
              textAlign: TextAlign.center,
            )));
  }

  // void fillLyricsWithColorUntil({required int lastIndex, int? firstIndex}) {
  //   firstIndex = 0;
  //   for (int i = firstIndex; i < lastIndex; i++) {
  //     lyrWidgetList[i] = getHighlighted(i);
  //   }
  // }
  //
  // void clearLyricsColorUntil({required int newIndex, int? oldIndex}) {
  //   oldIndex = lyrWidgetList.length;
  //   for (int i = oldIndex; i > newIndex; i--) {
  //     lyrWidgetList[i] = getNonHighlighted(i);
  //   }
  // }

  Widget lyricsWidget() {
    return FutureBuilder(
        future: lyrics,
        builder: (context, snapshot) {
          if (snapshot.hasError || snapshot.connectionState != ConnectionState.done) {
            return SizedBox(height: 100);
          } else {
            if (snapshot.data != null && snapshot.data!.statusCode == 200) {
              var jsonResponse = json.decode(snapshot.data!.body);
              if (playerWrapper.player.duration == null) {
                return SizedBox(height: 100);
              }
              ExtendedMediaItem metadata = playerWrapper.player.sequenceState!.currentSource!.tag as ExtendedMediaItem;
              dynamic finded = findMatchedDurationLyrics(
                  jsonResponse, playerWrapper.player.duration!.inSeconds, metadata.artist, metadata.title);
              if (finded == null) {
                return SizedBox(height: 100);
              }
              lyrObj = Lyrics.fromJson(finded);
              return StreamBuilder(
                  stream: playerWrapper.player.positionStream,
                  builder: (context, snapshot) {
                    final positionData = snapshot.data;
                    if (positionData == null || lyrObj == null) {
                      return SizedBox(height: 100);
                    }
                    int position = positionData.inMilliseconds;
                    if (currLyrInd == null) {
                      lyrWidgetList = List.generate(lyrObj!.syncedLyrics!.length, (index) => getNonHighlighted(index));
                      currLyrInd = findCurrLyrPart(Duration(milliseconds: position), lyrObj!.syncedLyrics!);
                      if (_scrollController.isAttached) {
                        _scrollController.scrollTo(
                            alignment: 0.4, index: currLyrInd!, duration: Duration(milliseconds: 400));
                      }
                      if (position > lyrObj!.syncedLyrics![currLyrInd!].start.inMilliseconds) {
                        lyrWidgetList[currLyrInd!] = getHighlighted(currLyrInd!);
                      }
                      // fillLyricsWithColorUntil(lastIndex: currLyrInd! + 1);
                      // if (currLyrInd != -1) {
                      //   lyrWidgetList[currLyrInd!] = Padding(
                      //       padding: EdgeInsets.only(top: 15, bottom: 15, left: 10, right: 10),
                      //       child: Text(
                      //         lyrObj.syncedLyrics![currLyrInd!].lyrics,
                      //         style: GoogleFonts.lilitaOne(
                      //             fontWeight: FontWeight.w500, fontSize: 25, color: Colors.white),
                      //         textAlign: TextAlign.center,
                      //       ));
                      // }
                    } else {
                      if (position > lyrObj!.syncedLyrics![0].start.inMilliseconds && currLyrInd == 0) {
                        lyrWidgetList[0] = getHighlighted(0);
                      }
                      if (position - lyrObj!.syncedLyrics![currLyrInd!].end.inMilliseconds > 0 &&
                          lyrObj!.syncedLyrics!.length > currLyrInd! + 1) {
                        int prevInd = currLyrInd!;
                        while (position - lyrObj!.syncedLyrics![currLyrInd!].end.inMilliseconds > 0 &&
                            lyrObj!.syncedLyrics!.length > currLyrInd! + 1) {
                          currLyrInd = currLyrInd! + 1;
                        }
                        if (_scrollController.isAttached) {
                          _scrollController.scrollTo(
                              alignment: 0.4, index: currLyrInd!, duration: Duration(milliseconds: 400));
                        }
                        // if (currLyrInd != -1) {
                        //   lyrWidgetList[currLyrInd!] = Padding(
                        //       padding: EdgeInsets.only(top: 15, bottom: 15, left: 10, right: 10),
                        //       child: Text(
                        //         lyrObj.syncedLyrics![currLyrInd!].lyrics,
                        //         style: GoogleFonts.lilitaOne(
                        //             fontWeight: FontWeight.w500, fontSize: 25, color: Colors.grey),
                        //         textAlign: TextAlign.center,
                        //       ));
                        // }
                        if (currLyrInd != 0) {
                          lyrWidgetList[prevInd] = getNonHighlighted(prevInd);
                        }
                        lyrWidgetList[currLyrInd!] = getHighlighted(currLyrInd!);
                        // scrollControllerLyrics.animateTo(scrollControllerLyrics.position.pixels + 75,
                        //     duration: Duration(milliseconds: 400), curve: Curves.fastOutSlowIn);
                      }
                    }
                    return Padding(
                        padding: const EdgeInsets.only(bottom: 30, top: 10),
                        child: ClipRRect(
                            clipBehavior: Clip.antiAlias,
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 12.0,
                                  sigmaY: 12.0,
                                ),
                                child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    color: const Color.fromARGB(29, 55, 49, 49),
                                    alignment: Alignment.center,
                                    child:
                                        // NotificationListener(
                                        //   onNotification: (t) {
                                        //     if (t is ScrollStartNotification) {
                                        //       print("here");
                                        //       setState(() {
                                        //         currLyrInd = currLyrInd! + 1;
                                        //       });
                                        //     }
                                        //     return false;
                                        //   },
                                        //     child:
                                        //     ListView(
                                        // controller: scrollControllerLyrics,
                                        // children: lyrWidgetList,

                                        ScrollablePositionedList.builder(
                                      physics: const RangeMaintainingScrollPhysics(),
                                      itemScrollController: _scrollController,
                                      itemCount: lyrWidgetList.length,
                                      itemBuilder: (context, index) {
                                        return lyrWidgetList[index];
                                      },
                                    )))));
                  });
            } else {
              return SizedBox(height: 100);
            }
          }
        });
  }
}

class Controls extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final CarouselController carouselController;
  final Function() updateFunc;

  const Controls({super.key, required this.audioPlayer, required this.carouselController, required this.updateFunc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: audioPlayer.sequenceStateStream,
        builder: (context1, snapshot1) {
          if (snapshot1.data == null) {
            return const CircularProgressIndicator(color: Colors.red);
          }
          // playerWrapper.player.currentIndexStream.listen((event) {
          //   if (event != null) {
          //     carouselController.animateToPage(curve: Curves.ease, event, duration: const Duration(milliseconds: 300));
          //   }
          // });
          return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
              onPressed: () {
                // progressBarHeight = 20;
              },
              icon: const Icon(Icons.shuffle_rounded, color: Colors.white),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: (snapshot1.data!.currentIndex == 0)
                    ? () {
                        playerWrapper.seek(position: const Duration(), inSession: socket.connected);
                        _myAnimatedWidgetForm = AnimatedWidgetForm.art;
                        updateFunc();
                      }
                    : () async {
                        playerWrapper.seek(
                            position: const Duration(),
                            index: playerWrapper.player.currentIndex! - 1,
                            inSession: socket.connected);
                        try {
                          await carouselController.animateToPage(
                              curve: Curves.ease,
                              playerWrapper.player.currentIndex! - 1,
                              duration: const Duration(milliseconds: 300));
                        } catch (e) {
                          print(e);
                        }
                        updateFunc();
                      },
                icon: const Icon(Icons.skip_previous_rounded),
                color: Colors.white,
                iconSize: 60),
            StreamBuilder<PlayerState>(
              stream: audioPlayer.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processionState = playerState?.processingState;
                final playing = playerState?.playing;
                if (!(playing ?? false)) {
                  return IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        playerWrapper.play(inSession: socket.connected);
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      color: Colors.white,
                      iconSize: 80);
                } else if (processionState != ProcessingState.completed) {
                  return IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        playerWrapper.pause(inSession: socket.connected);
                      },
                      icon: const Icon(Icons.pause_rounded),
                      color: Colors.white,
                      iconSize: 80);
                }
                return const Icon(Icons.play_arrow_rounded, size: 80, color: Colors.white);
              },
            ),
            IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: (snapshot1.data!.currentIndex == snapshot1.data!.sequence.length - 1)
                    ? () {
                        playerWrapper.seek(position: const Duration(), inSession: socket.connected);
                        _myAnimatedWidgetForm = AnimatedWidgetForm.art;
                        updateFunc();
                      }
                    : () async {
                        playerWrapper.seek(
                            position: const Duration(),
                            index: playerWrapper.player.currentIndex! + 1,
                            inSession: socket.connected);
                        try {
                          await carouselController.animateToPage(
                              curve: Curves.ease,
                              playerWrapper.player.currentIndex! + 1,
                              duration: const Duration(milliseconds: 300));
                        } catch (e) {
                          print(e);
                        }
                        updateFunc();
                      },
                icon: const Icon(Icons.skip_next_rounded),
                color: Colors.white,
                iconSize: 60),
            IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  // _switch(() {
                  //   _myAnimatedWidget = ListView(children: [Text('test')], shrinkWrap: true,);
                  // });
                  _switch();
                  // Navigator.push(
                  //   context,
                  //   PageTransition(
                  //       child: const Queue(),
                  //       type: PageTransitionType.bottomToTop,
                  //       duration: const Duration(milliseconds: 200),
                  //       alignment: Alignment.center),
                  // ).then((value) => carouselController.jumpToPage(playerWrapper.player.currentIndex!));
                },
                icon: const Icon(Icons.queue_music_rounded),
                color: Colors.white,
                iconSize: 20),
          ]);
        });
  }
}
