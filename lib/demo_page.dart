import 'package:flutter/material.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:windows_phone_simulator/app_registry.dart';
import 'package:windows_phone_simulator/start_menu.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/widgets/metro_list_picker.dart';
import 'package:metro_ui/widgets/metro_text_box.dart';
import 'package:metro_ui/widgets/progress_bar.dart';
import 'package:metro_ui/widgets/progress_ring.dart';
import 'package:metro_ui/widgets/switcher.dart';

/// Demo 空白页面 —— 作为 "通过注册中心自注册" 的示例
///
/// 只需在任意入口处调用 [DemoPage.register()]，
/// 即可将本应用添加至开始菜单的应用列表中，无需修改 launcher.dart。
class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  /// 调用此方法即可将 Demo 应用注册到开始菜单的应用列表
  static void register() {
    AppRegistry().register(
      App(
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
            MetroAppTile(icon: Icon(Icons.explore, size: 70), count: 2),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                '一个通过注册中心自注册的 Demo 页面',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  bool _switchValue = true;
  String? _pickedValue;
  String? _pickedValue2;

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Opacity(
            //   opacity: 0.5,
            //   child: Image.asset(
            //     'images/backgrounds/demo_background.png',
            //     fit: BoxFit.fitWidth,
            //     alignment: Alignment.center,
            //   ),
            // ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                // Top aligned: an expanding ListPicker only pushes what is below it.
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'DEMO组件 演示',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const ProgressRing(
                    isActive: true,
                    size: 20,
                    foreground: Colors.white70,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 280,
                    child: Column(
                      children: [
                        const ProgressBar(
                          value: 0.35,
                          foreground: Colors.white70,
                        ),
                        const SizedBox(height: 16),
                        const ProgressBar(foreground: Colors.white70),
                        const SizedBox(height: 16),
                        const EditBox(hintText: '输入文字'),
                        ListPicker<String>(
                          items: const ['mobile yersion', 'stop/refresh', 'tabs'],
                          itemLabel: (v) => v,
                          value: _pickedValue,
                          placeholder: '请选择',
                          onChanged: (v) => setState(() => _pickedValue = v),
                        ),
                        ListPicker<String>(
                          items: const ['一', '二', '三', '四', '五'],
                          itemLabel: (v) => '选项 $v',
                          value: _pickedValue2,
                          placeholder: '五个选项（就地展开）',
                          onChanged: (v) => setState(() => _pickedValue2 = v),
                        ),
                        const SizedBox(height: 8),
                        MetroButton(onTap: () {}, child: const Text('按钮')),
                        const SizedBox(height: 8),
                        const MetroButton(child: Text('禁用')),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomSwitch(
                        value: _switchValue,
                        activeColor: Colors.white70,
                        onChanged: (v) => setState(() => _switchValue = v),
                      ),
                      const SizedBox(width: 24),
                      const CustomSwitch(
                        value: false,
                        activeColor: Colors.white70,
                        onChanged: null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
