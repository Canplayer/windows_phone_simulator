import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/metro_page_push.dart';
import 'package:metro_ui/metro_theme.dart';
import 'package:metro_ui/page.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/context_menu.dart';
import 'package:metro_ui/widgets/message_box.dart';
import 'package:metro_ui/widgets/page_header.dart';
import 'package:metro_ui/widgets/pivot.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/uix_typography.dart';
import 'package:metro_ui/widgets/pushable_double_line_list_item.dart';
import 'package:metro_ui/widgets/search_bar.dart';
import 'package:metro_ui/widgets/tile.dart';
import 'package:metro_ui/widgets/uix_page_slide.dart';
import 'package:windows_phone_simulator/app_registry.dart';
import 'package:windows_phone_simulator/start_menu.dart';

import 'call_progress.dart';
import 'call_settings_page.dart';
import 'keypad_page.dart';
import 'wp8_phone_palette.dart';

/// 自驱动的 Phone 磁贴：不关心外界的创建/销毁，
/// 挂载到屏幕上即开始播放角标时序：等 2s → 1 → 2 → 3 → 4 → 5，卸载时自动停止。
/// 每个磁贴实例持有自己的角标与时序任务，互不干扰。
class PhoneLiveTile extends StatefulWidget {
  final LiveTileSize size;
  final Widget? name;
  final Widget icon;

  const PhoneLiveTile({
    super.key,
    required this.size,
    required this.icon,
    this.name,
  });

  @override
  State<PhoneLiveTile> createState() => _PhoneLiveTileState();
}

class _PhoneLiveTileState extends State<PhoneLiveTile> {
  /// 磁贴内容（可以是任意 Widget：文字、图片、动画、组合……）
  late final ValueNotifier<Widget> _content;

  @override
  void initState() {
    super.initState();
    _content = ValueNotifier<Widget>(widget.icon);
    _playBadgeSequence();
  }

  /// 角标动画
  Future<void> _playBadgeSequence() async {
    // 等 2 秒才开始计数
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _content.value = _buildBadge(1);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _content.value = _buildBadge(2);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _content.value = _buildBadge(3);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    _content.value = _buildBadge(4);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _content.value = _buildBadge(5);
  }

  /// 数字角标：SVG 图标 + 角标数字
  Widget _buildBadge(int number) {
    return MetroAppTile(
      icon: widget.icon, // 直接用传入的 SVG 图标
      count: number, // 角标数字
    );
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 注意：ValueListenableBuilder 只包内容，不包 LiveTile 本体，
    // 这样 LiveTile 的 3D 翻转动画 State 保持稳定，不会因内容更新而重置。
    return LiveTile(
      size: widget.size,
      flipStyle: FlipStyle.elastic,
      name: widget.name,
      children: [
        ValueListenableBuilder<Widget>(
          valueListenable: _content,
          builder: (context, content, _) {
            return MetroAppTile(icon: content);
          },
        ),
      ],
    );
  }
}

class PhoneApp extends StatefulWidget {
  const PhoneApp({
    super.key,
    this.branding = 'PHONE',
    this.onVoicemail,
    this.onOpenPeople,
    this.onOpenSettings,
    this.settingsModel,
    this.onOpenHistoryItem,
    this.onSaveContact,
    this.onPlaceCall,
    this.onSearchContacts,
    this.formatNumber,
  });

  final String branding;
  final VoidCallback? onVoicemail;
  final VoidCallback? onOpenPeople;
  final VoidCallback? onOpenSettings;
  final PhoneSettingsModel? settingsModel;
  final ValueChanged<CallRecord>? onOpenHistoryItem;
  final ValueChanged<String>? onSaveContact;
  final bool Function(String number)? onPlaceCall;
  final ValueChanged<String>? onSearchContacts;
  final String Function(String number)? formatNumber;

  // ─── 图标模板 ─────────────────────────────────
  // 以“高度”为基准等比缩放：传目标高度即可，宽度按 SVG 宽高比自动计算。
  // 不要包 FittedBox —— LiveTile 外层已有画布 FittedBox 做等比缩放，
  // 嵌套 FittedBox 在紧约束下会退化失效（上一轮已验证）。
  static Widget appIcon(double height) {
    return SvgPicture.asset(
      'images/icons/phone_icon.svg',
      height: height,
      fit: BoxFit.contain, // 保持宽高比，等价于“以高度缩放”
      colorFilter: const ColorFilter.mode(Color(0xffffffff), BlendMode.srcIn),
    );
  }

