import 'package:flutter/material.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:windows_phone_simulator/app_registry.dart';
import 'package:windows_phone_simulator/start_menu.dart';

/// Demo 空白页面 —— 作为 "通过注册中心自注册" 的示例
///
/// 只需在任意入口处调用 [DemoPage.register()]，
/// 即可将本应用添加至开始菜单的应用列表中，无需修改 launcher.dart。
class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  /// 调用此方法即可将 Demo 应用注册到开始菜单的应用列表
  static void register() {
    AppRegistry().register(App(
      id: 'com.demo.demo',
      name: 'Demo',
      themeColor: Colors.purple,
      icon: const Icon(Icons.explore),
      page: const DemoPage(),
      smallTile: const LiveTile(
        size: LiveTileSize.small,
        flipStyle: FlipStyle.elastic,
        children: [
          MetroAppTile(
            icon: Icon(Icons.explore, color: Colors.white, size: 24),
          ),
        ],
      ),
      mediumTile: const LiveTile(
        size: LiveTileSize.medium,
        flipStyle: FlipStyle.elastic,
        name: Text('Demo'),
        children: [
          MetroAppTile(
            icon: Icon(Icons.explore, size: 70),
            count: 2,
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              '一个通过注册中心自注册的 Demo 页面',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    ));
  }

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  @override
  Widget build(BuildContext context) {
    return const MetroPageScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore, size: 80, color: Colors.white70),
            SizedBox(height: 20),
            Text(
              'Demo 页面',
              style: TextStyle(
                fontSize: 36,
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '此页面通过 AppRegistry 自注册到开始菜单',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
