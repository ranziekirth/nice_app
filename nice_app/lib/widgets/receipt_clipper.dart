// lib/widgets/receipt_clipper.dart
import 'package:flutter/material.dart';

/// Clips the bottom edge of a container into a zigzag, giving the
/// receipt card a torn-paper look.
class ReceiptClipper extends CustomClipper<Path> {
  final double toothWidth;
  final double toothHeight;

  const ReceiptClipper({this.toothWidth = 20, this.toothHeight = 10});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - toothHeight);

    final toothCount = (size.width / toothWidth).ceil();
    for (int i = 0; i < toothCount; i++) {
      final x1 = (i + 0.5) * toothWidth;
      final x2 = (i + 1) * toothWidth;
      path.lineTo(x1.clamp(0, size.width), size.height);
      path.lineTo(x2.clamp(0, size.width), size.height - toothHeight);
    }

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
