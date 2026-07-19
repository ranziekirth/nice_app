// lib/screens/tenant_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../models/tenant.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/month_card.dart';
import '../widgets/screen_background.dart';
import 'add_bill_screen.dart';
import 'receipt_screen.dart';

class TenantDetailScreen extends StatelessWidget {
  final Tenant tenant;

  const TenantDetailScreen({super.key, required this.tenant});

  Future<bool> _confirmDeleteBill(BuildContext context, Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Month', style: AppText.sectionTitle),
        content: Text(
          'Delete ${bill.month} ${bill.year}? This removes the bill and its receipt for good.',
          style: AppText.cardSubtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.unpaidRed),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirestoreService.deleteBill(bill.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${bill.month} ${bill.year} deleted.')),
        );
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppHeader(
                title: tenant.name,
                subtitle: tenant.room,
                showBack: true,
                centered: true,
              ),
              Expanded(
                child: StreamBuilder<List<Bill>>(
                  stream: FirestoreService.billsForTenant(tenant.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Couldn\'t load bills.',
                            style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.5))),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary));
                    }
                    final bills = snapshot.data!;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Months', style: AppText.sectionTitle),
                            if (bills.isNotEmpty)
                              Text('${bills.length}',
                                  style: AppText.sectionTitle
                                      .copyWith(color: Colors.black45)),
                          ],
                        ),
                        if (bills.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          const Text(
                            'Tap a month to view its receipt. Swipe right to delete.',
                            style: AppText.cardSubtitle,
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (bills.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded,
                                      size: 34, color: AppColors.primary),
                                ),
                                const SizedBox(height: 16),
                                const Text('No bills yet',
                                    style: AppText.cardTitle),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tap Add to create the first one.',
                                  textAlign: TextAlign.center,
                                  style: AppText.cardSubtitle,
                                ),
                              ],
                            ),
                          ),
                        for (final bill in bills)
                          MonthCard(
                            id: bill.id,
                            month: bill.month,
                            year: bill.year,
                            isPaid: bill.isPaid,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReceiptScreen(tenant: tenant, bill: bill),
                              ),
                            ),
                            onDelete: () => _confirmDeleteBill(context, bill),
                          ),
                        const SizedBox(height: 8),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddBillScreen(tenant: tenant),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 48, vertical: 16),
                            ),
                            child: const Text('Add'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
