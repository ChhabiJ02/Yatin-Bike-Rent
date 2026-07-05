import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_documents.dart';
import '../models/vehicle_handover.dart';
import '../models/travel_details.dart';
import '../models/kilometer_details.dart';
import '../models/transportation_model.dart';
import '../theme/app_theme.dart';
import '../widgets/form_image_picker.dart';
import '../services/challan_service.dart';
import 'transportation_details_screen.dart';

class ChallanEntryScreen extends StatefulWidget {
  final String? custCode;
  final Map<String, dynamic>? existingData;

  const ChallanEntryScreen({super.key, this.custCode, this.existingData});

  @override
  State<ChallanEntryScreen> createState() => _ChallanEntryScreenState();
}

class _ChallanEntryScreenState extends State<ChallanEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customersCollection = FirebaseFirestore.instance.collection('customers');

  // Controllers
  final _custCodeController = TextEditingController();
  final _dateController = TextEditingController();
  final _fyearController = TextEditingController();
  final _partyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aadharController = TextEditingController();
  final _licenseController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _daysController = TextEditingController();
  final _rateController = TextEditingController();
  final _billAmountController = TextEditingController();
  final _startKMController = TextEditingController();
  final _endKMController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _returnLocationController = TextEditingController();
  final _vehicleCameFromController = TextEditingController();
  final _vehicleReturnedToController = TextEditingController();
  final _customerCameFromController = TextEditingController();
  final _stayingAtController = TextEditingController();
  final _hotelNameController = TextEditingController();
  final _stayAddressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();

  // Date/Time for vehicle handover
  DateTime? _vehicleGivenDate;
  TimeOfDay? _vehicleGivenTime;
  DateTime? _vehicleReturnDate;
  TimeOfDay? _vehicleReturnTime;

  // Location options
  static const _pickupLocations = [
    'Surat Branch',
    'Ahmedabad Branch',
    'Mumbai Branch',
    'Delhi Branch',
    'Rajkot Branch',
    'Workshop',
    'Another Customer',
    'Custom Location',
  ];

  static const _cameFromOptions = [
    'Delhi',
    'Mumbai',
    'Ahmedabad',
    'Surat',
    'Rajkot',
    'Jaipur',
    'Kolkata',
    'Chennai',
    'Bangalore',
    'Hyderabad',
    'Other',
  ];

  static const _stayingAtOptions = [
    'Hotel',
    "Friend's House",
    "Relative's House",
    'Own House',
    'Other',
  ];

  // New section data
  CustomerDocuments? _customerDocuments;
  VehicleHandover? _vehicleHandover;
  TravelDetails? _travelDetails;
  KilometerDetails? _kilometerDetails;
  Transportation? _transportation;

  bool _isEditMode = false;
  bool _isSaving = false;

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  Future<void> _generateCustomerCode(String fyear) async {
    if (_isEditMode) {
      return;
    }

    try {
      final code = await ChallanService.generateCustomerCodeForFinancialYear(fyear);
      if (!mounted) return;
      _custCodeController.text = code;
      setState(() {});
    } catch (e) {
      debugPrint('Error generating customer code: $e');
    }
  }

  /// Acquire a unique customer code inside a transaction right before saving.
  /// This ensures no two concurrent saves receive the same code.
  Future<void> _acquireCustomerCodeForSave(String fyear) async {
    if (_isEditMode) return;

    try {
      final code = await ChallanService.generateCustomerCodeWithTransaction(fyear);
      if (!mounted) return;
      _custCodeController.text = code;
      setState(() {});
    } catch (e) {
      debugPrint('Error acquiring transactional customer code: $e');
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    // Set Date and FYear automatically
    final initialFyear = ChallanService.getCurrentFinancialYear();
    _dateController.text = _formatDateTime(DateTime.now());
    _fyearController.text = initialFyear;

    if (widget.custCode != null) {
      // Edit mode - load existing data without generating a new code
      _custCodeController.text = widget.custCode ?? '';
      _isEditMode = true;
      _loadExistingData();
    } else {
      // New entry mode - leave the field blank while the next customer code is generated.
      _custCodeController.text = '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateCustomerCode(initialFyear);
      });
    }
  }

  Future<void> _loadExistingData() async {
    if (widget.custCode == null) return;
    final doc = await _customersCollection.doc(widget.custCode).get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      _partyNameController.text = data['partyName'] ?? '';
      _addressController.text = data['address'] ?? '';
      _phoneController.text = data['smsPhone'] ?? '';
      _aadharController.text = data['aadharNo'] ?? '';
      _licenseController.text = data['licenceNo'] ?? '';
      _vehicleController.text = data['vehicleName'] ?? '';
      _daysController.text = data['days'] ?? '';
      _rateController.text = data['rate'] ?? '';
      _billAmountController.text = data['billAmount'] ?? '';
      // Load existing date and financial year (don't regenerate for editing)
      _dateController.text = data['sDate'] ?? _dateController.text;
      _fyearController.text = data['fyear'] ?? _fyearController.text;

      if (data['customerDocuments'] != null) {
        _customerDocuments = CustomerDocuments.fromMap(Map<String, dynamic>.from(data['customerDocuments']));
      }
      if (data['vehicleHandover'] != null) {
        _vehicleHandover = VehicleHandover.fromMap(Map<String, dynamic>.from(data['vehicleHandover']));
        _vehicleNumberController.text = _vehicleHandover!.vehicleNumber;
        _pickupLocationController.text = _vehicleHandover!.vehiclePickupLocation;
        _returnLocationController.text = _vehicleHandover!.vehicleReturnLocation;
        _vehicleCameFromController.text = _vehicleHandover!.vehicleCameFrom;
        _vehicleReturnedToController.text = _vehicleHandover!.vehicleReturnedTo;
        if (_vehicleHandover!.vehicleGivenDate.isNotEmpty) {
          final parts = _vehicleHandover!.vehicleGivenDate.split('-');
          if (parts.length == 3) {
            _vehicleGivenDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        }
        if (_vehicleHandover!.vehicleGivenTime.isNotEmpty) {
          final parts = _vehicleHandover!.vehicleGivenTime.split(':');
          if (parts.length == 2) {
            _vehicleGivenTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
        }
        if (_vehicleHandover!.vehicleReturnDate.isNotEmpty) {
          final parts = _vehicleHandover!.vehicleReturnDate.split('-');
          if (parts.length == 3) {
            _vehicleReturnDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        }
        if (_vehicleHandover!.vehicleReturnTime.isNotEmpty) {
          final parts = _vehicleHandover!.vehicleReturnTime.split(':');
          if (parts.length == 2) {
            _vehicleReturnTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
        }
      }
      if (data['travelDetails'] != null) {
        _travelDetails = TravelDetails.fromMap(Map<String, dynamic>.from(data['travelDetails']));
        _customerCameFromController.text = _travelDetails!.customerCameFrom;
        _stayingAtController.text = _travelDetails!.stayingAt;
        _hotelNameController.text = _travelDetails!.hotelName;
        _stayAddressController.text = _travelDetails!.stayAddress;
        _landmarkController.text = _travelDetails!.landmark;
        _cityController.text = _travelDetails!.city;
        _stateController.text = _travelDetails!.state;
        _pinCodeController.text = _travelDetails!.pinCode;
      }
      if (data['kilometerDetails'] != null) {
        _kilometerDetails = KilometerDetails.fromMap(Map<String, dynamic>.from(data['kilometerDetails']));
        _startKMController.text = _kilometerDetails!.startKM.toString();
        _endKMController.text = _kilometerDetails!.endKM.toString();
      }
      if (data['transportation'] != null) {
        _transportation = Transportation.fromMap(Map<String, dynamic>.from(data['transportation']));
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _custCodeController.dispose();
    _dateController.dispose();
    _fyearController.dispose();
    _partyNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _aadharController.dispose();
    _licenseController.dispose();
    _vehicleController.dispose();
    _vehicleNumberController.dispose();
    _daysController.dispose();
    _rateController.dispose();
    _billAmountController.dispose();
    _startKMController.dispose();
    _endKMController.dispose();
    _pickupLocationController.dispose();
    _returnLocationController.dispose();
    _vehicleCameFromController.dispose();
    _vehicleReturnedToController.dispose();
    _customerCameFromController.dispose();
    _stayingAtController.dispose();
    _hotelNameController.dispose();
    _stayAddressController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Challan' : 'New Challan'),
        backgroundColor: AppColors.ember,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Code, Date, Financial Year - Read-only fields at top
              _buildSectionHeader('Entry Info'),
              _buildReadOnlyField('Customer Code', _custCodeController),
              _buildTextField('Date', _dateController),
              _buildReadOnlyField('Financial Year', _fyearController),
              const SizedBox(height: 24),
              _buildSectionHeader('Customer Details'),
              _buildTextField('Party Name', _partyNameController, required: true),
              _buildTextField('Phone', _phoneController, keyboardType: TextInputType.phone, required: true),
              _buildTextField('Address', _addressController, maxLines: 2),
              _buildTextField('Aadhar No.', _aadharController),
              _buildTextField('License No.', _licenseController),
              const SizedBox(height: 24),
              _buildSectionHeader('Customer Documents'),
              _buildDocumentSection(),
              const SizedBox(height: 24),
              _buildSectionHeader('Vehicle Handover'),
              _buildVehicleHandoverSection(),
              const SizedBox(height: 24),
              _buildSectionHeader('Travel Details'),
              _buildTravelSection(),
              const SizedBox(height: 24),
              _buildSectionHeader('Kilometer Tracking'),
              _buildKilometerSection(),
              const SizedBox(height: 24),
              _buildSectionHeader('Booking Info'),
              _buildBookingSection(),
              const SizedBox(height: 24),

              // Transportation Details Button
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<Transportation>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransportationDetailsScreen(
                        initialData: _transportation,
                      ),
                    ),
                  );
                  if (result != null && mounted) {
                    setState(() {
                      _transportation = result;
                    });
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: AppColors.ember,
                  side: const BorderSide(color: AppColors.ember),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.local_shipping),
                label: Text(
                  _transportation != null && !_transportation!.isEmpty
                      ? 'Transportation Details (Added)'
                      : 'Transportation Details',
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveChallan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ember,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEditMode ? 'Update Challan' : 'Save Challan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.ember,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: required ? (v) => v == null || v.isEmpty ? '$label required' : null : null,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.ink,
        ),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentSection() {
    return Column(
      children: [
        FormImagePicker(
          label: 'Aadhaar Front',
          imageUrl: _customerDocuments?.aadhaarFront,
          folder: 'documents/${_custCodeController.text}/aadhaar',
          isRequired: true,
          onImageSelected: (url) {
            setState(() {
              _customerDocuments = (_customerDocuments ?? CustomerDocuments())
                  .copyWith(aadhaarFront: url);
            });
          },
        ),
        FormImagePicker(
          label: 'Aadhaar Back',
          imageUrl: _customerDocuments?.aadhaarBack,
          folder: 'documents/${_custCodeController.text}/aadhaar',
          isRequired: true,
          onImageSelected: (url) {
            setState(() {
              _customerDocuments = (_customerDocuments ?? CustomerDocuments())
                  .copyWith(aadhaarBack: url);
            });
          },
        ),
        FormImagePicker(
          label: 'License Front',
          imageUrl: _customerDocuments?.licenseFront,
          folder: 'documents/${_custCodeController.text}/license',
          isRequired: true,
          onImageSelected: (url) {
            setState(() {
              _customerDocuments = (_customerDocuments ?? CustomerDocuments())
                  .copyWith(licenseFront: url);
            });
          },
        ),
        FormImagePicker(
          label: 'License Back',
          imageUrl: _customerDocuments?.licenseBack,
          folder: 'documents/${_custCodeController.text}/license',
          isRequired: true,
          onImageSelected: (url) {
            setState(() {
              _customerDocuments = (_customerDocuments ?? CustomerDocuments())
                  .copyWith(licenseBack: url);
            });
          },
        ),
        FormImagePicker(
          label: 'Customer with Vehicle',
          imageUrl: _customerDocuments?.customerVehiclePhoto,
          folder: 'documents/${_custCodeController.text}/vehicle',
          isRequired: true,
          onImageSelected: (url) {
            setState(() {
              _customerDocuments = (_customerDocuments ?? CustomerDocuments())
                  .copyWith(customerVehiclePhoto: url);
            });
          },
        ),
        FormImagePicker(
          label: 'Travel Ticket (Optional)',
          imageUrl: _customerDocuments?.travelTicketPhoto,
          folder: 'documents/${_custCodeController.text}/travel',
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

  Widget _buildVehicleHandoverSection() {
    return Column(
      children: [
        _buildTextField('Vehicle Name', _vehicleController),
        _buildTextField('Vehicle Number', _vehicleNumberController),
        _buildDropdownField('Pickup Location', _pickupLocationController, _pickupLocations),
        _buildDropdownField('Return Location', _returnLocationController, _pickupLocations),
        const SizedBox(height: 12),
        _buildDateTimePicker('Vehicle Given Date', _vehicleGivenDate, _vehicleGivenTime, (date, time) {
          setState(() {
            _vehicleGivenDate = date;
            _vehicleGivenTime = time;
          });
        }),
        const SizedBox(height: 12),
        _buildDateTimePicker('Vehicle Return Date', _vehicleReturnDate, _vehicleReturnTime, (date, time) {
          setState(() {
            _vehicleReturnDate = date;
            _vehicleReturnTime = time;
          });
        }),
        const SizedBox(height: 12),
        _buildDropdownField('Vehicle Came From', _vehicleCameFromController, _pickupLocations),
        _buildDropdownField('Vehicle Returned To', _vehicleReturnedToController, _pickupLocations),
      ],
    );
  }

  Widget _buildDropdownField(String label, TextEditingController controller, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
        onChanged: (value) {
          if (value != null) {
            controller.text = value;
          }
        },
      ),
    );
  }

  Widget _buildDateTimePicker(
    String label,
    DateTime? date,
    TimeOfDay? time,
    Function(DateTime?, TimeOfDay?) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (pickedDate != null && mounted) {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: time ?? TimeOfDay.now(),
          );
          if (mounted) {
            onChanged(pickedDate, pickedTime);
          }
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null
              ? '${date.day}-${date.month}-${date.year}${time != null ? ' ${time.hour}:${time.minute}' : ''}'
              : 'Select $label',
          style: TextStyle(
            color: date != null ? AppColors.ink : AppColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildTravelSection() {
    return Column(
      children: [
        _buildDropdownField('Customer Came From', _customerCameFromController, _cameFromOptions),
        _buildDropdownField('Staying At', _stayingAtController, _stayingAtOptions),
        _buildTextField('Hotel/Place Name', _hotelNameController),
        _buildTextField('Stay Address', _stayAddressController, maxLines: 2),
        _buildTextField('Landmark', _landmarkController),
        Row(
          children: [
            Expanded(child: _buildTextField('City', _cityController)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('State', _stateController)),
          ],
        ),
        _buildTextField('PIN Code', _pinCodeController, keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildKilometerSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField('Start KM', _startKMController, keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField('End KM', _endKMController, keyboardType: TextInputType.number),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.ember.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Total Distance: ', style: TextStyle(fontSize: 16)),
              Text(
                _calculateTotalKM(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ember),
              ),
              const Text(' KM', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateTotalKM() {
    final start = int.tryParse(_startKMController.text) ?? 0;
    final end = int.tryParse(_endKMController.text) ?? 0;
    if (end >= start && start > 0) {
      return (end - start).toString();
    }
    return '0';
  }

  Widget _buildBookingSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField('Days', _daysController)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Rate/Day', _rateController)),
          ],
        ),
        _buildTextField('Bill Amount', _billAmountController),
      ],
    );
  }

  Future<void> _saveChallan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicleNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle Number is required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (!_isEditMode) {
        final fyear = _fyearController.text.trim().isEmpty
            ? ChallanService.getCurrentFinancialYear()
            : _fyearController.text.trim();
        await _acquireCustomerCodeForSave(fyear);
      }

      final customerCode = _custCodeController.text.trim();
      if (customerCode.isEmpty) {
        throw Exception('Customer code could not be generated');
      }

      // Update kilometer details
      final startKM = int.tryParse(_startKMController.text) ?? 0;
      final endKM = int.tryParse(_endKMController.text) ?? 0;
      if (startKM > 0 || endKM > 0) {
        _kilometerDetails = KilometerDetails(startKM: startKM, endKM: endKM);
      }

      // Build the data map
      final data = {
        'fyear': _fyearController.text,
        'custCode': customerCode,
        'partyName': _partyNameController.text.trim(),
        'sDate': _dateController.text,
        'address': _addressController.text.trim(),
        'smsPhone': _phoneController.text.trim(),
        'aadharNo': _aadharController.text.trim(),
        'licenceNo': _licenseController.text.trim(),
        'vehicleName': _vehicleController.text.trim(),
        'vehicleNumber': _vehicleNumberController.text.trim(),
        'days': _daysController.text.trim(),
        'rate': _rateController.text.trim(),
        'billAmount': _billAmountController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add customer documents if available
      if (_customerDocuments != null && !_customerDocuments!.isEmpty) {
        data['customerDocuments'] = _customerDocuments!.toMap();
      }

      // Add vehicle handover
      String? givenDateStr;
      String? givenTimeStr;
      String? returnDateStr;
      String? returnTimeStr;

      if (_vehicleGivenDate != null) {
        givenDateStr = '${_vehicleGivenDate!.day}-${_vehicleGivenDate!.month}-${_vehicleGivenDate!.year}';
      }
      if (_vehicleGivenTime != null) {
        givenTimeStr = '${_vehicleGivenTime!.hour}:${_vehicleGivenTime!.minute}';
      }
      if (_vehicleReturnDate != null) {
        returnDateStr = '${_vehicleReturnDate!.day}-${_vehicleReturnDate!.month}-${_vehicleReturnDate!.year}';
      }
      if (_vehicleReturnTime != null) {
        returnTimeStr = '${_vehicleReturnTime!.hour}:${_vehicleReturnTime!.minute}';
      }

      _vehicleHandover = VehicleHandover(
        vehicleName: _vehicleController.text.trim(),
        vehicleNumber: _vehicleNumberController.text.trim(),
        vehiclePickupLocation: _pickupLocationController.text.trim(),
        vehicleReturnLocation: _returnLocationController.text.trim(),
        vehicleGivenDate: givenDateStr ?? '',
        vehicleGivenTime: givenTimeStr ?? '',
        vehicleReturnDate: returnDateStr ?? '',
        vehicleReturnTime: returnTimeStr ?? '',
        vehicleCameFrom: _vehicleCameFromController.text.trim(),
        vehicleReturnedTo: _vehicleReturnedToController.text.trim(),
        returnStatus: _vehicleHandover?.returnStatus ?? 'Pending',
      );
      data['vehicleHandover'] = _vehicleHandover!.toMap();

      // Add travel details
      _travelDetails = TravelDetails(
        customerCameFrom: _customerCameFromController.text.trim(),
        stayingAt: _stayingAtController.text.trim(),
        hotelName: _hotelNameController.text.trim(),
        stayAddress: _stayAddressController.text.trim(),
        landmark: _landmarkController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pinCode: _pinCodeController.text.trim(),
      );
      data['travelDetails'] = _travelDetails!.toMap();

      // Add kilometer details
      if (_kilometerDetails != null) {
        data['kilometerDetails'] = _kilometerDetails!.toMap();
      }

      // Add transportation details inside the Challan document
      if (_transportation != null && !_transportation!.isEmpty) {
        data['transportation'] = _transportation!.toMap();
      }

      // Save to Firestore
      await _customersCollection.doc(_custCodeController.text).set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challan saved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }
}