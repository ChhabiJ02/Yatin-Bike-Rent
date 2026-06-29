import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../admin/admin_dashboard.dart';
import '../customer/customer_dashboard.dart';
import '../staff/staff_dashboard.dart';
import 'register_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController resetEmailController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';
  static const String _rememberMeKey = 'remember_me';

  bool obscurePassword = true;
  bool rememberMe = false;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    resetEmailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final savedRemember = await _secureStorage.read(key: _rememberMeKey);
      final savedEmail = await _secureStorage.read(key: _savedEmailKey);
      final savedPassword = await _secureStorage.read(key: _savedPasswordKey);

      if (!mounted) return;
      setState(() {
        rememberMe = savedRemember == 'true';
        if (rememberMe) {
          emailController.text = savedEmail ?? '';
          passwordController.text = savedPassword ?? '';
        }
      });
    } catch (_) {
      // Ignore storage failures and continue with empty fields.
    }
  }

  Future<void> _saveCredentials() async {
    if (rememberMe) {
      await _secureStorage.write(
        key: _savedEmailKey,
        value: emailController.text.trim(),
      );
      await _secureStorage.write(
        key: _savedPasswordKey,
        value: passwordController.text.trim(),
      );
      await _secureStorage.write(key: _rememberMeKey, value: 'true');
    } else {
      await _secureStorage.delete(key: _savedEmailKey);
      await _secureStorage.delete(key: _savedPasswordKey);
      await _secureStorage.delete(key: _rememberMeKey);
    }
  }

  Future<void> _clearSavedCredentials() async {
    await _secureStorage.delete(key: _savedEmailKey);
    await _secureStorage.delete(key: _savedPasswordKey);
    await _secureStorage.delete(key: _rememberMeKey);
  }

  Future<void> _handleLogin() async {
    setState(() {
      isLoading = true;
    });
    try {
      final loginIdentifier = emailController.text.trim();
      final cred = await AuthService.signIn(
        email: loginIdentifier,
        password: passwordController.text.trim(),
      );
      final user = AuthService.currentUser ?? cred.user;
      final uid = user?.uid;
      if (uid == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Could not resolve the signed-in account.',
        );
      }

      final roleFromDb = await AuthService.resolveUserRole(
        uid: uid,
        email: user?.email ?? emailController.text.trim(),
        loginIdentifier: loginIdentifier,
      );
      if (roleFromDb == null) {
        await AuthService.signOut();
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'missing-role',
          message:
              'No valid role found in Firebase users collection for this account.',
        );
      }

      Widget destination;
      if (roleFromDb == 'Admin') {
        destination = const AdminDashboard();
      } else if (roleFromDb == 'Staff') {
        destination = const StaffDashboard();
      } else {
        destination = const CustomerDashboard();
      }

      await _saveCredentials();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login failed')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showResetPasswordDialog() async {
    resetEmailController.text = emailController.text.trim();
    var isSending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              title: const Text('Reset password'),
              content: TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          final messenger = ScaffoldMessenger.of(
                            builderContext,
                          );
                          final navigator = Navigator.of(dialogContext);
                          if (email.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Enter your email address.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSending = true);
                          try {
                            await AuthService.sendPasswordResetEmail(email);
                            if (!dialogContext.mounted) return;
                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Password reset email sent. Check your inbox and spam folder.',
                                ),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            if (!dialogContext.mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.message ?? 'Could not send reset email',
                                ),
                              ),
                            );
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSending = false);
                            }
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.pageGradient),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo section with enhanced styling
                        Center(
                          child: Column(
                            children: [
                              Container(
                                height: 86,
                                width: 86,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.ember.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 16,
                                      spreadRadius: 3,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/logos/png/logo1.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'StreetBike',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 15,
                                      color: Colors.black.withValues(alpha: 0.4),
                                      offset: const Offset(2, 4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rental',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.amber,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 15,
                                      color: Colors.black.withValues(alpha: 0.4),
                                      offset: const Offset(2, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Login form container
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 22,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Welcome',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // const Text(
                                //   'Fast booking and seamless management for all users.',
                                //   textAlign: TextAlign.center,
                                //   style: TextStyle(
                                //     fontSize: 14,
                                //     color: Colors.black54,
                                //     height: 1.5,
                                //   ),
                                // ),
                                const SizedBox(height: 18),
                                // Email field with enhanced styling
                                TextField(
                                  controller: emailController,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    labelText: 'Email or Username',
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color: AppColors.ember,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: AppColors.ember,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Password field with enhanced styling
                                TextField(
                                  controller: passwordController,
                                  obscureText: obscurePassword,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: AppColors.ember,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          obscurePassword = !obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: AppColors.ember,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: AppColors.ember,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Remember me
                                Row(
                                  children: [
                                    Checkbox(
                                      value: rememberMe,
                                      activeColor: AppColors.ember,
                                      checkColor: Colors.white,
                                      onChanged: (value) async {
                                        final newValue = value ?? false;
                                        setState(() {
                                          rememberMe = newValue;
                                        });
                                        if (!newValue) {
                                          await _clearSavedCredentials();
                                        } else {
                                          await _saveCredentials();
                                        }
                                      },
                                    ),
                                    const Text(
                                      'Remember me',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                // Forgot password in next line on right side
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showResetPasswordDialog,
                                    style: TextButton.styleFrom(
                                      splashFactory: NoSplash.splashFactory,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.ember,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // Enhanced login button
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.ember,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 4,
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Sign up buttons - both centered
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        "Don't have an account?",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          final navigator = Navigator.of(context);
                                          final messenger = ScaffoldMessenger.of(
                                            context,
                                          );
                                          final created = await navigator.push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) => const RegisterScreen(),
                                            ),
                                          );
                                          if (!mounted) return;
                                          if (created == true) {
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Account created - please log in',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          splashFactory: NoSplash.splashFactory,
                                        ),
                                        child: Text(
                                          'Create one',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.ember,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

