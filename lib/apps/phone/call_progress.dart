import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/metro_theme.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/uix_typography.dart';
import 'package:metro_ui/widgets/phone_keypad.dart';

import 'keypad_page.dart';
import 'wp8_phone_palette.dart';

import 'package:metro_ui/widgets/uix_tight_text.dart';

/// Expanded PhoneShellUI cprog layer for one outgoing call.
///
/// Simulated outgoing Dialing state with the original shell controls.
class PhoneCallProgress extends StatefulWidget {
  const PhoneCallProgress({
    super.key,
    required this.number,
    required this.branding,
    this.displayName,
    this.onAddCall,
    this.onTone,
  });

  final String number, branding;
  final String? displayName;
  final VoidCallback? onAddCall;
  final ValueChanged<String>? onTone;

  Future<void> show(BuildContext context) => Navigator.of(context).push<void>(
    _CallProgressRoute(
      pageBuilder: (_, _, _) => MetroTheme(data: wp8PhoneTheme, child: this),
    ),
  );

  @override
  State<PhoneCallProgress> createState() => _PhoneCallProgressState();
}

class _PhoneCallProgressState extends State<PhoneCallProgress> {
  bool _keypad = false, _speaker = false, _muted = false;
  String _tones = '';

  @override
  Widget build(BuildContext context) {
    final palette = Wp8PhonePalette.of(context);
    return PhoneBackKey(
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  // Expanded_MainPanel_MinimumSize 330, including ButtonStrip.
                  constraints: const BoxConstraints(
                    minHeight: (330 - 81) * uixScale,
                  ),
                  child: _activeCall(palette),
                ),
                _buttonStrip(palette),
                if (_keypad)
                  ColoredBox(
                    // PhoneShellUI!Keypad_Content keeps the inset and gaps black.
                    color: const Color(0xff000000),
                    child: PhoneKeypad(
                      inCall: true,
                      highContrast: palette.highContrast,
                      background: palette.keyFace,
                      pressedBackground: palette.accent,
                      foreground: palette.textHigh,
                      secondaryForeground: palette.textMid,
                      pressedForeground: palette.pressedKeyText,
                      onKey: (digit) {
                        widget.onTone?.call(digit);
                        setState(() => _tones += digit);
                      },
                    ),
                  )
                else
                  _buttonGrid(palette),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _activeCall(Wp8PhonePalette palette) => ColoredBox(
    color: palette.chrome,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(start: 20 * uixScale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: 40 * uixScale,
              end: 12 * uixScale,
            ),
            child: UixTightText.fromText(
              Text(
                widget.branding,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: uixFontSize(15),
                  fontWeight: UixFontWeight.normal,
                  color: palette.textMid,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 195 * uixScale,
              bottom: 22 * uixScale,
            ),
            child: UixTightText.fromText(
              Text(
                'DIALING...',
                style: TextStyle(
                  fontSize: uixFontSize(15),
                  fontWeight: UixFontWeight.semiBold,
                  color: palette.accent,
                ),
              ),
            ),
          ),
          UixTightText.fromText(
            Text(
              widget.displayName ?? widget.number,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontSize: uixFontSize(54),
                letterSpacing: -2 * uixScale,
                fontWeight: UixFontWeight.semiLight,
                color: palette.textHigh,
              ),
            ),
          ),
          if (widget.displayName != null || _tones.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11 * uixScale),
              child: UixTightText.fromText(
                Text(
                  _tones.isEmpty ? widget.number : _tones,
                  style: TextStyle(
                    fontSize: uixFontSize(21),
                    fontWeight: UixFontWeight.normal,
                    color: palette.textMid,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _buttonStrip(Wp8PhonePalette palette) => ColoredBox(
    color: palette.chrome,
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        2 * uixScale,
        2 * uixScale,
        2 * uixScale,
        2 * uixScale,
      ),
      child: SizedBox(
        height: 77 * uixScale,
        child: Row(
          children: [
            Expanded(
              flex: 316,
              child: _ShellButton(
                label: 'END CALL',
                face: palette.accent,
                foreground: palette.pressedKeyText,
                pressedFace: palette.textHigh,
                pressedForeground: palette.page,
                command: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 4 * uixScale),
            Expanded(
              flex: 156,
              child: _ShellButton(
                label: _keypad ? 'call controls' : 'keypad',
                icon: _keypad ? 'grid' : 'dialpad',
                iconSize: 34,
                showLabel: false,
                face: palette.keyFace,
                foreground: palette.textHigh,
                pressedFace: palette.accent,
                pressedForeground: palette.pressedKeyText,
                command: () => setState(() => _keypad = !_keypad),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buttonGrid(Wp8PhonePalette palette) {
    Widget button(
      String label,
      String icon, {
      bool selected = false,
      VoidCallback? command,
    }) {
      return _ShellButton(
        label: label,
        icon: icon,
        face: selected ? palette.accent : palette.keyFace,
        foreground: selected ? palette.pressedKeyText : palette.textHigh,
        pressedFace: palette.keyFace,
        pressedForeground: palette.textHigh,
        command: command,
      );
    }

    Widget row(List<Widget> items) => SizedBox(
      height: 98 * uixScale,
      child: Row(
        children: [
          for (final (index, item) in items.indexed) ...[
            if (index > 0) const SizedBox(width: 4 * uixScale),
            Expanded(child: item),
          ],
        ],
      ),
    );
    // PhoneShellUI!ButtonGrid_Content sets BaseBlackColor on mainPanel.
    return ColoredBox(
      color: const Color(0xff000000),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: 2 * uixScale,
          top: 2 * uixScale,
          end: 2 * uixScale,
        ),
        child: Column(
          children: [
            row([
              button(
                'SPEAKER',
                'speaker',
                selected: _speaker,
                command: () => setState(() => _speaker = !_speaker),
              ),
              button(
                'MUTE',
                'mute',
                selected: _muted,
                command: () => setState(() => _muted = !_muted),
              ),
              button('HOLD', 'hold'),
            ]),
            const SizedBox(height: 4 * uixScale),
            row([
              button('BLUETOOTH', 'bluetooth'),
              button('ADD CALL', 'caller.join', command: widget.onAddCall),
              const SizedBox.shrink(),
            ]),
          ],
        ),
      ),
    );
  }
}

class _CallProgressRoute extends RawDialogRoute<void> {
  _CallProgressRoute({required super.pageBuilder})
    : super(
        barrierDismissible: false,
        barrierColor: const Color(0x00000000),
        transitionDuration: const Duration(milliseconds: 500),
        transitionBuilder: _buildTransition,
      );

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> a,
    Animation<double> secondary,
    Widget child,
  ) {
    final closing = a.status == AnimationStatus.reverse;
    final t = closing ? 1 - a.value : a.value;
    // PhoneShellUI!Expanded: FlipInExpandedAreaOnShow / FlipOutExpandedAreaOnHide.
    final turn = closing
        ? const UixExp(10).transform(t) * math.pi / 2
        : (const UixLog(150)
                      .transform(((t * 500 - 260) / 240).clamp(0.0, 1.0)) -
                  1) *
              math.pi /
              9;
    final alpha = closing
        ? ((1 - t) * 22).clamp(0.0, 1.0)
        : ((t * 500 - 250) / 10).clamp(0.0, 1.0);
    return IgnorePointer(
      ignoring: closing || t < 1,
      child: Opacity(
        opacity: alpha,
        child: Transform(
          alignment: const FractionalOffset(.5, .2),
          transform: Matrix4.identity()..rotateX(turn),
          child: child,
        ),
      ),
    );
  }
}

class _ShellButton extends StatefulWidget {
  const _ShellButton({
    required this.label,
    required this.face,
    required this.foreground,
    required this.pressedFace,
    required this.pressedForeground,
    this.command,
    this.icon,
    this.iconSize = 30,
    this.showLabel = true,
  });

  final String label;
  final String? icon;
  final Color face, foreground, pressedFace, pressedForeground;
  final VoidCallback? command;
  final double iconSize;
  final bool showLabel;

  @override
  State<_ShellButton> createState() => _ShellButtonState();
}

class _ShellButtonState extends State<_ShellButton> {
  bool _pressed = false;
  void _press(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Wp8PhonePalette.of(context);
    final icon = widget.icon;
    final enabled = widget.command != null;
    final foreground = _pressed
        ? widget.pressedForeground
        : enabled
        ? widget.foreground
        : palette.textMid;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.command,
        onTapDown: enabled ? (_) => _press(true) : null,
        onTapUp: enabled ? (_) => _press(false) : null,
        onTapCancel: enabled ? () => _press(false) : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _pressed ? widget.pressedFace : widget.face,
            border: palette.highContrast
                ? Border.all(color: foreground, width: 3 * uixScale)
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Image.asset(
                    '$wp8PhoneAssets/call_${icon.replaceAll('.', '_')}_${_pressed ? 'down' : 'rest'}.png',
                    width: widget.iconSize * uixScale,
                    height: widget.iconSize * uixScale,
                    color: foreground,
                    excludeFromSemantics: true,
                  ),
                if (widget.showLabel)
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: uixFontSize(icon == null ? 17 : 16),
                      fontWeight: icon == null
                          ? UixFontWeight.semiBold
                          : UixFontWeight.normal,
                      color: foreground,
                      decoration: TextDecoration.none,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
