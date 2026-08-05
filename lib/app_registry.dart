import 'package:windows_phone_simulator/start_menu.dart';

/// 应用注册中心 —— 全局单例
///
/// 任何页面只要在自己文件里调用 [AppRegistry().register(...)]，
/// 即可将自身注册到开始菜单的应用列表中，无需修改 [LauncherPage]。
class AppRegistry {
  // ─── 单例 ─────────────────────────────────────────────────
  AppRegistry._();
  static final AppRegistry _instance = AppRegistry._();
  factory AppRegistry() => _instance;

  final List<App> _apps = [];

  /// 所有已注册的应用（不可变快照）
  List<App> get apps => List.unmodifiable(_apps);

  /// 注册一个应用
  ///
  /// 如果 [app.id] 已存在则跳过，避免重复注册。
  void register(App app) {
    if (_apps.any((a) => a.id == app.id)) {
      // 已注册，跳过
      return;
    }
    _apps.add(app);
  }

  /// 按 id 移除注册
  void unregister(String id) {
    _apps.removeWhere((a) => a.id == id);
  }

  /// 清空所有注册
  void clear() {
    _apps.clear();
  }
}
