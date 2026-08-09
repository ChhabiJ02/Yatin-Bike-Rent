import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../screens/challan_entry_screen.dart';
import '../screens/invoice_preview_screen.dart';
import '../screens/payment_record_screen.dart';
import '../theme/app_theme.dart';

class CustomerBookingsScreen extends StatefulWidget {
  final String? filterType; // Can be 'todays_bookings' or 'todays_returns'

  const CustomerBookingsScreen({super.key, this.filterType});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = const [
    'All',
    'Return Pending',
    'Returned',
    'Received',
  ];

  final _customersCollection =
      FirebaseFirestore.instance.collection('customers');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper function to check if a given date is today
  bool _isToday(dynamic dateField) {
    if (dateField == null) return false;
    DateTime? date;

    if (dateField is Timestamp) {
      date = dateField.toDate();
    } else if (dateField is String) {
      try {
        // Handles formats like 'dd-MM-yyyy HH:mm:ss' or 'dd-MM-yyyy'
        if (dateField.length > 10) {
          date = DateFormat('dd-MM-yyyy HH:mm:ss').parse(dateField);
        } else {
          date = DateFormat('dd-MM-yyyy').parse(dateField);
        }
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

  void _openEntryForm({String? custCode}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallanEntryScreen(custCode: custCode),
      ),
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

    if (confirmed == true && mounted) {
      try {
        final docRef = _customersCollection.doc(custCode);
        final doc = await docRef.get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          final handover = Map<String, dynamic>.from(data['vehicleHandover'] ?? {});
          handover['returnStatus'] = status;
          await docRef.update({'vehicleHandover': handover});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Vehicle marked as $status')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating status: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine AppBar Title based on the filterType
    String appBarTitle;
    if (widget.filterType == 'todays_bookings') {
      appBarTitle = "Today's Bookings";
    } else if (widget.filterType == 'todays_returns') {
      appBarTitle = "Today's Returns";
    } else if (widget.filterType == 'pending_payments') {
      appBarTitle = "Pending Payments";
    } else {
      appBarTitle = "Customer Bookings";
    }

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          appBarTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conditionally show filter chips only when not in a filtered view
            if (widget.filterType == null)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.ember,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.ember
                                : Colors.white.withAlpha(200),
                          ),
                        ),
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilter = filter);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by Name or Code...',
                  hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withAlpha(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // Customer List Stream
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _customersCollection
                    .orderBy('sDate', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No customer entries found.', style: TextStyle(color: AppColors.muted)),
                    );
                  }

                  // Filter & Convert Documents
                  final customers = snapshot.data!.docs.where((doc) {
                    final customer = Customer.fromFirestore(
                      doc as DocumentSnapshot<Map<String, dynamic>>,
                    );
                    final name = customer.name.toLowerCase();
                    final code = customer.custCode.toLowerCase();

                    // --- Search Filter ---
                    final matchesSearch = _searchQuery.isEmpty ||
                        name.contains(_searchQuery.toLowerCase()) ||
                        code.contains(_searchQuery.toLowerCase());

                    if (!matchesSearch) return false;

                    // --- Pre-defined Filter (from dashboard) ---
                    if (widget.filterType != null) {
                      if (widget.filterType == 'todays_bookings') {
                        return _isToday(customer.createdAt) || _isToday(customer.sDate);
                      }
                      if (widget.filterType == 'todays_returns') {
                        final handover = customer.vehicleHandover;
                        final isReturned = handover?['returnStatus'] == 'Returned';
                        if (!isReturned) return false;

                        final returnDate = handover?['vehicleReturnDate'];
                        final fallbackDate = customer.createdAt ?? customer.sDate;
                        
                        return _isToday(
                          (returnDate != null && returnDate.toString().isNotEmpty)
                              ? returnDate
                              : fallbackDate,
                        );
                      }
                      if (widget.filterType == 'pending_payments') {
                        final billAmountStr = customer.billAmount;
                        final double billAmount =
                            double.tryParse(billAmountStr) ?? 0.0;

                        double paymentAmount = 0.0;
                        final paymentMap = customer.payment;
                        if (paymentMap != null) {
                          final paStr = paymentMap['paymentAmount'] as String?;
                          paymentAmount = double.tryParse(paStr ?? '') ?? 0.0;
                        }

                        final double pending = billAmount - paymentAmount;
                        return pending > 0;
                      }
                    }

                    // --- Chip Filter (only if no pre-defined filter) ---
                    final returnStatus = customer.vehicleHandover?['returnStatus'] ?? 'Pending';
                    final paymentStatus = customer.vehicleHandover?['paymentStatus'] ?? '';
                    
                    bool matchesChipFilter = true;
                    if (_selectedFilter == 'Return Pending') {
                      matchesChipFilter = returnStatus != 'Returned';
                    } else if (_selectedFilter == 'Returned') {
                      matchesChipFilter = returnStatus == 'Returned';
                    } else if (_selectedFilter == 'Received') {
                      matchesChipFilter = paymentStatus == 'Received';
                    }
                    
                    return matchesChipFilter;

                  }).toList();

                  if (customers.isEmpty) {
                    return const Center(
                      child: Text('No matching entries found.', style: TextStyle(color: AppColors.muted)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final doc = customers[index];
                      final customer = Customer.fromFirestore(
                        doc as DocumentSnapshot<Map<String, dynamic>>,
                      );
                      return _CustomerEntryCard(
                        customer: customer,
                        onStatusChange: _updateReturnStatus,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntryForm(),
        label: const Text('New Entry', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_business),
        backgroundColor: AppColors.ember,
        foregroundColor: Colors.white,
      ),
    );
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