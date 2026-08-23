import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/customer_documents.dart';
import '../models/transportation_model.dart';
import '../screens/transportation_details_screen.dart';
import '../services/challan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/form_image_picker.dart';

class ChallanEntry {
  final String fyear;
  final String custCode;
  final String partyName;
  final String sDate;
  final String address;
  final String address2;
  final String landmark;
  final String area;
  final String city;
  final String pincode;
  final String smsPhone;
  final String reference;
  final String aadharNo;
  final String licenceNo;
  final String remark;
  final String fineRs;
  final String returnDate;
  final String vehicleName;
  final String days;
  final String rate;
  final String billAmount;
  final String pickupRs;
  final String dropRs;
  final String extraP;
  final String helmet;
  final Transportation? transportation;

  ChallanEntry({
    required this.fyear,
    required this.custCode,
    required this.partyName,
    required this.sDate,
    required this.address,
    required this.address2,
    required this.landmark,
    required this.area,
    required this.city,
    required this.pincode,
    required this.smsPhone,
    required this.reference,
    required this.aadharNo,
    required this.licenceNo,
    required this.remark,
    required this.fineRs,
    required this.returnDate,
    required this.vehicleName,
    required this.days,
    required this.rate,
    required this.billAmount,
    required this.pickupRs,
    required this.dropRs,
    required this.extraP,
    required this.helmet,
    this.transportation,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'fyear': fyear,
      'custCode': custCode,
      'partyName': partyName,
      'sDate': sDate,
      'address': address,
      'address2': address2,
      'landmark': landmark,
      'area': area,
      'city': city,
      'pincode': pincode,
      'smsPhone': smsPhone,
      'reference': reference,
      'aadharNo': aadharNo,
      'licenceNo': licenceNo,
      'remark': remark,
      'fineRs': fineRs,
      'returnDate': returnDate,
      'vehicleName': vehicleName,
      'days': days,
      'rate': rate,
      'billAmount': billAmount,
      'pickupRs': pickupRs,
      'dropRs': dropRs,
      'extraP': extraP,
      'helmet': helmet,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (transportation != null && !transportation!.isEmpty) {
      map['transportation'] = transportation!.toMap();
    }

    return map;
  }
}

class ChallanForm {
  static final CollectionReference<Customer> _customersCollection =
      FirebaseFirestore.instance.collection('customers').withConverter<Customer>(
            fromFirestore: (snapshot, _) => Customer.fromFirestore(snapshot),
            toFirestore: (customer, _) => customer.toMap(),
          );

  static CollectionReference<Customer> get customersCollection => _customersCollection;

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _ChallanFormWidget();
      },
    );
    return result ?? false;
  }

  static Future<bool> showForEdit(
    BuildContext context, {
    required String custCode,
    required String sDate,
    required String partyName,
    required String address,
    required String address2,
    required String landmark,
    required String area,
    required String city,
    required String pincode,
    required String smsPhone,
    required String reference,
    required String aadharNo,
    required String licenceNo,
    required String remark,
    required String fineRs,
    required String returnDate,
    required String vehicleName,
    required String days,
    required String rate,
    required String billAmount,
    required String pickupRs,
    required String dropRs,
    required String extraP,
    required String helmet,
    Transportation? transportation,
    CustomerDocuments? customerDocuments,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ChallanFormWidget(
          custCode: custCode,
          sDate: sDate,
          partyName: partyName,
          address: address,
          address2: address2,
          landmark: landmark,
          area: area,
          city: city,
          pincode: pincode,
          smsPhone: smsPhone,
          reference: reference,
          aadharNo: aadharNo,
          licenceNo: licenceNo,
          remark: remark,
          fineRs: fineRs,
          returnDate: returnDate,
          vehicleName: vehicleName,
          days: days,
          rate: rate,
          billAmount: billAmount,
          pickupRs: pickupRs,
          dropRs: dropRs,
          extraP: extraP,
          helmet: helmet,
          transportation: transportation,
          customerDocuments: customerDocuments,
        );
      },
    );
    return result ?? false;
  }
}

