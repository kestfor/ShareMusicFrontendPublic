import 'dart:collection';

import 'features/api_requests/sources/objects.dart';

final class EntryItem extends LinkedListEntry<EntryItem> {
  final dynamic data;
  final String id;
  late final DateTime cachedTime;

  EntryItem({required this.data, required this.id, cachedTime}) {
    this.cachedTime = cachedTime ?? DateTime.now();
  }
}

class SearchingHistory {
  final LinkedList<EntryItem> list;
  final int length;

  SearchingHistory({this.length = 20, LinkedList<EntryItem>? list}) : list = list ?? LinkedList<EntryItem>();

  void _delete({required String id}) {
    for (var entry in list) {
      if (entry.id == id) {
        list.remove(entry);
        break;
      }
    }
  }

  void push({required dynamic item, required String id, cachedTime}) {
    if (list.length > 1) {
      _delete(id: id);
    }
    if (list.length < length) {
      list.addFirst(EntryItem(data: item, id: id, cachedTime: cachedTime));
    } else {
      list.remove(list.last);
      list.addFirst(EntryItem(data: item, id: id, cachedTime: cachedTime));
    }
  }

  dynamic getItem(int index) {
    if (index >= length) {
      throw IndexError.withLength(index, length);
    }
    return list.elementAt(index).data;
  }

  //returns list of objects sorted by relevance
  List<dynamic> toList() {
    List<dynamic> res = [];
    for (var entry in list) {
      res.add(entry.data);
    }
    return res;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> res = {};
    res['length'] = length;
    res['list'] = [];
    for (var entry in list) {
      res['list']
          .add({'id': entry.data.id, 'data': entry.data.toJson(), 'cachedTime': entry.cachedTime.toIso8601String()});
    }
    return res;
  }

  factory SearchingHistory.fromJson(Map<String, dynamic> json) {
    SearchingHistory newObj = SearchingHistory(length: json['length']);
    List<dynamic> objects = json['list'];
    for (int i = objects.length - 1; i >= 0; i--) {
      var item = objects[i];
      if (item['data']['type'] == 'FullArtist') {
        newObj.push(
            item: FullArtist.fromJson(item['data']),
            id: item['id'],
            cachedTime: item['cachedTime'] == null ? item['cachedTime'] : DateTime.parse(item['cachedTime']));
      } else if (item['data']['type'] == 'SimpleTrack') {
        newObj.push(
            item: SimpleTrack.fromJson(item['data']),
            id: item['id'],
            cachedTime: item['cachedTime'] == null ? item['cachedTime'] : DateTime.parse(item['cachedTime']));
      } else if (item['data']['type'] == 'SimpleAlbum') {
        newObj.push(
            item: SimpleAlbum.fromJson(item['data']),
            id: item['id'],
            cachedTime: item['cachedTime'] == null ? item['cachedTime'] : DateTime.parse(item['cachedTime']));
      } else if (item['data']['type'] == 'ArtistPage') {
        newObj.push(
            item: Artist.fromJson(item['data']),
            id: item['id'],
            cachedTime: item['cachedTime'] == null ? item['cachedTime'] : DateTime.parse(item['cachedTime']));
      } else if (item['data']['type'] == "FullAlbum") {
        newObj.push(
            item: FullAlbum.fromJson(item['data']),
            id: item['id'],
            cachedTime: item['cachedTime'] == null ? item['cachedTime'] : DateTime.parse(item['cachedTime']));
      }
    }
    return newObj;
  }
}

// void main() {
//   dynamic test = dynamic(id: 'a', name: 'a', type: 'test', uri: 'sdf', href: 'saf');
//   dynamic test1 = dynamic(id: 'b', name: 'a', type: 'test', uri: 'sdf', href: 'saf');
//   LinkedList<EntryItem> b = LinkedList();
//   b.add(EntryItem(data: test));
//   b.add(EntryItem(data: test1));
//   SearchingHistory a = SearchingHistory(length: 10);
//   a.push(item: test);
//   a.push(item: test1);
//   print(a.toJson());
//   Map<String, dynamic> json = a.toJson();
//   var t = SearchingHistory.fromJson(json);
//   print(t.toJson());
// }
