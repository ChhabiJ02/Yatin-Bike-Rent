import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          // Check if the widget is still in the tree
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
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const UserAppBarTitle(fallbackTitle: 'Staff'),
        actions: const [AppSettingsMenu()],
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
                      color: AppColors.ember.withValues(alpha: 0.24),
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
              const SizedBox(height: 20),
              _buildStatsCards(),
              const SizedBox(height: 20),
              Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _returnFilter == 'All',
                    onTap: () => setState(() => _returnFilter = 'All'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Return Pending',
                    isSelected: _returnFilter == 'Pending',
                    onTap: () => setState(() => _returnFilter = 'Pending'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Returned',
                    isSelected: _returnFilter == 'Returned',
                    onTap: () => setState(() => _returnFilter = 'Returned'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Customer Entries',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              StreamBuilder(
                stream: _getFilteredCustomerStream(),
                builder: _buildCustomerList,
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Bookings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              StreamBuilder(
                stream: RentalService.bookingsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No bookings available.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    );
                  }
                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data();
                      final customerName =
                          (data['customerName'] as String?) ??
                          (data['customer'] as String?) ??
                          'Customer';
                      final vehicleName =
                          (data['vehicleName'] as String?) ?? 'Vehicle';
                      final start = data['startAt'] is Timestamp
                          ? (data['startAt'] as Timestamp).toDate()
                          : null;
                      final end = data['endAt'] is Timestamp
                          ? (data['endAt'] as Timestamp).toDate()
                          : null;
                      final period = start != null && end != null
                          ? '${start.day}-${start.month} - ${end.day}-${end.month}'
                          : (data['rentalPeriod'] as String?) ?? '';
                      final status = (data['status'] as String?) ?? 'Pending';
                      final total =
                          ((data['totalAmount'] as num?)?.toInt() ?? 0)
                              .toString();

                      return _BookingCard(
                        booking: Booking(
                          id: doc.id,
                          customerName: customerName,
                          vehicleName: vehicleName,
                          rentalPeriod: period,
                          status: status,
                          totalAmount: int.tryParse(total) ?? 0,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 100), // Padding for the FAB
            ],
          ),
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

  Stream<QuerySnapshot<Customer>> _getFilteredCustomerStream() {
    Query<Customer> query = _customersCollection.orderBy(
      'sDate',
      descending: true,
    );
    if (_returnFilter == 'Returned') {
      query = query.where(
        'vehicleHandover.returnStatus',
        isEqualTo: 'Returned',
      );
    } else if (_returnFilter == 'Pending') {
      // Firestore doesn't support '!=' queries efficiently.
      // We can query for 'is not null' if the field is absent in returned docs,
      // or filter client-side as a fallback. Here we will filter client-side.
    }
    return query.snapshots();
  }

  Widget _buildCustomerList(
    BuildContext context,
    AsyncSnapshot<QuerySnapshot<Customer>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (snapshot.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Error: ${snapshot.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    var docs = snapshot.data?.docs ?? [];
    if (docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No customer entries available.',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    // Client-side filter for 'Pending'
    if (_returnFilter == 'Pending') {
      docs = docs.where((doc) {
        final customer = doc.data();
        return customer.vehicleHandover?['returnStatus'] != 'Returned';
      }).toList();
    }

    if (docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No pending customer entries found.',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return Column(
      children: docs.map((doc) {
        final customer = doc.data();
        return _CustomerEntryCard(
          customer: customer,
          onStatusChange: _updateReturnStatus,
        );
      }).toList(),
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: Future.wait([
        RentalService.bookingsStream().first,
        _customersCollection.snapshots().first,
      ]).asStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 150); // Placeholder height
        }
        final bookingDocs = snapshot.data![0].docs;
        final customerDocs = snapshot.data![1].docs;

        final openBookings = bookingDocs
            .where((d) => (d.data() as Map)['status'] == 'Pending')
            .length;
        final confirmedBookings = bookingDocs
            .where((d) => (d.data() as Map)['status'] == 'Confirmed')
            .length;
        final checkedInBookings = bookingDocs
            .where((d) => (d.data() as Map)['status'] == 'Checked In')
            .length;

        final pendingReturns = customerDocs.where((d) {
          final handover = (d.data() as Customer).vehicleHandover;
          return handover?['returnStatus'] != 'Returned';
        }).length;
        final totalReturned = customerDocs.length - pendingReturns;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    count: openBookings,
                    label: 'Open',
                    icon: Icons.pending_actions,
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    count: confirmedBookings,
                    label: 'Confirmed',
                    icon: Icons.verified,
                    color: AppColors.mint,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    count: checkedInBookings,
                    label: 'Checked In',
                    icon: Icons.login,
                    color: AppColors.sky,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
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
            ),
          ],
        );
      },
    );
  }
}

