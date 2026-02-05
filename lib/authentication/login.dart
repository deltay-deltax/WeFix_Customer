import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Still needed for FirebaseAuthException
import 'package:wefix/core/services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/auth_input_field.dart';
import '../../core/services/location_service.dart';
import 'signup.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  // Initialize your AuthService
  final AuthService _authService = AuthService();

  // Added loading states
  bool _emailLoading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<bool> _handleBack(BuildContext context) async => false;

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: WillPopScope(
        onWillPop: () => _handleBack(context),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Text(
                    'Login here',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    "Welcome back, you’ve\nbeen missed!",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                InputField(
                  hint: 'Email',
                  controller: emailCtrl,

                  fillColor: AppColors.inputFill,
                ),
                const SizedBox(height: 18),
                InputField(
                  hint: 'Password',
                  controller: passCtrl,
                  obscureText: true,
                  fillColor: AppColors.inputFill,
                ),
                const SizedBox(height: 3),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Forgot your password?",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildLoginButton(context), // Updated this widget
                const SizedBox(height: 22),
                _buildGoogleButton(context), // Updated this widget
                const SizedBox(height: 22),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: const Text(
                      "Create new account",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: content,
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      height: 51,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2.5,
        ),
        // Disable button when loading
        onPressed: _emailLoading || _googleLoading
            ? null
            : () async {
                final email = emailCtrl.text.trim();
                final pass = passCtrl.text.trim();
                if (email.isEmpty || pass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter email and password')),
                  );
                  return;
                }

                setState(() => _emailLoading = true);
                try {
                  // --- REPLACED ---
                  await _authService.signInWithEmail(email, pass);
                  // Ask for location permission immediately after login
                  final loc = LocationService();
                  await loc.ensurePermission();
                  final pos = await loc.getCurrentPosition();
                  if (pos != null) {
                    await loc.reverseGeocode(pos.latitude, pos.longitude);
                  }
                  // ---

                  if (!mounted) return;
                  Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                } on FirebaseAuthException catch (e) {
                  final msg = e.message ?? 'Sign in failed';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(msg)));
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sign in failed')),
                  );
                } finally {
                  if (mounted) {
                    setState(() => _emailLoading = false);
                  }
                }
              },
        child: _emailLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Sign in',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        // Disable button when loading
        onPressed: _emailLoading || _googleLoading
            ? null
            : () async {
                setState(() => _googleLoading = true);
                try {
                  // --- REPLACED ---
                  await _authService.signInWithGoogle();
                  // ---

                  if (!mounted) return;
                  Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                } on FirebaseAuthException catch (e) {
                  final msg = e.message ?? 'Google sign-in failed';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(msg)));
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Google sign-in failed')),
                  );
                } finally {
                  if (mounted) {
                    setState(() => _googleLoading = false);
                  }
                }
              },
        child: _googleLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icon/google_g.svg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}
