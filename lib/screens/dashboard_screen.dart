import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Selected filter: 'All', 'Return Pending', 'Returned', 'Recent Bookings'
  String _selectedFilter = 'All';

  // Sample data count (Replace with your actual stream/provider/database data)
  int returnPendingCount = 5;
  int totalReturnedCount = 12;

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
          // 1. Metric Cards Section (Only Return Pending & Total Returned)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Return Pending',
                      count: returnPendingCount,
                      color: Colors.orange.shade700,
                      icon: Icons.pending_actions,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Returned',
                      count: totalReturnedCount,
                      color: Colors.green.shade700,
                      icon: Icons.check_circle_outline,
                    ),
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
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }

  // Customer / Booking items rendering with safety bounds
  Widget _buildCustomerList() {
    // Demo data list - Replace with your dynamic data stream / list
    List<Map<String, String>> sampleData = [
      {'name': 'Rahul Sharma', 'bike': 'Royal Enfield Classic 350', 'status': 'Return Pending'},
      {'name': 'Priya Patel', 'bike': 'TVS Jupiter', 'status': 'Returned'},
      {'name': 'Amit Verma', 'bike': 'Honda Activa 6G', 'status': 'Recent Bookings'},
    ];

    // Filter items safely
    List<Map<String, String>> filteredList = sampleData.where((item) {
      if (_selectedFilter == 'All') return true;
      return item['status'] == _selectedFilter;
    }).toList();

    if (filteredList.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
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
              subtitle: Text(item['bike'] ?? 'Vehicle Details'),
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