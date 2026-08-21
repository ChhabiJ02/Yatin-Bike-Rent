import 'package:flutter/material.dart';
import '../models/transportation_model.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class TransportationDetailsScreen extends StatefulWidget {
  final Transportation? initialData;

  const TransportationDetailsScreen({
    super.key,
    this.initialData,
  });

  @override
  State<TransportationDetailsScreen> createState() => _TransportationDetailsScreenState();
}

class _TransportationDetailsScreenState extends State<TransportationDetailsScreen> {
  final documentPendingController = TextEditingController();
  final dlrMailController = TextEditingController();
  final pickupLocationController = TextEditingController();
  final startingKmController = TextEditingController();

  DateTime? _pickupDateTime;
  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    documentPendingController.text = data.documentPending;
    dlrMailController.text = data.dlrMail;
    pickupLocationController.text = data.pickupLocation;
    startingKmController.text = data.startingKm;

    final initialDate = _parseDate(data.pickupDate);
    final initialTime = _parseTime(data.pickupTime);
    if (initialDate != null) {
      _pickupDateTime = DateTime(initialDate.year, initialDate.month, initialDate.day, initialTime?.hour ?? 0, initialTime?.minute ?? 0);
    }
  }

  @override
  void dispose() {
    documentPendingController.dispose();
    dlrMailController.dispose();
    pickupLocationController.dispose();
    startingKmController.dispose();
    super.dispose();
  }

  Transportation _buildTransportationData() {
    return Transportation(
      dispPaper: '', // Field remove karel hovathi empty string pass kari chhe
      documentPending: documentPendingController.text.trim(),
      dlrMail: dlrMailController.text.trim(),
      pickupDate: _pickupDateTime != null ? _formatDate(_pickupDateTime!) : '',
      pickupTime: _pickupDateTime != null ? _formatTime(TimeOfDay.fromDateTime(_pickupDateTime!)) : '',
      pickupLocation: pickupLocationController.text.trim(),
      startingKm: startingKmController.text.trim(),
      dropDate: '',
      dropTime: '',
      dropLocation: '',
      stay: '',
      kms: 0,
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool readOnly = false,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    final match = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(value);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
  }

  TimeOfDay? _parseTime(String value) {
    if (value.isEmpty) return null;
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) return null;
    return TimeOfDay(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }

  void _handleBack() {
    final transportationData = _buildTransportationData();
    Navigator.pop(context, transportationData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Transportation Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transportation Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Fill in transportation and logistics details.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Card 1: Paper Information
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      'Document Pending',
                      documentPendingController,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'DLR Mail',
                      dlrMailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
            ),

            // Card 2: Pickup Information
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _pickupDateTime ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null && mounted) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_pickupDateTime ?? DateTime.now()),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              _pickupDateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Pickup Date and Time',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _pickupDateTime != null
                              ? DateFormat('dd-MM-yyyy HH:mm').format(_pickupDateTime!)
                              : 'Select Date and Time',
                          style: TextStyle(color: _pickupDateTime != null ? AppColors.ink : AppColors.muted),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Pickup Location',
                      pickupLocationController,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Starting KM',
                      startingKmController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),

            // Back Button
            ElevatedButton(
              onPressed: _handleBack,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.ember,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back),
                  SizedBox(width: 8),
                  Text(
                    'Back to Challan Entry',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}