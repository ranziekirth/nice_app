// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/app_data.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_screen.dart';

/// Lets code outside the widget tree (the auth listener below) drive
/// navigation, since bottom-tab switches use pushReplacement — sign-out can
/// happen from any tab, several route-replacements deep, so there's no
/// single fixed screen to pop back to.
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _watchAuthState();
  runApp(const NiceApp());
}

// The splash screen makes the *initial* sign-in/sign-out decision using the
// cached [AuthService.currentUser] (see splash_screen.dart), so this only
// needs to react to changes after that — which is why its first (replayed)
// event is deliberately ignored here.
bool _skippedInitialAuthEvent = false;

void _watchAuthState() {
  AuthService.authStateChanges.listen((user) async {
    if (!_skippedInitialAuthEvent) {
      _skippedInitialAuthEvent = true;
      return;
    }
    final nav = navigatorKey.currentState;
    if (user == null) {
      await AppData.reset();
      nav?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    } else {
      await AppData.init();
      nav?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  });
}

class NiceApp extends StatelessWidget {
  const NiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Nice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
