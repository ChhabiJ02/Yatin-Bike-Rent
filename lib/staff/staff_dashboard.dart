import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer.dart';
import '../services/rental_service.dart';
import '../widgets/user_app_bar_title.dart';
import '../theme/app_theme.dart';
import '../widgets/app_settings_menu.dart';
import '../screens/challan_entry_screen.dart';
import '../screens/invoice_preview_screen.dart';
import '../screens/payment_record_screen.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final _customersCollection = FirebaseFirestore.instance
      .collection('customers')
      .withConverter<Customer>(
        fromFirestore: (snapshots, _) => Customer.fromFirestore(snapshots),
        toFirestore: (customer, _) => customer.toMap(),
      );
  String _returnFilter = 'All';

  void _openEntryForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChallanEntryScreen()),
    );
  }

  Future<void> _updateReturnStatus(String custCode, String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mark as $status?'),
        content: Text('This will update the vehicle return status to $status.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              status,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final docRef = _customersCollection.doc(custCode);
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        final handover = data.vehicleHandover ?? {};
        handover['returnStatus'] = status;
        await docRef.update({'vehicleHandover': handover});
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Vehicle marked as $status')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const UserAppBarTitle(fallbackTitle: 'Staff'),
        actions: const [AppSettingsMenu()],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
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
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.assignment_turned_in,
                        color: Colors.white,
                        size: 42,
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Booking Control Desk',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Track customer reservations and update status quickly.',
                        style: TextStyle(color: Colors.white, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: _buildStatsCards(),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterHeaderDelegate(
                selectedFilter: _returnFilter,
                onFilterChanged: (newFilter) {
                  setState(() => _returnFilter = newFilter);
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              sliver: SliverToBoxAdapter(
                child: _returnFilter == 'Recent Bookings'
                    ? StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: RentalService.bookingsStream(),
                        builder: (context, snapshot) {
                          return _buildBookingListContent(context, snapshot);
                        },
                      )
                    : StreamBuilder<QuerySnapshot<Customer>>(
                        stream: _getCustomersQuery().snapshots(),
                        builder: (context, snapshot) {
                          return _buildCustomerListContent(context, snapshot);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEntryForm,
        backgroundColor: AppColors.ember,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business),
        label: const Text('New Entry'),
      ),
    );
  }

  Query<Customer> _getCustomersQuery() {
    Query<Customer> query = _customersCollection.orderBy(
      'sDate',
      descending: true,
    );
    if (_returnFilter == 'Returned') {
      query = query.where(
        'vehicleHandover.returnStatus',
        isEqualTo: 'Returned',
      );
    }
    return query;
  }

  Widget _buildBookingListContent(
    BuildContext context,
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    final docs = snapshot.data?.docs ?? [];
    if (docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No recent bookings available.',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return Card(
          child: ListTile(
            title: Text(doc.data()['customerName'] ?? 'Booking'),
          ),
        );
      },
    );
  }

  Widget _buildCustomerListContent(
    BuildContext context,
    AsyncSnapshot<QuerySnapshot<Customer>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    if (snapshot.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Error: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    var docs = snapshot.data?.docs ?? [];
    if (docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No customer entries available.',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    if (_returnFilter == 'Pending') {
      docs = docs.where((doc) {
        final customer = doc.data();
        return customer.vehicleHandover?['returnStatus'] != 'Returned';
      }).toList();
    }

    if (docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No pending customer entries found.',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final customer = docs[index].data();
        return _CustomerEntryCard(
          customer: customer,
          onStatusChange: _updateReturnStatus,
        );
      },
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<QuerySnapshot<Customer>>(
      stream: _customersCollection.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 80);
        }
        final customerDocs = snapshot.data!.docs;

        final pendingReturns = customerDocs.where((d) {
          final handover = d.data().vehicleHandover;
          return handover?['returnStatus'] != 'Returned';
        }).length;
        final totalReturned = customerDocs.length - pendingReturns;

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                count: pendingReturns,
                label: 'Return Pending',
                icon: Icons.schedule,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                count: totalReturned,
                label: 'Total Returned',
                icon: Icons.check_circle,
                color: AppColors.mint,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  _FilterHeaderDelegate({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: selectedFilter == 'All',
                  onTap: () => onFilterChanged('All'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Return Pending',
                  isSelected: selectedFilter == 'Pending',
                  onTap: () => onFilterChanged('Pending'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Returned',
                  isSelected: selectedFilter == 'Returned',
                  onTap: () => onFilterChanged('Returned'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Recent Bookings',
                  isSelected: selectedFilter == 'Recent Bookings',
                  onTap: () => onFilterChanged('Recent Bookings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            selectedFilter == 'Recent Bookings' ? 'Recent Bookings' : 'Customer Entries',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 💡 Extent હાઇટ 120 કરી દીધી છે જેથી હવે ક્યારેય ઓવરફ્લો એરર નહીં આવે
  @override
  double get maxExtent => 120;

  @override
  double get minExtent => 120;

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) {
    return selectedFilter != oldDelegate.selectedFilter;
  }
}

class _CustomerEntryCard extends StatelessWidget {
  final Customer customer;
  final Function(String custCode, String status)? onStatusChange;

  const _CustomerEntryCard({required this.customer, this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final returnStatus = customer.vehicleHandover?['returnStatus'] ?? 'Pending';
    final isReturned = returnStatus == 'Returned';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.ember.withAlpha(25),
                child: const Icon(Icons.person, color: AppColors.ember, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name.isNotEmpty ? customer.name : 'Customer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Code: ${customer.custCode}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  customer.vehicleName.isNotEmpty ? customer.vehicleName : 'Vehicle',
                  style: const TextStyle(
                    color: AppColors.ember,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _ReturnStatusBadge(status: returnStatus),
            ],
          ),

          const SizedBox(height: 14),

          // Dates & Days Row
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 15, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  customer.returnDate.isNotEmpty
                      ? '${customer.sDate} - ${customer.returnDate}'
                      : customer.sDate,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.access_time_filled, size: 15, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                '${customer.days.isNotEmpty ? customer.days : "0"} days',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Amount & Rate Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '₹ ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    customer.billAmount.isNotEmpty ? customer.billAmount : "0",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Text(
                'Rate: ₹${customer.rate.isNotEmpty ? customer.rate : "0"}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 8),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChallanEntryScreen(custCode: customer.custCode),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(color: AppColors.ember, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoicePreviewScreen(custCode: customer.custCode),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Invoice',
                  style: TextStyle(color: AppColors.ember, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              if (!isReturned)
                TextButton(
                  onPressed: () {
                    if (onStatusChange != null) {
                      onStatusChange!(customer.custCode, 'Returned');
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Mark Returned',
                    style: TextStyle(color: AppColors.ember, fontWeight: FontWeight.bold),
                  ),
                ),
              if (isReturned)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentRecordScreen(custCode: customer.custCode),
                      ),
                    );
                  },
                  icon: const Icon(Icons.currency_rupee, size: 14),
                  label: const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.ember,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Compact padding
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.ember : Colors.white.withAlpha(200),
        ),
      ),
      showCheckmark: false,
      onSelected: (_) => onTap(),
    );
  }
}

class _ReturnStatusBadge extends StatelessWidget {
  final String status;

  const _ReturnStatusBadge({this.status = 'Pending'});

  Color get _badgeColor {
    return status == 'Returned' ? AppColors.mint : AppColors.amber;
  }

  IconData get _icon {
    return status == 'Returned' ? Icons.check_circle : Icons.schedule;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _badgeColor.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _badgeColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: _badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}