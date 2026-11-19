import 'package:flutter/material.dart' show Theme, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:metro_ui/metro_theme.dart';

/// PhoneColors with ThemeOverride=3 (follow the current system theme).
/// UIXMobile.dll 0x1002d349, light/dark tables 0x100069c0/0x10006a58.
class Wp8PhonePalette {
  Wp8PhonePalette.of(BuildContext context) : _theme = Theme.of(context);

  final ThemeData _theme;

  bool get light => _theme.brightness == Brightness.light;
  bool get highContrast =>
      _theme.extension<MetroSystemThemeData>()?.highContrast ?? false;

  Color get page => _theme.colorScheme.surface;
  Color get accent =>
      highContrast ? _theme.colorScheme.onSurface : _theme.colorScheme.primary;

  // ThemeColor indexes 18 (TextHigh), 20 (TextMid) and 26 (BaseLow).
  Color get textHigh => highContrast
      ? _theme.colorScheme.onSurface
      : light
      ? const Color(0xde000000)
      : const Color(0xffffffff);
  Color get textMid => highContrast
      ? _theme.colorScheme.onSurface
      : light
      ? const Color(0x73000000)
      : const Color(0x99ffffff);
  Color get baseLow =>
      light ? const Color(0x73000000) : const Color(0x73ffffff);

  // ThemeColor indexes 17 (Chrome) and 8 (key face).
  Color get chrome => highContrast ? page : _theme.colorScheme.surfaceContainer;
  Color get keyFace => highContrast
      ? page
      : light
      ? const Color(0xffffffff)
      : const Color(0xff383838);
  Color get pressedKeyText => highContrast ? page : const Color(0xffffffff);
}
