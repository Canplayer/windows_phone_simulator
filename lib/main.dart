import 'package:flutter/material.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/metro_scroll_behavior.dart';
import 'package:windows_phone_simulator/splashscreen_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MetroApp(
      title: 'Flutter Demo',
      metroColor: Color.fromARGB(255, 229, 20, 0),
      useWVGAMode: true,
      //version: MetroDesignVersion.wp7,
      scrollBehavior: MetroScrollBehavior(),
      home: Splashscreen(),
    );
  }
}