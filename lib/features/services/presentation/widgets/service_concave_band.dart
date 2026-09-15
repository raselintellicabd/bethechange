import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Single navy band: concave (scooped) top edge + plain rectangular body.
///
/// Replaces the old wave painter + square stack that looked like two pieces
/// (white convex lens over a flat navy block).
class ServiceConcaveBand extends StatelessWidget {
  const ServiceConcaveBand({
    super.key,
    required this.child,
    this.color = AppColors.brandNavy,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 28),
    this.curveHeight = 36,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double curveHeight;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _ConcaveTopClipper(curveHeight: curveHeight),
      child: ColoredBox(
        color: color,
        child: Padding(
          padding: EdgeInsets.only(top: curveHeight * 0.55).add(padding),
          child: child,
        ),
      ),
    );
  }
}

class _ConcaveTopClipper extends CustomClipper<Path> {
  const _ConcaveTopClipper({required this.curveHeight});

  final double curveHeight;

  @override
  Path getClip(Size size) {
    final dip = curveHeight.clamp(12.0, size.height);
    final sideY = dip * 0.22;
    return Path()
      ..moveTo(0, sideY)
      ..quadraticBezierTo(size.width * 0.5, dip, size.width, sideY)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _ConcaveTopClipper oldClipper) {
    return oldClipper.curveHeight != curveHeight;
  }
}
