// lib/screens/sign_in_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_background.dart';

/// Standard email sign-in / sign-up screen.
///
/// One screen with a segmented toggle between "Sign in" and "Sign up".
/// Uses [AuthService] for real Firebase email + password accounts, so the
/// email entered must be a genuine address and the credentials are verified.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

enum _Mode { signIn, signUp }

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _Mode _mode = _Mode.signIn;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  bool get _isSignUp => _mode == _Mode.signUp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _switchMode(_Mode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_isSignUp) {
        await AuthService.signUp(email: email, password: password);
      } else {
        await AuthService.signIn(email: email, password: password);
      }
      // main.dart's auth listener swaps to Home on its own the moment this
      // resolves — nothing to navigate to here. By the time we get here
      // `this` is very likely already unmounted.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_isSignUp ? 'Account created. Welcome!' : 'Signed in.')),
      );
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Shared handler for the "Continue with …" buttons. A null user means the
  /// person just closed the browser — not an error, so stay quiet.
  Future<void> _socialSignIn(Future<dynamic> Function() signIn) async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final user = await signIn();
      if (user == null) return;
      // Same as _submit: main.dart's auth listener swaps to Home on its own.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in.')),
      );
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(
          () => _error = 'Enter your email first, then tap "Forgot password".');
      return;
    }
    try {
      await AuthService.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email.')),
      );
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        // Skyline artwork behind the whole screen, a touch stronger than
        // the faint watermark used elsewhere, so it reads as the hero image.
        opacity: 0.3,
        child: SafeArea(
          child: Column(
            children: [
              // Back button — only shown when there's actually somewhere
              // to go back to (this screen is the app's root while signed out).
              if (Navigator.of(context).canPop())
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textColor, size: 20),
                    ),
                  ),
                )
              else
                const SizedBox(height: 24),
              const SizedBox(height: 8),
              // Brand mark — temporary logo, swap assets/images/n_logo.png
              // for the final file whenever it's ready.
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppStyle.softShadow,
                ),
                child: Image.asset(
                  'assets/images/n_logo.png',
                  color: AppColors.primary,
                  colorBlendMode: BlendMode.srcIn,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _isSignUp ? 'Create your account' : 'Welcome back',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor),
              ),
              const SizedBox(height: 4),
              Text(
                _isSignUp
                    ? 'Sign up to manage your tenants'
                    : 'Sign in to continue',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              // The form card.
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppStyle.cardGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppStyle.softShadow,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ModeToggle(
                              mode: _mode,
                              onChanged: _busy ? null : _switchMode),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            textInputAction: _isSignUp
                                ? TextInputAction.next
                                : TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  size: 20),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.textFaded,
                                ),
                              ),
                            ),
                            validator: _validatePassword,
                          ),
                          if (_isSignUp) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmController,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon:
                                    Icon(Icons.lock_outline_rounded, size: 20),
                              ),
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return 'Passwords don\'t match.';
                                }
                                return null;
                              },
                            ),
                          ],
                          if (!_isSignUp) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _busy ? null : _forgotPassword,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  minimumSize: const Size(0, 36),
                                ),
                                child: const Text('Forgot password?',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.unpaidSoft,
                                borderRadius:
                                    BorderRadius.circular(AppStyle.radiusSmall),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: AppColors.unpaidRed, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                          color: AppColors.unpaidRed,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.2, color: Colors.white),
                                  )
                                : Text(
                                    _isSignUp ? 'Create account' : 'Sign in'),
                          ),
                          const SizedBox(height: 18),
                          // "or continue with" divider + social buttons.
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Colors.black12)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('or continue with',
                                    style: AppText.cardSubtitle),
                              ),
                              Expanded(child: Divider(color: Colors.black12)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _SocialButton(
                                  label: 'Google',
                                  mark: 'G',
                                  markColor: const Color(0xFF4285F4),
                                  onPressed: _busy
                                      ? null
                                      : () => _socialSignIn(
                                          AuthService.signInWithGoogle),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SocialButton(
                                  label: 'Facebook',
                                  mark: 'f',
                                  markColor: const Color(0xFF1877F2),
                                  onPressed: _busy
                                      ? null
                                      : () => _socialSignIn(
                                          AuthService.signInWithFacebook),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSignUp
                                    ? 'Already have an account?'
                                    : 'New here?',
                                style: AppText.cardSubtitle,
                              ),
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _switchMode(_isSignUp
                                        ? _Mode.signIn
                                        : _Mode.signUp),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  minimumSize: const Size(0, 36),
                                ),
                                child: Text(
                                  _isSignUp ? 'Sign in' : 'Create one',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email.';
    // Simple, permissive email shape check.
    final ok = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v);
    if (!ok) return 'Enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter your password.';
    if (_isSignUp && v.length < 6) return 'Use at least 6 characters.';
    return null;
  }
}

/// "Continue with Google/Facebook" button. Uses a styled letter mark instead
/// of a bundled logo asset to keep the app dependency-free; swap [mark] for
/// an Image.asset if official brand logos are added later.
class _SocialButton extends StatelessWidget {
  final String label;
  final String mark;
  final Color markColor;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.mark,
    required this.markColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textColor,
        side: const BorderSide(color: Colors.black12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            mark,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: markColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Segmented Sign in / Sign up control.
class _ModeToggle extends StatelessWidget {
  final _Mode mode;
  final ValueChanged<_Mode>? onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppStyle.radiusSmall),
      ),
      child: Row(
        children: [
          _segment('Sign in', _Mode.signIn),
          _segment('Sign up', _Mode.signUp),
        ],
      ),
    );
  }

  Widget _segment(String label, _Mode value) {
    final selected = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.textFaded,
            ),
          ),
        ),
      ),
    );
  }
}
