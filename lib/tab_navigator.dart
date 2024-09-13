import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/widgets/main_screens/home_screen.dart';
import 'package:flutter_application_1/features/widgets/main_screens/library_screen.dart';
import 'package:flutter_application_1/features/widgets/main_screens/search_screen_init.dart';

class TabNavigatorRoutes {
  static const String root = '/';
  static const String detail = '/detail';
}

class TabNavigator extends StatelessWidget {
  const TabNavigator({super.key, required this.navigatorKey, required this.tabItem});

  final GlobalKey<NavigatorState> navigatorKey;
  final String tabItem;

  @override
  Widget build(BuildContext context) {
    Widget child = const Scaffold();
    if (tabItem == "Home") {
      child = const HomeScreen();
    } else if (tabItem == "Search") {
      child = const SearchScreenInit();
    } else if (tabItem == "Library") {
      child = const LibraryScreen();
    }

    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => child);
      },
    );
  }
}
