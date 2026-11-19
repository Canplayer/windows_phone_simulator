import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/metro_theme.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/uix_typography.dart';
import 'package:metro_ui/widgets/message_box.dart';
import 'package:metro_ui/widgets/phone_keypad.dart';
import 'package:metro_ui/widgets/uix_page_slide.dart';

import 'wp8_phone_palette.dart';

import 'package:metro_ui/widgets/uix_tight_text.dart';

const wp8PhoneTheme = MetroThemeData.fromPreset(
  version: MetroDesignVersion.wp8,
);
const wp8PhoneAssets = 'images/wp8_phone';

class KeypadPage extends StatefulWidget {
  const KeypadPage({
    super.key,
    this.branding = 'PHONE',
    required this.onDial,
    this.onSaveContact,
    this.onVoicemail,
    this.formatNumber,
  });

  final String branding;
  final bool Function(String number) onDial;
  final ValueChanged<String>? onSaveContact;
  final VoidCallback? onVoicemail;
  final String Function(String number)? formatNumber;

  @override
  State<KeypadPage> createState() => _KeypadPageState();
}

class _KeypadPageState extends State<KeypadPage> with WidgetsBindingObserver {
  final _slide = GlobalKey<UixPageSlideState>();
  String _number = '';
  bool _submitted = false;
  bool _clipboardHasContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _readClipboardState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _readClipboardState();
  }

  Future<void> _readClipboardState() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    final available = text != null && _dialableClipboard(text).isNotEmpty;
    if (mounted && available != _clipboardHasContent) {
      setState(() => _clipboardHasContent = available);
    }
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (text != null && mounted) _append(_dialableClipboard(text));
    if (mounted) _readClipboardState();
  }

  // The WP clipboard model returns dialable characters, independently of the
  // original display text. The simulator supports the keypad alphabet.
  String _dialableClipboard(String text) =>
      text.replaceAll(RegExp(r'[^0-9+*#]'), '');

  void _append(String text) => setState(() => _number += text);

  void _backspace() {
    if (_number.isNotEmpty) {
      setState(() => _number = _number.characters.skipLast(1).toString());
    }
  }

  void _dial() {
    // Phone!Dialer::OnDialClicked keeps the page open for an invalid number.
    if (_submitted || !widget.onDial(_number)) return;
    setState(() {
      _submitted = true;
      _number = '';
    });
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return MetroTheme(
      data: wp8PhoneTheme,
      child: Builder(builder: _buildPage),
    );
  }

  Widget _buildPage(BuildContext context) {
    final palette = Wp8PhonePalette.of(context);
    final canHoldOne = _number.isEmpty || _number == '1';
    final saveContact = widget.onSaveContact;
    return PhoneBackKey(
      child: MetroPageScaffold(
        useMaterialSurface: false,
        extendBodyToApplicationBar: false,
        disableDefaultPushAnimation: true,
        disableDefaultPopAnimation: true,
        onDidPush: () async {
          await _slide.currentState?.show();
        },
        onDidPop: () async {
          await _slide.currentState?.hide();
        },
        applicationBar: MetroApplicationBar(
          theme: wp8PhoneTheme,
          showMenuIndicator: false,
          customContent: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24 * uixScale),
            child: Row(
              children: [
                Expanded(
                  child: _command('call', _number.isEmpty ? null : _dial),
                ),
                const SizedBox(width: 24 * uixScale),
                Expanded(
                  child: _command(
                    'save',
                    _number.isEmpty || saveContact == null
                        ? null
                        : () => saveContact(_number),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Phone!Dialer_Content: keypad at Bottom, accumulator panel at Client.
        body: UixPageSlide(
          key: _slide,
          initiallyVisible: false,
          child: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  Expanded(
                    child: ClipRect(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          PositionedDirectional(
                            start: 24 * uixScale,
                            end: 24 * uixScale,
                            top: 24 * uixScale,
                            child: UixTightText.fromText(
                              Text(
                                widget.branding,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontSize: uixFontSize(17),
                                  fontWeight: UixFontWeight.semiBold,
                                  color: palette.textHigh,
                                ),
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            start: 24 * uixScale,
                            top: 71 * uixScale,
                            end: 0,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 363 * uixScale,
                                ),
                                child: UixTightText.fromText(
                                  Text(
                                    widget.formatNumber?.call(_number) ??
                                        _number,
                                    key: const ValueKey('dialer-accumulator'),
                                    maxLines: 1,
                                    overflow: TextOverflow.clip,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: uixFontSize(40),
                                      fontWeight: UixFontWeight.semiLight,
                                      color: palette.textHigh,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_number.isNotEmpty)
                            PositionedDirectional(
                              top: 32 * uixScale,
                              end: 9 * uixScale,
                              child: _PhoneImageButton(
                                label: 'backspace',
                                image: 'backspace',
                                width: 49,
                                height: 34,
                                color: palette.textHigh,
                                pressedColor: palette.baseLow,
                                padding: const EdgeInsets.fromLTRB(
                                  16 * uixScale,
                                  30 * uixScale,
                                  16 * uixScale,
                                  31 * uixScale,
                                ),
                                onTap: _backspace,
                                onLongPress: () => setState(() => _number = ''),
                              ),
                            ),
                          if (_clipboardHasContent)
                            PositionedDirectional(
                              start: 0,
                              bottom: 12 * uixScale,
                              child: _PhoneImageButton(
                                label: 'paste',
                                image: 'paste_rest',
                                downImage: 'paste_down',
                                width: 48,
                                height: 48,
                                color: palette.textHigh,
                                pressedColor: palette.textHigh,
                                padding: EdgeInsets.zero,
                                onTap: _paste,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight,
                    ),
                    child: ColoredBox(
                      color: palette.chrome,
                      child: PhoneKeypad(
                        background: palette.keyFace,
                        pressedBackground: palette.accent,
                        foreground: palette.textHigh,
                        secondaryForeground: palette.textMid,
                        pressedForeground: palette.pressedKeyText,
                        highContrast: palette.highContrast,
                        onKey: _append,
                        onHoldOne: canHoldOne ? widget.onVoicemail : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _command(String label, VoidCallback? onTap) =>
      MetroTextCommand(label: label, onPressed: onTap);
}

/// Escape on desktop acts like a press of the hardware Back key.
class PhoneBackKey extends StatelessWidget {
  const PhoneBackKey({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: (_, event) {
      if (event is! KeyDownEvent ||
          event.logicalKey != LogicalKeyboardKey.escape) {
        return KeyEventResult.ignored;
      }
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    },
    child: child,
  );
}

class _PhoneImageButton extends StatefulWidget {
  const _PhoneImageButton({
    required this.label,
    required this.image,
    this.downImage,
    required this.width,
    required this.height,
    required this.color,
    required this.pressedColor,
    required this.padding,
    required this.onTap,
    this.onLongPress,
  });

  final String label, image;
  final String? downImage;
  final double width, height;
  final Color color, pressedColor;
  final EdgeInsets padding;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_PhoneImageButton> createState() => _PhoneImageButtonState();
}

class _PhoneImageButtonState extends State<_PhoneImageButton> {
  bool _down = false;
  void _setDown(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    button: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setDown(true),
      onTapUp: (_) => _setDown(false),
      onTapCancel: () => _setDown(false),
      onLongPress: widget.onLongPress,
      child: Padding(
        padding: widget.padding,
        child: Image.asset(
          '$wp8PhoneAssets/${_down ? widget.downImage ?? widget.image : widget.image}.png',
          width: widget.width * uixScale,
          height: widget.height * uixScale,
          color: _down ? widget.pressedColor : widget.color,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}