class _CustomerEntryCard extends StatelessWidget {
  final Customer customer;
  final Function(String custCode, String status)? onStatusChange;

  const _CustomerEntryCard({required this.customer, this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.ember.withValues(alpha: 0.16),
                child: const Icon(Icons.person, color: AppColors.ember),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name.isNotEmpty ? customer.name : 'Customer',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${customer.custCode}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  customer.vehicleName.isNotEmpty
                      ? customer.vehicleName
                      : 'Vehicle',
                ),
                backgroundColor: AppColors.ember.withValues(alpha: 0.12),
                labelStyle: const TextStyle(
                  color: AppColors.ember,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              _ReturnStatusBadge(
                status: customer.vehicleHandover?['returnStatus'] ?? 'Pending',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                size: 18,
                color: AppColors.muted,
              ),
              const SizedBox(width: 8),
              Text(
                '${customer.sDate} - ${customer.returnDate}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.timer, size: 18, color: AppColors.muted),
              const SizedBox(width: 8),
              Text(
                '${customer.days} days',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.currency_rupee,
                size: 18,
                color: AppColors.muted,
              ),
              const SizedBox(width: 8),
              Text(
                customer.billAmount.isNotEmpty ? customer.billAmount : '0',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(width: 16),
              const Text('Rate: ', style: TextStyle(color: AppColors.muted)),
              Text(
                customer.rate.isNotEmpty ? customer.rate : '0',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Use a Row to make the Wrap take the full width, allowing alignment to work correctly.
          Row(
            children: [
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChallanEntryScreen(custCode: customer.custCode),
                          ),
                        );
                      },
                      child: const Text('Edit'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoicePreviewScreen(
                              custCode: customer.custCode,
                            ),
                          ),
                        );
                      },
                      child: const Text('Invoice'),
                    ),
                    if (customer.vehicleHandover?['returnStatus'] !=
                        'Returned') ...[
                      TextButton(
                        onPressed: () {
                          if (onStatusChange != null) {
                            onStatusChange!(customer.custCode, 'Returned');
                          }
                        },
                        child: const Text('Mark Returned'),
                      ),
                    ],
                    if (customer.vehicleHandover?['returnStatus'] == 'Returned')
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentRecordScreen(
                                custCode: customer.custCode,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.currency_rupee, size: 18),
                        label: const Text('Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mint,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.ember
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.ember
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.muted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _badgeColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _badgeColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: _badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  Color get _statusColor {
    if (booking.status == 'Pending') return AppColors.amber;
    if (booking.status == 'Confirmed') return AppColors.mint;
    return AppColors.sky;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: statusColor.withValues(alpha: 0.16),
                child: Icon(Icons.person, color: statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.vehicleName,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(booking.status),
                backgroundColor: statusColor.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                size: 18,
                color: AppColors.muted,
              ),
              const SizedBox(width: 8),
              Text(
                booking.rentalPeriod,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.currency_rupee,
                size: 18,
                color: AppColors.muted,
              ),
              const SizedBox(width: 8),
              Text(
                '${booking.totalAmount}',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () {}, child: const Text('Details')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () {}, child: const Text('Update')),
            ],
          ),
        ],
      ),
    );
  }
}
