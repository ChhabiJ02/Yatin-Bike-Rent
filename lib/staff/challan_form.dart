import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../admin/transportation_form.dart';
import '../theme/app_theme.dart';

class ChallanEntry {
  final String fyear;
  final String cCode;
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

  ChallanEntry({
    required this.fyear,
    required this.cCode,
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
  });

  Map<String, dynamic> toMap() {
    return {
      'fyear': fyear,
      'cCode': cCode,
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
  }
}

class ChallanForm {
  static final CollectionReference<Map<String, dynamic>> _customersCollection =
      FirebaseFirestore.instance.collection('customers');

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
}

class _CustomerCodeResult {
  final String prefix;
  final int maxId;

  _CustomerCodeResult(this.prefix, this.maxId);
}

class _ChallanFormWidget extends StatefulWidget {
  const _ChallanFormWidget();

  @override
  State<_ChallanFormWidget> createState() => _ChallanFormWidgetState();
}

class _ChallanFormWidgetState extends State<_ChallanFormWidget> {
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

  @override
  void initState() {
    super.initState();
    final fyear = _currentFinancialYear();
    fyearController.text = fyear;
    customerCodeController.text = '';
    _loadNextCustomerCode(fyear);
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

  int? _extractNumericSuffix(String code) {
    // Handle codes like 26260001 or older 2627006 forms.
    final exactMatch = RegExp(r'^\d{4}0+(\d+)$').firstMatch(code);
    if (exactMatch != null) {
      return int.tryParse(exactMatch.group(1)!);
    }
    if (code.length > 6) {
      return int.tryParse(code.substring(6));
    }
    return null;
  }

  String _formatCustomerCode(String fyear, int id) {
    // Expecting fyear like '2026-2027'. Produce short form: '26270008'
    // Format: YYYYIIII where YY = last two digits of start year, YY = last two digits of end year,
    // IIII = 4-digit zero-padded incremental ID (ensures 8-digit format).
    try {
      final parts = fyear.split(RegExp(r'[^0-9]+')).where((s) => s.isNotEmpty).toList();
      int start = DateTime.now().year;
      int end = start + 1;
      if (parts.length >= 2) {
        start = int.tryParse(parts[0]) ?? start;
        end = int.tryParse(parts[1]) ?? (start + 1);
      }
      final s2 = (start % 100).toString().padLeft(2, '0');
      final e2 = (end % 100).toString().padLeft(2, '0');
      final idStr = id.toString().padLeft(4, '0');
      return '$s2$e2$idStr';
    } catch (_) {
      return id.toString().padLeft(4, '0');
    }
  }

  String _formatCustomerCodeWithPrefix(String prefix, int id) {
    return '$prefix${id.toString().padLeft(4, '0')}';
  }

  Future<_CustomerCodeResult> _findMaxCustomerIdForFyear(String fyear) async {
    final currentPrefix = _codePrefix(fyear);
    int maxId = 0;

    // 1) Scan customers for the same financial year and check both cCode field and doc.id
    final customersForYear = await ChallanForm._customersCollection
        .where('fyear', isEqualTo: fyear)
        .get();
    for (final doc in customersForYear.docs) {
      final data = doc.data();
      final codeField = data['cCode'] as String?;
      if (codeField != null && codeField.startsWith(currentPrefix)) {
        final s = _extractNumericSuffix(codeField);
        if (s != null && s > maxId) maxId = s;
      }
      final idCode = doc.id;
      if (idCode.startsWith(currentPrefix)) {
        final s = _extractNumericSuffix(idCode);
        if (s != null && s > maxId) maxId = s;
      }
    }

    // 2) Scan all customers (in case some codes were saved under different years)
    final allCustomers = await ChallanForm._customersCollection.get();
    for (final doc in allCustomers.docs) {
      final data = doc.data();
      final codeField = data['cCode'] as String?;
      if (codeField != null && codeField.startsWith(currentPrefix)) {
        final s = _extractNumericSuffix(codeField);
        if (s != null && s > maxId) maxId = s;
      }
      final idCode = doc.id;
      if (idCode.startsWith(currentPrefix)) {
        final s = _extractNumericSuffix(idCode);
        if (s != null && s > maxId) maxId = s;
      }
    }

    // 3) Scan challans for the same financial year and check both cCode field and document id
    final challansForYear = await FirebaseFirestore.instance
        .collection('challans')
        .where('fyear', isEqualTo: fyear)
        .get();
    for (final doc in challansForYear.docs) {
      final data = doc.data();
      final codeField = data['cCode'] as String?;
      if (codeField != null && codeField.startsWith(currentPrefix)) {
        final s = _extractNumericSuffix(codeField);
        if (s != null && s > maxId) maxId = s;
      }
      final idCode = doc.id;
      if (idCode.startsWith(currentPrefix)) {
        final s = _extractNumericSuffix(idCode);
        if (s != null && s > maxId) maxId = s;
      }
    }

    // 4) Scan all challans (in case some codes were saved under different years)
    final allChallans = await FirebaseFirestore.instance.collection('challans').get();
    for (final doc in allChallans.docs) {
      final data = doc.data();
      final codeField = data['cCode'] as String?;
      if (codeField != null && codeField.startsWith(currentPrefix)) {
        final s = _extractNumericSuffix(codeField);
        if (s != null && s > maxId) maxId = s;
      }
      final idCode = doc.id;
      if (idCode.startsWith(currentPrefix)) {
        final s = _extractNumericSuffix(idCode);
        if (s != null && s > maxId) maxId = s;
      }
    }

    debugPrint('findMaxCustomerIdForFyear($fyear) -> prefix=$currentPrefix maxId=$maxId');
    if (maxId > 0) {
      return _CustomerCodeResult(currentPrefix, maxId);
    }

    int fallbackMaxId = 0;
    String fallbackPrefix = currentPrefix;

    final allCustomersFromCustomers = await FirebaseFirestore.instance.collection('customers').get();
    for (final doc in allCustomersFromCustomers.docs) {
      final code = (doc.data()['cCode'] as String?) ?? doc.id;
      final s = _extractNumericSuffix(code);
      if (s != null && s > fallbackMaxId) {
        fallbackMaxId = s;
        fallbackPrefix = code.length >= 4 ? code.substring(0, 4) : code;
      }
    }

    final fallbackChallans = await FirebaseFirestore.instance.collection('challans').get();
    for (final doc in fallbackChallans.docs) {
      final code = (doc.data()['cCode'] as String?) ?? doc.id;
      final s = _extractNumericSuffix(code);
      if (s != null && s > fallbackMaxId) {
        fallbackMaxId = s;
        fallbackPrefix = code.length >= 4 ? code.substring(0, 4) : code;
      }
    }

    debugPrint('Fallback prefix=$fallbackPrefix fallbackMaxId=$fallbackMaxId');
    return _CustomerCodeResult(fallbackPrefix, fallbackMaxId);
  }
  

  String _codePrefix(String fyear) {
    final parts = fyear.split(RegExp(r'[^0-9]+')).where((s) => s.isNotEmpty).toList();
    int start = DateTime.now().year;
    int end = start + 1;
    if (parts.length >= 2) {
      start = int.tryParse(parts[0]) ?? start;
      end = int.tryParse(parts[1]) ?? (start + 1);
    }
    final s2 = (start % 100).toString().padLeft(2, '0');
    final e2 = (end % 100).toString().padLeft(2, '0');
    return '$s2$e2';
  }

  Future<void> _loadNextCustomerCode(String fyear) async {
    try {
      final prefixResult = await _findMaxCustomerIdForFyear(fyear);
      final nextId = prefixResult.maxId + 1;
      final nextCode = _formatCustomerCodeWithPrefix(prefixResult.prefix, nextId);
      debugPrint('Next customer code for $fyear: prefix=${prefixResult.prefix} maxId=${prefixResult.maxId} nextCode=$nextCode');
      if (!mounted) return;
      customerCodeController.text = nextCode;
    } catch (error) {
      debugPrint('Failed to load next customer code: $error');
      if (!mounted) return;
      customerCodeController.text = _formatCustomerCode(fyear, 1);
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
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
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

  Future<void> _saveChallanEntry(ChallanEntry entry) async {
    final data = entry.toMap();
    
    // Parse sDate (YYYY-MM-DD format) to DateTime, then convert to Firestore Timestamp
    try {
      if (entry.sDate.isNotEmpty) {
        final dateTime = DateTime.parse(entry.sDate);
        data['sDate'] = Timestamp.fromDate(dateTime);
      }
    } catch (e) {
      debugPrint('Failed to parse date: $e');
    }
    
    await ChallanForm._customersCollection.doc(entry.cCode).set(data);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to Firebase successfully.')),
    );
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
                    child: const Row(
                      children: [
                        Icon(
                          Icons.edit_document,
                          color: Colors.white,
                          size: 34,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Challan Entry',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Fill in customer and booking details.',
                                style: TextStyle(
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
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        dateController.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('Fyear', fyearController, readOnly: true),
                  const SizedBox(height: 12),
                  _buildTextField('Party\'s Name', partyNameController),
                  const SizedBox(height: 12),
                  _buildTextField('Address', addressController, maxLines: 2),
                  const SizedBox(height: 12),
                  _buildTextField('Address2', address2Controller),
                  const SizedBox(height: 12),
                  _buildTextField('Landmark', landmarkController),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Area', areaController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('City', cityController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('Pincode', pincodeController),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField('SMS Phone', smsPhoneController),
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
                        child: _buildTextField('Aadhar No.', aadharController),
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
                        child: _buildTextField(
                          'Vehicle Name',
                          vehicleController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Days', daysController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Rate', rateController)),
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
                      final navigator = Navigator.of(context);
                      final entry = ChallanEntry(
                        fyear: fyearController.text.trim(),
                        cCode: customerCodeController.text.trim(),
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
                      );

                      await _saveChallanEntry(entry);
                      if (!mounted) return;
                      navigator.pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save Entry',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TransportationForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('Transportation Details'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.sky,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
