import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/api_requests/sources/playlist_requests.dart';
import 'package:flutter_application_1/features/utils.dart';
import 'package:flutter_application_1/globals.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../api_requests/sources/objects.dart';

class NewPlaylistCreationScreen extends StatelessWidget {
  final textController = TextEditingController();

  NewPlaylistCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.white10, Colors.white54])),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Name your playlist',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Padding(
                      padding: const EdgeInsets.all(40),
                      child: TextField(
                        style: GoogleFonts.roboto(fontSize: 30, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(fillColor: Colors.transparent, focusColor: Colors.grey),
                        controller: textController,
                        textAlign: TextAlign.center,
                      )),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ButtonStyle(
                                fixedSize: const MaterialStatePropertyAll<Size>(Size(100, 20)),
                                shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                    side: const BorderSide(color: Colors.grey)))),
                            child: Text(
                              'Cancel',
                              style: Theme.of(context).textTheme.titleMedium,
                            ))),
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextButton(
                            onPressed: () async {
                              String name = textController.text;
                              Map<String, dynamic>? newPlaylistId =
                                  await createPlaylist(name: name, userId: userData['id'], hash: userData["hash"]);
                              if (newPlaylistId == null) {
                                showMessage(context, 'something went wrong');
                              } else {
                                Map<String, dynamic> newPlaylist = {
                                  'playlist_name': name,
                                  'tracks_id': [],
                                  'art_uri': null,
                                  'playlist_id': newPlaylistId['playlist_id']
                                };
                                userData['playlists'][newPlaylistId['playlist_id']] = newPlaylist;
                                if (insertItemPlaylist != null) {
                                  insertItemPlaylist!(Playlist.fromJson(newPlaylist));
                                }
                              }

                              // Future<Map<String, dynamic>?> newPlaylistId =
                              //     createPlaylist(name: name, userId: userData['id'], hash: userData["hash"]);
                              Navigator.of(context, rootNavigator: true).pop();
                              // await Future.delayed(const Duration(milliseconds: 300), () {
                              //   Navigator.of(mainScreensContext['Library'], rootNavigator: false)
                              //       .push(CupertinoPageRoute(builder: (context) {
                              //     return FutureBuilder(
                              //         future: newPlaylistId,
                              //         builder: (context, snapshot) {
                              //           if (snapshot.connectionState != ConnectionState.done) {
                              //             return const Scaffold(
                              //                 body: Center(
                              //                     child: CircularProgressIndicator(
                              //               color: Colors.red,
                              //             )));
                              //           } else if (snapshot.hasError || snapshot.data == null) {
                              //             return const Scaffold(body: Center(child: Text("Something went wrong")));
                              //           } else {
                              //             Map<String, dynamic> newPlaylist = {
                              //               'playlist_name': name,
                              //               'tracks_id': [],
                              //               'art_uri': null,
                              //               'playlist_id': snapshot.data!['playlist_id']
                              //             };
                              //             userData['playlists'][snapshot.data!['playlist_id']] = newPlaylist;
                              //             return PlaylistScreen(
                              //               playlistId: snapshot.data!['playlist_id'],
                              //             );
                              //           }
                              //         });
                              //   }));
                              // });
                            },
                            style: ElevatedButton.styleFrom(
                              shape: const StadiumBorder(),
                              backgroundColor: Colors.red,
                              fixedSize: const Size(100, 20),
                            ),
                            // style: ButtonStyle(
                            //
                            //   fixedSize: const MaterialStatePropertyAll<Size>(Size(100, 20)),
                            //   backgroundColor: const MaterialStatePropertyAll<Color>(Colors.red),
                            //     shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(18.0), side: BorderSide(color: Colors.red)))),
                            child: Text(
                              'Create',
                              style: Theme.of(context).textTheme.titleMedium,
                            )))
                  ]),
                ]),
          )),
    );
  }
}
