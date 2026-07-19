// lib/services/reminder_service.dart
import 'dart:async';

import '../data/app_data.dart';
import '../models/bill.dart';
import '../models/tenant.dart';
import 'firestore_service.dart';

/// Turns tenant/bill data into two kinds of app-generated reminders, and
/// merges them with whatever is actually stored in the `notifications`
/// collection:
///
///   - a monthly nudge to read the electric meter, from the 20th onward
///   - a per-bill nudge once a bill is past its due date
///     (bill date + [Bill.dueDays])
///
/// These are computed on the fly from live data rather than written to
/// Firestore, so they always reflect current state (e.g. a bill reminder
/// disappears the moment that bill is marked paid) without needing a
/// backend job to create/clean them up.
class ReminderService {
  ReminderService._();

  static const int meterReadingDay = 20;

  static List<AppNotification> buildReminders(
    List<Tenant> tenants,
    List<Bill> bills,
    DateTime now,
  ) {
    final reminders = <AppNotification>[];

    if (now.day >= meterReadingDay) {
      reminders.add(AppNotification(
        id: 'reminder-meter-${now.year}-${now.month}',
        title: 'Read the electric meter',
        subtitle:
            "It's the $meterReadingDay${_ordinalSuffix(meterReadingDay)} — time to record this "
            "month's electricity readings for every tenant.",
        date: DateTime(now.year, now.month, meterReadingDay),
        type: 'reminder',
      ));
    }

    final tenantsById = {for (final t in tenants) t.id: t};
    for (final bill in bills) {
      if (bill.isPaid) continue;
      if (!now.isAfter(bill.dueDate)) continue;

      final tenant = tenantsById[bill.tenantId];
      // Bill left behind by a deleted tenant — nothing to remind about.
      if (tenant == null) continue;
      final tenantLabel = '${tenant.name} (Room ${tenant.room})';
      reminders.add(AppNotification(
        id: 'reminder-unpaid-${bill.id}',
        title: 'Unpaid bill reminder',
        subtitle:
            "$tenantLabel still hasn't paid the ${bill.month} ${bill.year} bill — "
            "it was due ${formatDate(bill.dueDate)}.",
        date: bill.dueDate,
        type: 'unpaid',
      ));
    }

    return reminders;
  }

  static String _ordinalSuffix(int day) {
    if (day % 100 >= 11 && day % 100 <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  // A single shared broadcast stream so every screen/widget that wants the
  // combined list (or just whether anything is unread) subscribes to the
  // same underlying Firestore listeners instead of each opening its own.
  static final Stream<List<AppNotification>> _combined = _buildCombinedStream();

  // Plain broadcast streams don't replay their last value to a listener that
  // subscribes late — and the Home header/bottom nav bar always subscribe to
  // _combined first (as soon as the app opens), so by the time the
  // Notifications screen itself subscribes, the update has already been
  // missed and its StreamBuilder is left waiting forever. Caching the latest
  // value and replaying it to each new subscriber fixes that.
  static List<AppNotification>? _lastValue;

  static Stream<List<AppNotification>> combinedNotifications() async* {
    final cached = _lastValue;
    if (cached != null) yield cached;
    yield* _combined;
  }

  static Stream<bool> hasUnread() =>
      combinedNotifications().map((list) => list.any((n) => !n.read));

  static Stream<List<AppNotification>> _buildCombinedStream() {
    late final StreamController<List<AppNotification>> controller;
    List<Tenant>? tenants;
    List<Bill>? bills;
    List<AppNotification>? notifications;
    StreamSubscription<List<Tenant>>? tenantSub;
    StreamSubscription<List<Bill>>? billSub;
    StreamSubscription<List<AppNotification>>? notificationSub;

    void emit() {
      if (tenants == null || bills == null || notifications == null) return;
      final combined = [
        ...buildReminders(tenants!, bills!, DateTime.now()),
        ...notifications!,
      ]..sort((a, b) => b.date.compareTo(a.date));
      _lastValue = combined;
      controller.add(combined);
    }

    controller = StreamController<List<AppNotification>>.broadcast(
      onListen: () {
        tenantSub = FirestoreService.tenants().listen((v) {
          tenants = v;
          emit();
        });
        billSub = FirestoreService.allBills().listen((v) {
          bills = v;
          emit();
        });
        notificationSub = FirestoreService.notifications().listen((v) {
          notifications = v;
          emit();
        });
      },
      onCancel: () {
        tenantSub?.cancel();
        billSub?.cancel();
        notificationSub?.cancel();
      },
    );
    return controller.stream;
  }
}
