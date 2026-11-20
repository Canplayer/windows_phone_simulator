import 'package:flutter/material.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/metro_theme.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/widgets/list_picker.dart';
import 'package:metro_ui/widgets/message_box.dart';
import 'package:metro_ui/widgets/page_header.dart';
import 'package:metro_ui/widgets/toggle_switch.dart';
import 'package:windows_phone_simulator/app_registry.dart';
import 'package:windows_phone_simulator/start_menu.dart';

class ThemeDemoPage extends StatefulWidget {
  const ThemeDemoPage({super.key});

  static void register() {
    AppRegistry().register(
      App(
        id: 'com.canplayer.themedemo',
        name: 'Theme demo',
        icon: const Icon(Icons.palette_outlined, color: Colors.white),
        page: const ThemeDemoPage(),
        smallTile: const LiveTile(
          size: LiveTileSize.small,
          children: [
            MetroAppTile(
              icon: Icon(Icons.palette_outlined, color: Colors.white, size: 32),
            ),
          ],
        ),
        mediumTile: const LiveTile(
          size: LiveTileSize.medium,
          name: Text('Theme demo'),
          children: [
            MetroAppTile(
              icon: Icon(Icons.palette_outlined, color: Colors.white, size: 70),
            ),
          ],
        ),
      ),
    );
  }

  @override
  State<ThemeDemoPage> createState() => _ThemeDemoPageState();
}

class _ThemeDemoPageState extends State<ThemeDemoPage> {
  MetroDesignVersion? _version;
  Brightness? _brightness;
  bool? _highContrast;

  void _reset() => setState(() {
    _version = null;
    _brightness = null;
    _highContrast = null;
  });

  String _versionLabel(MetroDesignVersion version) => switch (version) {
    MetroDesignVersion.wp7 => 'Windows Phone 7',
    MetroDesignVersion.wp8 => 'Windows Phone 8',
    MetroDesignVersion.wp81 => 'Windows Phone 8.1',
  };

  @override
  Widget build(BuildContext context) {
    final system = MetroSystemThemeData.of(context);
    final version = _version ?? system.version;
    final brightness = _brightness ?? Theme.of(context).brightness;
    final highContrast = _highContrast ?? system.highContrast;
    final preview = MetroThemeData.fromPreset(
      version: version,
      brightness: brightness,
      highContrast: highContrast,
    );
    return MetroTheme(
      data: preview,
      child: Builder(
        builder: (previewContext) => MetroPageScaffold(
          header: const MetroPageHeader(
            title: Text('FLUMETRO'),
            singlePivotHeader: Text('theme demo'),
          ),
          extendBodyToApplicationBar: false,
          applicationBar: MetroApplicationBar(
            // The overlay lives above this page's MetroTheme.
            theme: preview,
            buttons: [
              MetroAppBarButton(
                label: 'message',
                icon: const Icon(Icons.message_outlined),
                onPressed: () => const MetroMessageBox(
                  title: 'Theme preview',
                  message: 'This dialog uses the preview theme.',
                  confirmLabel: 'ok',
                  cancelLabel: 'cancel',
                ).show(previewContext),
              ),
            ],
            menuItems: [
              MetroAppBarMenuItem(label: 'reset preview', onPressed: _reset),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24 * uixScale),
            children: [
              const Text('version'),
              ListPicker<MetroDesignVersion>(
                items: MetroDesignVersion.values,
                value: version,
                itemLabel: _versionLabel,
                onChanged: (value) => setState(() => _version = value),
              ),
              ToggleSwitch(
                label: 'light theme',
                value: brightness == Brightness.light,
                onChanged: (value) => setState(() {
                  _brightness = value ? Brightness.light : Brightness.dark;
                }),
              ),
              const SizedBox(height: 24 * uixScale),
              ToggleSwitch(
                label: 'high contrast',
                value: highContrast,
                onChanged: (value) => setState(() => _highContrast = value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
