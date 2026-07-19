// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/bill.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/screen_background.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppHeader(title: 'Notifications'),
              Expanded(
                child: StreamBuilder<List<AppNotification>>(
                  stream: ReminderService.combinedNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Couldn\'t load notifications.',
                            style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.45))),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary));
                    }
                    final notifications = snapshot.data!;
                    if (notifications.isEmpty) {
                      return Center(
                        child: Text('No notifications yet.',
                            style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.45))),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      children: [
                        for (final notification in notifications)
                          _NotificationTile(notification: notification),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(current: NiceTab.notifications),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isUnpaidAlert = notification.type == 'unpaid' ||
        (notification.type.isEmpty &&
            notification.title.toLowerCase().contains('unpaid'));
    final isReminder = notification.type == 'reminder';

    final IconData icon;
    final Color color;
    if (isUnpaidAlert) {
      icon = Icons.error_outline_rounded;
      color = AppColors.unpaidRed;
    } else if (isReminder) {
      icon = Icons.bolt_rounded;
      color = AppColors.primary;
    } else if (notification.type == 'bill-added') {
      icon = Icons.receipt_long_rounded;
      color = AppColors.primary;
    } else if (notification.type == 'tenant-added') {
      icon = Icons.person_add_alt_1_rounded;
      color = AppColors.paidGreen;
    } else {
      icon = Icons.check_circle_outline_rounded;
      color = AppColors.paidGreen;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child:
                            Text(notification.title, style: AppText.cardTitle)),
                    if (!notification.read)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8, top: 4),
                        decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notification.subtitle, style: AppText.cardSubtitle),
                const SizedBox(height: 6),
                Text(formatDate(notification.date),
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
