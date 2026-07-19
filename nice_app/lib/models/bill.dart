// lib/models/bill.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// An extra billable line item beyond the default Electricity/Water/Wifi,
/// e.g. "Rent".
class BillCategory {
  final String name;
  final double amount;

  const BillCategory({required this.name, required this.amount});

  factory BillCategory.fromMap(Map<String, dynamic> map) => BillCategory(
        name: map['name'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {'name': name, 'amount': amount};
}

/// A single month's bill for one tenant.
///
/// Electricity is derived from a meter reading difference, not entered
/// directly:
///   kWh used = currentElectricity - previousElectricity
///   Electricity total = kWh used x rate-per-kWh
///
/// The rate-per-kWh is a landlord-wide setting (edited from Profile),
/// not stored per bill, so it's passed in when totals are computed.
class Bill {
  final String id;
  final String tenantId;
  final String month; // e.g. "June"
  final int year;
  final DateTime date;
  final double previousElectricity;
  final double currentElectricity;
  final double waterAmount;
  final double wifiAmount;
  final List<BillCategory> extraCategories;
  final bool isPaid;

  const Bill({
    required this.id,
    required this.tenantId,
    required this.month,
    required this.year,
    required this.date,
    required this.previousElectricity,
    required this.currentElectricity,
    required this.waterAmount,
    required this.wifiAmount,
    this.extraCategories = const [],
    this.isPaid = false,
  });

  /// Every bill is due this many days after it's created. This is the one
  /// source of truth for the payment window — the Home due-date card and the
  /// unpaid reminder both derive from it.
  static const int dueDays = 10;

  DateTime get dueDate => date.add(const Duration(days: dueDays));

  double get kwhUsed => currentElectricity - previousElectricity;

  double electricityTotal(double ratePerKwh) => kwhUsed * ratePerKwh;

  double grandTotal(double ratePerKwh) {
    double total = electricityTotal(ratePerKwh) + waterAmount + wifiAmount;
    for (final category in extraCategories) {
      total += category.amount;
    }
    return total;
  }

  factory Bill.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Bill(
      id: doc.id,
      tenantId: data['tenantId'] as String? ?? '',
      month: data['month'] as String? ?? '',
      year: data['year'] as int? ?? DateTime.now().year,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      previousElectricity:
          (data['previousElectricity'] as num?)?.toDouble() ?? 0,
      currentElectricity: (data['currentElectricity'] as num?)?.toDouble() ?? 0,
      waterAmount: (data['waterAmount'] as num?)?.toDouble() ?? 0,
      wifiAmount: (data['wifiAmount'] as num?)?.toDouble() ?? 0,
      extraCategories: ((data['extraCategories'] as List<dynamic>?) ?? [])
          .map((c) => BillCategory.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList(),
      isPaid: data['isPaid'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'tenantId': tenantId,
        'month': month,
        'year': year,
        'date': Timestamp.fromDate(date),
        'previousElectricity': previousElectricity,
        'currentElectricity': currentElectricity,
        'waterAmount': waterAmount,
        'wifiAmount': wifiAmount,
        'extraCategories': extraCategories.map((c) => c.toMap()).toList(),
        'isPaid': isPaid,
      };
}

class CalendarNote {
  final String id;
  final DateTime date;
  final String text;

  const CalendarNote({this.id = '', required this.date, required this.text});

  factory CalendarNote.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CalendarNote(
      id: doc.id,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      text: data['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'text': text,
      };
}

class AppNotification {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final bool read;

  /// '' (default/unset), 'unpaid', or 'reminder' — picks the icon/color the
  /// notification tile renders with. Falls back to a title-text guess when
  /// unset, so older Firestore docs written before this field existed still
  /// render correctly.
  final String type;

  const AppNotification({
    this.id = '',
    required this.title,
    required this.subtitle,
    required this.date,
    this.read = false,
    this.type = '',
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] as bool? ?? false,
      type: data['type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'date': Timestamp.fromDate(date),
        'read': read,
        'type': type,
      };
}
