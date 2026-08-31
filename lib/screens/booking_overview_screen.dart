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
    final locationController = TextEditingController(
      text: (_handover['vehiclePickupLocation'] ?? '').toString(),
    );
    DateTime? pickupDate = _parseBookingDate(_handover['vehicleGivenDate']);
    TimeOfDay? pickupTime = _parseBookingTime(_handover['vehicleGivenTime']);
    DateTime? returnDate = _parseBookingDate(
      _handover['vehicleReturnDate'] ?? widget.customer.returnDate,
    );
    TimeOfDay? returnTime = _parseBookingTime(_handover['vehicleReturnTime']);

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
                _dateTimeEditField(
                  label: 'Pickup Date & Time',
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
                  label: 'Return Date & Time',
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
    locationController.dispose();
  }

  Future<void> _editRental() async {
    final startController = TextEditingController(
      text: (_transport['startingKm'] ?? _handover['kmStartingNumber'] ?? '')
          .toString(),
    );
    final rateController = TextEditingController(text: _rate);
    var hasExtraHelmet = _hasExtraHelmet;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refresh) => AlertDialog(
          title: const Text('Edit Rental Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Start KM'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Rate / Day'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _helmetOption(
                      '1 Helmet',
                      Icons.sports_motorsports_outlined,
                      !hasExtraHelmet,
                      () => refresh(() => hasExtraHelmet = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _helmetOption(
                      '2 Helmets',
                      Icons.sports_motorsports_outlined,
                      hasExtraHelmet,
                      () => refresh(() => hasExtraHelmet = true),
                    ),
                  ),
                ],
              ),
            ],
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
                await _updateFirestore({
                  'transportation': transport,
                  'rate': rateController.text.trim(),
                  'billAmount': _calculateTotal(
                    _days,
                    rateController.text.trim(),
                    hasExtraHelmet,
                  ).toString(),
                  'hasExtraHelmet': hasExtraHelmet,
                  'extraHelmetCharge': hasExtraHelmet ? 50.0 : 0.0,
                });
                if (!mounted) return;
                setState(() {
                  _transport = transport;
                  _rate = rateController.text.trim();
                  _hasExtraHelmet = hasExtraHelmet;
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
    startController.dispose();
    rateController.dispose();
  }

  DateTime? _parseBookingDate(Object? value) {
    final parts = value?.toString().split(' ')[0].split('-') ?? [];
    if (parts.length != 3) return null;
    return DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
  }

  TimeOfDay? _parseBookingTime(Object? value) {
    final parts = value?.toString().split(':') ?? [];
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    return hour == null || minute == null
        ? null
        : TimeOfDay(hour: hour, minute: minute);
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

  Widget _helmetOption(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.black : const Color(0xFFE0E0E0),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
            ),
            const SizedBox(width: 5),
            Icon(icon, size: 26),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editPayment() async {
    await _editSection(
      'Payment',
      {
        'Paid Amount': _paid,
        'Reference ID': (_data['referenceId'] ?? '').toString(),
      },
      (values) async {
        await _updateFirestore({
          'paidAmount': values['Paid Amount'],
          'referenceId': values['Reference ID'],
        });
        setState(() {
          _paid = values['Paid Amount']!;
          _data['paidAmount'] = _paid;
          _data['referenceId'] = values['Reference ID'];
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final handover = _handover;
    final transportation = _transport;
    final status = (handover['returnStatus'] ?? 'Pending').toString();
    final returned = status.toLowerCase() == 'returned';
    final paid = _paid;
    final bill = _bill;
    final pending = (bill - (double.tryParse(paid.toString()) ?? 0)).clamp(
      0,
      double.infinity,
    );

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
                  Icons.calendar_month_outlined,
                  'Pickup Date & Time',
                  '${_value(handover['vehicleGivenDate'])} ${_value(handover['vehicleGivenTime'])}',
                ),
                _detail(
                  Icons.calendar_month_outlined,
                  'Return Date & Time',
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
                _detail(
                  Icons.sports_motorsports_outlined,
                  'Helmet',
                  _hasExtraHelmet ? '2 Helmets' : '1 Helmet',
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
                  _amount(
                    'Due Amount',
                    '₹${pending.toStringAsFixed(0)}',
                    danger: pending > 0,
                  ),
                ],
              ),
            ], onEdit: _editPayment),
            Row(
              children: [
                Expanded(
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
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: returned ? null : () => widget.onReturn?.call(),
                    icon: const Icon(Icons.refresh),
                    label: Text(returned ? 'Returned' : 'Return Vehicle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
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
