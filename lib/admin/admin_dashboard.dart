import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:street_bike_rental/admin/vehicle_management_screen.dart';
import 'package:street_bike_rental/admin/staff_management_screen.dart';
import 'package:street_bike_rental/admin/customer_bookings_screen.dart';
import 'package:street_bike_rental/admin/customer_list_screen.dart';

import '../services/auth_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // Today's Date Comparison Helper Function
  bool _isToday(dynamic dateField) {
    if (dateField == null) return false;
    DateTime? date;

    if (dateField is Timestamp) {
      date = dateField.toDate();
    } else if (dateField is String) {
      date = DateTime.tryParse(dateField);
    } else if (dateField is DateTime) {
      date = dateField;
    }

    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F8A4B);
    const darkGreenGradient = Color(0xFF0B6B3A);
    const bgBackgroundColor = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () {},
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined,
                    color: Colors.white, size: 28),
                onPressed: () {},
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---------------- 1. GREEN HERO HEADER ----------------
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen, darkGreenGradient],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder(
                        stream: AuthService.currentUserProfileStream(),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.data();
                          final name = (data?['name'] as String?)?.trim();
                          return Text(
                            name?.isNotEmpty == true ? name! : 'Admin',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Have a great day!',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                  Positioned(
                    right: -10,
                    bottom: 0,
                    child: Image.network(
                      'https://png.pngtree.com/png-vector/20250913/ourmid/pngtree-white-motor-scooter-with-vintage-classic-design-and-chrome-metal-details-png-image_17421023.webp',
                      height: 150,
                      width: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.two_wheeler,
                              size: 100, color: Colors.white24),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- 2. EXACT Dynamic Cards (No Subtitle) ----------------
                  Row(
                    children: [
                      // Card 1: Vehicles Count
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('vehicles')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final totalVehicles = snapshot.data?.docs.length ?? 0;

                          return _buildTopStatCard(
                            title: 'Vehicles',
                            value: '$totalVehicles',
                            icon: Icons.pedal_bike,
                            iconColor: primaryGreen,
                            bgColor: const Color(0xFFF0FDF4),
                            valueColor: primaryGreen,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VehicleManagementScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 8),

                      // Card 2: Bookings Count
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('bookings')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final totalBookings = snapshot.data?.docs.length ?? 0;

                          return _buildTopStatCard(
                            title: 'Bookings',
                            value: '$totalBookings',
                            icon: Icons.receipt_long_outlined,
                            iconColor: const Color(0xFFEA580C),
                            bgColor: const Color(0xFFFFF7ED),
                            valueColor: const Color(0xFFEA580C),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CustomerBookingsScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 8),

                      // Card 3: Customers Count (role == 'customer')
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];
                          final customerCount = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final role = data['role']?.toString().toLowerCase().trim();
                            return role == 'customer' || role == 'user';
                          }).length;

                          return _buildTopStatCard(
                            title: 'Customers',
                            value: '$customerCount',
                            icon: Icons.group_outlined,
                            iconColor: const Color(0xFF2563EB),
                            bgColor: const Color(0xFFEFF6FF),
                            valueColor: const Color(0xFF2563EB),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CustomerListScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 8),

                      // Card 4: Staff Count (role == 'staff')
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];
                          final staffCount = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final role = data['role']?.toString().toLowerCase().trim();
                            return role == 'staff' || role == 'admin';
                          }).length;

                          return _buildTopStatCard(
                            title: 'Staff',
                            value: '$staffCount',
                            icon: Icons.badge_outlined,
                            iconColor: const Color(0xFF7C3AED),
                            bgColor: const Color(0xFFF5F3FF),
                            valueColor: const Color(0xFF7C3AED),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StaffManagementScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ---------------- 3. FINANCIAL CARDS ----------------
                  Row(
                    children: [
                      Expanded(
                        child: _buildFinancialCard(
                          title: "Today's Collection",
                          amount: "₹18,500",
                          titleColor: primaryGreen,
                          amountColor: primaryGreen,
                          bgColor: const Color(0xFFF0FDF4),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildFinancialCard(
                          title: "Pending Payments",
                          amount: "₹7,200",
                          titleColor: const Color(0xFFEA580C),
                          amountColor: const Color(0xFFEA580C),
                          bgColor: const Color(0xFFFFF7ED),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ---------------- 4. TODAY OVERVIEW ----------------
                  const Text(
                    'Today Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dynamic Today's Bookings
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      final todayBookingsCount = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _isToday(data['createdAt']) ||
                            _isToday(data['bookingDate']) ||
                            _isToday(data['date']);
                      }).length;

                      return _buildOverviewTile(
                        icon: Icons.calendar_today_outlined,
                        title: "Today's Bookings",
                        count: "$todayBookingsCount",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerBookingsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Dynamic Today's Returns
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      final todayReturnsCount = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _isToday(data['returnDate']) ||
                            _isToday(data['endDate']) ||
                            _isToday(data['dropOffDate']);
                      }).length;

                      return _buildOverviewTile(
                        icon: Icons.exit_to_app_rounded,
                        title: "Today's Returns",
                        count: "$todayReturnsCount",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerBookingsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ---------------- 5. NEW BOOKING BUTTON ----------------
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add, color: Colors.white, size: 24),
                      label: const Text(
                        'New Booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💡 Clean Stat Card Builder (No Subtitle)
  Widget _buildTopStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required String amount,
    required Color titleColor,
    required Color amountColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'View details',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 10, color: titleColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTile({
    required IconData icon,
    required String title,
    required String count,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0F8A4B), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}