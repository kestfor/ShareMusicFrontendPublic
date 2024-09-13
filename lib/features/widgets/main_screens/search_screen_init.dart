import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/widgets/main_screens/search_screen.dart';
import 'package:flutter_application_1/globals.dart';
import 'package:page_transition/page_transition.dart';


import '../../../socket.dart';

class SearchScreenInit extends StatefulWidget {
  const SearchScreenInit({super.key});

  @override
  State<SearchScreenInit> createState() => _SearchScreenInit();
}

class _SearchScreenInit extends State<SearchScreenInit> {

  final TextEditingController _controller = TextEditingController();

  void _newRoom() {
    connectAndListen();
    print("new room func");
    socket.emit("create_room", userData["id"]);
  }

  void _enterRoom(String? room) {
    connectAndListen();
    print("enter room func");
    if (room != null) {
      print(room);
      Map<String, dynamic> data = {};
      data["user_id"] = userData["id"];
      data["room_id"] = room;
      socket.emit("enter_room", json.encode(data));
    } else {
      print('пошел нахуй');
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    mainScreensContext['Search'] = context;
    return SafeArea(
        bottom: false,
        child: Scaffold(
            // appBar: AppBar(),
            floatingActionButton: null,
            body: Column(children: [
              Padding(
                  padding: const EdgeInsets.all(15),
                  child: SizedBox(
                      height: 50,
                      child: CupertinoSearchTextField(
                        suffixInsets: const EdgeInsets.only(right: 20),
                        autofocus: false,
                        style: Theme.of(context).textTheme.bodyMedium,
                        onTap: () {
                          Navigator.push(
                                  context, PageTransition(child: const SearchScreen(), type: PageTransitionType.fade))
                              .then((value) => FocusManager.instance.primaryFocus?.unfocus());
                        },
                      ))),
              Padding(padding: const EdgeInsets.all(20), child: CupertinoButton(onPressed: _newRoom, color: Colors.white10, child: const Text("new room", style: TextStyle(color: Colors.grey),),)),
              Padding(padding: const EdgeInsets.only(left: 20, right: 20), child: CupertinoTextField(
                style: Theme.of(context).textTheme.bodyMedium,
                onSubmitted: (String? val) {
                  _enterRoom(val);
                },
                controller: _controller,
                decoration: const BoxDecoration(color: Colors.white10),
              )),
              Padding(padding: const EdgeInsets.all(20), child:
              CupertinoButton(color: Colors.white10, onPressed:()=> setState((){}), child: const Text("update room", style: TextStyle(color: Colors.grey)))),
              Text(roomId),


            ])));
  }
}
