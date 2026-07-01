import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
                      color: AppColors.ember.withValues(alpha: 0.24),
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
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
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
                          SizedBox(height: 6),
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
              const SizedBox(height: 22),
              const Row(
                children: [
                  _CountCard(
                    title: 'Vehicles',
                    collection: 'vehicles',
                    icon: Icons.pedal_bike,
                    color: AppColors.mint,
                  ),
                  SizedBox(width: 14),
                  _CountCard(
                    title: 'Bookings',
                    collection: 'bookings',
                    icon: Icons.receipt_long,
                    color: AppColors.sky,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  _CountCard(
                    title: 'Customers',
                    collection: 'customers',
                    icon: Icons.group,
                    color: AppColors.amber,
                  ),
                  SizedBox(width: 14),
                  _RevenueCard(
                    title: 'Revenue',
                    icon: Icons.currency_rupee,
                    color: AppColors.ember,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),

              // Vehicle Return Status Summary
              const Text(
                'Vehicle Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _VehicleStatusCard(
                      title: 'Available',
                      icon: Icons.check_circle,
                      color: AppColors.mint,
                      filterKey: 'available',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _VehicleStatusCard(
                      title: 'Booked',
                      icon: Icons.pedal_bike,
                      color: AppColors.ember,
                      filterKey: 'booked',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _VehicleStatusCard(
                      title: 'Return Pending',
                      icon: Icons.schedule,
                      color: AppColors.amber,
                      filterKey: 'returnPending',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _VehicleStatusCard(
                      title: 'Returned',
                      icon: Icons.assignment_turned_in,
                      color: AppColors.sky,
                      filterKey: 'returned',
                    ),
                  ),
                ],
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
                childAspectRatio: 0.98,
                children: const [
                  _AdminCard(
                    title: 'Vehicles',
                    icon: Icons.pedal_bike,
                    color: AppColors.mint,
                  ),
                  _AdminCard(
                    title: 'Bookings',
                    icon: Icons.receipt_long,
                    color: AppColors.sky,
                  ),
                  _AdminCard(
                    title: 'Staff',
                    icon: Icons.group,
                    color: AppColors.amber,
                  ),
                  _AdminCard(
                    title: 'Reports',
                    icon: Icons.bar_chart,
                    color: AppColors.ember,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.softCard(),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping, color: AppColors.sky, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transportation Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Transportation is now captured inside Challan entries.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const _UserRoleManager(),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserRoleManager extends StatelessWidget {
  const _UserRoleManager();

  static const _roles = ['Customer', 'Staff', 'Admin'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.manage_accounts, color: AppColors.ember),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'User Roles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Only admins can promote users to Staff or Admin.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: AuthService.usersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Text(
                  'Could not load users.',
                  style: TextStyle(color: Colors.red),
                );
              }

              final users = snapshot.data?.docs ?? [];
              if (users.isEmpty) {
                return const Text(
                  'No users registered yet.',
                  style: TextStyle(color: AppColors.muted),
                );
              }

              return Column(
                children: users.map((doc) {
                  final data = doc.data();
                  final name = (data['name'] as String?)?.trim();
                  final email = (data['email'] as String?)?.trim();
                  final currentRole = data['role'] as String? ?? 'Customer';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.ember.withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.person_outline,
                            color: AppColors.ember,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name?.isNotEmpty == true ? name! : 'User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                email?.isNotEmpty == true ? email! : doc.id,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: _roles.contains(currentRole)
                              ? currentRole
                              : 'Customer',
                          underline: const SizedBox.shrink(),
                          borderRadius: BorderRadius.circular(14),
                          items: _roles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ),
                              )
                              .toList(),
                          onChanged: (role) async {
                            if (role == null || role == currentRole) return;
                            await AuthService.updateUserRole(
                              uid: doc.id,
                              role: role,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Role updated to $role.')),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final String title;
  final String collection;
  final IconData icon;
  final Color color;

  const _CountCard({
    required this.title,
    required this.collection,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.softCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 16),
            StreamBuilder(
              stream: RentalService.countStream(collection),
              builder: (context, snapshot) {
                final value = snapshot.data?.docs.length ?? 0;
                return Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _RevenueCard({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.softCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 16),
            StreamBuilder(
              stream: RentalService.bookingsStream(),
              builder: (context, snapshot) {
                final total = snapshot.data?.docs.fold<int>(0, (total, doc) {
                      return total + ((doc.data()['totalAmount'] as num?)?.toInt() ?? 0);
                    }) ??
                    0;
                return Text(
                  'Rs $total',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _AdminCard({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage detailed data from one place.',
            style: TextStyle(color: AppColors.muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _VehicleStatusCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String filterKey;

  const _VehicleStatusCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.filterKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.softCard(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCountStream(),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountStream() {
    if (filterKey == 'returnPending' || filterKey == 'returned') {
      return StreamBuilder(
        stream: FirebaseFirestore.instance.collection('customers').snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          int count = 0;
          for (final doc in docs) {
            final handover = doc.data()['vehicleHandover'] as Map<String, dynamic>?;
            final status = handover?['returnStatus'] as String? ?? 'Pending';
            if (filterKey == 'returned' && status == 'Returned') {
              count++;
            } else if (filterKey == 'returnPending' && status != 'Returned') {
              count++;
            }
          }
          return Text(
            '$count',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          );
        },
      );
    }

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        int count = 0;
        for (final doc in docs) {
          final available = doc.data()['available'] as bool? ?? false;
          if (filterKey == 'available' && available) {
            count++;
          } else if (filterKey == 'booked' && !available) {
            count++;
          }
        }
        return Text(
          '$count',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        );
      },
    );
  }
}

