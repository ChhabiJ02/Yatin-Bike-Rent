import 'package:flutter/material.dart';
import 'package:street_bike_rental/screens/splash_screen.dart';
import 'package:street_bike_rental/theme/app_theme.dart';

class StreetBikeRentalApp extends StatelessWidget {
  const StreetBikeRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreetBike Rental',
      theme: AppTheme.light,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}