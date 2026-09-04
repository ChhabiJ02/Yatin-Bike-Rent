import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:street_bike_rental/admin/customer_bookings_screen.dart';
import 'package:street_bike_rental/admin/customer_list_screen.dart';
import 'package:street_bike_rental/admin/profile_screen.dart';
import 'package:street_bike_rental/admin/vehicle_management_screen.dart';

import '../screens/login_screen.dart';
import '../screens/challan_entry_screen.dart';
import '../services/auth_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '').trim() ?? '') ?? 0.0;
  }

  double _pendingAmount(Map<String, dynamic> data) {
    final billAmount = _parseAmount(data['billAmount']);
    final payment = data['payment'];
    final paymentMap = payment is Map
        ? Map<String, dynamic>.from(payment)
        : <String, dynamic>{};
    final paidAmount = _parseAmount(
      paymentMap['paymentAmount'] ??
          paymentMap['paidAmount'] ??
          data['paidAmount'] ??
          data['paymentAmount'],
    );
    return (billAmount - paidAmount).clamp(0.0, double.infinity).toDouble();
  }

  // Today's Date Comparison Helper Function
  bool _isToday(dynamic dateField) {
    if (dateField == null) return false;
    DateTime? date;

    if (dateField is Timestamp) {
      date = dateField.toDate();
    } else if (dateField is String) {
      try {
        // Handles 'dd-MM-yyyy HH:mm:ss' format
        date = DateFormat('dd-MM-yyyy HH:mm:ss').parse(dateField);
      } catch (e) {
        // Fallback for ISO 8601 format
        date = DateTime.tryParse(dateField);
      }
    } else if (dateField is DateTime) {
      date = dateField;
    }

    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF111111);
    const darkGreenGradient = Color(0xFF000000);
    const bgBackgroundColor = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgBackgroundColor,

      // ---------------- 🟩 1. SIDE DRAWER ----------------
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen, darkGreenGradient],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: primaryGreen, size: 40),
              ),
              accountName: StreamBuilder(
                stream: AuthService.currentUserProfileStream(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final name = (data?['name'] as String?)?.trim();
                  return Text(
                    name?.isNotEmpty == true ? name! : 'Admin User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              accountEmail: Text(
                AuthService.currentUser?.email ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: primaryGreen),
              title: const Text(
                'My Profile',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context); // Close Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                await AuthService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),

      // ---------------- 🟩 2. APP BAR ----------------
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
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
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: Colors.white,
                  size: 28,
                ),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- 🟩 4. DYNAMIC STAT CARDS ----------------
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
                                  builder: (_) =>
                                      const VehicleManagementScreen(),
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
                            .collection('customers')
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
                                  builder: (_) =>
                                      const CustomerBookingsScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 8),

                      // Card 3: Customers Count
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final docs = snapshot.data?.docs ?? [];
                          final customerCount = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final role = data['role']
                                ?.toString()
                                .toLowerCase()
                                .trim();
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
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ---------------- 🟩 5. FINANCIAL CARDS ----------------
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('customers')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildFinancialCard(
                                title: "Today's Collection",
                                amount: "...",
                                titleColor: primaryGreen,
                                amountColor: primaryGreen,
                                bgColor: const Color(0xFFF0FDF4),
                              );
                            }
                            if (snapshot.hasError) {
                              return _buildFinancialCard(
                                title: "Today's Collection",
                                amount: "Error",
                                titleColor: primaryGreen,
                                amountColor: primaryGreen,
                                bgColor: const Color(0xFFF0FDF4),
                              );
                            }

                            double totalCollection = 0.0;
                            final docs = snapshot.data?.docs ?? [];
                            for (var doc in docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final createdAt = data['createdAt'];
                              final sDate = data['sDate'];

                              // Check if the booking/payment is for today
                              if (_isToday(createdAt) || _isToday(sDate)) {
                                final paymentMap =
                                    data['payment'] as Map<String, dynamic>?;
                                if (paymentMap != null) {
                                  final paymentAmountStr =
                                      paymentMap['paymentAmount'] as String?;
                                  if (paymentAmountStr != null &&
                                      paymentAmountStr.isNotEmpty) {
                                    totalCollection +=
                                        double.tryParse(paymentAmountStr) ??
                                            0.0;
                                  }
                                }
                              }
                            }

                            // Format the total collection amount
                            final formatter = NumberFormat('#,##0', 'en_IN');
                            final formattedAmount =
                                "₹ ${formatter.format(totalCollection)}";

                            return _buildFinancialCard(
                              title: "Today's Collection",
                              amount: formattedAmount,
                              titleColor: primaryGreen,
                              amountColor: primaryGreen,
                              bgColor: const Color(0xFFF0FDF4),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('customers')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildFinancialCard(
                                title: "Pending Payments",
                                amount: "...",
                                subtitle: "Loading...",
                                titleColor: const Color(0xFFEA580C),
                                amountColor: const Color(0xFFEA580C),
                                bgColor: const Color(0xFFFFF7ED),
                              );
                            }
                            if (snapshot.hasError) {
                              return _buildFinancialCard(
                                title: "Pending Payments",
                                amount: "Error",
                                subtitle: "Could not calculate",
                                titleColor: const Color(0xFFEA580C),
                                amountColor: const Color(0xFFEA580C),
                                bgColor: const Color(0xFFFFF7ED),
                              );
                            }

                            double totalPendingAmount = 0.0;
                            int pendingCount = 0;
                            final docs = snapshot.data?.docs ?? [];

                            for (var doc in docs) {
                              final data = doc.data() as Map<String, dynamic>;

                                final pending = _pendingAmount(data);

                              if (pending > 0) {
                                totalPendingAmount += pending;
                                pendingCount++;
                              }
                            }

                            // Format the total pending amount
                            final formatter = NumberFormat('#,##0', 'en_IN');
                            final formattedAmount =
                                "₹ ${formatter.format(totalPendingAmount)}";

                            return _buildFinancialCard(
                              title: "Pending Payments",
                              amount: formattedAmount,
                              subtitle: "$pendingCount Pending",
                              titleColor: const Color(0xFFEA580C),
                              amountColor: const Color(0xFFEA580C),
                              bgColor: const Color(0xFFFFF7ED),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CustomerBookingsScreen(
                                      filterType: 'pending_payments',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ---------------- 🟩 6. TODAY OVERVIEW ----------------
                  const Text(
                    'Today Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Today's Bookings
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('customers')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Display a loading indicator while fetching data
                        return _buildOverviewTile(
                          icon: Icons.calendar_today_outlined,
                          title: "Today's Bookings",
                          count: "...",
                          onTap: () {},
                        );
                      }
                      if (snapshot.hasError) {
                        // Display an error message if something goes wrong
                        return _buildOverviewTile(
                          icon: Icons.error_outline,
                          title: "Today's Bookings",
                          count: "!",
                          onTap: () {},
                        );
                      }

                      // When data is loaded, display the count
                      final docs = snapshot.data?.docs ?? [];
                      final todayBookingsCount = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _isToday(data['sDate']);
                      }).length;

                      return _buildOverviewTile(
                        icon: Icons.calendar_today_outlined,
                        title: "Today's Bookings",
                        count: "$todayBookingsCount",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CustomerBookingsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Available Vehicles: total vehicles - active rentals
                  // An active rental = returnStatus NOT in {'completed', 'returned'}
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('vehicles')
                        .snapshots(),
                    builder: (context, vehiclesSnap) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('customers')
                            .snapshots(),
                        builder: (context, customersSnap) {
                          if (vehiclesSnap.connectionState ==
                                  ConnectionState.waiting ||
                              customersSnap.connectionState ==
                                  ConnectionState.waiting) {
                            return _buildOverviewTile(
                              icon: Icons.two_wheeler_outlined,
                              title: 'Available Vehicles',
                              count: '...',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const VehicleManagementScreen(),
                                  ),
                                );
                              },
                            );
                          }
                          if (vehiclesSnap.hasError ||
                              customersSnap.hasError) {
                            return _buildOverviewTile(
                              icon: Icons.error_outline,
                              title: 'Available Vehicles',
                              count: '!',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const VehicleManagementScreen(),
                                  ),
                                );
                              },
                            );
                          }

                          final totalVehicles =
                              vehiclesSnap.data?.docs.length ?? 0;
                          final customers =
                              customersSnap.data?.docs ?? [];
                          int activeRentals = 0;
                          for (final doc in customers) {
                            final data =
                                doc.data() as Map<String, dynamic>;
                            final handover =
                                data['vehicleHandover']
                                    as Map<String, dynamic>?;
                            final rawStatus = (handover?['returnStatus'] ?? '')
                                .toString()
                                .trim()
                                .toLowerCase();
                            final isActive = rawStatus != 'returned' &&
                                rawStatus != 'completed';
                            if (isActive) activeRentals++;
                          }
                          final available =
                              (totalVehicles - activeRentals).clamp(0, 1 << 30);

                          return _buildOverviewTile(
                            icon: Icons.two_wheeler_outlined,
                            title: 'Available Vehicles',
                            count: '$available',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const VehicleManagementScreen(),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Today's Returns (original block)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('customers')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildOverviewTile(
                          icon: Icons.exit_to_app_rounded,
                          title: "Today's Returns",
                          count: "...",
                          onTap: () {},
                        );
                      }
                      if (snapshot.hasError) {
                        return _buildOverviewTile(
                          icon: Icons.error_outline,
                          title: "Today's Returns",
                          count: "!",
                          onTap: () {},
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      final todayReturnsCount = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final handover =
                            data['vehicleHandover'] as Map<String, dynamic>?;

                        // returnStatus 'Returned' હોવું જોઈએ
                        final isReturned =
                            handover?['returnStatus'] == 'Returned';

                        // ૧. અગ્રતા: vehicleReturnDate તારીખ ચકાસો
                        // ૨. જો તે ખાલી હોય તો document ની સાચી createdAt / sDate ચકાસો
                        final returnDate = handover?['vehicleReturnDate'];
                        final fallbackDate =
                            data['createdAt'] ?? data['sDate'];

                        final isReturnToday = _isToday(
                          (returnDate != null && returnDate.toString().isNotEmpty)
                              ? returnDate
                              : fallbackDate,
                        );

                        return isReturned && isReturnToday;
                      }).length;

                      return _buildOverviewTile(
                        icon: Icons.exit_to_app_rounded,
                        title: "Today's Returns",
                        count: "$todayReturnsCount",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerBookingsScreen(
                                filterType: 'todays_returns',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  const SizedBox(height: 20),

                  // ---------------- 🟩 7. NEW BOOKING BUTTON ----------------
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChallanEntryScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
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

  // 💡 Stat Card Builder
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

  // 💡 Financial Card Builder
  Widget _buildFinancialCard({
    required String title,
    required String amount,
    required Color titleColor,
    required Color amountColor,
    required Color bgColor,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: titleColor.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
      ),
    );
  }

  // 💡 Overview Tile Builder
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 2,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF111111), size: 20),
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