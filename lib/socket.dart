import 'dart:convert';

import 'package:flutter_kronos/flutter_kronos.dart';
import 'package:get/state_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:socket_io_client/socket_io_client.dart';

import 'features/api_requests/sources/objects.dart';
import 'globals.dart';
import 'package:flutter_application_1/features/api_requests/header.dart' as api;

void connectAndListen() {
  // socket = io(api.domain, OptionBuilder().setTransports(["websocket"]).build());
  socket.onConnect((data) {
    print('connect');
  });

  socket.on('room_id', (data) {
    print("room event");
    roomId = data;
    print(roomId);
  });

  socket.on('create_room_answer', (data) {
    print("created room");
    roomId = data;
    print(roomId);
    playerWrapper.unMute();

    // TODO Zaebis, vse TESTED.  json.encode() !!! NE UDALYATb, potomushto v socket prihodit dohuya arguments vmesto 1
    if (playerWrapper.playlist.length != 0) {
      List<dynamic> dataToSend = List.generate(playerWrapper.playlist.length, (index) => playerWrapper.playlist.sequence[index].tag as ExtendedMediaItem);
      socket.emit('set_queue', json.encode(dataToSend));
    }
  });

  socket.on('enter_room_answer', (data) {
    print("entered room");
    print(data);
    roomId = data;
    print(roomId);
    playerWrapper.mute();
  });

  socket.on('init_queue', (data) async {
    print("init_queue event");
    // print(data);
    List<ExtendedMediaItem> tracks = List.generate(data.length, (index) => ExtendedMediaItem.fromJson(json: jsonDecode(data[index])));
    if (playerWrapper.player.playing) {
      playerWrapper.player.stop();
    }

    await playerWrapper.clear_queue();

    print(playerWrapper.playlist.children);
    List<AudioSource> sources = [];
    for (var track in tracks) {
      sources.add(AudioSource.uri(Uri.parse(track.fileUrl!), tag: track));
    }
    await playerWrapper.playlist.addAll(sources);
    if (!playerWrapper.player.playing) {
      playerWrapper.player.play();
    }
    socket.emit("ask_sync");
  });

  socket.on('ask_sync', (data) {
    socket.emit('sync', {'index': playerWrapper.player.currentIndex, 'time_step': playerWrapper.player.position.inMilliseconds});
  });



  socket.on('sync', (data) {
    if (data['index'] != null && data['time_step'] != null) {
      playerWrapper.seek(position: Duration(milliseconds: data['time_step']), index: data['index'], );
    }
    if (data['index'] != null) {
      playerWrapper.seek(index: data['index'], position: const Duration());
    }
    if (data['time_step'] != null) {
      playerWrapper.seek(position: Duration(milliseconds: data['time_step']));
    }
  });

  socket.on('turn_on_playlist', (data) {
    print('turn_on_playlist event');
    var res = jsonDecode(data);
    List<ExtendedMediaItem> tracks = List.generate(res.length, (index) => ExtendedMediaItem.fromJson(json:res[index]));
    List<String> sources = List.generate(tracks.length, (index) => tracks[index].fileUrl!);
    playerWrapper.turnOnPlaylist(tracksMetaData: tracks, sourceUris: sources);
  });

  //When an event recieved from server, data is added to the stream
  socket.on('add_to_queue', (data) {
    print("add to queue event");
    ExtendedMediaItem metadata = ExtendedMediaItem.fromJson(json: data);
    playerWrapper.addToQueue(metaData: metadata, sourceUri: metadata.fileUrl);
  });

  socket.on('play_next', (data) {
    print("play next event");
    ExtendedMediaItem metadata = ExtendedMediaItem.fromJson(json: data);
    playerWrapper.addToQueue(toEnd: false, metaData: metadata, sourceUri: metadata.fileUrl);
  });

  socket.on('delete_from_queue', (data) {
    print('delete event');
    playerWrapper.remove(index: data);
  });

  socket.on('move_track', (data) {
    print('move_track');
    var res = jsonDecode(data);
    print("${res['old_index']} to ${res['new_index']}");
    playerWrapper.moveTrack(oldIndex: res['old_index'], newIndex: res['new_index']);
  });

  socket.on('turn_on_track', (data) async {
    print('turn_on_track');
    ExtendedMediaItem metadata = ExtendedMediaItem.fromJson(json: data);
    await playerWrapper.turnOnTrack(metaData: metadata, sourceUri: metadata.fileUrl);
    if (colorRefresh != null) {
      await colorRefresh!();
    }
  });

  socket.on('play', (data) {
    print('play');
    playerWrapper.play();
  });

  socket.on('pause', (data) {
    print('pause');
    playerWrapper.pause();
  });

  socket.on('seek', (data) {
    print('seek');
    var res = jsonDecode(data);
    playerWrapper.seek(position: Duration(milliseconds: res['position']), index: res['index']);
  });

  socket.on("sync_time", (data) async{
    print('sync_time socket update');
    print(data);
    int? ntpTime = await FlutterKronos.getCurrentNtpTimeMs;
    int delta = data['playing'] ? (data["ntp_time"] - ntpTime).abs()*1000 : 0;
    print("delta $delta");
    playerWrapper.seek(position: Duration(microseconds: data['track_pos'] + delta));
  });

  socket.onDisconnect((_) {
    playerWrapper.unMute();
    print("disconnected");
  });
}
