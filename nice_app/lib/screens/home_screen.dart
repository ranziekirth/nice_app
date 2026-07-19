// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/bill.dart';
import '../models/tenant.dart';
import '../services/firestore_service.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/screen_background.dart';
import 'tenant_detail_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // When there are more than this many tenants, the list collapses behind a
  // "View all" toggle so the dashboard cards above stay in reach.
  static const int _collapsedTenantCount = 3;
  bool _showAllTenants = false;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _openTenant(Tenant tenant) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TenantDetailScreen(tenant: tenant)),
    );
  }

  Future<void> _showAddTenantDialog() async {
    final nameController = TextEditingController();
    final roomController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        bool saving = false;
        String? error;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              if (nameController.text.trim().isEmpty ||
                  roomController.text.trim().isEmpty) {
                return;
              }
              setDialogState(() {
                saving = true;
                error = null;
              });
              final name = nameController.text.trim();
              final room = roomController.text.trim();
              try {
                await FirestoreService.addTenant(Tenant(
                  id: '',
                  name: name,
                  room: room,
                ));
                FirestoreService.logActivity(
                  title: 'Tenant $name added to Room $room',
                  subtitle: 'New tenant moved in.',
                  type: 'tenant-added',
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (_) {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    saving = false;
                    error = "Couldn't save. Check your connection and try again.";
                  });
                }
              }
            }

            return PopScope(
              canPop: !saving,
              child: AlertDialog(
                backgroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                title: const Text('Add Tenant', style: AppText.sectionTitle),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !saving,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: roomController,
                      enabled: !saving,
                      decoration: const InputDecoration(labelText: 'Room No.'),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!,
                          style: const TextStyle(
                              color: AppColors.unpaidRed, fontSize: 13)),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed:
                        saving ? null : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.black54)),
                  ),
                  ElevatedButton(
                    onPressed: saving ? null : submit,
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Add'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditTenantDialog(Tenant tenant) async {
    final nameController = TextEditingController(text: tenant.name);
    final roomController = TextEditingController(text: tenant.room);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;
        String? error;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              if (nameController.text.trim().isEmpty ||
                  roomController.text.trim().isEmpty) {
                return;
              }
              setDialogState(() {
                saving = true;
                error = null;
              });
              try {
                await FirestoreService.updateTenant(
                  tenant.id,
                  name: nameController.text.trim(),
                  room: roomController.text.trim(),
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (_) {
                if (dialogContext.mounted) {
                  setDialogState(() {
                    saving = false;
                    error = "Couldn't save. Check your connection and try again.";
                  });
                }
              }
            }

            return PopScope(
              canPop: !saving,
              child: AlertDialog(
                backgroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                title: const Text('Edit Tenant', style: AppText.sectionTitle),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !saving,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: roomController,
                      enabled: !saving,
                      decoration: const InputDecoration(labelText: 'Room No.'),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!,
                          style: const TextStyle(
                              color: AppColors.unpaidRed, fontSize: 13)),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed:
                        saving ? null : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.black54)),
                  ),
                  ElevatedButton(
                    onPressed: saving ? null : submit,
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDeleteTenant(Tenant tenant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Tenant', style: AppText.sectionTitle),
        content: Text(
          'Remove ${tenant.name} (Room ${tenant.room})? This cannot be undone.',
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
      await FirestoreService.deleteTenant(tenant.id);
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
                title: AppData.landlordName,
                titlePrefix: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting,
                        style: AppText.headerSubtitle
                            .copyWith(color: AppColors.textFaded)),
                    const SizedBox(height: 2),
                    Text(AppData.landlordName, style: AppText.headerTitle),
                  ],
                ),
                trailing: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen()),
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_rounded,
                            size: 20, color: AppColors.primary),
                      ),
                      Positioned(
                        right: -1,
                        top: -1,
                        child: StreamBuilder<bool>(
                          stream: ReminderService.hasUnread(),
                          builder: (context, snapshot) {
                            if (snapshot.data != true) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.unpaidRed,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.background, width: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Tenant>>(
                  stream: FirestoreService.tenants(),
                  builder: (context, tenantSnapshot) {
                    if (tenantSnapshot.hasError) {
                      return Center(
                        child: Text('Couldn\'t load tenants.',
                            style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.5))),
                      );
                    }
                    return StreamBuilder<List<Bill>>(
                      stream: FirestoreService.allBills(),
                      builder: (context, billSnapshot) {
                        if (!tenantSnapshot.hasData || !billSnapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary));
                        }
                        return _buildDashboard(
                            tenantSnapshot.data!, billSnapshot.data ?? []);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(current: NiceTab.home),
    );
  }

  Widget _buildDashboard(List<Tenant> tenants, List<Bill> bills) {
    final now = DateTime.now();
    final monthName = AppData.monthNames[now.month - 1];
    final monthBills = bills
        .where((b) => b.month == monthName && b.year == now.year)
        .toList();

    double uncollected = 0;
    double collected = 0;
    final unpaidTenantIds = <String>{};
    for (final bill in monthBills) {
      final total = bill.grandTotal(AppData.kwhRate);
      if (bill.isPaid) {
        collected += total;
      } else {
        uncollected += total;
        unpaidTenantIds.add(bill.tenantId);
      }
    }

    // The due-date card shows the single most urgent deadline: the earliest
    // due date across every unpaid bill (any month, not just the current one,
    // so an old overdue bill can't hide behind a newer one).
    Bill? nextDueBill;
    for (final bill in bills) {
      if (bill.isPaid) continue;
      if (nextDueBill == null || bill.dueDate.isBefore(nextDueBill.dueDate)) {
        nextDueBill = bill;
      }
    }

    var dueLabel = 'Due date';
    var dueValue = 'No dues';
    Color? dueColor;
    if (nextDueBill != null) {
      final tenantName = {
        for (final t in tenants) t.id: t.name
      }[nextDueBill.tenantId];
      if (tenantName != null && tenantName.isNotEmpty) {
        dueLabel = 'Due date · $tenantName';
      }
      final today = DateTime(now.year, now.month, now.day);
      final due = nextDueBill.dueDate;
      final daysLeft =
          DateTime(due.year, due.month, due.day).difference(today).inDays;
      if (daysLeft > 1) {
        dueValue = 'In $daysLeft days';
      } else if (daysLeft == 1) {
        dueValue = 'Tomorrow';
      } else if (daysLeft == 0) {
        dueValue = 'Today';
        dueColor = AppColors.primary;
      } else {
        dueValue = '${-daysLeft} ${daysLeft == -1 ? 'day' : 'days'} late';
        dueColor = AppColors.unpaidRed;
      }
    }

    final collapsed =
        !_showAllTenants && tenants.length > _collapsedTenantCount;
    final visibleTenants =
        collapsed ? tenants.sublist(0, _collapsedTenantCount) : tenants;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        _SummaryCard(
          uncollected: uncollected,
          unpaidCount: unpaidTenantIds.length,
          tenantCount: tenants.length,
          monthLabel: '$monthName ${now.year}',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                label: 'Collected · ${monthName.substring(0, 3)}',
                value: formatCurrency(collected),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStatCard(
                label: dueLabel,
                value: dueValue,
                valueColor: dueColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tenants', style: AppText.sectionTitle),
            if (tenants.length > _collapsedTenantCount)
              GestureDetector(
                onTap: () =>
                    setState(() => _showAllTenants = !_showAllTenants),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  _showAllTenants ? 'Show less' : 'View all',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                ),
              ),
          ],
        ),
        if (tenants.isNotEmpty) ...[
          const SizedBox(height: 6),
          const Text('Swipe a tenant right to edit, left to delete.',
              style: AppText.cardSubtitle),
        ],
        const SizedBox(height: 14),
        if (tenants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.people_alt_rounded,
                      size: 34, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text('No tenants yet', style: AppText.cardTitle),
                const SizedBox(height: 4),
                const Text(
                  'Tap Add Tenant to create the first one.',
                  textAlign: TextAlign.center,
                  style: AppText.cardSubtitle,
                ),
              ],
            ),
          ),
        for (final tenant in visibleTenants)
          _TenantRow(
            tenant: tenant,
            status: _TenantMonthStatus.compute(tenant, monthBills),
            onView: () => _openTenant(tenant),
            onEdit: () => _showEditTenantDialog(tenant),
            onDeleteConfirm: () => _confirmDeleteTenant(tenant),
          ),
        const SizedBox(height: 8),
        Center(
          child: ElevatedButton(
            onPressed: _showAddTenantDialog,
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Add Tenant +'),
          ),
        ),
        const SizedBox(height: 26),
        const Text('Recent activity', style: AppText.sectionTitle),
        const SizedBox(height: 12),
        const _RecentActivity(),
      ],
    );
  }
}

