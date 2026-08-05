import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/stack_panel.dart';
import 'package:windows_phone_simulator/app_registry.dart';
import 'package:windows_phone_simulator/start_menu.dart';

class PhoneApp extends StatefulWidget {
  const PhoneApp({super.key});

  // ─── 图标模板 ─────────────────────────────────
  // 以“高度”为基准等比缩放：传目标高度即可，宽度按 SVG 宽高比自动计算。
  // 不要包 FittedBox —— LiveTile 外层已有画布 FittedBox 做等比缩放，
  // 嵌套 FittedBox 在紧约束下会退化失效（上一轮已验证）。
  static Widget appIcon(double height) {
    return SvgPicture.asset(
      'images/icons/phone_icon.svg',
      height: height,
      fit: BoxFit.contain, // 保持宽高比，等价于“以高度缩放”
      colorFilter: const ColorFilter.mode(
        Colors.white,
        BlendMode.srcIn,
      ),
    );
  }

  static void register() {
    AppRegistry().register(App(
      id: 'com.ms.phone',
      name: 'Phone',
      //themeColor: Colors.purple,
      icon: appIcon(32), // 应用列表图标
      page: const PhoneApp(),
      smallTile: LiveTile(
        size: LiveTileSize.small,
        flipStyle: FlipStyle.elastic,
        children: [
          MetroAppTile(
            icon: appIcon(36), // 小磁贴：画布 79.5px，占比约 45%
          ),
        ],
      ),
      mediumTile: LiveTile(
        size: LiveTileSize.medium,
        flipStyle: FlipStyle.elastic,
        name: const Text('Phone'),
        children: [
          MetroAppTile(
            icon: appIcon(72), // 中磁贴：画布 168px，占比约 43%
          ),
        ],
      ),
    ));
  }

  @override
  State<PhoneApp> createState() => _PhoneAppState();
}

class _PhoneAppState extends State<PhoneApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      //backgroundColor: Colors.blueGrey,
      stackPanel: const StackPanel(
        top: Text('FLUMETRO'),
        bottom: Text('about'),
      ),
      body: Builder(
        // 使用 Builder 来获取正确的 context
        builder: (scaffoldContext) {
          return const Column(
            children: <Widget>[
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 19.0),
                  child: SingleChildScrollView(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '''hello world''',
                            style: TextStyle(fontSize: 20),
                          ),
                        ]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
