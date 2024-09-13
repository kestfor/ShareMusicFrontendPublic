import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/api_requests/sources/social_requests.dart'
    as api;
import 'package:flutter_application_1/features/widgets/tiles/user_tile.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> searchResultAll;
  final controllerText = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchResultAll = Future(() => {});
  }

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        extendBody: true,
        body: SafeArea(
            child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.all(15),
                child: SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        Expanded(
                            child: TapRegion(
                          onTapOutside: (PointerDownEvent a) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          child: CupertinoSearchTextField(
                            onSuffixTap: () {
                              setState(() {
                                controllerText.clear();
                                searchResultAll = Future(() => {});
                              });
                            },
                            suffixInsets: const EdgeInsets.only(right: 20),
                            suffixIcon: const Icon(Icons.clear),
                            onChanged: (val) {
                              setState(() {
                                searchResultAll = val != ""
                                    ? api.userSearch(val)
                                    : Future(() => {});
                              });
                            },
                            controller: controllerText,
                            style: theme.textTheme.bodyMedium,
                          ),
                        )),
                        SizedBox(
                            child: CupertinoButton(
                          child: const Text(
                            "cancel",
                            style: TextStyle(
                                color: Color.fromARGB(255, 208, 46, 60)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ))
                      ],
                    ))),
            Expanded(
                child: FutureBuilder<dynamic>(
              future: searchResultAll,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Scaffold(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    body: const Center(
                        child: CircularProgressIndicator(
                      color: Colors.red,
                    )),
                  );
                }
                if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: snapshot.data["data"].length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return UserTile(
                            userId: snapshot.data["data"][index]["user_id"],
                            photoUrl: snapshot.data["data"][index]["photo_url"],
                            username: snapshot.data["data"][index]["username"],
                            firstName: snapshot.data["data"][index]
                                ["first_name"],
                            lastName: snapshot.data["data"][index]
                                ["last_name"]);
                      });
                } else if (snapshot.hasError) {
                  print(snapshot.error);
                  return Scaffold(
                      body: Center(
                          child: Column(children: [
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          "something went wrong",
                          style: Theme.of(context).textTheme.bodyLarge,
                        )),
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: IconButton(
                            onPressed: () {
                              setState(() {
                                searchResultAll =
                                    api.userSearch(controllerText.text);
                              });
                            },
                            icon: const Icon(Icons.refresh)))
                  ])));
                } else {
                  return Text("pusto");
                }
              },
            )),
          ],
        )));
  }
}
