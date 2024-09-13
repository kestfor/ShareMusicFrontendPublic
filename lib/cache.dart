// import 'package:flutter_application_1/features/api_requests/header.dart';
import 'package:flutter_application_1/queue_struct.dart';
import 'features/api_requests/sources/objects.dart';

class Cache {
  late int _itemsMaxAmount;
  final Map<String, CacheItem> _bucket = {};

  Cache({itemsMaxAmount = 20, List<String>? keys}) {
    keys ??= ["artists", 'albums', 'artistPages'];
    _itemsMaxAmount = itemsMaxAmount;
    for (var item in keys) {
      _bucket[item] = CacheItem(length: itemsMaxAmount);
    }
  }

  CacheItem? operator [](String key) {
    return _bucket[key];
  }

  void operator []=(String key, dynamic value) {
    _bucket[key]?[value.id] = value;
  }

  int length() {
    return _itemsMaxAmount;
  }

  _addCacheItem(String key, CacheItem value) {
    _bucket[key] = value;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> res = {'keys': []};
    for (var key in _bucket.keys) {
      res[key] = _bucket[key]?.toJson();
      res['keys'].add(key);
    }
    res["itemsMaxAmount"] = _itemsMaxAmount;
    return res;
  }

  factory Cache.fromJson(Map<String, dynamic> json) {
    var res = Cache(
        itemsMaxAmount: json['itemsMaxAmount'],
        keys: List.generate(json['keys'].length, (index) => json['keys'].toString()));
    for (var key in json['keys']) {
      res._addCacheItem(key, CacheItem.fromJson(json[key]));
    }
    return res;
  }
}

class CacheItem extends SearchingHistory {
  CacheItem({super.length, super.list});

  DateTime? getCacheTime(String id) {
    for (var item in list) {
      if (item.id == id) {
        return item.cachedTime;
      }
    }
    return null;
  }

  dynamic operator [](String id) {
    for (var item in list) {
      if (item.id == id) {
        return item.data;
      }
    }
    return null;
  }

  void operator []=(String id, dynamic value) {
    push(item: value, id: id);
  }

  @override
  factory CacheItem.fromJson(Map<String, dynamic> json) {
    CacheItem newObj = CacheItem(length: json['length']);
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
//   // Cache c = Cache();
//   // print(c.toJson());
//   // print(Cache.fromJson(c.toJson()));
// }
