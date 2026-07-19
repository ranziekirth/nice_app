// lib/widgets/month_card.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A bill row for one month.
///
/// Gestures (mirrors the tenant card's swipe language):
///   swipe right  -> delete the month (asks to confirm first)
/// Marking as paid happens on the receipt screen (tap the card).
class MonthCard extends StatelessWidget {
  final String id;
  final String month;
  final int year;
  final bool isPaid;
  final VoidCallback onTap;

  /// Returns true if the month was actually deleted (card is then removed).
  final Future<bool> Function() onDelete;

  const MonthCard({
    super.key,
    required this.id,
    required this.month,
    required this.year,
    required this.isPaid,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isPaid ? AppColors.paidGreen : AppColors.unpaidRed;
    final statusBg = isPaid ? AppColors.paidSoft : AppColors.unpaidSoft;

    final card = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppStyle.cardGradient,
          borderRadius: BorderRadius.circular(AppStyle.radius),
          boxShadow: AppStyle.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(month,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor)),
                  const SizedBox(height: 2),
                  Text('$year', style: AppText.cardSubtitle),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPaid
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    size: 14,
                    color: statusColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isPaid ? 'Paid' : 'Unpaid',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Dismissible(
        key: ValueKey(id),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) => onDelete(), // true = remove the card
        // Swipe right reveals this: delete.
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.unpaidRed,
            borderRadius: BorderRadius.circular(AppStyle.radius),
          ),
          child:
              const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
        ),
        child: card,
      ),
    );
  }
}