class _ChallanFormWidget extends StatefulWidget {
  final String? custCode;
  final String? sDate;
  final String? partyName;
  final String? address;
  final String? address2;
  final String? landmark;
  final String? area;
  final String? city;
  final String? pincode;
  final String? smsPhone;
  final String? reference;
  final String? aadharNo;
  final String? licenceNo;
  final String? remark;
  final String? fineRs;
  final String? returnDate;
  final String? vehicleName;
  final String? days;
  final String? rate;
  final String? billAmount;
  final String? pickupRs;
  final String? dropRs;
  final String? extraP;
  final String? helmet;
  final Transportation? transportation;
  final CustomerDocuments? customerDocuments;

  const _ChallanFormWidget({
    this.sDate,
    this.custCode,
    this.partyName,
    this.address,
    this.address2,
    this.landmark,
    this.area,
    this.city,
    this.pincode,
    this.smsPhone,
    this.reference,
    this.aadharNo,
    this.licenceNo,
    this.remark,
    this.fineRs,
    this.returnDate,
    this.vehicleName,
    this.days,
    this.rate,
    this.billAmount,
    this.pickupRs,
    this.dropRs,
    this.extraP,
    this.helmet,
    this.transportation,
    this.customerDocuments,
  });



  @override
  State<_ChallanFormWidget> createState() => _ChallanFormWidgetState();
}

class _ChallanFormWidgetState extends State<_ChallanFormWidget> {
  final _formKey = GlobalKey<FormState>();

  final customerCodeController = TextEditingController();
  final dateController = TextEditingController();
  final fyearController = TextEditingController();
  final partyNameController = TextEditingController();
  final addressController = TextEditingController();
  final landmarkController = TextEditingController();
  final areaController = TextEditingController();
  final cityController = TextEditingController();
  final address2Controller = TextEditingController();
  final pincodeController = TextEditingController();
  final smsPhoneController = TextEditingController();
  final referenceController = TextEditingController();
  final aadharController = TextEditingController();
  final licenceController = TextEditingController();
  final remarkController = TextEditingController();
  final fineController = TextEditingController();
  final vehicleController = TextEditingController();
  final rateController = TextEditingController();
  final pickupController = TextEditingController();
  final dropController = TextEditingController();
  final returnDateController = TextEditingController();
  final daysController = TextEditingController();
  final billAmountController = TextEditingController();
  final extraController = TextEditingController();
  final helmetController = TextEditingController();

  Transportation? _transportationData;
  CustomerDocuments? _customerDocuments;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();

    _isEditMode = widget.custCode != null && widget.custCode!.isNotEmpty;

