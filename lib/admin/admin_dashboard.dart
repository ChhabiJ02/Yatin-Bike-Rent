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
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ember.withAlpha(60),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 66,
                      width: 66,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(46),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withAlpha(71),
                        ),
                      ),
                      child: const Icon(
                        Icons.dashboard_customize,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StreamBuilder(
                            stream: AuthService.currentUserProfileStream(),
                            builder: (context, snapshot) {
                              final data = snapshot.data?.data();
                              final name = (data?['name'] as String?)?.trim();
                              final display = name?.isNotEmpty == true ? 'Welcome Back, $name' : 'Welcome Back, Admin';
                              return Text(
                                display,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Control fleet, bookings, staff, and revenue from one sharp view.',
                            style: TextStyle(color: Colors.white, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                // 💡 Aspect Ratio ઓછો કર્યો જેથી કન્ટેન્ટ સમાઈ જાય અને ઓવરફ્લો ન થાય
                childAspectRatio: 1.1,
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
                    route: const CustomerBookingsScreen(),
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
      // 💡 પ્યોર સોલિડ વાઈટ (Solid White) કલર અને શેડો
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (route != null) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => route!));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title management coming soon!')),
              );
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [ 
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black, // વાઈટ કાર્ડ પર સ્પષ્ટ વંચાય તેવો ડાર્ક કલર
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage detailed data from one place.',
                  style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
