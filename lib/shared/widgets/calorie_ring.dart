import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/tokens.dart';

final _num = NumberFormat.decimalPattern('ko');

/// 남은 칼로리 원형 게이지. 값이 바뀌면 부드럽게 채워진다.
class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.eaten,
    required this.goal,
    this.size = 208,
  });

  final int eaten;
  final int goal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final over = eaten > goal;
    final remaining = (goal - eaten).abs();
    final target = goal > 0 ? eaten / goal : 0.0;

    return Semantics(
      label: over ? '목표보다 $remaining 킬로칼로리 초과' : '$remaining 킬로칼로리 남음',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: AppMotion.ring,
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              track: p.surfaceAlt,
              colors: over ? [p.over, p.over] : [AppBrand.orangeLight, p.brand],
              stroke: size * 0.085,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _num.format(remaining),
                    style: AppText.display.copyWith(
                      fontSize: size * 0.21,
                      color: over ? p.over : p.text1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    over ? 'kcal 초과' : 'kcal 남음',
                    style: AppText.label.copyWith(
                      color: over ? p.over : p.text2,
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
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.colors,
    required this.stroke,
  });

  final double progress;
  final Color track;
  final List<Color> colors;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    canvas.drawArc(
      arc,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    final sweep = math.pi * 2 * progress.clamp(0.0, 1.0);
    if (sweep <= 0) return;
    canvas.drawArc(
      arc,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          colors: colors,
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
    // 둥근 시작 끝이 그라데이션 마지막 색을 집어오지 않도록 시작 색으로 덮는다
    canvas.drawCircle(
      Offset(arc.center.dx, arc.top),
      stroke / 2,
      Paint()..color = colors.first,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.colors != colors ||
      old.stroke != stroke;
}

String formatKcal(int v) => _num.format(v);
