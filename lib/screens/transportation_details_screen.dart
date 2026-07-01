import 'package:flutter/material.dart';
import '../models/transportation_model.dart';
import '../theme/app_theme.dart';

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
  final dispPaperController = TextEditingController();
  final documentPendingController = TextEditingController();
  final dlrMailController = TextEditingController();
  final pickupDateController = TextEditingController();
  final pickupTimeController = TextEditingController();
  final pickupLocationController = TextEditingController();
  final dropDateController = TextEditingController();
  final dropTimeController = TextEditingController();
  final dropLocationController = TextEditingController();
  final stayController = TextEditingController();
  final kmsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    dispPaperController.text = data.dispPaper;
    documentPendingController.text = data.documentPending;
    dlrMailController.text = data.dlrMail;
    pickupDateController.text = data.pickupDate;
    pickupTimeController.text = data.pickupTime;
    pickupLocationController.text = data.pickupLocation;
    dropDateController.text = data.dropDate;
    dropTimeController.text = data.dropTime;
    dropLocationController.text = data.dropLocation;
    stayController.text = data.stay;
    kmsController.text = data.kms > 0 ? data.kms.toString() : '';
  }

  @override
  void dispose() {
    dispPaperController.dispose();
    documentPendingController.dispose();
    dlrMailController.dispose();
    pickupDateController.dispose();
    pickupTimeController.dispose();
    pickupLocationController.dispose();
    dropDateController.dispose();
    dropTimeController.dispose();
    dropLocationController.dispose();
    stayController.dispose();
    kmsController.dispose();
    super.dispose();
  }

  Transportation _buildTransportationData() {
    return Transportation(
      dispPaper: dispPaperController.text.trim(),
      documentPending: documentPendingController.text.trim(),
      dlrMail: dlrMailController.text.trim(),
      pickupDate: pickupDateController.text.trim(),
      pickupTime: pickupTimeController.text.trim(),
      pickupLocation: pickupLocationController.text.trim(),
      dropDate: dropDateController.text.trim(),
      dropTime: dropTimeController.text.trim(),
      dropLocation: dropLocationController.text.trim(),
      stay: stayController.text.trim(),
      kms: int.tryParse(kmsController.text.trim()) ?? 0,
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

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final currentDate = _parseDate(controller.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = _formatDate(picked);
    }
  }

  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final currentTime = _parseTime(controller.text);
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      controller.text = _formatTime(picked);
    }
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
                      'DISP. PAPER',
                      dispPaperController,
                    ),
                    const SizedBox(height: 16),
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
            // const SizedBox(height: 5),

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
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Pickup Date',
                            pickupDateController,
                            readOnly: true,
                            onTap: () => _selectDate(context, pickupDateController),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            'Pickup Time',
                            pickupTimeController,
                            readOnly: true,
                            onTap: () => _selectTime(context, pickupTimeController),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Pickup Location',
                      pickupLocationController,
                    ),
                  ],
                ),
              ),
            ),
            // const SizedBox(height: 16),

            // Card 3: Drop Information
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
                      'Drop Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Drop Date',
                            dropDateController,
                            readOnly: true,
                            onTap: () => _selectDate(context, dropDateController),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            'Drop Time',
                            dropTimeController,
                            readOnly: true,
                            onTap: () => _selectTime(context, dropTimeController),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Drop Location',
                      dropLocationController,
                    ),
                  ],
                ),
              ),
            ),
            // const SizedBox(height: 16),

            // Card 4: Additional Information
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
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Stay',
                            stayController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            'KMS',
                            kmsController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // const SizedBox(height: 32),

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