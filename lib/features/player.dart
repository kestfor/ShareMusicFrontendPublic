import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/api_requests/header.dart';
import 'package:flutter_application_1/features/utils.dart';
import 'package:flutter_application_1/globals.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:socket_io_client/socket_io_client.dart';

class PlayerWrapper {
  double? _savedVolume;
  final AudioPlayer player = AudioPlayer();
  final Socket socket;
  ConcatenatingAudioSource playlist = ConcatenatingAudioSource(children: []);

  PlayerWrapper({required this.socket});

  Map<String, String>? _convertHeaders(Map<String, dynamic>? headers) {
    if (headers == null) {
      return null;
    }
    Map<String, String> res = {};
    for (var item in headers.entries) {
      res[item.key] = item.value.toString();
    }
    return res;
  }

  void mute() {
    // if (_savedVolume == null) {
    //   _savedVolume = player.volume;
    //   player.setVolume(0);
    // }
  }
  //
  // Future<ExtendedMediaItem?> _getExtendedMediaItem(String id, String artist, String track, int duration, MediaItem mediaItem) async {
  //   Map<String, dynamic> res = await getTrackUrlByInfo(id, artist, track, duration);
  //   if (res[id] != null) {
  //     return ExtendedMediaItem();
  //   }
  // }

  void unMute() {
    // if (_savedVolume != null) {
    //   player.setVolume(_savedVolume!);
    //   _savedVolume = null;
    // }
  }

  //fullId contains ids of track, artists, and albums separated by ':' for example: '{trackId}:{artistsId}:{albumId}'
  Future<void> turnOnTrack(
      {BuildContext? context, required ExtendedMediaItem metaData, bool inSession = false, String? sourceUri}) async {
    if (player.playing) {
      player.pause();
    }
    Map<String, dynamic> res = sourceUri == null
        ? await getTrackUrlByInfo(
            metaData.trackId, metaData.artist, metaData.title, (metaData.duration.inMilliseconds / 1000).round())
        : {metaData.trackId: sourceUri};
    if (res[metaData.trackId] != null) {
      print(res[metaData.trackId]);
      metaData.fileUrl = res[metaData.trackId]['url'];
      metaData.headers = _convertHeaders(res[metaData.trackId]['headers']);
      playlist = ConcatenatingAudioSource(children: [AudioSource.uri(Uri.parse(metaData.fileUrl!), tag: metaData, headers: metaData.headers)]);
      await player.setAudioSource(playlist);
      player.setLoopMode(LoopMode.all);
      player.play();
      if (inSession) {
        metaData.fileUrl = res[metaData.trackId]['url'];
        metaData.headers = _convertHeaders(res[metaData.trackId]['headers']);
        socket.emit("turn_on_track", metaData.toJson());
      }
    } else if (context != null) {
      showMessage(context, "can't load song");
    }
  }

  Future<void> remove({required int index, inSession = false}) async {
    print(index);
    if (index > 0 && playlist.length > index) {
      await playlist.removeAt(index);
    } else {
      throw IndexError.withLength(index, playlist.length);
    }

    //socket
    if (inSession) {
      socket.emit("delete_from_queue", index);
    }
    //
  }

  static ExtendedMediaItem getMetaData({required SimplifiedTrack track, required SimpleAlbum album}) {
    return ExtendedMediaItem.fromSimplifiedObjects(track: track, album: album);
  }

  Future<void> moveTrack({required int oldIndex, required int newIndex, bool inSession = false}) async {
    await playlist.move(oldIndex, newIndex);

    //socket
    if (inSession) {
      socket.emit('move_track', jsonEncode({'old_index': oldIndex, 'new_index': newIndex}));
    }
    //
  }

