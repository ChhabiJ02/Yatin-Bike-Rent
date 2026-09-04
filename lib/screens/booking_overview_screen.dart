import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/customer.dart';
import '../theme/app_theme.dart';
import 'payment_record_screen.dart';

class BookingOverviewScreen extends StatefulWidget {
  final Customer customer;
  final Map<String, dynamic> docData;
  final Future<void> Function()? onReturn;
  final Future<void> Function()? onExtend;

  const BookingOverviewScreen({
    super.key,
    required this.customer,
    required this.docData,
    this.onReturn,
    this.onExtend,
  });

  @override
  State<BookingOverviewScreen> createState() => _BookingOverviewScreenState();
}

class _BookingOverviewScreenState extends State<BookingOverviewScreen> {
  late Map<String, dynamic> _data;
  late Map<String, dynamic> _handover;
  late Map<String, dynamic> _travel;
  late Map<String, dynamic> _transport;
  late String _name;
  late String _phone;
  late String _whatsapp;
  late String _rate;
  late String _paid;
  late String _days;
  double _bill = 0;
  late bool _hasExtraHelmet;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.docData);
    _handover = Map<String, dynamic>.from(
      widget.customer.vehicleHandover ?? {},
    );
    _travel = Map<String, dynamic>.from(widget.customer.travelDetails ?? {});
    _transport = Map<String, dynamic>.from(
      widget.customer.transportation ?? {},
    );
    _name = widget.customer.name;
    _phone = widget.customer.smsPhone;
    _whatsapp = (_data['alternatePhone'] ?? '').toString();
    _rate = widget.customer.rate;
    _days = widget.customer.days;
    _bill = double.tryParse(widget.customer.billAmount) ?? 0;
    _hasExtraHelmet = widget.customer.hasExtraHelmet;
    _paid =
        (_data['paidAmount'] ??
                widget.customer.payment?['paymentAmount'] ??
                '0')
            .toString();
  }

  String _value(Object? value) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? '-' : text;
  }

  Widget _section(String title, List<Widget> children, {VoidCallback? onEdit}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E3E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (onEdit != null)
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map(
            (child) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: child,
              ),
            ),
          )
          .toList(),
    );
  }

  // Renders helmet count as icon(s) only (no text).
  Widget _detailHelmet({required int helmetCount}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sports_motorsports_outlined,
            size: 20,
            color: AppColors.ink,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Helmet',
                  style: TextStyle(fontSize: 11, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < helmetCount; i++) ...[
                      const Icon(
                        Icons.sports_motorsports,
                        size: 22,
                        color: AppColors.ink,
                      ),
                      if (i < helmetCount - 1) const SizedBox(width: 6),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editSection(
    String title,
    Map<String, String> values,
    Future<void> Function(Map<String, String>) onSave,
  ) async {
    final controllers = values.map(
      (key, value) => MapEntry(key, TextEditingController(text: value)),
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit $title'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: controllers.entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: entry.key,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final result = controllers.map(
                (key, controller) => MapEntry(key, controller.text.trim()),
              );
              await onSave(result);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Future<void> _updateFirestore(Map<String, dynamic> values) async {
    await FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customer.custCode)
        .update(values);
  }

  Future<void> _reloadBooking() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customer.custCode)
        .get();
    if (!mounted || !snapshot.exists) return;
    final data = snapshot.data() ?? {};
    setState(() {
      _data = data;
      _handover = Map<String, dynamic>.from(data['vehicleHandover'] ?? {});
      _transport = Map<String, dynamic>.from(data['transportation'] ?? {});
      _days = (data['days'] ?? _days).toString();
      _rate = (data['rate'] ?? _rate).toString();
      _bill =
          double.tryParse((data['billAmount'] ?? _bill).toString()) ?? _bill;
      _hasExtraHelmet = data['hasExtraHelmet'] == true;
    });
  }

  Future<void> _editCustomer() async {
    await _editSection(
      'Customer Details',
      {'Name': _name, 'Mobile Number': _phone, 'WhatsApp Number': _whatsapp},
      (values) async {
        await _updateFirestore({
          'partyName': values['Name'],
          'smsPhone': values['Mobile Number'],
          'alternatePhone': values['WhatsApp Number'],
        });
        setState(() {
          _name = values['Name']!;
          _phone = values['Mobile Number']!;
          _whatsapp = values['WhatsApp Number']!;
        });
      },
    );
  }

  Future<void> _editBooking() async {
    final cityController = TextEditingController(
      text: (_travel['city'] ?? _data['city'] ?? '').toString(),
    );
    final stayController = TextEditingController(
      text: (_travel['stayingAt'] ?? _travel['hotelName'] ?? '').toString(),
    );
    final locationController = TextEditingController(
      text: (_handover['vehiclePickupLocation'] ?? '').toString(),
    );
    // Fall back to the customer-level sDate / returnDate when the
    // handover map does not contain its own date (older records).
    final pickupDateRaw = (_handover['vehicleGivenDate'] ?? '').toString();
    final pickupTimeRaw = (_handover['vehicleGivenTime'] ?? '').toString();
    final returnDateRaw = (_handover['vehicleReturnDate'] ?? widget.customer.returnDate)
        .toString();
    final returnTimeRaw = (_handover['vehicleReturnTime'] ?? '').toString();
    final customerSDate = widget.customer.sDate;

    DateTime? pickupDate = _parseBookingDate(
      pickupDateRaw.isNotEmpty ? pickupDateRaw : customerSDate,
    );
    TimeOfDay? pickupTime = _parseBookingTime(
      pickupTimeRaw.isNotEmpty
          ? pickupTimeRaw
          : (pickupDateRaw.isNotEmpty ? null : customerSDate),
    );
    DateTime? returnDate = _parseBookingDate(returnDateRaw);
    TimeOfDay? returnTime = _parseBookingTime(returnTimeRaw);

    Future<void> pickDateTime({
      required bool isReturn,
      required StateSetter refresh,
    }) async {
      final selectedDate = await showDatePicker(
        context: context,
        initialDate: (isReturn ? returnDate : pickupDate) ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      );
      if (selectedDate == null || !mounted) return;
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: (isReturn ? returnTime : pickupTime) ?? TimeOfDay.now(),
      );
      if (!mounted) return;
      if (isReturn) {
        returnDate = selectedDate;
        returnTime = selectedTime ?? returnTime;
      } else {
        pickupDate = selectedDate;
        pickupTime = selectedTime ?? pickupTime;
      }
      refresh(() {});
    }

    String dateTimeText(DateTime? date, TimeOfDay? time) {
      if (date == null) return 'Select date and time';
      final dateText =
          '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      return '$dateText ${time?.format(context) ?? ''}'.trim();
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refresh) => AlertDialog(
          title: const Text('Edit Booking Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'From City'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stayController,
                  decoration: const InputDecoration(
                    labelText: 'Stay',
                    hintText: 'Hotel name / Stay location',
                    prefixIcon: Icon(Icons.hotel_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                _dateTimeEditField(
                  label: 'Pickup',
                  value: dateTimeText(pickupDate, pickupTime),
                  onTap: () => pickDateTime(isReturn: false, refresh: refresh),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Pickup Location',
                  ),
                ),
                const SizedBox(height: 12),
                _dateTimeEditField(
                  label: 'Return',
                  value: dateTimeText(returnDate, returnTime),
                  onTap: () => pickDateTime(isReturn: true, refresh: refresh),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final handover = Map<String, dynamic>.from(_handover);
                handover['vehicleGivenDate'] = pickupDate == null
                    ? ''
                    : '${pickupDate!.day}-${pickupDate!.month}-${pickupDate!.year}';
                handover['vehicleGivenTime'] =
                    pickupTime?.format(context) ?? '';
                handover['vehiclePickupLocation'] = locationController.text
                    .trim();
                handover['vehicleReturnDate'] = returnDate == null
                    ? ''
                    : '${returnDate!.day}-${returnDate!.month}-${returnDate!.year}';
                handover['vehicleReturnTime'] =
                    returnTime?.format(context) ?? '';
                final travel = Map<String, dynamic>.from(_travel);
                travel['city'] = cityController.text.trim();
                travel['stayingAt'] = stayController.text.trim();
                travel['hotelName'] = stayController.text.trim();
                await _updateFirestore({
                  'vehicleHandover': handover,
                  'travelDetails': travel,
                  'returnDate': handover['vehicleReturnDate'],
                  'days': _totalDaysFor(handover).toString(),
                });
                if (!mounted) return;
                setState(() {
                  _handover = handover;
                  _travel = travel;
                  _days = _totalDaysFor(handover).toString();
                  _bill = _calculateTotal(_days, _rate, _hasExtraHelmet);
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    cityController.dispose();
    stayController.dispose();
    locationController.dispose();
  }

  Future<void> _editRental() async {
    final startController = TextEditingController(
      text: (_transport['startingKm'] ?? _handover['kmStartingNumber'] ?? '')
          .toString(),
    );
    final rateController = TextEditingController(text: _rate);
    final daysController = TextEditingController(text: _days);
    // Helmet count: 0 = None, 1 = 1 Helmet, 2 = 2 Helmets
    int helmetCount = _hasExtraHelmet ? 2 : 1;
    bool hasExtraHelmet() => helmetCount == 2;

    // Live preview values used inside the dialog
    double liveBill = _calculateTotal(_days, _rate, hasExtraHelmet());
    double liveDue() => (liveBill - (double.tryParse(_paid) ?? 0))
        .clamp(0, double.infinity)
        .toDouble();

    void recompute() {
      liveBill = _calculateTotal(
        daysController.text.trim(),
        rateController.text.trim(),
        hasExtraHelmet(),
      );
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refresh) {
          // Listen to changes in text fields so total/due update on every keystroke.
          void onAnyChanged() {
            recompute();
            refresh(() {});
          }

          return AlertDialog(
            title: const Text('Edit Rental Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: startController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Start KM'),
                    onChanged: (_) => onAnyChanged(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: daysController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Days'),
                          onChanged: (_) => onAnyChanged(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: rateController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Rate / Day'),
                          onChanged: (_) => onAnyChanged(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Helmet',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _helmetIconOption(
                          Icons.close,
                          helmetCount == 0,
                          () {
                            helmetCount = 0;
                            onAnyChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _helmetIconOption(
                          Icons.sports_motorsports_outlined,
                          helmetCount == 1,
                          () {
                            helmetCount = 1;
                            onAnyChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _helmetIconOption(
                          Icons.sports_motorsports_outlined,
                          helmetCount == 2,
                          () {
                            helmetCount = 2;
                            onAnyChanged();
                          },
                          doubleIcon: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _amount('Total', '₹${liveBill.toStringAsFixed(0)}'),
                        _amount(
                          'Due',
                          '₹${liveDue().toStringAsFixed(0)}',
                          danger: liveDue() > 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final transport = Map<String, dynamic>.from(_transport);
                  transport['startingKm'] = startController.text.trim();
                  final newRate = rateController.text.trim();
                  final newDays = daysController.text.trim();
                  final newBill = _calculateTotal(
                    newDays,
                    newRate,
                    hasExtraHelmet(),
                  );
                  await _updateFirestore({
                    'transportation': transport,
                    'rate': newRate,
                    'days': newDays,
                    'billAmount': newBill.toString(),
                    'helmetCount': helmetCount,
                    'hasExtraHelmet': hasExtraHelmet(),
                    'extraHelmetCharge': hasExtraHelmet() ? 50.0 : 0.0,
                  });
                  if (!mounted) return;
                  setState(() {
                    _transport = transport;
                    _rate = newRate;
                    _days = newDays;
                    _hasExtraHelmet = hasExtraHelmet();
                    _bill = newBill;
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    startController.dispose();
    rateController.dispose();
    daysController.dispose();
  }

  DateTime? _parseBookingDate(Object? value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    // Stored format can be either "dd-MM-yyyy" or "dd-MM-yyyy HH:mm:ss".
    final datePart = raw.split(' ').first;
    final parts = datePart.split('-');
    if (parts.length != 3) return null;

    // Normalise each part to handle unpadded day/month.
    String pad(String s) => s.length == 1 ? '0$s' : s;
    final day = pad(parts[0]);
    final month = pad(parts[1]);
    final yearRaw = parts[2];
    // Year may include time suffix in some legacy data ("2026 10:30:00").
    final year = yearRaw.split(' ').first.padLeft(4, '0');
    return DateTime.tryParse('$year-$month-$day');
  }

  TimeOfDay? _parseBookingTime(Object? value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  double _calculateTotal(String days, String rate, bool extraHelmet) {
    final totalDays = double.tryParse(days) ?? 0;
    final dailyRate = double.tryParse(rate) ?? 0;
    return totalDays * dailyRate +
        (extraHelmet ? 50 : 0) +
        (widget.customer.hasMobileHolder ? 30 : 0);
  }

  int _totalDaysFor(Map<String, dynamic> handover) {
    final pickupDate = _parseBookingDate(handover['vehicleGivenDate']);
    final returnDate = _parseBookingDate(handover['vehicleReturnDate']);
    if (pickupDate == null || returnDate == null) {
      return int.tryParse(_days) ?? 1;
    }
    final pickupTime = _parseBookingTime(handover['vehicleGivenTime']);
    final returnTime = _parseBookingTime(handover['vehicleReturnTime']);
    final pickup = DateTime(
      pickupDate.year,
      pickupDate.month,
      pickupDate.day,
      pickupTime?.hour ?? 0,
      pickupTime?.minute ?? 0,
    );
    final returned = DateTime(
      returnDate.year,
      returnDate.month,
      returnDate.day,
      returnTime?.hour ?? 0,
      returnTime?.minute ?? 0,
    );
    final days = returned.difference(pickup).inMinutes / (24 * 60);
    return days <= 0 ? 1 : days.ceil();
  }

  String _totalDaysFromDates() {
    final pickupDate = _parseBookingDate(_handover['vehicleGivenDate']);
    final returnDate = _parseBookingDate(
      _handover['vehicleReturnDate'] ?? widget.customer.returnDate,
    );
    if (pickupDate == null || returnDate == null) return _days;
    final pickupTime = _parseBookingTime(_handover['vehicleGivenTime']);
    final returnTime = _parseBookingTime(_handover['vehicleReturnTime']);
    final pickup = DateTime(
      pickupDate.year,
      pickupDate.month,
      pickupDate.day,
      pickupTime?.hour ?? 0,
      pickupTime?.minute ?? 0,
    );
    final returned = DateTime(
      returnDate.year,
      returnDate.month,
      returnDate.day,
      returnTime?.hour ?? 0,
      returnTime?.minute ?? 0,
    );
    final days = returned.difference(pickup).inMinutes / (24 * 60);
    return (days <= 0 ? 1 : days.ceil()).toString();
  }

  Widget _dateTimeEditField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          suffixIcon: const Icon(Icons.expand_more),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(value),
      ),
    );
  }

  Widget _helmetIconOption(
    IconData icon,
    bool selected,
    VoidCallback onTap, {
    bool doubleIcon = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 64,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          border: Border.all(
            color: selected ? Colors.black : const Color(0xFFE0E0E0),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: doubleIcon
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      icon,
                      size: 22,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                  ],
                )
              : Icon(
                  icon,
                  size: 26,
                  color: selected ? Colors.white : AppColors.ink,
                ),
        ),
      ),
    );
  }

  Future<void> _editPayment() async {
    final totalController = TextEditingController(
      text: _bill.toStringAsFixed(0),
    );
    final paidController = TextEditingController(text: _paid);
    final dueController = TextEditingController(text: '0');
    final overpaidController = TextEditingController(text: '0');
    final referenceIdController = TextEditingController(
      text: (_data['referenceId'] ?? '').toString(),
    );

    void recompute() {
      final total = double.tryParse(totalController.text.trim()) ?? 0;
      final paid = double.tryParse(paidController.text.trim()) ?? 0;
      final diff = paid - total;
      if (diff >= 0) {
        // Paid exceeds total -> overpaid, no due.
        dueController.text = '0';
        overpaidController.text = diff.toStringAsFixed(0);
      } else {
        dueController.text = (-diff).toStringAsFixed(0);
        overpaidController.text = '0';
      }
    }

    // Initialise derived values from the current saved paid amount.
    recompute();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocalState) {
          return AlertDialog(
            title: const Text('Edit Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: totalController,
                    readOnly: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Amount',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: paidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Paid Amount',
                    ),
                    onChanged: (_) {
                      recompute();
                      setLocalState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Due Amount',
                    ),
                    onChanged: (_) {
                      // Manual edit: treat Due as an offset against paid.
                      final due =
                          double.tryParse(dueController.text.trim()) ?? 0;
                      final total =
                          double.tryParse(totalController.text.trim()) ?? 0;
                      paidController.text = (total + due).toStringAsFixed(0);
                      recompute();
                      setLocalState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: overpaidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Overpaid Amount',
                    ),
                    onChanged: (_) {
                      // Manual edit: treat Overpaid as an offset against paid.
                      final overpaid = double.tryParse(
                            overpaidController.text.trim(),
                          ) ??
                          0;
                      final total =
                          double.tryParse(totalController.text.trim()) ?? 0;
                      paidController.text =
                          (total + overpaid).toStringAsFixed(0);
                      recompute();
                      setLocalState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: referenceIdController,
                    decoration: const InputDecoration(
                      labelText: 'Reference ID',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  await _updateFirestore({
                    'paidAmount': paidController.text.trim(),
                    'referenceId': referenceIdController.text.trim(),
                  });
                  if (!mounted) return;
                  setState(() {
                    _paid = paidController.text.trim();
                    _data['paidAmount'] = _paid;
                    _data['referenceId'] = referenceIdController.text.trim();
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    totalController.dispose();
    paidController.dispose();
    dueController.dispose();
    overpaidController.dispose();
    referenceIdController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final handover = _handover;
    final transportation = _transport;
    final status = (handover['returnStatus'] ?? 'Pending').toString();
    final normalizedStatus = status.toLowerCase().trim();
    final returned =
        normalizedStatus == 'returned' || normalizedStatus == 'completed';
    final paid = _paid;
    final bill = _bill;
    final pending = (bill - (double.tryParse(paid.toString()) ?? 0)).clamp(
      0,
      double.infinity,
    );
    final overpaid = (double.tryParse(paid.toString()) ?? 0) - bill;
    final hasOverpaid = overpaid > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit Booking',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Record Payment',
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () async {
                    final paid = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentRecordScreen(
                          custCode: widget.customer.custCode,
                          initialAmount: widget.customer.billAmount,
                        ),
                      ),
                    );
                    if (paid is String && mounted) {
                      setState(() {
                        _paid = paid;
                        _data['paidAmount'] = paid;
                      });
                    }
                  },
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(11),
                    child: Icon(
                      Icons.currency_rupee,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Open WhatsApp',
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _openWhatsApp,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(11),
                    child: Icon(
                      Icons.chat_outlined,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Delete Booking',
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Delete Booking'),
                        content: const Text(
                          'Are you sure you want to delete this booking? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && mounted) {
                      await FirebaseFirestore.instance
                          .collection('customers')
                          .doc(widget.customer.custCode)
                          .delete();
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(11),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            _section('Vehicle', [
              Row(
                children: [
                  const Icon(Icons.two_wheeler_outlined, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _value(widget.customer.vehicleName),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusBadge(status: returned ? 'Returned' : 'Running'),
                ],
              ),
              const SizedBox(height: 10),
              _detailRow([
                _detail(
                  Icons.confirmation_number_outlined,
                  'Number Plate',
                  _value(handover['vehicleNumber']),
                ),
                _detail(
                  Icons.currency_rupee,
                  'Rate / Day',
                  '₹${_value(_rate)}',
                ),
              ]),
            ]),
            _section('Customer Details', [
              _detailRow([
                _detail(Icons.person_outline, 'Name', _value(_name)),
                _detail(Icons.phone_outlined, 'Mobile Number', _value(_phone)),
              ]),
              _detailRow([
                _detail(
                  Icons.chat_outlined,
                  'WhatsApp Number',
                  _value(_whatsapp),
                ),
                const SizedBox.shrink(),
              ]),
            ], onEdit: _editCustomer),
            _section('Booking Details', [
              _detailRow([
                _detail(
                  Icons.location_on_outlined,
                  'From City',
                  _value(_travel['city'] ?? _data['city']),
                ),
                _detail(
                  Icons.location_on_outlined,
                  'Pickup Location',
                  _value(handover['vehiclePickupLocation']),
                ),
              ]),
              _detailRow([
                _detail(
                  Icons.hotel_outlined,
                  'Stay',
                  _value(_travel['stayingAt'] ?? _travel['hotelName']),
                ),
                const SizedBox.shrink(),
              ]),
              _detailRow([
                _detail(
                  Icons.calendar_month_outlined,
                  'Pickup',
                  '${_value(handover['vehicleGivenDate'])} ${_value(handover['vehicleGivenTime'])}',
                ),
                _detail(
                  Icons.calendar_month_outlined,
                  'Return',
                  '${_value(handover['vehicleReturnDate'] ?? widget.customer.returnDate)} ${_value(handover['vehicleReturnTime'])}',
                ),
              ]),
            ], onEdit: _editBooking),
            _section('Rental Details', [
              _detailRow([
                _detail(
                  Icons.speed_outlined,
                  'Start KM',
                  _value(
                    transportation['startingKm'] ??
                        handover['kmStartingNumber'],
                  ),
                ),
                _detail(
                  Icons.today_outlined,
                  'Total Days',
                  _totalDaysFromDates(),
                ),
              ]),
              _detailRow([
                _detailHelmet(
                  helmetCount: _hasExtraHelmet ? 2 : 1,
                ),
                const SizedBox.shrink(),
              ]),
            ], onEdit: _editRental),
            _section('Payment', [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _amount('Total Amount', '₹${bill.toStringAsFixed(0)}'),
                  _amount('Paid Amount', '₹${_value(paid)}'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _amount(
                        'Due Amount',
                        '₹${pending.toStringAsFixed(0)}',
                        danger: pending > 0,
                      ),
                      if (hasOverpaid) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Overpaid: ₹${overpaid.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ], onEdit: _editPayment),
            Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: returned ? 0.45 : 1.0,
                    child: IgnorePointer(
                      ignoring: returned,
                      child: OutlinedButton.icon(
                        onPressed: widget.onExtend == null
                            ? null
                            : () async {
                                await widget.onExtend!.call();
                                await _reloadBooking();
                              },
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: const Text('Extend Booking'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Opacity(
                    opacity: returned ? 0.45 : 1.0,
                    child: IgnorePointer(
                      ignoring: returned,
                      child: ElevatedButton.icon(
                        onPressed: returned
                            ? null
                            : () => widget.onReturn?.call(),
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          returned ? 'Returned' : 'Return Vehicle',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: returned
                              ? Colors.grey
                              : Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _amount(String label, String value, {bool danger = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.ink),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: danger ? Colors.red : AppColors.ink,
          ),
        ),
      ],
    );
  }

  Future<void> _openWhatsApp() async {
    final phone = (_phone.isEmpty ? _whatsapp : _phone).replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) return;
    final dialCode = phone.length == 10 ? '91' : '';
    final uri = Uri.https('wa.me', '/$dialCode$phone', {
      'text':
          'Booking details: $_name, ${widget.customer.vehicleName}, ${_handover['vehicleNumber'] ?? 'N/A'}, ${_handover['vehicleGivenDate'] ?? widget.customer.sDate} to ${_handover['vehicleReturnDate'] ?? widget.customer.returnDate}.',
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'Returned' ? Colors.amber.shade700 : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
