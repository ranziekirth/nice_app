// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tenant.dart';
import '../models/bill.dart';
import '../models/feedback_entry.dart';

/// Talks to Firestore. Screens listen to these streams instead of
/// reading a static in-memory list, so changes sync live across devices.
///
/// Everything lives under `users/{uid}/...` so each signed-in account only
/// ever sees its own data:
///   users/{uid}/tenants        { name, room }
///   users/{uid}/bills          { tenantId, month, year, date, previousElectricity,
///                                currentElectricity, waterAmount, wifiAmount,
///                                extraCategories, isPaid }
///   users/{uid}/notes          { date, text }
///   users/{uid}/notifications  { title, subtitle, date, read }
///   users/{uid}/settings/main  { kwhRate, landlordName, propertyAddress }
class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// The signed-in user's uid. Every method below requires a signed-in
  /// user — the app only reaches these screens once auth is established.
  static String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('FirestoreService used with no signed-in user.');
    }
    return uid;
  }

  static DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(_uid);

  // ----- Tenants -----

  static Stream<List<Tenant>> tenants() {
    return _userDoc.collection('tenants').orderBy('room').snapshots().map(
          (snap) => snap.docs.map(Tenant.fromDoc).toList(),
        );
  }

  static Future<void> addTenant(Tenant tenant) {
    return _userDoc.collection('tenants').add(tenant.toMap());
  }

  /// Removes the tenant along with every bill that belongs to them, so
  /// dashboard totals and reminders don't keep counting orphaned bills.
  static Future<void> deleteTenant(String tenantId) async {
    final bills = await _userDoc
        .collection('bills')
        .where('tenantId', isEqualTo: tenantId)
        .get();
    final batch = _db.batch();
    for (final doc in bills.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_userDoc.collection('tenants').doc(tenantId));
    await batch.commit();
  }

  static Future<void> updateTenant(String tenantId,
      {required String name, required String room}) {
    return _userDoc
        .collection('tenants')
        .doc(tenantId)
        .update({'name': name, 'room': room});
  }

  // ----- Bills -----

  static Stream<List<Bill>> billsForTenant(String tenantId) {
    return _userDoc
        .collection('bills')
        .where('tenantId', isEqualTo: tenantId)
        .snapshots()
        .map((snap) {
      final bills = snap.docs.map(Bill.fromDoc).toList();
      bills.sort((a, b) => b.date.compareTo(a.date));
      return bills;
    });
  }

  static Future<void> addBill(Bill bill) {
    return _userDoc.collection('bills').add(bill.toMap());
  }

  /// All bills across every tenant — used to work out reminders (e.g.
  /// unpaid-after-10-days) without needing a per-tenant subscription.
  static Stream<List<Bill>> allBills() {
    return _userDoc.collection('bills').snapshots().map(
          (snap) => snap.docs.map(Bill.fromDoc).toList(),
        );
  }

  static Future<void> deleteBill(String billId) {
    return _userDoc.collection('bills').doc(billId).delete();
  }

  /// Not wired to any button yet — there's no "mark as paid" action in
  /// the UI today — but it's here for when you add one.
  static Future<void> setBillPaid(String billId, bool isPaid) {
    return _userDoc.collection('bills').doc(billId).update({'isPaid': isPaid});
  }

  // ----- Notes -----

  static Stream<List<CalendarNote>> notes() {
    return _userDoc.collection('notes').snapshots().map(
          (snap) => snap.docs.map(CalendarNote.fromDoc).toList(),
        );
  }

  static Future<void> addNote(CalendarNote note) {
    return _userDoc.collection('notes').add(note.toMap());
  }

  // ----- Notifications -----

  /// Writes an activity entry (e.g. "bill added", "tenant added") into the
  /// notifications collection so it shows up in Home's Recent activity feed
  /// and on the Notifications screen. Stored as already-read so it never
  /// lights up the unread bell dot.
  static Future<void> logActivity({
    required String title,
    required String subtitle,
    required String type,
  }) {
    return _userDoc.collection('notifications').add(AppNotification(
          title: title,
          subtitle: subtitle,
          date: DateTime.now(),
          read: true,
          type: type,
        ).toMap());
  }

  static Stream<List<AppNotification>> notifications() {
    return _userDoc.collection('notifications').snapshots().map((snap) {
      final list = snap.docs.map(AppNotification.fromDoc).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  // ----- Feedback -----

  /// Saves the signed-in user's app review. Lives in a TOP-LEVEL `feedback`
  /// collection — not under users/{uid} — so the admin account can read
  /// everyone's reviews (see firestore.rules).
  static Future<void> submitFeedback({
    required int rating,
    required String message,
    required String name,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    return _db.collection('feedback').add(FeedbackEntry(
          uid: _uid,
          name: name,
          email: user?.email ?? '',
          rating: rating,
          message: message,
          date: DateTime.now(),
        ).toMap());
  }

  /// Every user's review, newest first. Only the admin account can actually
  /// read this — Firestore rules reject the query for anyone else.
  static Stream<List<FeedbackEntry>> allFeedback() {
    return _db.collection('feedback').snapshots().map((snap) {
      final list = snap.docs.map(FeedbackEntry.fromDoc).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  // ----- Settings -----

  static DocumentReference<Map<String, dynamic>> get settingsDoc =>
      _userDoc.collection('settings').doc('main');

  static Future<void> updateLandlordName(String name) {
    return settingsDoc.set({'landlordName': name}, SetOptions(merge: true));
  }

  static Future<void> updatePropertyAddress(String address) {
    return settingsDoc
        .set({'propertyAddress': address}, SetOptions(merge: true));
  }

  static Future<void> updateKwhRate(double rate) {
    return settingsDoc.set({'kwhRate': rate}, SetOptions(merge: true));
  }
}
