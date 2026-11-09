import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// 앱 아이콘과 같은 로고 타일 (assets/brand/tile.png)
class LogoTile extends StatelessWidget {
  const LogoTile({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/tile.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: '스냅칼 로고',
    );
  }
}

/// 로고 + "스냅칼" 글자
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 32, this.color, this.subtitle});
  final double size;
  final Color? color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.text1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoTile(size: size),
        SizedBox(width: size * 0.32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '스냅칼',
              style: TextStyle(
                fontSize: size * 0.62,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
                color: c,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: AppText.caption.copyWith(color: c.withAlpha(150)),
              ),
          ],
        ),
      ],
    );
  }
}

/// 로고의 뷰파인더 모서리. 촬영 화면 프레임 등에 쓴다.
class ViewfinderFrame extends StatelessWidget {
  const ViewfinderFrame({
    super.key,
    required this.child,
    this.strokeWidth = 5,
    this.cornerLength = 36,
    this.radius = 14,
  });

  final Widget child;
  final double strokeWidth;
  final double cornerLength;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _CornerPainter(strokeWidth, cornerLength, radius),
      child: child,
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(this.w, this.l, this.r);
  final double w;
  final double l;
  final double r;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = AppBrand.neonGradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    final a = w / 2;
    final bx = size.width - w / 2;
    final by = size.height - w / 2;

    Path corner(Offset start, Offset ctrl, Offset end) => Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(
        ctrl.dx + (start.dx - ctrl.dx).sign * r,
        ctrl.dy + (start.dy - ctrl.dy).sign * r,
      )
      ..quadraticBezierTo(
        ctrl.dx,
        ctrl.dy,
        ctrl.dx + (end.dx - ctrl.dx).sign * r,
        ctrl.dy + (end.dy - ctrl.dy).sign * r,
      )
      ..lineTo(end.dx, end.dy);

    canvas
      ..drawPath(
        corner(Offset(a, a + l), Offset(a, a), Offset(a + l, a)),
        paint,
      )
      ..drawPath(
        corner(Offset(bx - l, a), Offset(bx, a), Offset(bx, a + l)),
        paint,
      )
      ..drawPath(
        corner(Offset(a, by - l), Offset(a, by), Offset(a + l, by)),
        paint,
      )
      ..drawPath(
        corner(Offset(bx - l, by), Offset(bx, by), Offset(bx, by - l)),
        paint,
      );
  }

  @override
  bool shouldRepaint(_CornerPainter old) =>
      old.w != w || old.l != l || old.r != r;
}
