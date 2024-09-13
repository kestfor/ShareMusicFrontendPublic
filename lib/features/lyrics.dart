import 'dart:convert';

import 'package:http/http.dart' as http;

class Pair<T, V> {
  T first;
  V second;

  Pair({required this.first, required this.second});
}

class SyncedLyricsEntry {
  final Duration start;
  final String lyrics;
  final Duration end;

  const SyncedLyricsEntry({required this.lyrics, required this.start, required this.end});
}

class Lyrics {
  final int id;
  final String name;
  final String trackName;
  final String artistName;
  final String albumName;
  final double duration;
  final bool instrumental;
  final String plainLyrics;
  List<SyncedLyricsEntry>? syncedLyrics;

  Lyrics(
      {required this.id,
      required this.name,
      required this.trackName,
      required this.artistName,
      required this.duration,
      required this.albumName,
      required this.instrumental,
      required this.plainLyrics,
      this.syncedLyrics});

  factory Lyrics.fromJson(Map<String, dynamic> json) {
    return Lyrics(
        id: json['id'],
        name: json['name'],
        trackName: json['trackName'],
        artistName: json['artistName'],
        duration: json['duration'],
        albumName: json['albumName'],
        instrumental: json['instrumental'],
        plainLyrics: json['plainLyrics'],
        syncedLyrics: json.containsKey('syncedLyrics') ? _parseSyncedLyrics(lyrics: json['syncedLyrics']) : null);
  }

  static Duration _parseTimeStep(String time) {
    int minDivInd = time.indexOf(':');
    int secDivInd = time.indexOf('.');
    int minutes = int.parse(time.substring(0, minDivInd));
    int seconds = int.parse(time.substring(minDivInd + 1, secDivInd));
    int milliseconds = int.parse(time.substring(secDivInd + 1));
    return Duration(minutes: minutes, seconds: seconds, milliseconds: milliseconds);
  }

  static Pair<int, int>? _findTime(String str, int start) {
    int startInd = str.indexOf('[', start);
    if (startInd == -1) {
      return null;
    }
    int endInd = str.indexOf(']', startInd + 1);
    return Pair(first: startInd, second: endInd);
  }

  static Pair<int, int>? _findLyrics(String str, int start) {
    int startInd = str.indexOf(']', start);
    int endInd = str.indexOf('[', startInd);
    if (endInd == -1) {
      return null;
    }
    return Pair(first: startInd + 1, second: endInd - 1);
  }

  static List<SyncedLyricsEntry> _parseSyncedLyrics({required String lyrics}) {
    List<SyncedLyricsEntry> res = [];
    Duration startTime = const Duration();
    Duration endTime = const Duration();
    String? partOfLyr = "";
    bool isEnd = false;
    Pair<int, int>? start = _findTime(lyrics, lyrics.indexOf('['));
    while (true) {
      if (isEnd) {
        endTime = _parseTimeStep(lyrics.substring(start!.first + 1, start.second - 1));
        res.add(SyncedLyricsEntry(lyrics: partOfLyr!, start: startTime, end: endTime));
        isEnd = false;
        startTime = endTime;
      } else {
        startTime = _parseTimeStep(lyrics.substring(start!.first + 1, start.second - 1));
        isEnd = true;
      }
      start = _findLyrics(lyrics, start.second);
      if (start == null) {
        break;
      }
      partOfLyr = lyrics.substring(start.first + 1, start.second);
      start = _findTime(lyrics, start.second);
      isEnd = true;
    }
    return res;
  }
}

void main() async {
  String url = 'https://lrclib.net/api/search?q=sicko%20mode';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    if (jsonResponse != []) {
      Lyrics lyr = Lyrics.fromJson(jsonResponse[0]);
      for (var item in lyr.syncedLyrics!) {
        print(item.start);
        print(item.lyrics);
      }
    }
  }
}
