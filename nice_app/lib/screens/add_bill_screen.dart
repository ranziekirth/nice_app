// lib/screens/add_bill_screen.dart
import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/bill.dart';
import '../models/tenant.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class _CategoryRow {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
}

class AddBillScreen extends StatefulWidget {
  final Tenant tenant;

  const AddBillScreen({super.key, required this.tenant});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  static const TextStyle _fieldLabel = TextStyle(
      fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black54);

  String? _selectedMonth;
  final _previousController = TextEditingController();
  final _currentController = TextEditingController();
  final _waterController = TextEditingController();
  final _wifiController = TextEditingController();
  final List<_CategoryRow> _categories = [];
  String? _errorText;
  bool _saving = false;

  // Used to auto-fill "Previous" from the tenant's prior month's bill, when
  // that prior bill is for the calendar month immediately before the one
  // selected (e.g. May -> June, but not May -> July).
  List<Bill> _existingBills = [];
  String? _autoFilledFrom;

  double get _previous => double.tryParse(_previousController.text) ?? 0;
  double get _current => double.tryParse(_currentController.text) ?? 0;
  double get _kwhUsed {
    final diff = _current - _previous;
    return diff > 0 ? diff : 0;
  }

  double get _electricityTotal => _kwhUsed * AppData.kwhRate;

  @override
  void initState() {
    super.initState();
    FirestoreService.billsForTenant(widget.tenant.id).first.then((bills) {
      if (!mounted) return;
      setState(() => _existingBills = bills);
      if (_selectedMonth != null) _onMonthChanged(_selectedMonth);
    });
  }

  @override
  void dispose() {
    _previousController.dispose();
    _currentController.dispose();
    _waterController.dispose();
    _wifiController.dispose();
    for (final row in _categories) {
      row.nameController.dispose();
      row.amountController.dispose();
    }
    super.dispose();
  }

  void _addCategoryRow() {
    setState(() => _categories.add(_CategoryRow()));
  }

  void _removeCategoryRow(int index) {
    setState(() {
      _categories[index].nameController.dispose();
      _categories[index].amountController.dispose();
      _categories.removeAt(index);
    });
  }

  void _onMonthChanged(String? month) {
    setState(() {
      _selectedMonth = month;
      _errorText = null;

      final previousBill = _findPreviousConsecutiveBill(month);
      if (previousBill != null) {
        final reading = previousBill.currentElectricity;
        _previousController.text = reading == reading.roundToDouble()
            ? reading.toStringAsFixed(0)
            : reading.toString();
        _autoFilledFrom = '${previousBill.month} ${previousBill.year}';
      } else {
        _previousController.clear();
        _autoFilledFrom = null;
      }
    });
  }

