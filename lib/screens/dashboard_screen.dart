import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../admin/vehicle_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Selected filter: 'All', 'Return Pending', 'Returned', 'Recent Bookings'
  String _selectedFilter = 'All';

  // Live metric counts driven by Firestore streams
  int returnPendingCount = 0;
  int totalReturnedCount = 0;
  int availableVehicles = 0;

  final List<String> _filterTabs = [
    'All',
    'Return Pending',
    'Returned',
    'Recent Bookings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Metric Cards Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Available Vehicles',
                          count: availableVehicles,
                          color: Colors.blue.shade700,
                          icon: Icons.two_wheeler_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VehicleManagementScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Return Pending',
                          count: returnPendingCount,
                          color: Colors.orange.shade700,
                          icon: Icons.pending_actions,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Total Returned',
                          count: totalReturnedCount,
                          color: Colors.green.shade700,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Sticky Filter Bar (Fixed at top while scrolling)
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyFilterDelegate(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterTabs.map((tab) {
                      final isSelected = _selectedFilter == tab;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(tab),
                          selected: isSelected,
                          selectedColor: Theme.of(context).primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedFilter = tab;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // 3. Customer / Booking List (Safe from Red Screen Errors)
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: _buildCustomerList(),
          ),

          // 4. Hidden stream that feeds the 'Available Vehicles' card.
          SliverToBoxAdapter(
            child: _buildAvailableVehiclesStream(),
          ),
        ],
      ),
    );
  }

  // Metric Card Widget
  Widget _buildMetricCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Live customer/booking list (driven by Firestore)
  Widget _buildCustomerList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('customers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'Could not load bookings.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final items = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final handover = data['vehicleHandover'] as Map<String, dynamic>?;
          final rawStatus = (handover?['returnStatus'] ?? 'Pending')
              .toString()
              .trim()
              .toLowerCase();
          String displayStatus;
          if (rawStatus == 'returned' || rawStatus == 'completed') {
            displayStatus = 'Returned';
          } else {
            displayStatus = 'Return Pending';
          }
          return {
            'name': (data['name'] ?? 'Unknown Customer').toString(),
            'bike': (data['vehicleName'] ?? data['bike'] ?? '').toString(),
            'status': displayStatus,
          };
        }).toList();

        // Update live metric counts from the same data.
        _updateCountsFromItems(items);

        final filteredList = items.where((item) {
          if (_selectedFilter == 'All') return true;
          return item['status'] == _selectedFilter;
        }).toList();

        if (filteredList.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'No records found.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = filteredList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.two_wheeler),
                  ),
                  title: Text(item['name'] ?? 'Unknown Customer'),
                  subtitle: Text(
                    (item['bike'] ?? '').toString().isEmpty
                        ? 'Vehicle Details'
                        : item['bike']!,
                  ),
                  trailing: Chip(
                    label: Text(
                      item['status'] ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              );
            },
            childCount: filteredList.length,
          ),
        );
      },
    );
  }

  // Recalculate Return Pending / Total Returned from current list
  // (Available Vehicles is set by the dedicated stream listener).
  void _updateCountsFromItems(List<Map<String, String>> items) {
    int pending = 0;
    int returned = 0;
    for (final item in items) {
      if (item['status'] == 'Return Pending') pending++;
      if (item['status'] == 'Returned') returned++;
    }
    if (pending != returnPendingCount || returned != totalReturnedCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          returnPendingCount = pending;
          totalReturnedCount = returned;
        });
      });
    }
  }

  // Live 'Available Vehicles' count = total vehicles - active rentals
  Widget _buildAvailableVehiclesStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
      builder: (context, vehiclesSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('customers').snapshots(),
          builder: (context, customersSnap) {
            int compute() {
              if (vehiclesSnap.hasData == false ||
                  customersSnap.hasData == false) {
                return 0;
              }
              final totalVehicles = vehiclesSnap.data?.docs.length ?? 0;
              int activeRentals = 0;
              for (final doc in customersSnap.data?.docs ?? const []) {
                final data = doc.data() as Map<String, dynamic>;
                final handover =
                    data['vehicleHandover'] as Map<String, dynamic>?;
                final rawStatus =
                    (handover?['returnStatus'] ?? '').toString().trim().toLowerCase();
                if (rawStatus != 'returned' && rawStatus != 'completed') {
                  activeRentals++;
                }
              }
              return (totalVehicles - activeRentals).clamp(0, 1 << 30);
            }

            final value = compute();
            if (value != availableVehicles) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => availableVehicles = value);
              });
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}

// Delegate for Sticky Header
class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyFilterDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 56.0;

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(covariant _StickyFilterDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}