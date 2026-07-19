// lib/widgets/feedback_sheet.dart
import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

/// Opens the "rate the app" bottom sheet: 5 tappable stars plus a comment
/// box, like a Play Store review. Shows a snackbar when it's sent.
Future<void> showFeedbackSheet(BuildContext context) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FeedbackSheet(),
  );
  if (sent == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks for your feedback!')),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  bool _sending = false;

  static const List<String> _ratingLabels = [
    'Very dissatisfied',
    'Dissatisfied',
    'It\'s okay',
    'Satisfied',
    'Very satisfied',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0 || _sending) return;

    setState(() => _sending = true);
    try {
      await FirestoreService.submitFeedback(
        rating: _rating,
        message: _commentController.text.trim(),
        name: AppData.landlordName,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Couldn\'t send feedback. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lifts the sheet above the keyboard while the comment box is focused.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppStyle.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppStyle.accentShadow(AppColors.primary),
                ),
                child: const Icon(Icons.rate_review_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 14),
              const Text('Enjoying Nice?', style: AppText.sectionTitle),
              const SizedBox(height: 4),
              const Text(
                'Tell us how satisfied you are with the app.',
                textAlign: TextAlign.center,
                style: AppText.cardSubtitle,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  final filled = starIndex <= _rating;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = starIndex),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 40,
                        color: filled
                            ? const Color(0xFFF5A623)
                            : AppColors.textFadedLight,
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(
                height: 24,
                child: _rating > 0
                    ? Text(
                        _ratingLabels[_rating - 1],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      )
                    : null,
              ),
              TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Tell us more about your experience (optional)',
                  hintStyle: TextStyle(fontSize: 13.5),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _rating == 0 || _sending ? null : _submit,
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit feedback'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
