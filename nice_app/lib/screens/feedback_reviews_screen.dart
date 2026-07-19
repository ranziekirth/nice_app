// lib/screens/feedback_reviews_screen.dart
import 'package:flutter/material.dart';
import '../models/feedback_entry.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

/// Admin-only screen (opened from Profile > Check reviews) listing every
/// user's feedback: an average-rating summary card on top, then each review
/// with its stars, comment, author and date. Firestore rules only let the
/// admin account read the feedback collection, so this screen is never
/// reachable — nor readable — by regular users.
class FeedbackReviewsScreen extends StatelessWidget {
  const FeedbackReviewsScreen({super.key});

  static const Color _starGold = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(
                title: 'User Reviews', showBack: true, centered: true),
            Expanded(
              child: StreamBuilder<List<FeedbackEntry>>(
                stream: FirestoreService.allFeedback(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Couldn\'t load reviews. Make sure this account '
                          'has admin access.',
                          textAlign: TextAlign.center,
                          style: AppText.cardSubtitle,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary));
                  }

                  final reviews = snapshot.data!;
                  if (reviews.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.reviews_outlined,
                              size: 56, color: AppColors.textFadedLight),
                          const SizedBox(height: 12),
                          const Text('No reviews yet',
                              style: AppText.cardTitle),
                          const SizedBox(height: 4),
                          const Text(
                              'User feedback will show up here once it\'s sent.',
                              style: AppText.cardSubtitle),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    children: [
                      _SummaryCard(reviews: reviews),
                      const SizedBox(height: 24),
                      Text('All reviews (${reviews.length})',
                          style: AppText.sectionTitle),
                      const SizedBox(height: 14),
                      ...reviews.map((r) => _ReviewCard(review: r)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big average number + stars + per-star distribution bars, like a store
/// listing's ratings header.
class _SummaryCard extends StatelessWidget {
  final List<FeedbackEntry> reviews;

  const _SummaryCard({required this.reviews});

  @override
  Widget build(BuildContext context) {
    final average =
        reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length;
    final counts = List<int>.filled(5, 0);
    for (final r in reviews) {
      counts[r.rating - 1]++;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppStyle.cardGradient,
        borderRadius: BorderRadius.circular(AppStyle.radius),
        boxShadow: AppStyle.softShadow,
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                average.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < average.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: FeedbackReviewsScreen._starGold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                style: AppText.cardSubtitle,
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = counts[star - 1];
                final fraction =
                    reviews.isEmpty ? 0.0 : count / reviews.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text('$star',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textColor)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 7,
                            backgroundColor: AppColors.background,
                            valueColor: const AlwaysStoppedAnimation(
                                FeedbackReviewsScreen._starGold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 20,
                        child: Text('$count',
                            textAlign: TextAlign.end,
                            style: AppText.cardSubtitle),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final FeedbackEntry review;

  const _ReviewCard({required this.review});

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = review.name.isNotEmpty ? review.name : 'Anonymous';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  displayName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: AppText.cardTitle,
                        overflow: TextOverflow.ellipsis),
                    if (review.email.isNotEmpty)
                      Text(review.email,
                          style: AppText.cardSubtitle,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(_formatDate(review.date), style: AppText.cardSubtitle),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < review.rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 18,
                color: FeedbackReviewsScreen._starGold,
              ),
            ),
          ),
          if (review.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.message,
                style: AppText.cardSubtitle.copyWith(height: 1.45)),
          ],
        ],
      ),
    );
  }
}
