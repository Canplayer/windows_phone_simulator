# Windows Phone Simulator

基于 `metro_ui` 的 Windows Phone 界面模拟器。应用根节点使用 WP8.1 预设，电话应用使用局部 WP8 预设。开始屏、磁贴、应用列表和电话流程由这个仓库装配，可复用的控件和转场位于相邻 `Flutter-MetroUI` 仓库。

## 运行

将两个仓库放在同一父目录。`pubspec.yaml` 通过 `../Flutter-MetroUI` 引用本地组件库。使用组件库 `.fvmrc` 指定的 Flutter 版本。

```sh
flutter pub get
flutter test
flutter run
```

`lib/main.dart` 注册应用，`lib/app_registry.dart` 提供启动页的数据。`lib/launcher.dart` 和 `lib/start_menu.dart` 实现应用列表与磁贴。电话的页面、模型和配色位于 `lib/apps/phone/`，随应用打包的原版位图位于 `images/wp8_phone/`。默认通话为本地模拟，可通过 `PhoneApp` 的回调连接宿主行为。

维护时先读相邻组件库的 `TECHNICAL_SPEC.md`。该规范覆盖框架职责、控件参数、主题范围、文本边界，以及原版资源、单位和动画的验证方法。
