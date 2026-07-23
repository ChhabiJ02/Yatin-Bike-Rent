import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:streetbike_rental/admin/admin_dashboard.dart';
import 'package:streetbike_rental/customer/customer_dashboard.dart';
import 'package:streetbike_rental/screens/login_screen.dart';
import 'package:streetbike_rental/services/auth_service.dart';
import 'package:streetbike_rental/theme/app_theme.dart';

class StreetBikeRentalApp extends StatelessWidget {
  const StreetBikeRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreetBike Rental',
      theme: AppTheme.light,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          // User is logged in, check their role
          return const RoleBasedRedirect();
        }
        // User is not logged in
        return const LoginScreen();
      },
    );
  }
}

class RoleBasedRedirect extends StatelessWidget {
  const RoleBasedRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: AuthService.currentUserProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final role = data['role'] as String?;

          if (role == 'Admin' || role == 'Staff') {
            return const AdminDashboard();
          }
        }
        // Default to customer dashboard if role is not Admin/Staff or not set
        return const CustomerDashboard();
      },
    );
  }
}