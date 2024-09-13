import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/api_requests/sources'
    '/objects.dart' as objects;
import 'package:flutter_application_1/features/api_requests/sources'
    '/social_requests.dart' as api;
import 'package:flutter_application_1/features/widgets/profile_screen.dart';

class UserTile extends StatefulWidget {
  final int userId;
  String? username;
  String? photoUrl;
  String? firstName;
  String? lastName;
  final bool private;

  UserTile({
    required this.userId,
    this.username,
    this.photoUrl,
    this.firstName,
    this.lastName,
    this.private=false,
    super.key,
  });

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  late Future<objects.User?> user;

  @override
  void initState() {
    super.initState();
    getInfo();
  }

  void getInfo() async {
    if (widget.username == null &&
        widget.photoUrl == null &&
        widget.firstName == null &&
        widget.lastName == null) {
      user = api.getUserInfo(widget.userId.toString());
    } else {
      user = Future(() => objects.User(
          userId: widget.userId,
          username: widget.username,
          photoUrl: widget.photoUrl,
          firstName: widget.firstName,
          lastName: widget
              .lastName));
    }
  }

  Widget userTile(objects.User user) {
    return InkWell(
        splashColor: Colors.transparent,
        onTap: () async {
          CachedNetworkImage.evictFromCache(user.photoUrl!);
          Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) => ProfileScreen(user: user, private: widget.private,)),
          );
        },
        child: Padding(
            padding:
            const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
            child: ListTile(
              leading: CachedNetworkImage(
                imageUrl: user.photoUrl!,
                width: 50.0,
                height: 50.0,
                imageBuilder: (context, imageProvider) =>
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                            image: imageProvider, fit: BoxFit.cover),
                      ),
                    ),
                placeholder: (context, url) =>
                const CircularProgressIndicator(
                  color: Colors.red,
                ),
                errorWidget: (context, url, error) => const Icon(Icons.person),
              ),
              title: Text(
                user.username != null ? user.username! : user.firstName!,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            )));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<objects.User?>(
      future: user,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Center(
                child: CircularProgressIndicator(color: Colors.red));
          default:
            if (snapshot.hasError || !snapshot.hasData) {
              return Text("asd");
            } else {
              return userTile(snapshot.data!);
            }
        }
      },
    );
  }
}