/// The big accent card at the top of the dashboard: how much is still
/// uncollected for the current month, and how many tenants that covers.
class _SummaryCard extends StatelessWidget {
  final double uncollected;
  final int unpaidCount;
  final int tenantCount;
  final String monthLabel;

  const _SummaryCard({
    required this.uncollected,
    required this.unpaidCount,
    required this.tenantCount,
    required this.monthLabel,
  });

  String get _statusLine {
    if (tenantCount == 0) return 'No tenants yet · $monthLabel';
    if (unpaidCount == 0) return 'All tenants paid · $monthLabel';
    final word = tenantCount == 1 ? 'tenant' : 'tenants';
    return '$unpaidCount of $tenantCount $word unpaid · $monthLabel';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppStyle.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppStyle.accentShadow(AppColors.primaryDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uncollected this month',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(uncollected),
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _statusLine,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the two small white stat cards under the summary card.
class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;

  /// Overrides the value's text color, e.g. red when a bill is overdue.
  final Color? valueColor;

  const _MiniStatCard(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppStyle.cardGradient,
        borderRadius: BorderRadius.circular(AppStyle.radius),
        boxShadow: AppStyle.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColors.textFaded)),
          const SizedBox(height: 6),
          Text(value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.textColor)),
        ],
      ),
    );
  }
}

