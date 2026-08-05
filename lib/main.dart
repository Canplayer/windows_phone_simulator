import 'package:flutter/material.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/metro_scroll_behavior.dart';
import 'package:windows_phone_simulator/apps/about/about.dart';
import 'package:windows_phone_simulator/apps/phone/phone.dart';
import 'package:windows_phone_simulator/demo_page.dart';
import 'package:windows_phone_simulator/splashscreen_page.dart';

void main() {
  // ─── 各页面在此自注册到开始菜单 ─────────────────────────
  // 其他页面只需在自己的文件中定义静态 register() 方法，
  // 然后在这里调用即可，无需修改 launcher.dart。
  DemoPage.register();
  AboutPage.register();
  PhoneApp.register();
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