// lib/widgets/app_header.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The header shown at the top of every screen.
///
/// Two layouts:
/// - centered: back button pinned left, title/subtitle centered (used on
///   detail-style screens like Tenant Detail and Receipt).
/// - leading: title left-aligned, optional trailing icon on the right
///   (used on Home, Calendar, Notifications, Profile).
///
/// Design: flat and blends into the scaffold background instead of a
/// bold color block, separated from the content below by a soft shadow.
/// The accent color is reserved for small circular icon chips (back
/// button, trailing action) so it reads as a highlight, not a heavy
/// block of color.
class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final bool centered;
  final Widget? trailing;
  final Widget? titlePrefix;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.centered = false,
    this.trailing,
    this.titlePrefix,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primarySoft.withValues(alpha: 0.7),
            AppColors.background
          ],
        ),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          // Soft glow blobs — a little warmth behind the title instead of a
          // flat panel. Purely decorative, so they sit under the content and
          // never intercept taps.
          Positioned(
            right: -34,
            top: -48,
            child: IgnorePointer(
                child:
                    _glowBlob(120, AppColors.primary.withValues(alpha: 0.18))),
          ),
          Positioned(
            left: -46,
            bottom: -58,
            child: IgnorePointer(
                child: _glowBlob(
                    110, AppColors.primaryDark.withValues(alpha: 0.09))),
          ),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 18, 20, 20),
              child:
                  centered ? _buildCentered(context) : _buildLeading(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }

  Widget _buildCentered(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBack)
            Positioned(
              left: 0,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.primary, size: 17),
                ),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.headerTitle,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    style: AppText.headerSubtitle
                        .copyWith(color: AppColors.textFaded)),
              ],
            ],
          ),
          if (trailing != null) Positioned(right: 0, child: trailing!),
        ],
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titlePrefix ?? Text(title, style: AppText.headerTitle),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    style: AppText.headerSubtitle
                        .copyWith(color: AppColors.textFaded)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
