import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'objects.dart' as objects;

const localDomain = "http://10.0.2.2:8000";
const localDomain2 = "http://127.0.0.1:8000";
const globalDomain = "https://sharemusic.site";

const domain = globalDomain;
const apiUrl = "$domain/api/social";

Future<objects.User?> getUserInfo(String userId) async {
  final response = await http.get(Uri.parse('$apiUrl/users/$userId'));
  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    if (jsonResponse['status'] == 'success') {
      return objects.User.fromJson(jsonResponse['data']);
    }
  }
  return null;
}

Future<String> getRelation(int fromUserId, int toUserId) async {
  final response = await http.get(Uri.parse("$apiUrl/view_relation/$fromUserId,$toUserId"));
  if (response.statusCode == 200) {
    Map<String, dynamic> responseMap = jsonDecode(response.body);
    if (responseMap['status'] == "success"){
      return responseMap['type'];
    }
    return "error";
  } else {
    return "error";
  }
}

Future<String> sendFollowRequest(int fromUserId, int toUserId) async {
  Map<String, dynamic> body = {
    "first_user_id": fromUserId,
    "second_user_id": toUserId,
    "action": fromUserId < toUserId ? "first_user_follow" : "second_user_follow"
  };
  final response = await http.post(Uri.parse("$apiUrl/users/follow"),
      body: jsonEncode(body),
      headers: {
        "Accept": "application/json",
        "content-type": "application/json"
      });
  if (response.statusCode == 200) {
    Map<String, dynamic> res = jsonDecode(response.body);
    return res['result'];
  } else {
    return 'error';
  }
}

Future<String> sendUnfollow(int fromUserId, int toUserId) async{
  Map<String, dynamic> body = {
    "first_user_id": fromUserId,
    "second_user_id": toUserId,
    "action": fromUserId < toUserId ? "first_user_unfollow" : "second_user_unfollow"
  };
  final response = await http.post(Uri.parse("$apiUrl/users/unfollow"),
      body: jsonEncode(body),
      headers: {
        "Accept": "application/json",
        "content-type": "application/json"
      });
  if (response.statusCode == 200) {
    Map<String, dynamic> res = jsonDecode(response.body);
    return res['result'];
  } else {
    return "error";
  }
}

Future<Map<String, dynamic>> userSearch(String query) async{
  final response = await http.get(Uri.parse("$apiUrl/users/search/$query"),
      headers: {
        "Accept": "application/json",
        "content-type": "application/json"
      });
  if (response.statusCode == 200) {
    Map<String, dynamic> res = jsonDecode(response.body);
    print(res);
    return res;
  } else {
    return {};
  }
}