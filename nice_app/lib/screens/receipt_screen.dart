// lib/screens/receipt_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../data/app_data.dart';
import '../models/bill.dart';
import '../models/tenant.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/receipt_clipper.dart';

class ReceiptScreen extends StatefulWidget {
  final Tenant tenant;
  final Bill bill;

  const ReceiptScreen({super.key, required this.tenant, required this.bill});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  late bool _isPaid = widget.bill.isPaid;
  bool _markingPaid = false;

  Tenant get _tenant => widget.tenant;
  Bill get _bill => widget.bill;

  Future<void> _shareReceipt() async {
    final rate = AppData.kwhRate;
    final lines = StringBuffer()
      ..writeln('Receipt — ${_bill.month} ${_bill.year}')
      ..writeln('Address: ${AppData.propertyAddress}')
      ..writeln('Date: ${formatDate(_bill.date)}')
      ..writeln('Name: ${_tenant.name}')
      ..writeln('Room: ${_tenant.room}')
      ..writeln('')
      ..writeln(
          'Electricity (${_bill.kwhUsed.toStringAsFixed(0)} kWh × ${formatCurrency(rate)}): ${formatCurrency(_bill.electricityTotal(rate))}')
      ..writeln('Water: ${formatCurrency(_bill.waterAmount)}')
      ..writeln('Wifi: ${formatCurrency(_bill.wifiAmount)}');
    for (final category in _bill.extraCategories) {
      lines.writeln('${category.name}: ${formatCurrency(category.amount)}');
    }
    lines
      ..writeln('')
      ..writeln('Total: ${formatCurrency(_bill.grandTotal(rate))}')
      ..writeln('Status: ${_isPaid ? 'Paid' : 'Unpaid'}');

    await SharePlus.instance.share(ShareParams(
      text: lines.toString(),
      subject: 'Receipt — ${_tenant.name} · ${_bill.month} ${_bill.year}',
    ));
  }

  Future<void> _markAsPaid() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Mark as Paid', style: AppText.sectionTitle),
        content: Text(
          'Mark ${_bill.month} ${_bill.year} as paid? Total is ${formatCurrency(_bill.grandTotal(AppData.kwhRate))}.',
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
                ElevatedButton.styleFrom(backgroundColor: AppColors.paidGreen),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _markingPaid = true);
    try {
      await FirestoreService.setBillPaid(_bill.id, true);
      FirestoreService.logActivity(
        title: '${_bill.month} bill paid by ${_tenant.name}',
        subtitle:
            '${formatCurrency(_bill.grandTotal(AppData.kwhRate))} · Room ${_tenant.room}',
        type: 'bill-paid',
      );
      if (mounted) {
        setState(() {
          _isPaid = true;
          _markingPaid = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_bill.month} marked as paid.')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _markingPaid = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Couldn\'t mark as paid. Check your connection and try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rate = AppData.kwhRate;
    final electricityTotal = _bill.electricityTotal(rate);
    final grandTotal = _bill.grandTotal(rate);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              title: _tenant.name,
              subtitle: _tenant.room,
              showBack: true,
              centered: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Receipt', style: AppText.sectionTitle),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isPaid
                              ? AppColors.paidGreen.withValues(alpha: 0.12)
                              : AppColors.unpaidRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isPaid ? 'Paid' : 'Unpaid',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _isPaid
                                ? AppColors.paidGreen
                                : AppColors.unpaidRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipPath(
                    clipper: const ReceiptClipper(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Address: ${AppData.propertyAddress}',
                              textAlign: TextAlign.center,
                              style: AppText.cardSubtitle,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _InfoRow(
                              label: 'Date:', value: formatDate(_bill.date)),
                          const SizedBox(height: 10),
                          _InfoRow(label: 'Name:', value: _tenant.name),
                          const SizedBox(height: 10),
                          _InfoRow(label: 'Room:', value: _tenant.room),
                          const SizedBox(height: 18),
                          const Divider(height: 1, color: Color(0xFFEFEFEF)),
                          const SizedBox(height: 18),
                          _BillLineRow(
                            label: 'Electricity',
                            detail:
                                '${_bill.kwhUsed.toStringAsFixed(0)} kWh × ${formatCurrency(rate)}',
                            amount: electricityTotal,
                          ),
                          const SizedBox(height: 14),
                          _BillLineRow(
                              label: 'Water', amount: _bill.waterAmount),
                          const SizedBox(height: 14),
                          _BillLineRow(label: 'Wifi', amount: _bill.wifiAmount),
                          for (final category in _bill.extraCategories) ...[
                            const SizedBox(height: 14),
                            _BillLineRow(
                                label: category.name, amount: category.amount),
                          ],
                          const SizedBox(height: 18),
                          const Divider(height: 1, color: Color(0xFFEFEFEF)),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                formatCurrency(grandTotal),
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _shareReceipt,
                          icon: const Icon(Icons.share_rounded,
                              color: AppColors.primary, size: 18),
                          label: const Text('Share',
                              style: TextStyle(color: AppColors.primary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (!_isPaid) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _markingPaid ? null : _markAsPaid,
                            icon: _markingPaid
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_circle_rounded,
                                    size: 18),
                            label: const Text('Mark as Paid'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.paidGreen,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label, style: AppText.cardSubtitle)),
        Text(value, style: AppText.cardTitle),
      ],
    );
  }
}

class _BillLineRow extends StatelessWidget {
  final String label;
  final String? detail;
  final double amount;

  const _BillLineRow({required this.label, this.detail, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.cardTitle),
            if (detail != null) Text(detail!, style: AppText.cardSubtitle),
          ],
        ),
        Text(formatCurrency(amount), style: AppText.amount),
      ],
    );
  }
}
