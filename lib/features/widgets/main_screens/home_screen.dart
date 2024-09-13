import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/widgets/tiles/user_tile.dart';
import 'package:flutter_application_1/features/widgets/user_search_screen.dart';
import 'package:flutter_kronos/flutter_kronos.dart';

import '../../../globals.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    mainScreensNotify['Home'] = notify;
  }

  void notify() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    mainScreensContext['Home'] = context;
    var txt = TextEditingController();
    txt.text = "default";
    return Scaffold(
        appBar: AppBar(
          title: const Text('Music Home'),
        ),
        body: Center(
          child: Column(children: [
            UserTile(
              userId: int.parse(userData["id"]),
              private: true,
            ),
            UserTile(
              userId: 892098177,
            ),
            UserTile(
              userId: 553945148,
            ),
            SizedBox(
                height: 50,
                width: 100,
                child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(CupertinoPageRoute(
                          builder: (context) => const UserSearchScreen()));
                    },
                    child: Text("poisk"))),
            SizedBox(
                height: 50,
                width: 100,
                child: OutlinedButton(
                    onPressed: () async {
                      int? ntpTime = await FlutterKronos.getCurrentNtpTimeMs;
                      int trackPos =
                          playerWrapper.player.position.inMicroseconds;
                      print(await FlutterKronos
                          .getCurrentTimeMs); //return time from the fallback clock if Kronos
                      print(await FlutterKronos
                          .getCurrentNtpTimeMs); //return null if Kronos has not yet been synced
                      print(await FlutterKronos
                          .getDateTime); //return null if Kronos has not yet been synced
                      print(await FlutterKronos.getNtpDateTime);
                      Map<String, dynamic> data = {
                        "ntp_time": ntpTime,
                        "track_pos": trackPos,
                        "playing": playerWrapper.player.playing
                      };
                      socket.emit("sync_time", data);
                      print(data);
                    },
                    child: Text("time"))),
            SizedBox(
                height: 50,
                width: 100,
                child: OutlinedButton(
                    onPressed: () async {
                      playerWrapper.unMute();
                      playerWrapper.player.setVolume(50);
                    },
                    child: Text("unmute"))),
          ]),
        ));
  }
}