  Future<void> addToQueue(
      {BuildContext? context,
      required ExtendedMediaItem metaData,
      bool toEnd = true,
      bool inSession = false,
      String? sourceUri}) async {
    Map<String, dynamic> res = sourceUri == null
        ? await getTrackUrlByInfo(
            metaData.trackId, metaData.artist, metaData.title, (metaData.duration.inMilliseconds / 1000).round())
        : {metaData.trackId: sourceUri};

    // no url found
    if (res[metaData.trackId] == null) {
      if (context != null) {
        showMessage(context, "can't load song");
        return;
      }
    } else {
      metaData.fileUrl = res[metaData.trackId]['url'];
      metaData.headers = _convertHeaders(res[metaData.trackId]['headers']);
    }

    // add to queue
    if (toEnd) {
      AudioSource obj = AudioSource.uri(Uri.parse(metaData.fileUrl!), tag: metaData, headers: metaData.headers);
      await playlist.add(obj);
      //socket
      if (inSession) {
        metaData.fileUrl = res[metaData.trackId]['url'];
        metaData.headers = _convertHeaders(res[metaData.trackId]['headers']);
        Map<String, dynamic> dataToSend = metaData.toJson();
        socket.emit("add_to_queue", dataToSend);
      }
      //

      // play next
    } else {
      int index = player.sequenceState == null ? 0 : player.sequenceState!.currentIndex + 1;
      AudioSource obj = AudioSource.uri(Uri.parse(metaData.fileUrl!), tag: metaData, headers: metaData.headers);
      await playlist.insert(index, obj);

      //socket
      if (inSession) {
        metaData.fileUrl = res[metaData.trackId]['url'];
        metaData.headers = _convertHeaders(res[metaData.trackId]['headers']);
        Map<String, dynamic> dataToSend = metaData.toJson();
        socket.emit("play_next", dataToSend);
      }
      //
    }
    if (playlist.length == 1) {
      player.setAudioSource(playlist);
      player.setLoopMode(LoopMode.all);
      player.play();
    }
  }

  void turnOnPlaylist(
      {BuildContext? context,
      required List<ExtendedMediaItem> tracksMetaData,
      bool shuffle = false,
      List<String>? sourceUris,
      inSession = false}) async {
    int firstTrack = 0;
    if (shuffle) {
      firstTrack = Random().nextInt(tracksMetaData.length);
    }
    if (player.playing) {
      player.pause();
    }

    //if source uris was given by socket
    Map<String, dynamic> uris = {};
    if (sourceUris != null) {
      for (int i = 0; i < tracksMetaData.length; i++) {
        uris[tracksMetaData[i].trackId] = sourceUris[i];
      }
    }

    if (shuffle) {
      tracksMetaData.shuffle();
    }

    if (inSession) {
      List<dynamic> dataToSend = List.generate(tracksMetaData.length, (index) => tracksMetaData[index].toJson());
      socket.emit("turn_on_playlist", jsonEncode(dataToSend));
    }

    turnOnTrack(
        metaData: tracksMetaData[firstTrack],
        context: context,
        sourceUri: sourceUris == null ? null : sourceUris[firstTrack]);
    tracksMetaData.removeAt(firstTrack);
    Map<String, dynamic> urls = sourceUris == null ? await getAlbumTracks(tracksMetaData) : uris;
    for (int i = 0; i < tracksMetaData.length; i++) {
      if (urls[tracksMetaData[i].trackId]['url'] != null) {
        tracksMetaData[i].fileUrl = urls[tracksMetaData[i].trackId]['url'];
        tracksMetaData[i].headers = _convertHeaders(urls[tracksMetaData[i].trackId]['headers']);
        await playlist.add(AudioSource.uri(Uri.parse(tracksMetaData[i].fileUrl!), tag: tracksMetaData[i], headers: tracksMetaData[i].headers));
      }
    }
  }

  void play({bool inSession = false}) {
    player.play();
    if (inSession) {
      print("socket emit play");
      socket.emit("play");
    }
  }

  void pause({bool inSession = false}) {
    player.pause();
    if (inSession) {
      print("socket emit pause");
      socket.emit("pause");
    }
  }

  void seek({required Duration position, int? index, bool inSession = false}) {
    player.seek(position, index: index);
    if (inSession) {
      socket.emit("seek", jsonEncode({'position': position.inMilliseconds, 'index': index}));
    }
  }

  Future<void> clear_queue() async {
    playlist = ConcatenatingAudioSource(children: []);
    await player.setAudioSource(playlist);
  }
}