  static void register() {
    AppRegistry().register(
      App(
        id: 'com.ms.phone',
        name: 'Phone',
        //themeColor: Colors.purple,
        icon: appIcon(32), // 应用列表图标
        page: const PhoneApp(),
        smallTile: PhoneLiveTile(
          size: LiveTileSize.small,
          icon: appIcon(36), // 小磁贴：画布 79.5px，占比约 45%
        ),
        mediumTile: PhoneLiveTile(
          size: LiveTileSize.medium,
          name: const Text('Phone'),
          icon: appIcon(72), // 中磁贴：画布 168px，占比约 43%
        ),
      ),
    );
  }

  @override
  State<PhoneApp> createState() => _PhoneAppState();
}

class _PhoneAppState extends State<PhoneApp> {
  final _scaffoldKey = GlobalKey<MetroPageScaffoldState>();
  final _slide = GlobalKey<UixPageSlideState>();
  final _searchSlide = GlobalKey<UixPageSlideState>();
  final _searchFocus = FocusNode();
  final _searchText = TextEditingController();
  var _searching = false;
  var _dialerOpen = false;
  late final _settings = widget.settingsModel ?? PhoneSettingsModel();
  var _nextRecordId = _sampleCallRecords.length;
  var _history = <int, CallRecord>{
    for (final (index, record) in _sampleCallRecords.indexed) index: record,
  };