  /// Finds the tenant's bill for the calendar month right before [month]
  /// (e.g. June's previous month is May). Returns null if that bill doesn't
  /// exist — including when a month was skipped (May -> July isn't
  /// consecutive) — so the reading is left for manual entry.
  Bill? _findPreviousConsecutiveBill(String? month) {
    if (month == null) return null;
    final monthIndex = AppData.monthNames.indexOf(month);
    if (monthIndex == -1) return null;

    final now = DateTime.now();
    var previousMonthIndex = monthIndex - 1;
    var previousYear = now.year;
    if (previousMonthIndex < 0) {
      previousMonthIndex = 11;
      previousYear -= 1;
    }
    final previousMonthName = AppData.monthNames[previousMonthIndex];

    for (final bill in _existingBills) {
      if (bill.month == previousMonthName && bill.year == previousYear) {
        return bill;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (_selectedMonth == null) {
      setState(() => _errorText = 'Please select a month.');
      return;
    }
    if (_previousController.text.trim().isEmpty ||
        _currentController.text.trim().isEmpty) {
      setState(() => _errorText = 'Please enter both electricity readings.');
      return;
    }
    if (_current < _previous) {
      setState(() =>
          _errorText = 'Current reading should not be lower than previous.');
      return;
    }

    final extraCategories = <BillCategory>[];
    for (final row in _categories) {
      final name = row.nameController.text.trim();
      final amount = double.tryParse(row.amountController.text) ?? 0;
      if (name.isNotEmpty) {
        extraCategories.add(BillCategory(name: name, amount: amount));
      }
    }

    setState(() => _saving = true);

    final now = DateTime.now();
    final bill = Bill(
      id: '',
      tenantId: widget.tenant.id,
      month: _selectedMonth!,
      year: now.year,
      date: now,
      previousElectricity: _previous,
      currentElectricity: _current,
      waterAmount: double.tryParse(_waterController.text) ?? 0,
      wifiAmount: double.tryParse(_wifiController.text) ?? 0,
      extraCategories: extraCategories,
      isPaid: false,
    );
    try {
      await FirestoreService.addBill(bill);
      FirestoreService.logActivity(
        title: '${bill.month} bill added for ${widget.tenant.name}',
        subtitle:
            '${formatCurrency(bill.grandTotal(AppData.kwhRate))} · Room ${widget.tenant.room}',
        type: 'bill-added',
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorText =
              'Couldn\'t save the bill. Check your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              title: 'Add Bill',
              subtitle: '${widget.tenant.name} · Room ${widget.tenant.room}',
              showBack: true,
              centered: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  _SectionCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'Billing Month',
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedMonth,
                        decoration:
                            const InputDecoration(hintText: 'Choose a month'),
                        items: AppData.monthNames
                            .map((m) =>
                                DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: _onMonthChanged,
                      ),
                    ],
                  ),
                  _SectionCard(
                    icon: Icons.bolt_rounded,
                    title: 'Electricity',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Previous', style: _fieldLabel),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _previousController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                      hintText: 'e.g. 3290'),
                                  onChanged: (_) => setState(() {}),
                                ),
                                if (_autoFilledFrom != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome_rounded,
                                          size: 12, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'From $_autoFilledFrom',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.primary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Current', style: _fieldLabel),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _currentController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                      hintText: 'e.g. 3309'),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_currentController.text.isNotEmpty &&
                          _previousController.text.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_kwhUsed.toStringAsFixed(0)} kWh × ${formatCurrency(AppData.kwhRate)}',
                                style: AppText.cardSubtitle,
                              ),
                              Text(formatCurrency(_electricityTotal),
                                  style: AppText.amount),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  _SectionCard(
                    icon: Icons.payments_rounded,
                    title: 'Other Charges',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Water', style: _fieldLabel),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _waterController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration:
                                      const InputDecoration(hintText: 'Amount'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Wifi', style: _fieldLabel),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _wifiController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration:
                                      const InputDecoration(hintText: 'Amount'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      for (int i = 0; i < _categories.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _categories[i].nameController,
                                  decoration: const InputDecoration(
                                      hintText: 'Category (e.g. Rent)'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _categories[i].amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration:
                                      const InputDecoration(hintText: 'Amount'),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeCategoryRow(i),
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.black45),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _addCategoryRow,
                        icon: const Icon(Icons.add_rounded,
                            color: AppColors.primary, size: 18),
                        label: const Text('Add category',
                            style: TextStyle(color: AppColors.primary)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  if (_errorText != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.unpaidSoft,
                        borderRadius:
                            BorderRadius.circular(AppStyle.radiusSmall),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.unpaidRed, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorText!,
                              style: const TextStyle(
                                  color: AppColors.unpaidRed,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit'),
                    ),
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

/// A white rounded card with a small icon chip + title, used to group each
/// part of the form so the page reads as sections instead of a long flat
/// stack of fields.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard(
      {required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppStyle.cardGradient,
        borderRadius: BorderRadius.circular(AppStyle.radius),
        boxShadow: AppStyle.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppText.cardTitle),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
