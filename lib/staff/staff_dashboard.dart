import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/transportation_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/rental_service.dart';
import '../widgets/user_app_bar_title.dart';
import '../theme/app_theme.dart';
import '../widgets/app_settings_menu.dart';
import 'challan_form.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final _customersCollection = FirebaseFirestore.instance.collection('customers');

  void _openEntryForm() {
    ChallanForm.show(context);
  }

  void _openEditForm(String custCode) async {
    final doc = await _customersCollection.doc(custCode).get();
    if (doc.exists) {
      final data = doc.data()!;
      final transportationData = data['transportation'] != null
          ? Transportation.fromMap(Map<String, dynamic>.from(data['transportation']))
          : null;

      await ChallanForm.showForEdit(
        context,
        custCode: custCode,
        partyName: data['partyName'] ?? '',
        address: data['address'] ?? '',
        address2: data['address2'] ?? '',
        landmark: data['landmark'] ?? '',
        area: data['area'] ?? '',
        city: data['city'] ?? '',
        pincode: data['pincode'] ?? '',
        smsPhone: data['smsPhone'] ?? '',
        reference: data['reference'] ?? '',
        aadharNo: data['aadharNo'] ?? '',
        licenceNo: data['licenceNo'] ?? '',
        remark: data['remark'] ?? '',
        fineRs: data['fineRs'] ?? '',
        returnDate: data['returnDate'] ?? '',
        vehicleName: data['vehicleName'] ?? '',
        days: data['days'] ?? '',
        rate: data['rate'] ?? '',
        billAmount: data['billAmount'] ?? '',
        pickupRs: data['pickupRs'] ?? '',
        dropRs: data['dropRs'] ?? '',
        extraP: data['extraP'] ?? '',
        helmet: data['helmet'] ?? '',
        transportation: transportationData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const UserAppBarTitle(fallbackTitle: 'Staff'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
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
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AppTheme.softCard(),
                      child: StreamBuilder(
                        stream: RentalService.bookingsStream(),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];
                          final open = docs.where((d) => (d.data()['status'] as String?) == 'Pending').length;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.pending_actions, color: AppColors.amber, size: 24),
                              const SizedBox(height: 10),
                              Text('$open', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink)),
                              const SizedBox(height: 4),
                              const Text('Open', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AppTheme.softCard(),
                      child: StreamBuilder(
                        stream: RentalService.bookingsStream(),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];
                          final confirmed = docs.where((d) => (d.data()['status'] as String?) == 'Confirmed').length;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.verified, color: AppColors.mint, size: 24),
                              const SizedBox(height: 10),
                              Text('$confirmed', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink)),
                              const SizedBox(height: 4),
                              const Text('Confirmed', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AppTheme.softCard(),
                      child: StreamBuilder(
                        stream: RentalService.bookingsStream(),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];
                          final checkedIn = docs.where((d) => (d.data()['status'] as String?) == 'Checked In').length;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.login, color: AppColors.sky, size: 24),
                              const SizedBox(height: 10),
                              Text('$checkedIn', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink)),
                              const SizedBox(height: 4),
                              const Text('Checked In', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                            ],
                          );
                        },
                      ),
                    ),
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
                stream: _customersCollection.orderBy('sDate', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(12), child: SizedBox(height:24,width:24,child:CircularProgressIndicator(strokeWidth:2.5))));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No customer entries available.', style: TextStyle(color: AppColors.muted)),
                    );
                  }
                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data();
                      return _CustomerEntryCard(
                        custCode: doc.id,
                        partyName: data['partyName'] ?? '',
                        vehicleName: data['vehicleName'] ?? '',
                        sDate: data['sDate'] ?? '',
                        returnDate: data['returnDate'] ?? '',
                        days: data['days'] ?? '',
                        rate: data['rate'] ?? '',
                        billAmount: data['billAmount'] ?? '',
                      );
                    }).toList(),
                  );
                },
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
                    return const Center(child: Padding(padding: EdgeInsets.all(12), child: SizedBox(height:24,width:24,child:CircularProgressIndicator(strokeWidth:2.5))));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No bookings available.', style: TextStyle(color: AppColors.muted)),
                    );
                  }
                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data();
                      final customerName = (data['customerName'] as String?) ?? (data['customer'] as String?) ?? 'Customer';
                      final vehicleName = (data['vehicleName'] as String?) ?? 'Vehicle';
                      final start = data['startAt'] is Timestamp ? (data['startAt'] as Timestamp).toDate() : null;
                      final end = data['endAt'] is Timestamp ? (data['endAt'] as Timestamp).toDate() : null;
                      final period = start != null && end != null ? '${start.day}-${start.month} - ${end.day}-${end.month}' : (data['rentalPeriod'] as String?) ?? '';
                      final status = (data['status'] as String?) ?? 'Pending';
                      final total = ((data['totalAmount'] as num?)?.toInt() ?? 0).toString();

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
              const SizedBox(height: 92),
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
}

class _CustomerEntryCard extends StatelessWidget {
  final String custCode;
  final String partyName;
  final String vehicleName;
  final String sDate;
  final String returnDate;
  final String days;
  final String rate;
  final String billAmount;

  const _CustomerEntryCard({
    required this.custCode,
    required this.partyName,
    required this.vehicleName,
    required this.sDate,
    required this.returnDate,
    required this.days,
    required this.rate,
    required this.billAmount,
  });

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
                      partyName.isNotEmpty ? partyName : 'Customer',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: $custCode',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(vehicleName.isNotEmpty ? vehicleName : 'Vehicle'),
                backgroundColor: AppColors.ember.withValues(alpha: 0.12),
                labelStyle: const TextStyle(
                  color: AppColors.ember,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 18, color: AppColors.muted),
              const SizedBox(width: 8),
              Text('$sDate - $returnDate', style: const TextStyle(color: AppColors.muted)),
              const SizedBox(width: 16),
              const Icon(Icons.timer, size: 18, color: AppColors.muted),
              const SizedBox(width: 8),
              Text('$days days', style: const TextStyle(color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.currency_rupee, size: 18, color: AppColors.muted),
              const SizedBox(width: 8),
              Text(billAmount.isNotEmpty ? billAmount : '0', style: const TextStyle(color: AppColors.muted)),
              const SizedBox(width: 16),
              const Text('Rate: ', style: TextStyle(color: AppColors.muted)),
              Text(rate.isNotEmpty ? rate : '0', style: const TextStyle(color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  context.findAncestorStateOfType<_StaffDashboardState>()?._openEditForm(custCode);
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ember,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Removed sample static panels; values now come from Firestore streams in the UI.

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
