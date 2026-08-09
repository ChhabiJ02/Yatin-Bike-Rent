import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:street_bike_rental/models/customer_documents.dart';
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primaryGreen,
        elevation: 1,
        title: Text(
          appBarTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: _buildHeader(context),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conditionally show filter chips only when not in a filtered view
            if (widget.filterType == null)
              _buildFilterChips(),

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
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.muted)),
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
                    final vehicleNumber = (customer.vehicleHandover?['vehicleNumber'] ?? '').toLowerCase();
                    final name = customer.name.toLowerCase();
                    final code = customer.custCode.toLowerCase();

                    // --- Search Filter ---
                    final matchesSearch = _searchQuery.isEmpty ||
                        name.contains(_searchQuery.toLowerCase()) ||
                        code.contains(_searchQuery.toLowerCase());
                        // || vehicleNumber.contains(_searchQuery.toLowerCase());
                        
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

  PreferredSize _buildHeader(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        color: AppColors.primaryGreen,
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search by Name, Code, or Vehicle No...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.15),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
              selected: isSelected,
              selectedColor: AppColors.primaryGreen,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
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
    );
  }
}

class _CustomerEntryCard extends StatelessWidget {
  final Customer customer;
  final Function(String custCode, String status)? onStatusChange;

  const _CustomerEntryCard({required this.customer, this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    // --- Data Extraction and Null Safety ---
    final returnStatus = customer.vehicleHandover?['returnStatus'] ?? 'Pending';
    final isReturned = returnStatus == 'Returned';
    final customerDocs = customer.customerDocuments != null
        ? CustomerDocuments.fromMap(customer.customerDocuments!)
        : CustomerDocuments();

    final vehicleName = customer.vehicleName;
    final vehicleNumber = customer.vehicleHandover?['vehicleNumber'] ?? 'N/A';

    final pickupDate = customer.vehicleHandover?['vehicleGivenDate']?.isNotEmpty == true ? customer.vehicleHandover!['vehicleGivenDate'] : customer.sDate;
    final pickupTime = customer.vehicleHandover?['vehicleGivenTime']?.isNotEmpty == true ? customer.vehicleHandover!['vehicleGivenTime'] : DateFormat('HH:mm').format(DateTime.now());
    final returnDate = customer.vehicleHandover?['vehicleReturnDate'] ?? customer.returnDate;
    final returnTime = customer.vehicleHandover?['vehicleReturnTime'] ?? '';

    final double billAmount = double.tryParse(customer.billAmount) ?? 0.0;
    final double paidAmount = double.tryParse(customer.payment?['paymentAmount']?.toString() ?? '0.0') ?? 0.0;
    final double depositAmount = double.tryParse(customer.payment?['depositAmount']?.toString() ?? '0.0') ?? 0.0;
    final double pendingAmount = (billAmount - paidAmount).clamp(0, double.infinity);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (customerDocs.customerPhoto != null && customerDocs.customerPhoto!.isNotEmpty)
                      ? NetworkImage(customerDocs.customerPhoto!)
                      : null,
                  child: (customerDocs.customerPhoto == null || customerDocs.customerPhoto!.isEmpty)
                      ? Icon(Icons.person, size: 36, color: Colors.grey.shade400)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name.isNotEmpty ? customer.name : 'N/A',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 14, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            customer.smsPhone.isNotEmpty ? customer.smsPhone : 'N/A',
                            style: const TextStyle(fontSize: 13, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: _ReturnStatusBadge(status: returnStatus),
                ),
              ],
            ),
          ),

          // --- Vehicle & Dates ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    image: customerDocs.customerPhoto != null
                        ? DecorationImage(image: NetworkImage(customerDocs.customerPhoto!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: customerDocs.customerPhoto == null
                      ? const Icon(Icons.directions_bike, color: AppColors.muted, size: 40)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicleName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(vehicleNumber, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildDateColumn('Pickup', pickupDate, pickupTime),
                          Container(
                            height: 35,
                            width: 1,
                            color: Colors.grey.shade200,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          _buildDateColumn('Return', returnDate, returnTime.isNotEmpty ? returnTime : DateFormat('HH:mm').format(DateTime.now())),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Add-ons Chips ---
          if (customer.hasExtraHelmet || customer.hasMobileHolder)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  if (customer.hasExtraHelmet)
                    _buildAddonChip('+ Extra Helmet', '₹${customer.extraHelmetCharge.toStringAsFixed(0)}'),
                  if (customer.hasMobileHolder)
                    _buildAddonChip('+ Mobile Holder', '₹${customer.mobileHolderCharge.toStringAsFixed(0)}'),
                ],
              ),
            ),
          // --- Payment Summary ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPaymentStat('Paid', '₹${billAmount > 0 ? billAmount.toStringAsFixed(0) : paidAmount.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.green),
                    const VerticalDivider(width: 1),
                    _buildPaymentStat('Pending', '₹${pendingAmount.toStringAsFixed(0)}', Icons.hourglass_bottom, Colors.orange),
                    const VerticalDivider(width: 1),
                    _buildPaymentStat('Deposit', '₹${depositAmount.toStringAsFixed(0)}', Icons.shield, Colors.blue),
                  ],
                ),
              ),
            ),
          ),

          // --- Actions ---
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(context, 'Invoice', Icons.receipt_long, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePreviewScreen(custCode: customer.custCode)));
                  }),
                  const VerticalDivider(),
                  _buildActionButton(context, 'Payment', Icons.payment, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentRecordScreen(custCode: customer.custCode)));
                  }),
                  const VerticalDivider(),
                  _buildActionButton(context, 'Extend', Icons.sync, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Extend feature coming soon!')));
                  }),
                  if (!isReturned) ...[
                    const VerticalDivider(),
                    _buildActionButton(context, 'Return', Icons.keyboard_return, () {
                      if (onStatusChange != null) onStatusChange!(customer.custCode, 'Returned');
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonChip(String label, String price) {
    return Chip(
      avatar: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primaryGreen),
      label: Text('$label ($price)'),
      labelStyle: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 11),
      backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: AppColors.primaryGreen.withOpacity(0.2),
        ),
      ),
    );
  }

  Widget _buildDateColumn(String title, String date, String time) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(date.isNotEmpty ? date : DateFormat('dd-MM-yyyy').format(DateTime.now()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(time.isNotEmpty ? time : '--:--', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPaymentStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        )],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: AppColors.primaryGreen),
      label: Text(label, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _ReturnStatusBadge extends StatelessWidget {
  final String status;

  const _ReturnStatusBadge({this.status = 'Pending'});

  Color get _badgeColor {
    return status == 'Returned' ? AppColors.primaryGreen : AppColors.amber;
  }

  IconData get _icon {
    return status == 'Returned' ? Icons.check_circle : Icons.schedule;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}