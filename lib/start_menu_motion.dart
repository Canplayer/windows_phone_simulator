import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/uix_metrics.dart';

import 'global_perspective.dart';

enum StartTileTransition {
  forwardIn(350, -130, 0, UixEaseIn(10, .5)),
  forwardOut(167, 0, 50, UixExp(100)),
  backwardIn(250, 80, 0, UixLog(10));

  const StartTileTransition(
    this.durationMs,
    this.startDegrees,
    this.endDegrees,
    this.curve,
  );

  final int durationMs;
  final double startDegrees, endDegrees;
  final Curve curve;

  static const clickedDelayMs = 350;
  static const centerPointX = -.3;

  // TileGridCellPositioner adds a column delay to the Y-based feathering.
  // The Flutter viewport supplies the bounds of the native area of interest.
  double delayFor({
    required int column,
    required int columns,
    required double topInViewport,
    required double viewportHeight,
    required bool clicked,
  }) {
    if (this == forwardOut && clicked) return clickedDelayMs.toDouble();
    final xDelay = math.max(0, columns - 1 - column) * 25;
    return xDelay +
        _featherDelay(topInViewport, viewportHeight, 25 / (99 * uixScale));
  }

  double delayForApp({
    required double topInViewport,
    required double viewportHeight,
    required bool clicked,
  }) {
    if (this == forwardOut && clicked) return clickedDelayMs.toDouble();
    return _featherDelay(topInViewport, viewportHeight, 20 / (62 * uixScale));
  }

  double _featherDelay(
    double topInViewport,
    double viewportHeight,
    double millisecondsPerPixel,
  ) {
    final origin = viewportHeight - (2 * 99 - 12) * uixScale;
    return ((origin - topInViewport) * millisecondsPerPixel).clamp(
      0.0,
      viewportHeight * millisecondsPerPixel,
    );
  }

  double rotationAt(double milliseconds) {
    final t = (milliseconds / durationMs).clamp(0.0, 1.0);
    final degrees =
        startDegrees + (endDegrees - startDegrees) * curve.transform(t);
    return degrees * math.pi / 180;
  }

  double opacityAt(double milliseconds) => switch (this) {
    forwardIn => (milliseconds / 10).clamp(0.0, 1.0),
    backwardIn => ((milliseconds - 10) / 10).clamp(0.0, 1.0),
    forwardOut => (167 - milliseconds).clamp(0.0, 1.0),
  };
}

/// Shared opacity and scene rotation for the GridAdapter and ApplicationsPage.
class StartTransitionTransform extends StatelessWidget {
  const StartTransitionTransform({
    super.key,
    required this.clock,
    required this.transition,
    required this.delay,
    required this.child,
    this.origin = Offset.zero,
  });

  final AnimationController clock;
  final StartTileTransition transition;
  final double delay;
  final Offset origin;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: clock,
    builder: (context, child) {
      final elapsed = clock.value * clock.duration!.inMicroseconds / 1000;
      final localTime = elapsed - delay;
      final opacity = transition.opacityAt(localTime);
      return IgnorePointer(
        ignoring: clock.isAnimating || opacity == 0,
        child: Opacity(
          opacity: opacity,
          child: GlobalPerspective(
            enabled: opacity < 1,
            child: Transform(
              origin: origin,
              transform: Matrix4.rotationY(transition.rotationAt(localTime)),
              child: child,
            ),
          ),
        ),
      );
    },
    child: child,
  );
}
