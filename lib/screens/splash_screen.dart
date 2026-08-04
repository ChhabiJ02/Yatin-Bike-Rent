import 'dart:async';
import 'package:flutter/material.dart';
import '../admin/admin_dashboard.dart';
import '../customer/customer_dashboard.dart';
import '../services/auth_service.dart';
import '../staff/staff_dashboard.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<double> _textOpacity;
  Timer? _textTimer;
  Timer? _routeTimer;

  // 🎨 Green Theme Constants
  static const Color primaryGreen = Color(0xFF0F8A4B);
  static const Color darkGreen = Color(0xFF074726);
  static const Color mintGreen = Color(0xFF00FF88);

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotate = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Loading animation controller
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Start animations in sequence
    _logoController.forward();
    _textTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        _textController.forward();
      }
    });

    _routeTimer = Timer(const Duration(seconds: 4), _routeAfterSplash);
  }

  Future<void> _routeAfterSplash() async {
    if (!mounted) return;

    final user = AuthService.currentUser;
    if (user == null || !AuthService.isCurrentSessionActive()) {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final role = await AuthService.resolveUserRole(
      uid: user.uid,
      email: user.email,
    );
    if (role == null) {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    Widget destination;
    if (role == 'Admin') {
      destination = const AdminDashboard();
    } else if (role == 'Staff') {
      destination = const StaffDashboard();
    } else {
      destination = const CustomerDashboard();
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  void dispose() {
    _textTimer?.cancel();
    _routeTimer?.cancel();
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                width: double.infinity,
                height: constraints.maxHeight,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGreen, darkGreen],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            // Animated Logo with Green Shadows & Circular Shape
                            ScaleTransition(
                              scale: _logoScale,
                              child: RotationTransition(
                                turns: _logoRotate,
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: mintGreen.withValues(alpha: 0.35),
                                        blurRadius: 35,
                                        spreadRadius: 8,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/logos/png/main_logo.jpeg',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),
                            // App Name
                            FadeTransition(
                              opacity: _textOpacity,
                              child: Column(
                                children: [
                                  Text(
                                    'StreetBike Rental',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 3,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 15,
                                          color: Colors.black.withValues(alpha: 0.5),
                                          offset: const Offset(2, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: 60,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: mintGreen,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: mintGreen.withValues(alpha: 0.6),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Spinner Loader
                            FadeTransition(
                              opacity: _textOpacity,
                              child: Column(
                                children: [
                                  RotationTransition(
                                    turns: Tween(
                                      begin: 0.0,
                                      end: 1.0,
                                    ).animate(_loadingController),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          width: 3,
                                        ),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(3),
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            mintGreen,
                                          ),
                                          strokeWidth: 3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading...',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 13,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                    // Bottom Branding
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: FadeTransition(
                          opacity: _textOpacity,
                          child: Text(
                            "By Rex Solution'S",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
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
        },
      ),
    );
  }
}