    if (_isEditMode) {
      customerCodeController.text = widget.custCode ?? '';
      fyearController.text = widget.custCode?.split('/')[0] ?? _currentFinancialYear();
      dateController.text = widget.sDate ?? _formatChallanDateTime(DateTime.now());
      partyNameController.text = widget.partyName ?? '';
      addressController.text = widget.address ?? '';
      address2Controller.text = widget.address2 ?? '';
      landmarkController.text = widget.landmark ?? '';
      areaController.text = widget.area ?? '';
      cityController.text = widget.city ?? '';
      pincodeController.text = widget.pincode ?? '';
      smsPhoneController.text = widget.smsPhone ?? '';
      referenceController.text = widget.reference ?? '';
      aadharController.text = widget.aadharNo ?? '';
      licenceController.text = widget.licenceNo ?? '';
      remarkController.text = widget.remark ?? '';
      fineController.text = widget.fineRs ?? '';
      returnDateController.text = widget.returnDate ?? '';
      vehicleController.text = widget.vehicleName ?? '';
      daysController.text = widget.days ?? '';
      rateController.text = widget.rate ?? '';
      billAmountController.text = widget.billAmount ?? '';
      pickupController.text = widget.pickupRs ?? '';
      dropController.text = widget.dropRs ?? '';
      extraController.text = widget.extraP ?? '';
      helmetController.text = widget.helmet ?? '';
      _transportationData = widget.transportation;
      _customerDocuments = widget.customerDocuments;
    } else {
      final fyear = _currentFinancialYear();
      fyearController.text = fyear;
      dateController.text = _formatChallanDateTime(DateTime.now());
      customerCodeController.text = ChallanService.buildCustomerCode(fyear, 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateCustomerCode(fyear);
      });
    }
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatChallanDateTime(DateTime dateTime) {
    return '${_twoDigits(dateTime.day)}-${_twoDigits(dateTime.month)}-${dateTime.year} '
        '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}:${_twoDigits(dateTime.second)}';
  }

  DateTime? _parseChallanDateTime(String value) {
    final match = RegExp(
      r'^(\d{2})-(\d{2})-(\d{4}) (\d{2}):(\d{2}):(\d{2})$',
    ).firstMatch(value);
    if (match == null) return null;

    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
  }

  String _currentFinancialYear() {
    final now = DateTime.now();
    final currentYear = now.year;
    final fiscalYearStart = DateTime(currentYear, 4, 1);
    if (now.isBefore(fiscalYearStart)) {
      return '${currentYear - 1}-$currentYear';
    }
    return '$currentYear-${currentYear + 1}';
  }

  Future<void> _generateCustomerCode(String fyear) async {
    if (_isEditMode) return;

    try {
      final nextCode = await ChallanService.generateCustomerCodeForFinancialYear(fyear);
      if (!mounted) return;
      customerCodeController.text = nextCode;
      setState(() {});
    } catch (error) {
      debugPrint('Failed to load next customer code: $error');
    }
  }

  @override
  void dispose() {
    customerCodeController.dispose();
    dateController.dispose();
    fyearController.dispose();
    partyNameController.dispose();
    addressController.dispose();
    landmarkController.dispose();
    areaController.dispose();
    cityController.dispose();
    address2Controller.dispose();
    pincodeController.dispose();
    smsPhoneController.dispose();
    referenceController.dispose();
    aadharController.dispose();
    licenceController.dispose();
    remarkController.dispose();
    fineController.dispose();
    vehicleController.dispose();
    rateController.dispose();
    pickupController.dispose();
    dropController.dispose();
    returnDateController.dispose();
    daysController.dispose();
    billAmountController.dispose();
    extraController.dispose();
    helmetController.dispose();
    super.dispose();
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool readOnly = false,
    bool required = false,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTap: onTap,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDocumentSection() {
    return Column(
      children: [
        FormImagePicker(
          label: 'Aadhaar / License - Front',
          imageUrl: _customerDocuments?.idFront,
          folder: 'documents',
          onImageSelected: (url) {
            setState(() {
              _customerDocuments =
                  (_customerDocuments ?? CustomerDocuments()).copyWith(idFront: url);
            });
          },
        ),
        FormImagePicker(
          label: 'Aadhaar / License - Back',
          imageUrl: _customerDocuments?.idBack,
          folder: 'documents',
          onImageSelected: (url) {
            setState(() {
              _customerDocuments =
                  (_customerDocuments ?? CustomerDocuments()).copyWith(idBack: url);
            });
          },
        ),
        FormImagePicker(
          label: 'Customer with Vehicle/Ticket',
          imageUrl: _customerDocuments?.customerPhoto,
          folder: 'customer',
          onImageSelected: (url) {
            setState(() {
              _customerDocuments = (_customerDocuments ?? CustomerDocuments())
                  .copyWith(customerPhoto: url);
            });
          },
        ),
        FormImagePicker(
          label: 'Travel Ticket (Optional)',
          imageUrl: _customerDocuments?.travelTicketPhoto,
          folder: 'travel',
          onImageSelected: (url) {
            setState(() {
              _customerDocuments = (_customerDocuments ?? CustomerDocuments())
                  .copyWith(travelTicketPhoto: url);
            });
          },
        ),
      ],
    );
  }

  Future<void> _saveChallanEntry(ChallanEntry entry) async {
    try {
      await ChallanService.saveChallanWithTransaction(
        custCode: entry.custCode,
        customerData: entry.toMap(),
        transportation: entry.transportation?.toMap(),
        documents: _customerDocuments?.toMap(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challan saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error saving Challan: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save Challan: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.65,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_document,
                            color: Colors.white,
                            size: 34,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEditMode ? 'Edit Challan' : 'Challan Entry',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isEditMode
                                      ? 'Update customer and booking details.'
                                      : 'Fill in customer and booking details.',
                                  style: const TextStyle(
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
                    const SizedBox(height: 18),
                    _buildTextField(
                      'Cust. Code',
                      customerCodeController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'Date',
                      dateController,
                      readOnly: true,
                      onTap: () async {
                        final currentDateTime =
                            _parseChallanDateTime(dateController.text) ??
                                DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: currentDateTime,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          if (!context.mounted) return;
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(currentDateTime),
                          );
                          final time =
                              pickedTime ?? TimeOfDay.fromDateTime(currentDateTime);
                          dateController.text = _formatChallanDateTime(
                            DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              time.hour,
                              time.minute,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField('Fyear', fyearController, readOnly: true),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'Party\'s Name',
                      partyNameController,
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField('Address', addressController, maxLines: 2),
                    const SizedBox(height: 12),
                    _buildTextField('Address2', address2Controller),
                    const SizedBox(height: 12),
                    _buildTextField('Landmark', landmarkController),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('Area', areaController),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField('City', cityController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField('Pincode', pincodeController),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'SMS Phone',
                            smsPhoneController,
                            required: true,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            'Reference',
                            referenceController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Aadhar No.',
                            aadharController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            'Licence No.',
                            licenceController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField('Remark', remarkController, maxLines: 3),
                    const SizedBox(height: 20),
                    const Text(
                      'Customer Documents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentSection(),
                    const SizedBox(height: 20),
                    const Text(
                      'Booking Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('Fine Rs.', fineController),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            'Return Date',
                            returnDateController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: vehicleController.text.isEmpty
                                ? null
                                : vehicleController.text,
                            decoration: InputDecoration(
                              labelText: 'Vehicle Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Activa', child: Text('Activa')),
                              DropdownMenuItem(value: 'Access', child: Text('Access')),
                              DropdownMenuItem(value: 'Splendor', child: Text('Splendor')),
                              DropdownMenuItem(value: 'Honda Shine', child: Text('Honda Shine')),
                              DropdownMenuItem(value: 'Classic 350', child: Text('Classic 350')),
                            ],
                            onChanged: (value) {
                              vehicleController.text = value ?? '';
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vehicle Name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField('Days', daysController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('Rate', rateController),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            'Bill Amt',
                            billAmountController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('Pickup Rs.', pickupController),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField('Drop Rs.', dropController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('Extra P.', extraController),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField('Helmet', helmetController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (!(_formKey.currentState?.validate() ?? false) ||
                            !(_customerDocuments?.isComplete ?? false)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(!(_customerDocuments?.isComplete ?? false)
                                  ? 'Please upload all required customer documents.'
                                  : 'Please fill all required fields.'),
                              backgroundColor: Colors.orange.shade700,
                            ),
                          );
                          return;
                        }

                        try {
                          final entry = ChallanEntry(
                            fyear: fyearController.text.trim(),
                            custCode: customerCodeController.text.trim(),
                            partyName: partyNameController.text.trim(),
                            sDate: dateController.text.trim(),
                            address: addressController.text.trim(),
                            address2: address2Controller.text.trim(),
                            landmark: landmarkController.text.trim(),
                            area: areaController.text.trim(),
                            city: cityController.text.trim(),
                            pincode: pincodeController.text.trim(),
                            smsPhone: smsPhoneController.text.trim(),
                            reference: referenceController.text.trim(),
                            aadharNo: aadharController.text.trim(),
                            licenceNo: licenceController.text.trim(),
                            remark: remarkController.text.trim(),
                            fineRs: fineController.text.trim(),
                            returnDate: returnDateController.text.trim(),
                            vehicleName: vehicleController.text.trim(),
                            days: daysController.text.trim(),
                            rate: rateController.text.trim(),
                            billAmount: billAmountController.text.trim(),
                            pickupRs: pickupController.text.trim(),
                            dropRs: dropController.text.trim(),
                            extraP: extraController.text.trim(),
                            helmet: helmetController.text.trim(),
                            transportation: _transportationData,
                          );

                          await _saveChallanEntry(entry);
                          if (!context.mounted) return;
                          Navigator.of(context).pop(true);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error saving: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.ember,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Save Challan',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final result = await Navigator.push<Transportation>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransportationDetailsScreen(
                              initialData: _transportationData,
                            ),
                          ),
                        );
                        if (result != null && mounted) {
                          setState(() {
                            _transportationData = result;
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.ember),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.local_shipping,
                            size: 20,
                            color: AppColors.ember,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _transportationData != null &&
                                    !_transportationData!.isEmpty
                                ? 'Transportation Details (Added)'
                                : 'Transportation Details',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.ember,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}