/// A tenant's payment standing for the current month, driving the row
/// subtitle and the Paid/Unpaid chip.
class _TenantMonthStatus {
  final String detail; // shown after "Room X · "
  final String chipLabel;
  final Color chipBackground;
  final Color chipForeground;

  const _TenantMonthStatus._({
    required this.detail,
    required this.chipLabel,
    required this.chipBackground,
    required this.chipForeground,
  });

  /// [monthBills] must already be filtered to the current month/year.
  factory _TenantMonthStatus.compute(Tenant tenant, List<Bill> monthBills) {
    double due = 0;
    Bill? paidBill;
    for (final bill in monthBills) {
      if (bill.tenantId != tenant.id) continue;
      if (bill.isPaid) {
        paidBill = bill;
      } else {
        due += bill.grandTotal(AppData.kwhRate);
      }
    }

    if (due > 0) {
      return _TenantMonthStatus._(
        detail: '${formatCurrency(due)} due',
        chipLabel: 'Unpaid',
        chipBackground: AppColors.unpaidSoft,
        chipForeground: AppColors.unpaidRed,
      );
    }
    if (paidBill != null) {
      final shortMonth =
          AppData.monthNames[paidBill.date.month - 1].substring(0, 3);
      return _TenantMonthStatus._(
        detail: 'Paid $shortMonth ${paidBill.date.day}',
        chipLabel: 'Paid',
        chipBackground: AppColors.paidSoft,
        chipForeground: AppColors.paidGreen,
      );
    }
    return _TenantMonthStatus._(
      detail: 'No bill yet',
      chipLabel: 'No bill',
      chipBackground: AppColors.border,
      chipForeground: AppColors.textFaded,
    );
  }
}

class _TenantRow extends StatelessWidget {
  final Tenant tenant;
  final _TenantMonthStatus status;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final Future<bool> Function() onDeleteConfirm;

  const _TenantRow({
    required this.tenant,
    required this.status,
    required this.onView,
    required this.onEdit,
    required this.onDeleteConfirm,
  });

  // Soft background/foreground pairs cycled per tenant so avatars vary the
  // way they do in the mock-up instead of all reading terracotta.
  static const List<List<Color>> _avatarTones = [
    [Color(0xFFFBE7D8), Color(0xFFB85E31)], // terracotta
    [Color(0xFFE1F1E8), Color(0xFF2F9E68)], // green
    [Color(0xFFE3EDF9), Color(0xFF3E6FA8)], // blue
    [Color(0xFFF2E7F6), Color(0xFF8B5AA0)], // purple
  ];

  List<Color> get _tone {
    var sum = 0;
    for (final unit in tenant.name.codeUnits) {
      sum += unit;
    }
    return _avatarTones[sum % _avatarTones.length];
  }

  @override
  Widget build(BuildContext context) {
    final tone = _tone;

    final card = GestureDetector(
      onTap: onView,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          gradient: AppStyle.cardGradient,
          borderRadius: BorderRadius.circular(AppStyle.radius),
          boxShadow: AppStyle.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: tone[0],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: tone[1]),
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.name,
                    style: AppText.cardTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Room ${tenant.room} · ${status.detail}',
                    style: AppText.cardSubtitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: status.chipBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.chipLabel,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: status.chipForeground),
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(tenant.id),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onEdit();
            return false; // just opens the edit dialog, card snaps back
          }
          return await onDeleteConfirm(); // true = actually remove the card
        },
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppStyle.radius),
          ),
          child: const Icon(Icons.edit_rounded,
              color: AppColors.primary, size: 26),
        ),
        secondaryBackground: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.centerRight,
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

/// The latest few entries from the combined notification/reminder stream,
/// rendered as a compact feed. Tapping a row opens the Notifications screen.
class _RecentActivity extends StatelessWidget {
  static const int _maxEntries = 3;

  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: ReminderService.combinedNotifications(),
      builder: (context, snapshot) {
        final entries =
            (snapshot.data ?? []).take(_maxEntries).toList();
        if (entries.isEmpty) {
          return Text('No activity yet.',
              style: TextStyle(
                  fontSize: 13, color: Colors.black.withValues(alpha: 0.4)));
        }
        return Column(
          children: [
            for (final entry in entries) _ActivityTile(entry: entry),
          ],
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final AppNotification entry;

  const _ActivityTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    switch (entry.type) {
      case 'bill-added':
        icon = Icons.receipt_long_rounded;
        color = AppColors.primary;
      case 'tenant-added':
        icon = Icons.person_add_alt_1_rounded;
        color = AppColors.paidGreen;
      case 'unpaid':
        icon = Icons.error_outline_rounded;
        color = AppColors.unpaidRed;
      case 'reminder':
        icon = Icons.bolt_rounded;
        color = AppColors.primary;
      default:
        icon = Icons.check_circle_outline_rounded;
        color = AppColors.paidGreen;
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppStyle.cardGradient,
          borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
          boxShadow: AppStyle.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black45),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
