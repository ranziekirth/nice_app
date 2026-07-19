// lib/widgets/screen_background.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wraps a screen's body with the skyline artwork (assets/images/background.png)
/// sitting faintly behind the content, on top of the normal warm off-white
/// background color.
///
/// Adjust [watermarkOpacity] below to taste — it's the one knob that
/// controls how strong the watermark reads on every screen that uses it.
class ScreenBackground extends StatelessWidget {
  // 0.0 = invisible, 1.0 = full strength. Tweak this to your preference.
  static const double watermarkOpacity = 0.2;

  final Widget child;

  /// Per-screen override for how strong the watermark reads. Defaults to
  /// [watermarkOpacity] when omitted.
  final double? opacity;

  const ScreenBackground({super.key, required this.child, this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity ?? watermarkOpacity,
                child: Image.asset(
                  'assets/images/background.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
