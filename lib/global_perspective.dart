import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 具有全局 3D 摄像机视角的透明度组件。
/// 无论嵌套多深、滚动到哪里，其内部 3D 变换的消失点永远锁定在屏幕正中心。
///
/// ⚠️ 注意：
/// 这是 Flutter 3D 体系限制下的 Hack 方案。
/// 会引入额外 transform 开销，请谨慎使用。
class GlobalPerspective extends SingleChildRenderObjectWidget {
  /// 是否启用透视修正
  final bool enabled;

  /// 透视深度（Z轴缩放系数）
  final double perspectiveDepth;

  const GlobalPerspective({
    super.key,
    this.enabled = true,
    this.perspectiveDepth = 0.000795,
    required super.child,
  });

  @override
  RenderGlobalPerspective createRenderObject(BuildContext context) {
    return RenderGlobalPerspective(
      enabled: enabled,
      perspectiveDepth: perspectiveDepth,
      screenSize: MediaQuery.of(context).size,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGlobalPerspective renderObject,
  ) {
    renderObject
      ..enabled = enabled
      ..perspectiveDepth = perspectiveDepth
      ..screenSize = MediaQuery.of(context).size;
  }
}

class RenderGlobalPerspective extends RenderProxyBox {
  bool _enabled;
  double _perspectiveDepth;
  Size _screenSize;

  RenderGlobalPerspective({
    required bool enabled,
    required double perspectiveDepth,
    required Size screenSize,
    RenderBox? child,
  })  : _enabled = enabled,
        _perspectiveDepth = perspectiveDepth,
        _screenSize = screenSize,
        super(child);

  // =========================
  // Enabled
  // =========================

  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;

    // 只需要重绘，不需要重建 RenderObject
    markNeedsPaint();
  }

  // =========================
  // Perspective
  // =========================

  set perspectiveDepth(double value) {
    if (_perspectiveDepth == value) return;
    _perspectiveDepth = value;
    markNeedsPaint();
  }

  // =========================
  // Screen Size
  // =========================

  set screenSize(Size value) {
    if (_screenSize == value) return;
    _screenSize = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // 直接透传，不注入 transform
    if (!_enabled) {
      super.paint(context, offset);
      return;
    }

    // 1. 获取屏幕中心物理坐标
    final Offset globalScreenCenter =
        Offset(_screenSize.width / 2, _screenSize.height / 2);

    // 2. 转换为组件局部坐标
    final Offset localScreenCenter = globalToLocal(globalScreenCenter);

    // 3. 计算相对偏移
    final double dxFraction =
        size.width == 0 ? 0.5 : localScreenCenter.dx / size.width;

    final double dyFraction =
        size.height == 0 ? 0.5 : localScreenCenter.dy / size.height;

    // 4. 计算 transform origin
    final double originX = dxFraction * size.width;
    final double originY = dyFraction * size.height;

    // 5. 构建透视矩阵
    final Matrix4 perspectiveMatrix = Matrix4.identity()
      ..translateByDouble(originX, originY, 0.0, 1.0)
      ..multiply(
        Matrix4.identity()..setEntry(3, 2, _perspectiveDepth),
      )
      ..translateByDouble(-originX, -originY, 0.0, 1.0);

    // 6. 推入变换
    context.pushTransform(
      needsCompositing,
      offset,
      perspectiveMatrix,
      super.paint,
    );
  }
}