// lib/data/app_data.dart
import 'dart:async';
import '../services/firestore_service.dart';

class AppData {
  AppData._();

  static const List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // Sample/default values a brand-new account starts with, until the
  // landlord edits them from Profile / Property details.
  static const String defaultLandlordName = 'User';
  static const String defaultPropertyAddress = 'Add your property address';
  static const double defaultKwhRate = 34;

  static String landlordName = defaultLandlordName;
  static String propertyAddress = defaultPropertyAddress;
  static double kwhRate = defaultKwhRate;

  static StreamSubscription<dynamic>? _settingsSub;

  /// Loads the signed-in user's settings and keeps them updated live.
  /// Call this once right after auth resolves to a signed-in user.
  static Future<void> init() async {
    final doc = FirestoreService.settingsDoc;
    final snap = await doc.get();
    if (!snap.exists) {
      // Brand-new account: seed it with the defaults so Billing Settings
      // and Property details aren't blank on first run.
      await doc.set({
        'landlordName': defaultLandlordName,
        'propertyAddress': defaultPropertyAddress,
        'kwhRate': defaultKwhRate,
      });
      _applySettings({
        'landlordName': defaultLandlordName,
        'propertyAddress': defaultPropertyAddress,
        'kwhRate': defaultKwhRate,
      });
    } else {
      _applySettings(snap.data());
    }

    await _settingsSub?.cancel();
    _settingsSub =
        doc.snapshots().listen((snap) => _applySettings(snap.data()));
  }

  /// Clears cached settings back to defaults on sign-out, so the next
  /// account that signs in on this device doesn't briefly see stale values
  /// from the previous one.
  static Future<void> reset() async {
    await _settingsSub?.cancel();
    _settingsSub = null;
    landlordName = defaultLandlordName;
    propertyAddress = defaultPropertyAddress;
    kwhRate = defaultKwhRate;
  }

  static void _applySettings(Map<String, dynamic>? data) {
    if (data == null) return;
    final rate = data['kwhRate'];
    if (rate != null) kwhRate = (rate as num).toDouble();

    final name = data['landlordName'] as String?;
    if (name != null && name.isNotEmpty) landlordName = name;

    final address = data['propertyAddress'] as String?;
    if (address != null && address.isNotEmpty) propertyAddress = address;
  }

  static Future<void> updateKwhRate(double rate) async {
    kwhRate = rate;
    await FirestoreService.updateKwhRate(rate);
  }

  static Future<void> updateLandlordName(String name) async {
    landlordName = name;
    await FirestoreService.updateLandlordName(name);
  }

  static Future<void> updatePropertyAddress(String address) async {
    propertyAddress = address;
    await FirestoreService.updatePropertyAddress(address);
  }
}

String formatCurrency(double amount) {
  final rounded = amount.toStringAsFixed(2);
  final parts = rounded.split('.');
  final wholePart = parts[0];
  final buffer = StringBuffer();
  for (int i = 0; i < wholePart.length; i++) {
    if (i != 0 && (wholePart.length - i) % 3 == 0) buffer.write(',');
    buffer.write(wholePart[i]);
  }
  return '₱${buffer.toString()}.${parts[1]}';
}

String formatDate(DateTime date) {
  return '${AppData.monthNames[date.month - 1]} ${date.day}, ${date.year}';
}
