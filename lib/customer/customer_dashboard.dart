import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../services/rental_service.dart';
import '../widgets/user_app_bar_title.dart';
import '../theme/app_theme.dart';
import '../widgets/app_settings_menu.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const UserAppBarTitle(fallbackTitle: 'Customer'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          const AppSettingsMenu(),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ember.withAlpha(60), // ~0.24 alpha
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.electric_bike, color: Colors.white, size: 42),
                    SizedBox(height: 18),
                    Text(
                      'Find your next ride',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Compare bikes, prices, and availability for a perfect trip.',
                      style: TextStyle(color: Colors.white, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: _OverviewCard(
                      title: 'Popular',
                      value: '88%',
                      icon: Icons.trending_up,
                      color: AppColors.amber,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StreamBuilder(
                      stream: RentalService.vehiclesStream(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        final available = docs.where((d) => (d.data()['available'] as bool?) == true).length;
                        return _OverviewCard(
                          title: 'Available',
                          value: '$available',
                          icon: Icons.verified_outlined,
                          color: AppColors.mint,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Available Vehicles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder(
                stream: RentalService.vehiclesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(12), child: SizedBox(height:24,width:24,child:CircularProgressIndicator(strokeWidth:2.5))));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No vehicles available.', style: TextStyle(color: AppColors.muted)),
                    );
                  }
                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data();
                      final vehicle = Vehicle(
                        id: doc.id,
                        name: (data['name'] as String?) ?? 'Vehicle',
                        type: (data['type'] as String?) ?? '',
                        pricePerHour: (data['hourlyRate'] as int?) ?? (data['pricePerHour'] as int?) ?? 0,
                        pricePerDay: (data['dailyRate'] as int?) ?? (data['pricePerDay'] as int?) ?? 0,
                        available: (data['available'] as bool?) ?? true,
                        description: (data['description'] as String?) ?? '',
                      );
                      return _VehicleCard(vehicle: vehicle);
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewCard({
    required this.title,
    required this.value,
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
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;

  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.mint.withAlpha(46), // ~0.18 alpha
                      AppColors.sky.withAlpha(35), // ~0.14 alpha
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.pedal_bike,
                  size: 34,
                  color: AppColors.mint,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vehicle.type,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(vehicle.available ? 'Available' : 'Booked'),
                backgroundColor: vehicle.available ? AppColors.mint.withAlpha(30) // ~0.12 alpha
                    : Colors.red.shade50,
                labelStyle: TextStyle(
                  color: vehicle.available
                      ? AppColors.mint
                      : Colors.red.shade700,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            vehicle.description,
            style: const TextStyle(color: AppColors.ink, height: 1.45),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rs ${vehicle.pricePerHour}/hr',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'Rs ${vehicle.pricePerDay}/day',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: vehicle.available
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${vehicle.name} booked successfully!',
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Book'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
