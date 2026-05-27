import 'package:flutter/material.dart';
import '../models/booking.dart';
import 'challan_form.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

// Challan form moved to lib/staff/challan_form.dart

class _StaffDashboardState extends State<StaffDashboard> {
  // Challan storage moved to challan_form.dart

  static const _bookings = [
    Booking(
      id: 'b1',
      customerName: 'Anita Sharma',
      vehicleName: 'City Cruiser',
      rentalPeriod: 'May 22 - May 23',
      status: 'Confirmed',
      totalAmount: 300,
    ),
    Booking(
      id: 'b2',
      customerName: 'Ravi Patel',
      vehicleName: 'Electric Assist',
      rentalPeriod: 'May 24 - May 26',
      status: 'Pending',
      totalAmount: 1300,
    ),
    Booking(
      id: 'b3',
      customerName: 'Meera Jain',
      vehicleName: 'Mountain Rider',
      rentalPeriod: 'May 27 - May 28',
      status: 'Checked In',
      totalAmount: 1000,
    ),
  ];

  void _openEntryForm() {
    ChallanForm.show(context);
  }

  // Challan form logic moved to challan_form.dart

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Staff Booking Management',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Track customer reservations and update status quickly.',
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _MiniPanel(title: 'Open', value: '8', color: Colors.orange),
                _MiniPanel(title: 'Confirmed', value: '14', color: Colors.teal),
                _MiniPanel(title: 'Checked In', value: '5', color: Colors.blue),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Bookings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._bookings.map((booking) => _BookingCard(booking: booking)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: ElevatedButton.icon(
            onPressed: _openEntryForm,
            icon: const Icon(Icons.add_business),
            label: const Text('New Entry'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPanel extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MiniPanel({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFE8F8F5),
                  child: Icon(Icons.person, color: Color(0xFF0B7E76)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(booking.vehicleName, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                Chip(
                  label: Text(booking.status),
                  backgroundColor: booking.status == 'Pending'
                      ? Colors.orange.shade50
                      : booking.status == 'Confirmed'
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
                  labelStyle: TextStyle(
                    color: booking.status == 'Pending'
                        ? Colors.orange.shade800
                        : booking.status == 'Confirmed'
                            ? Colors.green.shade800
                            : Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 18, color: Colors.black54),
                const SizedBox(width: 8),
                Text(booking.rentalPeriod, style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.currency_rupee, size: 18, color: Colors.black54),
                const SizedBox(width: 8),
                Text('${booking.totalAmount}', style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
