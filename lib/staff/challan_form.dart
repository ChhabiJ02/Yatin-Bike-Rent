import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  final String pinCode;
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
    required this.pinCode,
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
      'pinCode': pinCode,
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
  static final CollectionReference<Map<String, dynamic>> _challansCollection =
      FirebaseFirestore.instance.collection('challans');

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
  final pinCodeController = TextEditingController();
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
    pinCodeController.dispose();
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

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
    );
  }

  Future<void> _saveChallanEntry(ChallanEntry entry) async {
    await ChallanForm._challansCollection.add(entry.toMap());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Firebase successfully.')));
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text(
                    'Challan Entry',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fill in the customer and booking details.',
                    style: TextStyle(color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  _buildTextField('Cust. Code', customerCodeController),
                  const SizedBox(height: 12),
                  _buildTextField('Date', dateController),
                  const SizedBox(height: 12),
                  _buildTextField('Fyear', fyearController),
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
                  _buildTextField('Pincode', pinCodeController),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('SMS Phone', smsPhoneController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Reference', referenceController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Aadhar No.', aadharController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Licence No.', licenceController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('Remark', remarkController, maxLines: 3),
                  const SizedBox(height: 20),
                  const Text(
                    'Booking Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Fine Rs.', fineController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Return Date', returnDateController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Vehicle Name', vehicleController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Days', daysController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Rate', rateController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Bill Amt', billAmountController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Pickup Rs.', pickupController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Drop Rs.', dropController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Extra P.', extraController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Helmet', helmetController)),
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
                        pinCode: pinCodeController.text.trim(),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save Entry', style: TextStyle(fontSize: 16)),
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
