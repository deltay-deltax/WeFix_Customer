import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Still needed for FirebaseAuthException
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wefix/core/services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/auth_input_field.dart';
import '../../core/services/location_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  // Initialize your AuthService
  final AuthService _authService = AuthService();

  bool _emailLoading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Create an account so you can explore all the\nexisting jobs',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 36),
                InputField(
                  hint: 'Name',
                  controller: nameCtrl,
                  fillColor: AppColors.inputFill,
                ),
                const SizedBox(height: 18),
                InputField(
                  hint: 'Email',
                  controller: emailCtrl,

                  fillColor: AppColors.inputFill,
                ),
                const SizedBox(height: 18),
                InputField(
                  hint: 'Phone number',
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  fillColor: AppColors.inputFill,
                ),
                const SizedBox(height: 18),
                InputField(
                  hint: 'Password',
                  controller: passCtrl,
                  obscureText: true,
                  fillColor: AppColors.inputFill,
                ),
                const SizedBox(height: 18),
                InputField(
                  hint: 'Confirm Password',
                  controller: confirmPassCtrl,
                  obscureText: true,
                  fillColor: AppColors.inputFill,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2.5,
                    ),
                    onPressed: _emailLoading || _googleLoading
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            final pass = passCtrl.text.trim();
                            final phone = phoneCtrl.text.trim();
                            final confirm = confirmPassCtrl.text.trim();

                            final emailRegex = RegExp(r'^.+@.+\..+$');
                            if (!emailRegex.hasMatch(email)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter a valid email address'),
                                ),
                              );
                              return;
                            }
                            if (email.isEmpty ||
                                phone.isEmpty ||
                                pass.isEmpty ||
                                confirm.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fill all required fields'),
                                ),
                              );
                              return;
                            }
                            if (pass.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password must be at least 6 characters',
                                  ),
                                ),
                              );
                              return;
                            }
                            if (pass != confirm) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Passwords do not match'),
                                ),
                              );
                              return;
                            }

                            setState(() => _emailLoading = true);
                            try {
                              debugPrint('[signup] email create start');

                              // --- REPLACED ---
                              // Use the AuthService to handle both Auth and Firestore
                              final cred = await _authService.signUpWithEmail(
                                email,
                                pass,
                              );
                              final uid =
                                  cred.user?.uid ??
                                  FirebaseAuth.instance.currentUser?.uid;
                              if (uid != null) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .set({
                                      'name': name,
                                      'phone': phone,
                                      'email': email,
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    }, SetOptions(merge: true));
                              }
                              // Request location right after signup
                              final loc = LocationService();
                              await loc.ensurePermission();
                              final pos = await loc.getCurrentPosition();
                              if (pos != null) {
                                await loc.reverseGeocode(
                                  pos.latitude,
                                  pos.longitude,
                                );
                              }
                              // ---

                              if (!context.mounted) return;
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(AppRoutes.home);
                            } on FirebaseAuthException catch (e) {
                              debugPrint(
                                '[signup] email auth exception code=${e.code} message=${e.message}',
                              );
                              final msg = e.message ?? 'Sign up failed';
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(msg)));
                            } catch (e) {
                              debugPrint('[signup] email unknown error: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sign up failed')),
                              );
                            } finally {
                              if (mounted)
                                setState(() => _emailLoading = false);
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
                            'Sign up',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _googleLoading || _emailLoading
                        ? null
                        : () async {
                            setState(() => _googleLoading = true);
                            try {
                              debugPrint('[signup] google signIn start');

                              // --- REPLACED ---
                              // Use the AuthService to handle both Auth and Firestore
                              final cred = await _authService
                                  .signInWithGoogle();
                              final uid =
                                  cred.user?.uid ??
                                  FirebaseAuth.instance.currentUser?.uid;
                              if (uid != null) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .set({
                                      'name': nameCtrl.text.trim(),
                                      'phone': phoneCtrl.text.trim(),
                                      'email': cred.user?.email,
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    }, SetOptions(merge: true));
                              }
                              // ---

                              if (!context.mounted) return;
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(AppRoutes.home);
                            } on FirebaseAuthException catch (e) {
                              debugPrint(
                                '[signup] google auth exception code=${e.code} message=${e.message}',
                              );
                              final msg = e.message ?? 'Google sign-in failed';
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(msg)));
                            } catch (e) {
                              debugPrint('[signup] google unknown error: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Google sign-in failed'),
                                ),
                              );
                            } finally {
                              if (mounted)
                                setState(() => _googleLoading = false);
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
                              const Text('Continue with Google'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.login);
                    },
                    child: const Text(
                      "Already have an account",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
