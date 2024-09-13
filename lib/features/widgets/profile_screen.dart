import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/api_requests/sources'
    '/objects.dart' as objects;
import 'package:flutter_application_1/features/api_requests/sources/social_requests.dart'
    as api;
import 'package:flutter_application_1/globals.dart';
import 'package:motion/motion.dart';

import '../../login.dart';
import '../utils.dart';

class ProfileScreen extends StatefulWidget {
  final objects.User user;
  final bool private;

  const ProfileScreen({
    super.key,
    required this.user,
    this.private = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<String> relation;
  Future<List<Color>> background = Future(() => [Colors.black12, Colors.black]);

  void getRelation() async {
    relation = api.getRelation(int.parse(userData['id']), widget.user.userId);
    print(await relation);
  }

  @override
  void initState() {
    super.initState();
    getRelation();
    Future.delayed(const Duration(milliseconds: 400), () {
      setState(() {
        background = getTwoPrimaryColors(widget.user.photoUrl!);
      });
    });
  }

  Text getUsernameWidget(Color color) {
    return Text(
      widget.user.username != null ? widget.user.username! : "Безымянный",
      style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500, color: color),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Text getNameWidget(Color color) {
    return Text(
      widget.user.firstName! +
          (widget.user.lastName == null ? "" : " ${widget.user.lastName!}"),
      style: TextStyle(fontWeight: FontWeight.w200, fontSize: 20, color: color),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget userSheet(objects.User user) {
    return Motion.elevated(
        borderRadius: const BorderRadius.all(Radius.circular(25)),
        elevation: 25,
        child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            child: Container(
                color: Colors.white10,
                child: Row(
                  children: [
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: CachedNetworkImage(
                          width: 150.0,
                          height: 150.0,
                          imageUrl: widget.user.photoUrl!,
                          imageBuilder: (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                  image: imageProvider, fit: BoxFit.cover),
                            ),
                          ),
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person, size: 100),
                        )),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        getUsernameWidget(Colors.white),
                        getNameWidget(Colors.white60)
                      ],
                    )
                  ],
                ))));
  }

  Widget getPrivateProfile() {
    return Scaffold(
        body: FutureBuilder<List<Color>>(
            builder:
                (BuildContext context, AsyncSnapshot<List<Color>> snapshot) {
              List<Color> background =
                  snapshot.data == null || snapshot.data!.isEmpty
                      ? [Colors.black12, Colors.black]
                      : [snapshot.data![0], snapshot.data![1]];
              return AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: background)),
                  alignment: Alignment.topCenter,
                  child: Scaffold(
                      backgroundColor: Colors.transparent,
                      appBar: AppBar(
                        backgroundColor: Colors.transparent,
                      ),
                      body: Column(
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(20),
                              child: userSheet(widget.user)),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(228, 161, 5, 5)
                                // side: BorderSide(width: 1.0, color: Colors.red),
                                ),
                            onPressed: () async {
                              userData = {};
                              await phoneStorage.delete(key: 'user_data');
                              playerWrapper.player.dispose();
                              setState(() {
                                // Navigator.of(mainScreensContext["Global"], rootNavigator: true).pop();
                                Navigator.of(mainScreensContext["Global"],
                                        rootNavigator: true)
                                    .pushReplacement(CupertinoPageRoute(
                                        builder: (context) => Login()));
                              });
                            },
                            child: const Text(
                              "Log Out",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16),
                            ),
                          )
                        ],
                      )));
            },
            future: background));
  }

  Widget getFollowButton(String relationType) {
    String text;
    var function;
    if (relationType == "second_user_follow" || relationType == "no_relation") {
      function = api.sendFollowRequest;
    }
    if (relationType == "first_user_follow" || relationType == "friends") {
      function = api.sendUnfollow;
    }
    switch (relationType) {
      case "first_user_follow":
        text = "отменить заявку";
      case "second_user_follow":
        text = "добавить в ответ";
      case "friends":
        text = "удалить из друзей";
      default:
        text = "отправить заявку";
    }

    return OutlinedButton(
        onPressed: () async {
          setState(() {
            relation = function(int.parse(userData['id']), widget.user.userId);
            print(function);
          });
        },
        child: Text(text));
  }

  Widget getPublicProfile() {
    return Scaffold(
        body: FutureBuilder<List<Color>>(
            builder:
                (BuildContext context, AsyncSnapshot<List<Color>> snapshot) {
              List<Color> background =
                  snapshot.data == null || snapshot.data!.isEmpty
                      ? [Colors.black12, Colors.black]
                      : [snapshot.data![0], snapshot.data![1]];
              return AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: background)),
                  alignment: Alignment.topCenter,
                  child: Scaffold(
                      backgroundColor: Colors.transparent,
                      appBar: AppBar(
                        backgroundColor: Colors.transparent,
                      ),
                      body: Column(
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(20),
                              child: userSheet(widget.user)),
                          FutureBuilder(
                              future: relation,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState !=
                                    ConnectionState.done) {
                                  return CircularProgressIndicator(
                                      color: Colors.red);
                                } else if (snapshot.data == "error") {
                                  return SizedBox(
                                      width: 200,
                                      height: 20,
                                      child: Text("something went wrong"));
                                } else {
                                  return SizedBox(
                                      width: 200,
                                      height: 20,
                                      child: getFollowButton(snapshot.data!));
                                }
                              }),
                        ],
                      )));
            },
            future: background));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.private) {
      return getPrivateProfile();
    } else {
      return getPublicProfile();
    }
  }
}
