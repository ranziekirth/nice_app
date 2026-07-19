// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), _continue);
  }

  Future<void> _continue() async {
    // A session that's already signed in (Firebase persists it on device)
    // skips straight to Home, so the user stays signed in until they
    // explicitly sign out — otherwise, sign-in is required first.
    final user = AuthService.currentUser;
    if (user != null) {
      await AppData.init();
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            user != null ? const HomeScreen() : const SignInScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      // Temporary logo mark — swap assets/images/n_logo.png for the final
      // logo file whenever it's ready, no code changes needed.
      body: Center(
        child: Image.asset(
          'assets/images/n_logo.png',
          width: 160,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
