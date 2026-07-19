// lib/screens/profile_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/screen_background.dart';
import '../widgets/feedback_sheet.dart';
import 'property_details_screen.dart';
import 'help_support_screen.dart';
import 'about_app_screen.dart';
import 'feedback_reviews_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _rateController;
  bool _savedJustNow = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rateController =
        TextEditingController(text: AppData.kwhRate.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _saveRate() async {
    final value = double.tryParse(_rateController.text);
    if (value == null || value <= 0) return;

    setState(() => _saving = true);
    await AppData.updateKwhRate(value);
    if (!mounted) return;

    setState(() {
      _saving = false;
      _savedJustNow = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _savedJustNow = false);
    });
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: AppData.landlordName);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Edit Name', style: AppText.sectionTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != AppData.landlordName) {
      await AppData.updateLandlordName(result);
      if (mounted) setState(() {});
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Sign out', style: AppText.sectionTitle),
        content: const Text(
            'You\'ll need to sign in again to sync your account.',
            style: AppText.cardSubtitle),
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
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.signOut();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppHeader(title: 'Profile'),
              Expanded(
                child: StreamBuilder<User?>(
                  stream: AuthService.authStateChanges,
                  initialData: AuthService.currentUser,
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  gradient: AppStyle.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow:
                                      AppStyle.accentShadow(AppColors.primary),
                                ),
                                child: const Icon(Icons.person_rounded,
                                    size: 44, color: Colors.white),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(AppData.landlordName,
                                      style: AppText.sectionTitle),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: _editName,
                                    behavior: HitTestBehavior.opaque,
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.edit_rounded,
                                          size: 16, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(AppData.propertyAddress,
                                  textAlign: TextAlign.center,
                                  style: AppText.cardSubtitle),
                              if (user != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.verified_rounded,
                                          size: 15, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        user.email ?? 'Signed in',
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryDark),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text('Billing Settings',
                            style: AppText.sectionTitle),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Electricity Rate (₱ per kWh)',
                                  style: AppText.cardTitle),
                              const SizedBox(height: 6),
                              const Text(
                                'Used to calculate every tenant\'s electricity bill: kWh used × this rate.',
                                style: AppText.cardSubtitle,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _rateController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: const InputDecoration(
                                          hintText: 'e.g. 34'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: _saving ? null : _saveRate,
                                    style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 22, vertical: 16)),
                                    child: _saving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        : const Text('Save'),
                                  ),
                                ],
                              ),
                              if (_savedJustNow) ...[
                                const SizedBox(height: 10),
                                const Text('Rate updated.',
                                    style: TextStyle(
                                        color: AppColors.paidGreen,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Account', style: AppText.sectionTitle),
                        const SizedBox(height: 16),
                        _ProfileMenuTile(
                          icon: Icons.home_work_outlined,
                          label: 'Property details',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PropertyDetailsScreen()),
                          ),
                        ),
                        _ProfileMenuTile(
                          icon: Icons.help_outline_rounded,
                          label: 'Help & support',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const HelpSupportScreen()),
                          ),
                        ),
                        _ProfileMenuTile(
                          icon: Icons.star_outline_rounded,
                          label: 'Send feedback',
                          onTap: () => showFeedbackSheet(context),
                        ),
                        _ProfileMenuTile(
                          icon: Icons.info_outline_rounded,
                          label: 'About app',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AboutAppScreen()),
                          ),
                        ),
                        // Admin-only: browse every user's feedback.
                        if (AuthService.isAdmin)
                          _ProfileMenuTile(
                            icon: Icons.reviews_outlined,
                            label: 'Check reviews',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const FeedbackReviewsScreen()),
                            ),
                          ),
                        if (user != null) ...[
                          const SizedBox(height: 6),
                          _ProfileMenuTile(
                            icon: Icons.logout_rounded,
                            label: 'Sign out',
                            isDestructive: true,
                            onTap: _signOut,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(current: NiceTab.profile),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.unpaidRed : Colors.black;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 14),
              Text(label,
                  style: TextStyle(
                      fontSize: 15, color: color, fontWeight: FontWeight.w500)),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
