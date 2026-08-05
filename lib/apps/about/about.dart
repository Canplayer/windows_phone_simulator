import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/stack_panel.dart';
import 'package:windows_phone_simulator/app_registry.dart';
import 'package:windows_phone_simulator/start_menu.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  static void register() {
    AppRegistry().register(App(
      id: 'com.canplayer.about',
      name: 'About',
      //themeColor: Colors.purple,
      icon: const Icon(Icons.info, color: Colors.white),
      page: const AboutPage(),
      smallTile: const LiveTile(
        size: LiveTileSize.small,
        flipStyle: FlipStyle.elastic,
        children: [
          MetroAppTile(
            icon: Icon(Icons.info, color: Colors.white, size: 32),
          ),
        ],
      ),
      mediumTile: const LiveTile(
        size: LiveTileSize.medium,
        flipStyle: FlipStyle.elastic,
        name: Text('about'),
        children: [
          MetroAppTile(
            icon: Icon(Icons.info, color: Colors.white, size: 70),
          ),
        ],
      ),
    ));
  }

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
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
          return Column(
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
                            '''I’m truly proud to announce the release of this project.
Thanks to Flutter’s efficient and delightful development experience, this classic Windows Phone design language has been brought back to life.
I hope you enjoy this project and consider using it in your own applications.
As an amateur developer, I know my code may still have plenty of room for improvement.
If you like this project, I warmly welcome your contributions to make it even better.
                            
And hey — if you’d like to show your support, I wouldn’t say no to a cup of coffee. XD''',
                            style: TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 32),
                          SvgPicture.asset(
                            height: 50,
                            width: 50,
                            'images/canplayer_logo.svg',
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 32),
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
