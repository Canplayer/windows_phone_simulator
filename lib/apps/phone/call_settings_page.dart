import 'package:flutter/widgets.dart';
import 'package:metro_ui/metro_theme.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/page_header.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/uix_typography.dart';
import 'package:metro_ui/widgets/message_box.dart';
import 'package:metro_ui/widgets/list_picker.dart';
import 'package:metro_ui/widgets/toggle_switch.dart';
import 'package:metro_ui/widgets/uix_edit_box.dart';
import 'package:metro_ui/widgets/uix_popup.dart';

import 'keypad_page.dart';
import 'wp8_phone_palette.dart';

import 'package:metro_ui/widgets/uix_tight_text.dart';

enum CallerIdSetting {
  everyone('everyone'),
  noOne('no one'),
  contacts('my contacts');

  const CallerIdSetting(this.label);
  final String label;
}

enum SimSecurityMode { ready, radioOff, noSim, unavailable }

/// Local simulator equivalents of the values supplied by PhoneSettings!IModel.
/// Null feature values represent a capability the host does not expose.
class PhoneSettingsModel {
  PhoneSettingsModel({
    this.phoneNumber = '',
    this.voicemailNumber = '',
    this.defaultVoicemailNumber,
    this.useDefaultVoicemail = false,
    this.callerId,
    this.callForwardingNumber,
    this.callForwardingEnabled = false,
    this.internationalAssist,
    this.longTones,
    this.simSecurityMode = SimSecurityMode.noSim,
    this.simSecurityEnabled = false,
    this.onSimSecurityChanged,
    this.onChangeSimPin,
  });

  final String phoneNumber;
  String? voicemailNumber;
  final String? defaultVoicemailNumber;
  bool useDefaultVoicemail;
  CallerIdSetting? callerId;
  String? callForwardingNumber;
  bool callForwardingEnabled;
  bool? internationalAssist;
  bool? longTones;
  final SimSecurityMode simSecurityMode;
  bool simSecurityEnabled;
  final Future<bool> Function(bool)? onSimSecurityChanged;
  final VoidCallback? onChangeSimPin;
}

/// PhoneSettings!CallSettingsDevice and CallSettings_Content, en-US.
class CallSettingsPage extends StatefulWidget {
  const CallSettingsPage({super.key, required this.model});

  final PhoneSettingsModel model;

  @override
  State<CallSettingsPage> createState() => _CallSettingsPageState();
}

class _CallSettingsPageState extends State<CallSettingsPage> {
  // CallSettings_Content!LocalConstants::MaxNumberLength and SpacerType=1.
  static const _maximumNumberLength = 32;
  static const _sectionSpacer = SizedBox(height: 40 * uixScale);

  PhoneSettingsModel get _model => widget.model;
  final _voicemailFocus = FocusNode();
  late final _voicemail = TextEditingController(text: _model.voicemailNumber);
  bool _changingSimSecurity = false;

  @override
  void dispose() {
    _voicemail.dispose();
    _voicemailFocus.dispose();
    super.dispose();
  }

  Future<void> _setSimSecurity(bool enabled) async {
    final update = _model.onSimSecurityChanged;
    if (update == null || _changingSimSecurity) return;
    setState(() => _changingSimSecurity = true);
    try {
      if (await update(enabled) && mounted) {
        setState(() => _model.simSecurityEnabled = enabled);
      }
    } finally {
      if (mounted) setState(() => _changingSimSecurity = false);
    }
  }

