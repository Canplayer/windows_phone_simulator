import 'package:flutter/material.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/widgets/stack_panel.dart';

/// 拨号键盘页面（暂为占位页）。
class KeypadPage extends StatelessWidget {
  const KeypadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      stackPanel: const StackPanel(
        top: Text('CHINA UNICOM'),
        bottom: Text('history'),
      ),
      applicationBar: MetroApplicationBar(
        backgroundColor: Colors.grey[900],
        buttons: [
          Container(
            width: 360,
            height: 38,
            child: Row(
              children: [
                Expanded(
                  child: MetroButton(
                    margin: EdgeInsets.zero,
                    child: Text("call", textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 10,),
                Expanded(
                  child: MetroButton(
                    margin: EdgeInsets.zero,
                    child: Text("save", textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Hello World',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}
