import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'features/utils.dart';
import 'globals.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<StatefulWidget> createState() => _LoginState();
}

String local_domain = "http://10.0.2.2";
String global_domain = "https://sharemusic.site"; // "http://sharemusic.site"; // "http://45.90.219.195"

String BOT_ID = "6306883114";
String DOMAIN = global_domain;

class _LoginState extends State<Login> {
  Widget webView() {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Music Login'),
        ),
        body: InAppWebView(

          initialUrlRequest: URLRequest(url: WebUri("$DOMAIN/login/"), allowsExpensiveNetworkAccess:true),
          onLoadStop: (InAppWebViewController controller, WebUri? url) async {
            if (url.toString().contains("result")) {
              final response = await controller.evaluateJavascript(source: "document.documentElement.innerText");
              if (response.startsWith("{")) {
                Navigator.pop(context);
                userData.addAll(jsonDecode(response));
                // phoneStorage.write(key: "user_data", value: jsonDecode(response));
              }
            }
          },
          onReceivedHttpError: (controller, request, errorResponse) async {
            if (request.url.toString().startsWith("$DOMAIN/login/result")) {
              showMessage(context, "Auth fail");
            }
            controller.loadUrl(urlRequest: URLRequest(url: WebUri("$DOMAIN/login/")));
          },
        ));
  }


  @override
  Widget build(BuildContext context) {
    // DEBUG
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    return Scaffold(
        body: Container(
            alignment: Alignment.center,
            child: CupertinoButton(
              color: const Color.fromARGB(255, 208, 46, 60),
              onPressed: () {
                Navigator.push(context, CupertinoPageRoute(builder: (context) => webView())).then((value) async {
                  if (userData.containsKey('id')) {
                    // Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
                    await Future.delayed(const Duration(milliseconds: 500), () {
                      Navigator.pushReplacement(context, CupertinoPageRoute(builder: (BuildContext context) => toAppFuture()));
                    });
                  }
                });
              },
              child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
            )));
  }
}