  Future<void> _editForwarding() async {
    final model = _model;
    final value = await Navigator.of(context).push(
      UixPopupRoute<String>(
        brightness: Wp8PhonePalette.of(context).light
            ? Brightness.light
            : Brightness.dark,
        pageBuilder: (_, _, _) =>
            _ForwardNumberDialog(number: model.callForwardingNumber!),
      ),
    );
    if (value != null && mounted) {
      setState(() {
        model.callForwardingNumber = value;
        model.callForwardingEnabled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => MetroTheme(
    data: wp8PhoneTheme,
    child: Builder(builder: _buildSettings),
  );

  Widget _buildSettings(BuildContext context) {
    final palette = Wp8PhonePalette.of(context);
    final callerId = _model.callerId;
    final forwardingNumber = _model.callForwardingNumber;
    final assisted = _model.internationalAssist;
    final longTones = _model.longTones;
    final voicemailDefault = _model.defaultVoicemailNumber;
    return PhoneBackKey(
      child: MetroPageScaffold(
        useMaterialSurface: false,
        // PhoneSettings!CallSettingsDevice.CallSettings derives from SinglePivotPage.
        header: MetroPageHeader(
          title: const Text('SETTINGS'),
          singlePivotHeader: const Text('phone'),
          titleStyle: TextStyle(color: palette.textHigh),
          singlePivotHeaderStyle: TextStyle(color: palette.textHigh),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          minimum: const EdgeInsets.symmetric(horizontal: 24 * uixScale),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_model.phoneNumber.isNotEmpty) ...[
                  _caption('My phone number', palette),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 12 * uixScale,
                      bottom: 56 * uixScale,
                    ),
                    child: UixTightText.fromText(
                      Text(
                        _model.phoneNumber,
                        style: TextStyle(
                          fontSize: uixFontSize(24),
                          fontWeight: UixFontWeight.semiLight,
                          color: palette.textHigh,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_model.voicemailNumber != null) ...[
                  if (voicemailDefault == null)
                    _caption('Voicemail number', palette)
                  else
                    ToggleSwitch(
                      label: 'Use default voicemail number',
                      value: _model.useDefaultVoicemail,
                      onChanged: (value) =>
                          setState(() => _model.useDefaultVoicemail = value),
                    ),
                  if (voicemailDefault == null || !_model.useDefaultVoicemail)
                    UixEditBox(
                      controller: _voicemail,
                      focusNode: _voicemailFocus,
                      backgroundImage: _editBoxBackground(palette),
                      placeholder: voicemailDefault == null
                          ? 'voicemail number'
                          : 'new voicemail number',
                      keyboardType: TextInputType.phone,
                      maxLength: _maximumNumberLength,
                      onChanged: (value) => _model.voicemailNumber = value,
                    ),
                  _sectionSpacer,
                ],
                if (callerId != null) ...[
                  _caption('Show my caller ID to', palette),
                  ListPicker<CallerIdSetting>(
                    items: CallerIdSetting.values,
                    value: callerId,
                    itemLabel: (value) => value.label,
                    onChanged: (value) =>
                        setState(() => _model.callerId = value),
                  ),
                  _sectionSpacer,
                ],
                if (forwardingNumber != null) ...[
                  _caption('Call forwarding', palette),
                  Transform.translate(
                    offset: const Offset(0, -15 * uixScale),
                    child: ToggleSwitch(
                      value: _model.callForwardingEnabled,
                      onChanged: (value) {
                        if (value && forwardingNumber.isEmpty) {
                          _editForwarding();
                        } else {
                          setState(() => _model.callForwardingEnabled = value);
                        }
                      },
                    ),
                  ),
                  if (_model.callForwardingEnabled)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(
                        width: 136 * uixScale,
                        child: MetroTextCommand(
                          label: forwardingNumber,
                          onPressed: _editForwarding,
                        ),
                      ),
                    ),
                  _sectionSpacer,
                ],
                if (assisted != null) ...[
                  ToggleSwitch(
                    value: assisted,
                    label: 'International assist',
                    description: 'Turning on this feature will help automatically correct some common mistakes while dialing internationally or dialing while abroad.',
                    onChanged: (value) =>
                        setState(() => _model.internationalAssist = value),
                  ),
                  _sectionSpacer,
                ],
                ..._simSecurity(palette),
                if (longTones != null)
                  ToggleSwitch(
                    value: longTones,
                    label: 'Long tones',
                    onChanged: (value) =>
                        setState(() => _model.longTones = value),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _simSecurity(Wp8PhonePalette palette) {
    switch (_model.simSecurityMode) {
      case SimSecurityMode.unavailable:
        return const [];
      case SimSecurityMode.noSim:
      case SimSecurityMode.radioOff:
        return [
          Text(
            _model.simSecurityMode == SimSecurityMode.noSim
                ? 'No SIM'
                : 'Radios are off',
            style: TextStyle(fontSize: uixFontSize(17), color: palette.textMid),
          ),
          _sectionSpacer,
        ];
      case SimSecurityMode.ready:
        return [
          ToggleSwitch(
            value: _model.simSecurityEnabled,
            label: 'SIM security',
            onChanged:
                _model.onSimSecurityChanged == null || _changingSimSecurity
                ? null
                : _setSimSecurity,
          ),
          if (_model.simSecurityEnabled) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(
                width: 204 * uixScale,
                child: MetroTextCommand(
                  label: 'change SIM PIN',
                  onPressed: _model.onChangeSimPin,
                ),
              ),
            ),
            _sectionSpacer,
          ],
        ];
    }
  }

  Widget _caption(String label, Wp8PhonePalette palette) =>
      UixTightText.fromText(
        Text(
          label,
          style: TextStyle(fontSize: uixFontSize(15), color: palette.textMid),
        ),
      );
}

AssetImage _editBoxBackground(Wp8PhonePalette palette) => AssetImage(
  '$wp8PhoneAssets/editbox_${palette.light ? 'light' : 'dark'}.png',
);

class _ForwardNumberDialog extends StatefulWidget {
  const _ForwardNumberDialog({required this.number});

  final String number;

  @override
  State<_ForwardNumberDialog> createState() => _ForwardNumberDialogState();
}

class _ForwardNumberDialogState extends State<_ForwardNumberDialog> {
  late final _number = TextEditingController(text: widget.number);
  final _focus = FocusNode();

  @override
  void dispose() {
    _number.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Wp8PhonePalette.of(context);
    return ColoredBox(
      color: palette.chrome,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          24 * uixScale,
          32 * uixScale,
          24 * uixScale,
          12 * uixScale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24 * uixScale),
              child: UixTightText.fromText(
                Text(
                  'Forward calls to',
                  style: TextStyle(
                    fontSize: uixFontSize(15),
                    color: palette.textMid,
                  ),
                ),
              ),
            ),
            UixEditBox(
              controller: _number,
              focusNode: _focus,
              backgroundImage: _editBoxBackground(palette),
              placeholder: 'Type number',
              keyboardType: TextInputType.phone,
              maxLength: _CallSettingsPageState._maximumNumberLength,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 32 * uixScale),
            Row(
              children: [
                Expanded(
                  child: MetroTextCommand(
                    label: 'save',
                    onPressed: _number.text.trim().isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_number.text.trim()),
                  ),
                ),
                const SizedBox(width: 24 * uixScale),
                Expanded(
                  child: MetroTextCommand(
                    label: 'cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
