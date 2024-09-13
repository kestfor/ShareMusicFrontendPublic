import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app.dart';

import 'features/utils.dart';
import 'globals.dart';
import 'login.dart';

class UserCheck extends StatefulWidget {
  const UserCheck({super.key});

  @override
  State<StatefulWidget> createState() => _UserCheckState();
}

class _UserCheckState extends State<UserCheck> {
  late final Future<String?> res;

  @override
  void initState() {
    res = phoneStorage.read(key: "user_data");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: res, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.red,),),);
      } else if (snapshot.hasError || snapshot.data == null) {
        return const Login();
      } else {
        userData = jsonDecode(snapshot.data!);
        return toAppFuture();
      }
    });
  }

}