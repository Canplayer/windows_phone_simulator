import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 具有全局 3D 摄像机视角的透明度组件。
/// 无论嵌套多深、滚动到哪里，其内部 3D 变换的消失点永远锁定在屏幕正中心。
/// 妥协的产物,这个玩意儿本不应该诞生,但是flutter本身存在一些限制,导致我不得不写这个组件来实现我想要的效果。
/// 这是个性能消耗有点不好看的组件,请谨慎使用。
class GlobalPerspectiveOpacity extends SingleChildRenderObjectWidget {
  final double opacity;
  final double perspectiveDepth; // 透视深度（Z轴缩放系数）

  const GlobalPerspectiveOpacity({
    super.key,
    required this.opacity,
    this.perspectiveDepth = 0.000795,
    required super.child,
  });

  @override
  RenderGlobalPerspectiveOpacity createRenderObject(BuildContext context) {
    return RenderGlobalPerspectiveOpacity(
      opacity: opacity,
      perspectiveDepth: perspectiveDepth,
      screenSize: MediaQuery.of(context).size,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderGlobalPerspectiveOpacity renderObject) {
    renderObject
      ..opacity = opacity
      ..perspectiveDepth = perspectiveDepth
      ..screenSize = MediaQuery.of(context).size;
  }
}

class RenderGlobalPerspectiveOpacity extends RenderProxyBox {
  double _opacity;
  double _perspectiveDepth;
  Size _screenSize;

  RenderGlobalPerspectiveOpacity({
    required double opacity,
    required double perspectiveDepth,
    required Size screenSize,
    RenderBox? child,
  })  : _opacity = opacity,
        _perspectiveDepth = perspectiveDepth,
        _screenSize = screenSize,
        super(child);

  set opacity(double value) {
    if (_opacity == value) return;
    _opacity = value;
    markNeedsPaint();
  }

  set perspectiveDepth(double value) {
    if (_perspectiveDepth == value) return;
    _perspectiveDepth = value;
    markNeedsPaint();
  }

  set screenSize(Size value) {
    if (_screenSize == value) return;
    _screenSize = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null && (_opacity > 0.0 && _opacity < 1.0);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || _opacity == 0.0) {
      return;
    }

    // 1. 获取屏幕中心物理坐标
    final Offset globalScreenCenter = Offset(_screenSize.width / 2, _screenSize.height / 2);

    // 2. 转换为组件的局部坐标系
    final Offset localScreenCenter = globalToLocal(globalScreenCenter);

    // 🌟 3. 核心修正：计算出动态的 FractionalOffset (相对偏移比例)
    // 假设组件宽 100，屏幕中心点在组件内部的 X 是 50，那 offset 就是 0.5
    // 假设屏幕中心点在组件外部左侧的 X 是 -100，那 offset 就是 -1.0
    final double dxFraction = size.width == 0 ? 0.5 : localScreenCenter.dx / size.width;
    final double dyFraction = size.height == 0 ? 0.5 : localScreenCenter.dy / size.height;

    // 4. 计算为了对齐这个点，矩阵需要做的绝对位移
    // 这等同于 Transform(alignment: FractionalOffset(dx, dy)) 的底层数学逻辑
    final double originX = dxFraction * size.width;
    final double originY = dyFraction * size.height;

    // 5. 构建完美的 3D 透视矩阵
    // 数学原理：先把画布推向对齐点 (origin)，应用透视，再把画布拉回来
    Matrix4 perspectiveMatrix = Matrix4.identity()
  ..translate(originX, originY)
  ..multiply(
    Matrix4.identity()
      ..setEntry(3, 2, _perspectiveDepth)
  )
  ..translate(-originX, -originY);

    if (_opacity == 1.0) {
      context.pushTransform(needsCompositing, offset, perspectiveMatrix, super.paint);
    } else {
      // 半透明状态下，先离屏画出带 3D 透视的内容，再整图应用透明度
      context.pushOpacity(offset, (_opacity * 255).round(), (ctx, off) {
        ctx.pushTransform(needsCompositing, off, perspectiveMatrix, super.paint);
      });
    }
  }
}