// lib/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/profile_screen.dart';

enum NiceTab { home, calendar, notifications, profile }

/// Bottom tab bar shown on the four top-level screens.
///
/// Tabs switch with an instant, animation-free route swap (zero-duration
/// PageRouteBuilder) instead of the default sliding push transition —
/// that slide animation firing on every tap was what made switching tabs
/// feel like it was glitching/stuttering.
class BottomNavBar extends StatelessWidget {
  final NiceTab current;

  const BottomNavBar({super.key, required this.current});

  void _goTo(BuildContext context, NiceTab tab) {
    if (tab == current) return;
    late final Widget screen;
    switch (tab) {
      case NiceTab.home:
        screen = const HomeScreen();
        break;
      case NiceTab.calendar:
        screen = const CalendarScreen();
        break;
      case NiceTab.notifications:
        screen = const NotificationScreen();
        break;
      case NiceTab.profile:
        screen = const ProfileScreen();
        break;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.only(
          top: 12, bottom: MediaQuery.of(context).padding.bottom + 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            active: current == NiceTab.home,
            onTap: () => _goTo(context, NiceTab.home),
          ),
          _NavItem(
            icon: Icons.calendar_today_rounded,
            label: 'Calendar',
            active: current == NiceTab.calendar,
            onTap: () => _goTo(context, NiceTab.calendar),
          ),
          StreamBuilder<bool>(
            stream: ReminderService.hasUnread(),
            builder: (context, snapshot) {
              return _NavItem(
                icon: Icons.notifications_rounded,
                label: 'Alerts',
                active: current == NiceTab.notifications,
                showDot: snapshot.data == true,
                onTap: () => _goTo(context, NiceTab.notifications),
              );
            },
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            active: current == NiceTab.profile,
            onTap: () => _goTo(context, NiceTab.profile),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool showDot;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon,
                    size: 22,
                    color:
                        active ? AppColors.primary : AppColors.textFadedLight),
                if (showDot)
                  Positioned(
                    right: -3,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.unpaidRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? AppColors.primary : AppColors.textFadedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
