import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:streetbike_rental/admin/vehicle_management_screen.dart';
import 'package:streetbike_rental/admin/staff_management_screen.dart';
import 'package:streetbike_rental/admin/customer_bookings_screen.dart';

import '../services/rental_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_settings_menu.dart';
import '../widgets/user_app_bar_title.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const UserAppBarTitle(fallbackTitle: 'Admin'),
        actions: const [AppSettingsMenu()],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // 💡 Light & Attractive Gradient Welcome Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0E7FF), Color(0xFFCFFAFE)], // Premium Light Indigo to Cyan
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 58,
                      width: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF4F46E5).withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.dashboard_customize,
                        color: Color(0xFF4F46E5),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StreamBuilder(
                            stream: AuthService.currentUserProfileStream(),
                            builder: (context, snapshot) {
                              final data = snapshot.data?.data();
                              final name = (data?['name'] as String?)?.trim();
                              final display = name?.isNotEmpty == true
                                  ? 'Welcome Back, $name'
                                  : 'Welcome Back, Admin';
                              return Text(
                                display,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E1B4B), // Premium Dark Slate
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Control fleet, bookings, staff, and revenue from one sharp view.',
                            style: TextStyle(
                              color: Color(0xFF4338CA),
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Actions Header
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),

              // 💡 Shorter Grid Cards (childAspectRatio: 1.15)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15, // 💡 આસ્પેક્ટ રેશિયો વધારવાથી કાર્ડ્સ નાના અને કોમ્પેક્ટ થઈ જશે
                children: const [
                  _AdminCard(
                    title: 'Vehicles',
                    icon: Icons.pedal_bike,
                    color: AppColors.mint,
                    route: VehicleManagementScreen(),
                  ),
                  _AdminCard(
                    title: 'Bookings',
                    icon: Icons.receipt_long,
                    color: AppColors.sky,
                    route: CustomerBookingsScreen(),
                  ),
                  _AdminCard(
                    title: 'Staff',
                    icon: Icons.group,
                    color: AppColors.amber,
                    route: StaffManagementScreen(),
                  ),
                ],
              ),
              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? route;

  const _AdminCard({
    required this.title,
    required this.icon,
    required this.color,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (route != null) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => route!),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title management coming soon!')),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Manage detailed data from one place.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 10.5,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}