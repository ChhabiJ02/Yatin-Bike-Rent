import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:street_bike_rental/services/challan_service.dart';
import 'package:flutter/services.dart';
import 'package:street_bike_rental/models/customer_documents.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../screens/challan_entry_screen.dart';
import '../screens/invoice_preview_screen.dart';
import '../screens/payment_record_screen.dart';
import '../theme/app_theme.dart';

class CustomerBookingsScreen extends StatefulWidget {
  final String? filterType;

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

  bool _isToday(dynamic dateField) {
    if (dateField == null) return false;
    DateTime? date;

    if (dateField is Timestamp) {
      date = dateField.toDate();
    } else if (dateField is String) {
      try {
        if (dateField.length > 10) {
          date = DateFormat('dd-MM-yyyy HH:mm:ss').parse(dateField);
        } else {
          date = DateFormat('dd-MM-yyyy').parse(dateField);
        }
      } catch (e) {
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

  Future<void> _showReturnDialog(String custCode) async {
    final dropDateController = TextEditingController(
        text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
    final dropTimeController =
        TextEditingController(text: TimeOfDay.now().format(context));
    final dropLocationController = TextEditingController();
    final endOdometerController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vehicle Return Details',
                    style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 20),
                TextField(
                  controller: dropDateController,
                  decoration: const InputDecoration(
                      labelText: 'Drop Date',
                      suffixIcon: Icon(Icons.calendar_today)),
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030));
                    if (picked != null) {
                      selectedDate = picked;
                      dropDateController.text =
                          DateFormat('dd-MM-yyyy').format(picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dropTimeController,
                  decoration: const InputDecoration(
                      labelText: 'Drop Time',
                      suffixIcon: Icon(Icons.access_time)),
                  readOnly: true,
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: ctx, initialTime: selectedTime);
                    if (picked != null && mounted) {
                      selectedTime = picked;
                      dropTimeController.text = picked.format(ctx);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dropLocationController,
                  decoration:
                      const InputDecoration(labelText: 'Drop Location'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endOdometerController,
                  decoration: const InputDecoration(
                      labelText: 'Ending Odometer Reading (KM)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final newDropDate = dropDateController.text;
                    final newDropTime = dropTimeController.text;
                    final newDropLocation = dropLocationController.text;
                    final newKmEndingNumber =
                        int.tryParse(endOdometerController.text);

                    if (newKmEndingNumber == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please enter a valid ending odometer reading.')),
                      );
                      return;
                    }

                    try {
                      final docRef = _customersCollection.doc(custCode);
                      final doc = await docRef.get();
                      if (doc.exists) {
                        final data = doc.data() ?? {};
                        final handover = Map<String, dynamic>.from(
                            data['vehicleHandover'] ?? {});

                        // Fetch starting KM from transportation or vehicleHandover
                        final transportation = Map<String, dynamic>.from(
                            data['transportation'] ?? {});
                        final int startingKm = int.tryParse(
                                transportation['kmStartingNumber']?.toString() ??
                                transportation['startingKm']?.toString() ??
                                handover['kmStartingNumber']?.toString() ??
                                '0') ??
                            0;

                        final int totalKm = (newKmEndingNumber - startingKm) > 0
                            ? (newKmEndingNumber - startingKm)
                            : 0;

                        handover['returnStatus'] = 'Returned';
                        handover['vehicleReturnDate'] = newDropDate;
                        handover['vehicleReturnTime'] = newDropTime;
                        handover['dropLocation'] = newDropLocation;
                        handover['kmEndingNumber'] = newKmEndingNumber;
                        handover['kmStartingNumber'] = startingKm;
                        handover['totalKmRun'] = totalKm;
                        handover['returnUpdatedAt'] =
                            FieldValue.serverTimestamp();

                        await docRef.update({
                          'vehicleHandover': handover,
                          'returnDate': newDropDate,
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Vehicle marked as Returned successfully!'),
                                backgroundColor: Colors.green),
                          );
                          Navigator.pop(ctx);
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Error marking vehicle as returned: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Confirm Return'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showExtendBookingDialog(Customer customer) async {
    final returnStatus = customer.vehicleHandover?['returnStatus']
            ?.toString()
            .trim()
            .toLowerCase() ??
        'pending';
    if (!{'pending', 'active'}.contains(returnStatus)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only active or pending rentals can be extended.')),
        );
      }
      return;
    }

    int extendedDays = 1;
    final daysController = TextEditingController(text: '1');

    final double basePrice = double.tryParse(customer.billAmount) ?? 0.0;
    final double perDayRate = double.tryParse(customer.rate) ?? 0.0;

    double newTotal = basePrice + (extendedDays * perDayRate);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Extend Booking',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Return: ${customer.returnDate.isNotEmpty ? customer.returnDate : "N/A"}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.primaryGreen),
                          onPressed: () {
                            int currentDays =
                                int.tryParse(daysController.text) ?? 1;
                            if (currentDays > 1) {
                              daysController.text =
                                  (currentDays - 1).toString();
                              setState(() {
                                extendedDays = currentDays - 1;
                                newTotal =
                                    basePrice + (extendedDays * perDayRate);
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: TextFormField(
                            controller: daysController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Days',
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value) ?? 0;
                              setState(() {
                                extendedDays = parsed;
                                newTotal =
                                    basePrice + (extendedDays * perDayRate);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppColors.primaryGreen),
                          onPressed: () {
                            int currentDays =
                                int.tryParse(daysController.text) ?? 0;
                            daysController.text =
                                (currentDays + 1).toString();
                            setState(() {
                              extendedDays = currentDays + 1;
                              newTotal =
                                  basePrice + (extendedDays * perDayRate);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'New Total: ₹${newTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child:
                      const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: extendedDays > 0
                      ? () => _confirmExtension(
                          dialogContext, customer, extendedDays, newTotal)
                      : null,
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmExtension(BuildContext dialogContext, Customer customer,
      int extendedDays, double newTotal) async {
    try {
      DateTime baseDate = DateTime.now();
      String preservedTime = '';

      // Prefer handover stored time if present
      if (customer.vehicleHandover != null && (customer.vehicleHandover?['vehicleReturnTime'] ?? '').toString().isNotEmpty) {
        preservedTime = customer.vehicleHandover!['vehicleReturnTime'].toString();
      }

      if (customer.returnDate.isNotEmpty) {
        try {
          final datePart = customer.returnDate.split(' ')[0];
          if (datePart.contains('-')) {
            final parts = datePart.split('-');
            if (parts.length == 3) {
              baseDate = DateTime(
                int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          } else if (datePart.contains('/')) {
            final parts = datePart.split('/');
            if (parts.length == 3) {
              baseDate = DateTime(
                int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          } else {
            baseDate = DateTime.tryParse(datePart) ?? DateTime.now();
          }
        } catch (_) {
          baseDate = DateTime.now();
        }
      }

      // If we have a preserved time, parse it into baseDate
      if (preservedTime.isEmpty) {
        // try to fetch from document handover stored in DB
        final docRefTemp = _customersCollection.doc(customer.custCode);
        final docSnapTemp = await docRefTemp.get();
        if (docSnapTemp.exists && docSnapTemp.data() != null) {
          final Map<String, dynamic> hand = Map<String, dynamic>.from(docSnapTemp.data()!['vehicleHandover'] ?? {});
          preservedTime = (hand['vehicleReturnTime'] ?? '').toString();
        }
      }

      int hour = 0;
      int minute = 0;
      if (preservedTime.isNotEmpty) {
        try {
          if (preservedTime.toLowerCase().contains('am') || preservedTime.toLowerCase().contains('pm')) {
            final dt = DateFormat.jm().parse(preservedTime);
            hour = dt.hour;
            minute = dt.minute;
          } else if (preservedTime.contains(':')) {
            final tparts = preservedTime.split(':');
            hour = int.tryParse(tparts[0]) ?? 0;
            minute = int.tryParse(tparts.length > 1 ? tparts[1] : '0') ?? 0;
          }
        } catch (_) {
          hour = 0;
          minute = 0;
        }
      }

      baseDate = DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);

      final updatedReturnDate = baseDate.add(Duration(days: extendedDays));
      final formattedNewDate = DateFormat('dd-MM-yyyy').format(updatedReturnDate);
      final formattedNewTime = '${updatedReturnDate.hour.toString().padLeft(2, '0')}:${updatedReturnDate.minute.toString().padLeft(2, '0')}';

      final int currentDays = int.tryParse(customer.days) ?? 1;
      final int totalDays = currentDays + extendedDays;

      final docRef = _customersCollection.doc(customer.custCode);
      final docSnap = await docRef.get();
      Map<String, dynamic> handover = {};
      if (docSnap.exists && docSnap.data() != null) {
        handover = Map<String, dynamic>.from(docSnap.data()!['vehicleHandover'] ?? {});
      }
      handover['vehicleReturnDate'] = formattedNewDate;
      // Preserve original time if present, else set from computed datetime
      handover['vehicleReturnTime'] = preservedTime.isNotEmpty ? preservedTime : formattedNewTime;

      await docRef.update({
        'returnDate': formattedNewDate,
        'billAmount': newTotal.toStringAsFixed(2),
        'days': totalDays.toString(),
        'vehicleHandover': handover,
      });

      if (mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Extended return date to $formattedNewDate successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error extending booking: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottom: _buildHeader(context),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.filterType == null) _buildFilterChips(),
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
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.muted)),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No customer entries found.',
                          style: TextStyle(color: AppColors.muted)),
                    );
                  }

                  final customers = snapshot.data!.docs.where((doc) {
                    final customer = Customer.fromFirestore(
                      doc as DocumentSnapshot<Map<String, dynamic>>,
                    );
                    final name = customer.name.toLowerCase();
                    final code = customer.custCode.toLowerCase();
                    final vehicleNo = (customer.vehicleHandover?['vehicleNumber'] ?? '').toString().toLowerCase();

                    final matchesSearch = _searchQuery.isEmpty ||
                        name.contains(_searchQuery.toLowerCase()) ||
                        code.contains(_searchQuery.toLowerCase()) ||
                        vehicleNo.contains(_searchQuery.toLowerCase());

                    if (!matchesSearch) return false;

                    if (widget.filterType != null) {
                      if (widget.filterType == 'todays_bookings') {
                        return _isToday(customer.createdAt) ||
                            _isToday(customer.sDate);
                      }
                      if (widget.filterType == 'todays_returns') {
                        final handover = customer.vehicleHandover;
                        final isReturned =
                            handover?['returnStatus'] == 'Returned';
                        if (!isReturned) return false;

                        final returnDate = handover?['vehicleReturnDate'];
                        final fallbackDate =
                            customer.createdAt ?? customer.sDate;

                        return _isToday(
                          (returnDate != null &&
                                  returnDate.toString().isNotEmpty)
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

                    final returnStatus =
                        customer.vehicleHandover?['returnStatus'] ?? 'Pending';
                    final paymentStatus =
                        customer.vehicleHandover?['paymentStatus'] ?? '';

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
                      child: Text('No matching entries found.',
                          style: TextStyle(color: AppColors.muted)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final doc = customers[index];
                      final docData = doc.data() as Map<String, dynamic>? ?? {};
                      final customer = Customer.fromFirestore(
                        doc as DocumentSnapshot<Map<String, dynamic>>,
                      );
                      return _CustomerEntryCard(
                        customer: customer,
                        docData: docData,
                        onReturn: _showReturnDialog,
                        onExtendBooking: _showExtendBookingDialog,
                        onEdit: () =>
                            _openEntryForm(custCode: customer.custCode),
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
        label: const Text('New Entry',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
            prefixIcon:
                Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.15),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
                  color: isSelected
                      ? AppColors.primaryGreen
                      : Colors.grey.shade300,
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
  final Map<String, dynamic> docData;
  final Function(Customer customer)? onExtendBooking;
  final Function(String custCode)? onReturn;
  final VoidCallback? onEdit;

  const _CustomerEntryCard({
    required this.customer,
    required this.docData,
    this.onExtendBooking,
    this.onReturn,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final returnStatus =
        customer.vehicleHandover?['returnStatus']?.toString() ?? 'Pending';
    final isReturned = returnStatus.trim().toLowerCase() == 'returned';
    final customerDocs = customer.customerDocuments != null
        ? CustomerDocuments.fromMap(customer.customerDocuments!)
        : CustomerDocuments();

    final vehicleName = customer.vehicleName;
    final vehicleNumber = customer.vehicleHandover?['vehicleNumber'] ?? 'N/A';

    final pickupDate =
        customer.vehicleHandover?['vehicleGivenDate']?.isNotEmpty == true
            ? customer.vehicleHandover!['vehicleGivenDate']
            : customer.sDate;
    final pickupTime =
        customer.vehicleHandover?['vehicleGivenTime']?.isNotEmpty == true
            ? customer.vehicleHandover!['vehicleGivenTime']
            : DateFormat('HH:mm').format(DateTime.now());

    String returnDate = '';
    String returnTime = '';

    // Prefer explicit handover values, fall back to top-level returnDate
    final handover = customer.vehicleHandover ?? {};
    if ((handover['vehicleReturnDate'] ?? '').toString().isNotEmpty) {
      returnDate = handover['vehicleReturnDate'].toString();
    } else {
      returnDate = customer.returnDate;
    }
    if ((handover['vehicleReturnTime'] ?? '').toString().isNotEmpty) {
      returnTime = handover['vehicleReturnTime'].toString();
    } else {
      returnTime = handover['vehicleReturnDate']?.toString().contains(' ') == true
          ? handover['vehicleReturnDate'].toString().split(' ').skip(1).join(' ')
          : (customer.returnDate.contains(' ') ? customer.returnDate.split(' ').skip(1).join(' ') : '--');
    }

    // Compute overdue: not returned AND now > returnDate+returnTime
    bool isOverdue = false;
    try {
      if (returnDate.isNotEmpty) {
        // parse date
        final datePart = returnDate.split(' ')[0];
        List<String> parts = datePart.contains('-') ? datePart.split('-') : datePart.split('/');
        if (parts.length == 3) {
          final int day = int.parse(parts[0]);
          final int month = int.parse(parts[1]);
          final int year = int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]);

          int hour = 0;
          int minute = 0;
          final rt = returnTime;
          if (rt != null && rt.isNotEmpty && rt != '--') {
            try {
              if (rt.toLowerCase().contains('am') || rt.toLowerCase().contains('pm')) {
                final dt = DateFormat.jm().parse(rt);
                hour = dt.hour;
                minute = dt.minute;
              } else if (rt.contains(':')) {
                final tparts = rt.split(':');
                hour = int.tryParse(tparts[0]) ?? 0;
                minute = int.tryParse(tparts.length > 1 ? tparts[1] : '0') ?? 0;
              }
            } catch (_) {
              hour = 0;
              minute = 0;
            }
          }

          final dt = DateTime(year, month, day, hour, minute);
          if (returnStatus != 'Returned' && DateTime.now().isAfter(dt)) {
            isOverdue = true;
          }
        }
      }
    } catch (_) {
      isOverdue = false;
    }

    // --- Dynamic Calculation Fixes ---
    final double billAmount = double.tryParse(customer.billAmount) ?? 0.0;
    
    // Fetch Paid Amount
    final double paidAmount = double.tryParse(
          customer.payment?['paymentAmount']?.toString() ??
          docData['paidAmount']?.toString() ??
          '0.0') ?? 0.0;

    // Fetch Deposit Amount
    final double depositAmount = double.tryParse(
          docData['deposit']?.toString() ??
          docData['depositAmount']?.toString() ??
          customer.payment?['depositAmount']?.toString() ??
          '0.0') ?? 0.0;

    // Dynamic Pending Calculation
    final double pendingAmount = (billAmount - paidAmount).clamp(0.0, double.infinity);

    // Dynamic Odometer & KM Calculations
    final transportation = Map<String, dynamic>.from(docData['transportation'] ?? {});
    final handoverDoc = Map<String, dynamic>.from(docData['vehicleHandover'] ?? {});

    final int startKm = int.tryParse(
            transportation['kmStartingNumber']?.toString() ??
            transportation['startingKm']?.toString() ??
            handover['kmStartingNumber']?.toString() ??
            '0') ??
        0;

    final int endKm = int.tryParse(handoverDoc['kmEndingNumber']?.toString() ?? '0') ?? 0;
    
    int totalKm = int.tryParse(handoverDoc['totalKmRun']?.toString() ?? '0') ?? 0;
    if (totalKm == 0 && endKm > startKm) {
      totalKm = endKm - startKm;
    }

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
        border: isOverdue ? Border.all(color: Colors.red.withOpacity(0.18)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (customerDocs.customerPhoto != null &&
                              customerDocs.customerPhoto!.isNotEmpty)
                          ? NetworkImage(customerDocs.customerPhoto!)
                          : null,
                      child: (customerDocs.customerPhoto == null ||
                              customerDocs.customerPhoto!.isEmpty)
                          ? Icon(Icons.person,
                              size: 36, color: Colors.grey.shade400)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name.isNotEmpty ? customer.name : 'N/A',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone,
                                  size: 14, color: AppColors.muted),
                              const SizedBox(width: 4),
                              Text(
                                customer.smsPhone.isNotEmpty
                                    ? customer.smsPhone
                                    : 'N/A',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: isOverdue
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.report_problem, size: 12, color: Colors.red),
                                  SizedBox(width: 6),
                                  Text('OVERDUE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            )
                          : _ReturnStatusBadge(status: returnStatus),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vehicleName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(vehicleNumber,
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildDateColumn(
                                  'Pickup', pickupDate, pickupTime),
                              Container(
                                height: 35,
                                width: 1,
                                color: Colors.grey.shade200,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              _buildDateColumn('Return', returnDate, returnTime, isOverdue: isOverdue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- KM Details View ---
              if (startKm > 0 || endKm > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryGreen.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Start: $startKm KM',
                            style: const TextStyle(fontSize: 12, color: AppColors.ink)),
                        Text('End: ${endKm > 0 ? "$endKm KM" : "--"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.ink)),
                        Text('Total: $totalKm KM',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen)),
                      ],
                    ),
                  ),
                ),

              if (customer.hasExtraHelmet || customer.hasMobileHolder)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      if (customer.hasExtraHelmet)
                        _buildAddonChip('+ Extra Helmet',
                            '₹${customer.extraHelmetCharge.toStringAsFixed(0)}'),
                      if (customer.hasMobileHolder)
                        _buildAddonChip('+ Mobile Holder',
                            '₹${customer.mobileHolderCharge.toStringAsFixed(0)}'),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPaymentStat(
                            'Paid',
                            '₹${paidAmount.toStringAsFixed(0)}',
                            Icons.account_balance_wallet,
                            Colors.green),
                        const VerticalDivider(width: 1),
                        _buildPaymentStat(
                            'Pending',
                            '₹${pendingAmount.toStringAsFixed(0)}',
                            Icons.hourglass_bottom,
                            Colors.orange),
                        const VerticalDivider(width: 1),
                        _buildPaymentStat(
                            'Deposit',
                            '₹${depositAmount.toStringAsFixed(0)}',
                            Icons.shield,
                            Colors.blue),
                      ],
                    ),
                  ),
                ),
              ),

              // --- 4 Action Buttons Row ---
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context,
                          'Invoice',
                          Icons.receipt_long,
                          () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => InvoicePreviewScreen(
                                        custCode: customer.custCode)));
                          },
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          'Payment',
                          Icons.payment,
                          () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PaymentRecordScreen(
                                        custCode: customer.custCode)));
                          },
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          'Extend',
                          Icons.sync,
                          isReturned
                              ? null
                              : () {
                                  if (onExtendBooking != null) {
                                    onExtendBooking!(customer);
                                  }
                                },
                          color: isReturned ? Colors.grey : AppColors.primaryGreen,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          isReturned ? 'Returned' : 'Return',
                          Icons.published_with_changes_outlined,
                          isReturned
                              ? null
                              : () {
                                  if (onReturn != null) {
                                    onReturn!(customer.custCode);
                                  }
                                },
                          color:
                              isReturned ? Colors.grey : AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddonChip(String label, String price) {
    return Chip(
      avatar: const Icon(Icons.add_circle_outline,
          size: 16, color: AppColors.primaryGreen),
      label: Text('$label ($price)'),
      labelStyle: const TextStyle(
          color: AppColors.primaryGreen,
          fontWeight: FontWeight.w600,
          fontSize: 11),
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

  Widget _buildDateColumn(String title, String date, String time, {bool isOverdue = false}) {
    final dateStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13,
      color: isOverdue ? Colors.red : AppColors.ink,
    );
    final timeStyle = TextStyle(
      color: isOverdue ? Colors.red : AppColors.muted,
      fontSize: 12,
    );

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
              date.isNotEmpty
                  ? date
                  : DateFormat('dd-MM-yyyy').format(DateTime.now()),
              style: dateStyle),
          Text(time.isNotEmpty ? time : '--:--', style: timeStyle),
        ],
      ),
    );
  }

  Widget _buildPaymentStat(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, IconData icon, VoidCallback? onPressed,
      {Color color = AppColors.primaryGreen}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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