  @override
  void dispose() {
    _searchText.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _openDialer() async {
    if (_dialerOpen) return;
    _dialerOpen = true;
    String? acceptedNumber;
    try {
      await metroPagePush(
        context,
        MetroPageRoute(
          builder: (_) => KeypadPage(
            branding: widget.branding,
            onDial: (number) {
              if (!_placeCall(number)) return false;
              acceptedNumber = number;
              return true;
            },
            formatNumber: widget.formatNumber,
            onSaveContact: widget.onSaveContact,
            onVoicemail: widget.onVoicemail,
          ),
        ),
        scaffoldKey: _scaffoldKey,
      );
    } finally {
      _dialerOpen = false;
    }
    if (mounted && acceptedNumber != null && widget.onPlaceCall == null) {
      await _showProgress(acceptedNumber!);
    }
  }

  Future<void> _showProgress(String number, {String? displayName}) {
    return PhoneCallProgress(
      number: widget.formatNumber?.call(number) ?? number,
      branding: widget.branding,
      displayName: displayName,
    ).show(context);
  }

  void _callBack(CallRecord record) {
    final number = record.callbackNumber;
    if (number != null && _placeCall(number) && widget.onPlaceCall == null) {
      _showProgress(number, displayName: record.contactName);
    }
  }

  void _openSettings() {
    metroPagePush(
      context,
      MetroPageRoute(builder: (_) => CallSettingsPage(model: _settings)),
      scaffoldKey: _scaffoldKey,
    );
  }

  bool _placeCall(String number) {
    final handler = widget.onPlaceCall;
    if (handler != null && !handler(number)) return false;
    final now = DateTime.now();
    final record = CallRecord(
      kind: CallKind.outgoing,
      number: number,
      timeLabel: '${now.month}/${now.day}/${now.year}',
    );
    setState(() => _history = {_nextRecordId++: record, ..._history});
    return true;
  }

  void _showSearch() {
    setState(() => _searching = true);
    _searchFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchSlide.currentState?.show();
    });
  }

  Future<void> _hideSearch() async {
    _searchFocus.unfocus();
    await _searchSlide.currentState?.hide();
    if (!mounted) return;
    _searchText.clear();
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) => MetroTheme(
    data: wp8PhoneTheme,
    child: Builder(builder: _buildPage),
  );

  Widget _buildPage(BuildContext context) {
    final palette = Wp8PhonePalette.of(context);
    final filter = _searchText.text.toLowerCase();
    final entries = _history.entries.where(
      (entry) =>
          !_searching || entry.value.number.toLowerCase().contains(filter),
    );
    final showSearchContacts = _searching && filter.isNotEmpty;
    final onSearchContacts = widget.onSearchContacts;
    final historyList = SingleChildScrollView(
      padding: EdgeInsets.only(top: _searching ? 4 * uixScale : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entries.isEmpty)
            Text(
              _searching ? 'No results' : 'To make a call, tap an icon below.',
            ),
          for (final entry in entries)
            CallHistoryTile(
              key: ValueKey(('phone-history', entry.key)),
              record: entry.value,
              highlightQuery: _searching ? _searchText.text : null,
              onCallBack: entry.value.callbackNumber == null
                  ? null
                  : () => _callBack(entry.value),
              onTap: widget.onOpenHistoryItem == null
                  ? null
                  : () => widget.onOpenHistoryItem!(entry.value),
              menu: MetroContextMenuItem(
                onTap: () => setState(() => _history.remove(entry.key)),
                child: const Text('delete item'),
              ),
            ),
          if (showSearchContacts)
            Padding(
              padding: const EdgeInsets.only(top: 26 * uixScale),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSearchContacts == null
                    ? null
                    : () => onSearchContacts(_searchText.text),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12 * uixScale),
                  child: Text(
                    'search contacts',
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: uixFontSize(25),
                      fontWeight: UixFontWeight.normal,
                      color: palette.textHigh,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return PhoneBackKey(
      child: MetroPageScaffold(
        key: _scaffoldKey,
        useMaterialSurface: false,
        extendBodyToApplicationBar: false,
        applicationBar: _searching
            ? null
            : MetroApplicationBar(
                theme: wp8PhoneTheme,
                buttons: [
                  _historyCommand('voicemail', widget.onVoicemail),
                  _historyCommand('keypad', _openDialer),
                  _historyCommand('people', widget.onOpenPeople),
                  _historyCommand('search', _showSearch),
                ],
                menuItems: [
                  MetroAppBarMenuItem(
                    label: 'delete all',
                    onPressed: _history.isEmpty
                        ? null
                        : () => _confirmDeleteAll(context),
                  ),
                  MetroAppBarMenuItem(
                    label: 'settings',
                    onPressed: widget.onOpenSettings ?? _openSettings,
                  ),
                ],
              ),
        disableDefaultPushNextAnimation: true,
        onDidPushNext: <T>(T _) async {
          if (_dialerOpen) {
            await _slide.currentState?.hide();
          } else {
            await _scaffoldKey.currentState?.playDefaultPushNextAnimation();
          }
        },
        disableDefaultPopNextAnimation: true,
        onDidPopNext: () {
          if (_dialerOpen) {
            _slide.currentState?.show();
          } else {
            _scaffoldKey.currentState?.playDefaultPopNextAnimation();
          }
        },
        onWillPop: !_searching
            ? null
            : () async {
                await _hideSearch();
                return false;
              },
        body: PopScope(
          canPop: !_searching,
          child: UixPageSlide(
            key: _slide,
            child: SafeArea(
              minimum: EdgeInsets.fromLTRB(
                24 * uixScale,
                (_searching ? 24 : 56) * uixScale,
                24 * uixScale,
                0,
              ),
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_searching)
                    UixPageSlide(
                      key: _searchSlide,
                      fromTop: true,
                      initiallyVisible: false,
                      child: MetroSearchBar(
                        controller: _searchText,
                        focusNode: _searchFocus,
                        backgroundImage: AssetImage(
                          '$wp8PhoneAssets/editbox_${palette.light ? 'light' : 'dark'}.png',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    )
                  else
                    MetroPageHeader(
                      title: Text(widget.branding),
                      titleStyle: TextStyle(color: palette.textHigh),
                      minimumPadding: EdgeInsets.zero,
                      // PhoneRes!MainPagePhone_titleText_Margins.
                      titleGap: 22 * uixScale,
                    ),
                  Expanded(
                    child: Pivot(
                      padding: EdgeInsets.zero,
                      interactive: false,
                      showHeader: !_searching,
                      items: [
                        PivotItem(
                          title: Text(
                            'history',
                            style: TextStyle(color: palette.textHigh),
                          ),
                          page: historyList,
                        ),
                      ],
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

  MetroAppBarButton _historyCommand(String label, VoidCallback? callback) {
    return MetroAppBarButton(
      label: label,
      icon: SvgPicture.asset(
        'images/icons/phone_appbar_$label.svg',
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
      onPressed: callback,
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final result = await const MetroMessageBox(
      title: 'Delete call history',
      message: 'Are you sure you want to delete the entire call history list?',
      confirmLabel: 'delete',
      cancelLabel: 'cancel',
    ).show(context);
    if (result == true && mounted) setState(_history.clear);
  }
}

/// ─── demo 数据：示例通话记录 ─────────────────────────
const List<CallRecord> _sampleCallRecords = [
  CallRecord(
    kind: CallKind.outgoing,
    number: 'Emergency call',
    canCallBack: false,
    timeLabel: '1/16/2015',
  ),
  CallRecord(
    kind: CallKind.missed,
    number: '13901234567',
    timeLabel: '1/16/2015',
  ),
  CallRecord(
    kind: CallKind.outgoing,
    number: '9981123456',
    timeLabel: '1/16/2015',
  ),
  CallRecord(kind: CallKind.outgoing, number: '95588', timeLabel: '1/15/2015'),
  CallRecord(kind: CallKind.incoming, number: '10086', timeLabel: '1/14/2015'),
  CallRecord(
    kind: CallKind.missed,
    number: '400-800-8888',
    timeLabel: '1/14/2015',
  ),
  CallRecord(
    kind: CallKind.outgoing,
    number: '1713704502848',
    timeLabel: '1/17/2015',
  ),
  CallRecord(
    kind: CallKind.incoming,
    number: '13901234567',
    timeLabel: '1/16/2015',
  ),
  CallRecord(
    kind: CallKind.outgoing,
    number: 'Emergency call',
    canCallBack: false,
    timeLabel: '1/16/2015',
  ),
  CallRecord(kind: CallKind.outgoing, number: '95588', timeLabel: '1/15/2015'),
  CallRecord(kind: CallKind.incoming, number: '10086', timeLabel: '1/14/2015'),
  CallRecord(
    kind: CallKind.missed,
    number: '400-800-8888',
    timeLabel: '1/14/2015',
  ),
];

enum CallKind { outgoing, incoming, missed }

class CallRecord {
  const CallRecord({
    required this.kind,
    required this.number,
    required this.timeLabel,
    this.canCallBack = true,
    this.contactName,
    this.methodLabel,
  });

  final CallKind kind;
  final String number;
  final String timeLabel;
  final bool canCallBack;
  final String? contactName;
  final String? methodLabel;

  String get header => contactName ?? number;
  String? get callbackNumber => canCallBack ? number : null;

  // PhoneRes string IDs 10070–10072 and 10124–10125 (en-US).
  String get subHeader {
    final direction = switch (kind) {
      CallKind.outgoing => 'Outgoing',
      CallKind.incoming => 'Incoming',
      CallKind.missed => 'Missed call',
    };
    final method = methodLabel;
    return method == null
        ? '$direction, $timeLabel'
        : '$direction, $method, $timeLabel';
  }
}

class CallHistoryTile extends StatelessWidget {
  const CallHistoryTile({
    super.key,
    required this.record,
    required this.menu,
    this.highlightQuery,
    this.onTap,
    this.onCallBack,
  });

  final CallRecord record;
  final MetroContextMenuItem menu;
  final String? highlightQuery;
  final VoidCallback? onTap;
  final VoidCallback? onCallBack;

  @override
  Widget build(BuildContext context) {
    final palette = Wp8PhonePalette.of(context);
    return MetroContextMenu(
      menu: menu,
      child: PushableDoubleLineListItem(
        header: record.header,
        enabled: record.canCallBack,
        highlightQuery: highlightQuery,
        highlightColor: palette.accent,
        subHeader: record.subHeader,
        headerColor: palette.textHigh,
        subHeaderColor: record.kind == CallKind.missed
            ? palette.accent
            : palette.textMid,
        onPressed: onTap,
        leading: Padding(
          // RealCallHistory_iconMargin is separate from the ImageButton padding.
          padding: const EdgeInsetsDirectional.only(end: uixScale),
          child: Opacity(
            opacity: record.canCallBack ? 1 : .5,
            child: _CallBackButton(light: palette.light, onTap: onCallBack),
          ),
        ),
      ),
    );
  }
}

class _CallBackButton extends StatefulWidget {
  const _CallBackButton({required this.light, this.onTap});

  final bool light;
  final VoidCallback? onTap;

  @override
  State<_CallBackButton> createState() => _CallBackButtonState();
}

class _CallBackButtonState extends State<_CallBackButton> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final callback = widget.onTap;
    final brightness = widget.light ? 'light' : 'dark';
    final state = _down && callback != null ? 'down' : 'rest';
    return Semantics(
      button: true,
      label: 'call back',
      enabled: callback != null,
      child: Tile(
        // RealCallHistoryItem's icon is a UIX ImageButton, with TiltBase.
        localTiltProjection: true,
        onTap: callback,
        onTouch: callback == null ? null : _setDown,
        child: Padding(
          // CallButtonStyle_ImageButtonPadding. The PNG fills only its own box.
          padding: const EdgeInsetsDirectional.only(
            top: 5 * uixScale,
            end: 18 * uixScale,
          ),
          child: Image.asset(
            '$wp8PhoneAssets/callback_${brightness}_$state.png',
            width: 43 * uixScale,
            height: 43 * uixScale,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
