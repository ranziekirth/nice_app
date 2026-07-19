// lib/screens/help_support_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const List<_Faq> _faqs = [
    _Faq(
      question: 'How do I add a new tenant?',
      answer:
          'From the Home screen, tap "Add Tenant +" below the tenant list, then enter the name and room number.',
    ),
    _Faq(
      question: 'How is the electricity charge calculated?',
      answer:
          'It\'s the difference between the current and previous meter readings, multiplied by your electricity rate. Update the rate anytime from Profile.',
    ),
    _Faq(
      question: 'How do I mark a bill as paid?',
      answer:
          'Open the tenant, then swipe left on the month you want to mark as paid.',
    ),
    _Faq(
      question: 'Can I remove a tenant?',
      answer:
          'Yes — on the Home screen, swipe left on a tenant card and confirm the deletion.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(
                title: 'Help & Support', showBack: true, centered: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  const Text('Frequently Asked Questions',
                      style: AppText.sectionTitle),
                  const SizedBox(height: 16),
                  for (final faq in _faqs)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: Text(faq.question, style: AppText.cardTitle),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(faq.answer, style: AppText.cardSubtitle)
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text('Still need help?', style: AppText.sectionTitle),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Reach out and we\'ll get back to you as soon as we can.',
                            style: AppText.cardSubtitle),
                        SizedBox(height: 12),
                        _ContactRow(
                            icon: Icons.email_outlined,
                            label: 'ranziekirthcahulugan@gmail.com'),
                        SizedBox(height: 10),
                        _ContactRow(
                            icon: Icons.phone_outlined,
                            label: '+63 993 659 0564'),
                        SizedBox(height: 10),
                        _ContactRow(
                            icon: Icons.web_asset_outlined,
                            label: 'https://ranzportfolio.vercel.app/'),
                      ],
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

class _Faq {
  final String question;
  final String answer;
  const _Faq({required this.question, required this.answer});
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(label, style: AppText.cardTitle),
      ],
    );
  }
}
