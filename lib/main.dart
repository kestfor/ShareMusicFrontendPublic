import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/userCheck.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_kronos/flutter_kronos.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:motion/motion.dart';
import 'package:page_transition/page_transition.dart';
import 'globals.dart';
import 'login.dart';

void main() async {
  await JustAudioBackground.init(
      androidNotificationChannelId: "com.ryanheise.bg_demo.channel.audio",
      androidNotificationChannelName: "Audio playback",
      androidNotificationOngoing: true);
  Motion.instance.initialize();
  Motion.instance.setUpdateInterval(100.fps);
  FlutterKronos.sync();

  if (Motion.instance.isPermissionRequired){
    Motion.instance.requestPermission();
  }
  runApp(MaterialApp(
      title: "ShareMusic",
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.redM3),
      theme: FlexThemeData.light(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const UserCheck()));
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (e) {
    print("not supported display mode");
  }
}
