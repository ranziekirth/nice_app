// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/bill.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/screen_background.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  static const List<String> _weekdayLabels = [
    'S',
    'M',
    'T',
    'W',
    'T',
    'F',
    'S'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  List<CalendarNote> _notesForDate(List<CalendarNote> notes, DateTime date) {
    return notes
        .where((n) =>
            n.date.year == date.year &&
            n.date.month == date.month &&
            n.date.day == date.day)
        .toList();
  }

  Future<void> _showAddNoteDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;
        String? error;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              if (controller.text.trim().isEmpty) return;
              setDialogState(() {
                saving = true;
                error = null;
              });
              try {
                await FirestoreService.addNote(CalendarNote(
                    date: _selectedDate, text: controller.text.trim()));
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
                title: Text('Note for ${formatDate(_selectedDate)}',
                    style: AppText.sectionTitle),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      enabled: !saving,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(hintText: 'Write a note...'),
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

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday %
            7; // Sun = 0

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppHeader(title: 'Calendar'),
              Expanded(
                child: StreamBuilder<List<CalendarNote>>(
                  stream: FirestoreService.notes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Couldn\'t load notes.',
                            style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.5))),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary));
                    }
                    final notes = snapshot.data!;
                    final notesForSelected =
                        _notesForDate(notes, _selectedDate);

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: () => _changeMonth(-1),
                                    icon:
                                        const Icon(Icons.chevron_left_rounded),
                                  ),
                                  Text(
                                    '${AppData.monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                                    style: AppText.cardTitle,
                                  ),
                                  IconButton(
                                    onPressed: () => _changeMonth(1),
                                    icon:
                                        const Icon(Icons.chevron_right_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (final label in _weekdayLabels)
                                    Expanded(
                                      child: Center(
                                        child: Text(label,
                                            style: const TextStyle(
                                                color: Colors.black45,
                                                fontSize: 12)),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7),
                                itemCount: daysInMonth + firstWeekday,
                                itemBuilder: (context, index) {
                                  if (index < firstWeekday) {
                                    return const SizedBox.shrink();
                                  }
                                  final day = index - firstWeekday + 1;
                                  final date = DateTime(_focusedMonth.year,
                                      _focusedMonth.month, day);
                                  final isSelected =
                                      date.year == _selectedDate.year &&
                                          date.month == _selectedDate.month &&
                                          date.day == _selectedDate.day;
                                  final hasNote =
                                      _notesForDate(notes, date).isNotEmpty;

                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedDate = date),
                                    child: Container(
                                      margin: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$day',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          if (hasNote)
                                            Container(
                                              width: 4,
                                              height: 4,
                                              margin:
                                                  const EdgeInsets.only(top: 2),
                                              decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Notes · ${formatDate(_selectedDate)}',
                                style: AppText.cardTitle),
                            GestureDetector(
                              onTap: _showAddNoteDialog,
                              child: const Icon(Icons.add_circle_rounded,
                                  color: AppColors.primary, size: 26),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (notesForSelected.isEmpty)
                          Text('No notes for this day.',
                              style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.45)))
                        else
                          for (final note in notesForSelected)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(note.text,
                                  style: AppText.cardSubtitle
                                      .copyWith(color: Colors.black87)),
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
      bottomNavigationBar: const BottomNavBar(current: NiceTab.calendar),
    );
  }
}
