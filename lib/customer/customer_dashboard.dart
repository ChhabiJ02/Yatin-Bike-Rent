import 'package:flutter/material.dart';
import '../models/vehicle.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  static const _vehicles = [
    Vehicle(
      id: 'v1',
      name: 'City Cruiser',
      type: 'Urban',
      pricePerHour: 50,
      pricePerDay: 300,
      available: true,
      description: 'Smooth ride for city streets with a comfortable seat.',
    ),
    Vehicle(
      id: 'v2',
      name: 'Mountain Rider',
      type: 'MTB',
      pricePerHour: 80,
      pricePerDay: 500,
      available: true,
      description: 'Strong and reliable for off-road and rough terrain.',
    ),
    Vehicle(
      id: 'v3',
      name: 'Electric Assist',
      type: 'E-Bike',
      pricePerHour: 100,
      pricePerDay: 650,
      available: true,
      description: 'Electric boost for easy rides with less effort.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Dashboard'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.shade700.withOpacity(0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Find your next ride',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Compare bikes, prices, and availability for a perfect trip.',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: const [
                Expanded(child: _OverviewCard(title: 'Popular', value: '88%')), 
                SizedBox(width: 16),
                Expanded(child: _OverviewCard(title: 'Available', value: '24')), 
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Vehicles',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._vehicles.map((vehicle) => _VehicleCard(vehicle: vehicle)),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;

  const _OverviewCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.pedal_bike, size: 34, color: Colors.teal),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(vehicle.type, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                Chip(
                  label: Text(vehicle.available ? 'Available' : 'Booked'),
                  backgroundColor: vehicle.available ? Colors.green.shade50 : Colors.red.shade50,
                  labelStyle: TextStyle(color: vehicle.available ? Colors.green.shade700 : Colors.red.shade700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(vehicle.description, style: const TextStyle(color: Colors.black87, height: 1.4)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹${vehicle.pricePerHour}/hr', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹${vehicle.pricePerDay}/day', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                ElevatedButton(
                  onPressed: vehicle.available
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${vehicle.name} booked successfully!')),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  child: const Text('Book Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
