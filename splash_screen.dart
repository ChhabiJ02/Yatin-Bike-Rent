import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate app initialization and navigate after a delay.
    // TODO: Replace this with actual app initialization logic
    // (e.g., checking auth state, loading data).
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        // TODO: Replace '/home' with your actual home screen route
        // or implement logic to navigate to login/home based on auth state.
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using the green from your logo's "streetbike" text
      backgroundColor: const Color(0xFF41A02E),
      body: Center(
        child: Image.asset('assets/logos/png/main_logo.jpeg'),
      ),
    );
  }
}