import 'dart:async';
import 'package:flutter/material.dart';
import '../admin/admin_dashboard.dart';
import '../customer/customer_dashboard.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Minimum display duration: just one frame so the spinner can paint.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeAfterSplash();
    });
  }

  Future<void> _routeAfterSplash() async {
    if (!mounted) return;

    final user = AuthService.currentUser;
    if (user == null || !AuthService.isCurrentSessionActive()) {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final role = await AuthService.resolveUserRole(
      uid: user.uid,
      email: user.email,
    );
    if (role == null) {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    Widget destination;
    if (role == 'Admin') {
      destination = const AdminDashboard();
    } else {
      destination = const CustomerDashboard();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
          ),
        ),
      ),
    );
  }
}
