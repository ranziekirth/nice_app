// Basic smoke test for the Nice app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nice_app/theme/app_theme.dart';
import 'package:nice_app/screens/sign_in_screen.dart';

void main() {
  testWidgets('Sign-in screen renders and toggles to sign-up', (WidgetTester tester) async {
    // SignInScreen renders without Firebase (auth is only called on submit)
    // and has no timers, so it's a clean widget to smoke-test.
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.theme, home: const SignInScreen()),
    );

    // Starts in sign-in mode.
    expect(find.text('Welcome back'), findsOneWidget);

    // Tapping "Sign up" in the segmented toggle switches to sign-up mode.
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });
}
