import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_documents.dart';
import '../models/customer.dart';
import '../models/vehicle_handover.dart';
import '../models/travel_details.dart';
import '../models/transportation_model.dart';
import '../theme/app_theme.dart';
import '../widgets/form_image_picker.dart';
import '../services/challan_service.dart';
import '../services/rental_service.dart';
import 'transportation_details_screen.dart';

class ChallanEntryScreen extends StatefulWidget {
  final String? custCode;
  final Map<String, dynamic>? existingData;

  const ChallanEntryScreen({super.key, this.custCode, this.existingData});

  @override
  State<ChallanEntryScreen> createState() => _ChallanEntryScreenState();
}

class _FieldFocus {
  final int step;
  final FocusNode focusNode;
  _FieldFocus(this.step, this.focusNode);
}

class _ChallanEntryScreenState extends State<ChallanEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customersCollection = FirebaseFirestore.instance.collection('customers');
  final _vehiclesCollection = FirebaseFirestore.instance.collection('vehicles');
  final _paymentSettingsCollection = FirebaseFirestore.instance.collection('paymentSettings');

  // Controllers
  final _custCodeController = TextEditingController();
  final _dateController = TextEditingController();
  final _fyearController = TextEditingController();
  final _partyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _customerCityController = TextEditingController();
  final _aadharController = TextEditingController();
  final _licenseController = TextEditingController();

  // Vehicle Entry Controllers
  final _vehicleEntryNoController = TextEditingController();
  final _vehicleEntryNameController = TextEditingController();
  final _vehicleEntryCategoriesController = TextEditingController();
  final _vehicleEntryDescriptionController = TextEditingController();
  final _vehicleChasisNoController = TextEditingController();
  final _vehicleEngNoController = TextEditingController();

  final _vehicleController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _daysController = TextEditingController();
  final _rateController = TextEditingController();
  final _billAmountController = TextEditingController();
  final _depositController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _returnLocationController = TextEditingController();
  final _customerCameFromController = TextEditingController();
  final _stayingAtController = TextEditingController();
  final _hotelNameController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();

  // Controllers for removed sections
  final _dropLocationController = TextEditingController();
  final _dropDateController = TextEditingController();
  final _dropTimeController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  
  // Wizard Step State
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Add-ons State
  bool _hasExtraHelmet = false;
  bool _hasMobileHolder = false;

  // Add-ons Charges
  static const double _extraHelmetCharge = 50.0;
  static const double _mobileHolderCharge = 30.0;

  // Searching State
  bool _isSearchingVehicle = false;

  // Date/Time for vehicle handover
  DateTime? _vehicleGivenDate;
  TimeOfDay? _vehicleGivenTime;
  DateTime? _vehicleReturnDate;
  TimeOfDay? _vehicleReturnTime;

  // Payment Options
  String _selectedPaymentMode = 'Cash';
  static const List<String> _paymentModes = ['Cash', 'UPI / QR', 'Bank Transfer', 'Card'];

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

  CustomerDocuments? _customerDocuments;
  VehicleHandover? _vehicleHandover;
  TravelDetails? _travelDetails;
  Transportation? _transportation;

  // State for selected QR Code
  String? _selectedQRCodeId;
  String? _selectedQRCodeImageUrl;

  final Map<TextEditingController, _FieldFocus> _focusNodes = {};

  bool _isEditMode = false;
  bool _isSaving = false; 

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  // Auto calculate Bill Amount
  void _calculateBillAmount() {
    final double days = double.tryParse(_daysController.text.trim()) ?? 0;
    final double rate = double.tryParse(_rateController.text.trim()) ?? 0;
    final double baseTotal = days * rate;

    final double helmetCharge = _hasExtraHelmet ? _extraHelmetCharge : 0;
    final double holderCharge = _hasMobileHolder ? _mobileHolderCharge : 0;
    final double total = baseTotal + helmetCharge + holderCharge;

    _billAmountController.text = total % 1 == 0 ? total.toInt().toString() : total.toStringAsFixed(2);
  }

  void _calculateReturnDate() {
    try {
      final int days = int.tryParse(_daysController.text.trim()) ?? 0;

      // Determine pickup date/time source (vehicle handover -> transportation -> entry date)
      String? pickupDateStr;
      String? pickupTimeStr;

      if (_vehicleHandover != null) {
        pickupDateStr = _vehicleHandover!.vehicleGivenDate.isNotEmpty
            ? _vehicleHandover!.vehicleGivenDate
            : null;
        pickupTimeStr = _vehicleHandover!.vehicleGivenTime.isNotEmpty
            ? _vehicleHandover!.vehicleGivenTime
            : null;
      }

      if ((pickupDateStr == null || pickupDateStr.isEmpty) && _transportation != null) {
        pickupDateStr = _transportation!.pickupDate.isNotEmpty ? _transportation!.pickupDate : null;
        pickupTimeStr = _transportation!.pickupTime.isNotEmpty ? _transportation!.pickupTime : pickupTimeStr;
      }

      if (pickupDateStr == null || pickupDateStr.isEmpty) {
        // Fallback to _dateController which contains full datetime string
        final full = _dateController.text.trim();
        if (full.isNotEmpty) {
          final parts = full.split(' ');
          pickupDateStr = parts.isNotEmpty ? parts[0] : null;
          if (parts.length > 1) {
            // parts[1] could be HH:MM:SS -> extract HH:MM
            final timeParts = parts[1].split(':');
            if (timeParts.length >= 2) {
              pickupTimeStr = '${timeParts[0]}:${timeParts[1]}';
            }
          }
        }
      }

      DateTime base = DateTime.now();
      final parsedDate = _parseDate(pickupDateStr);
      if (parsedDate != null) base = parsedDate;

      if (pickupTimeStr != null && pickupTimeStr.isNotEmpty) {
        final time = _parseTime(pickupTimeStr);
        if (time != null) {
          base = DateTime(base.year, base.month, base.day, time.hour, time.minute);
        }
      }

      final returnDt = base.add(Duration(days: days));
      setState(() {
        _vehicleReturnDate = DateTime(returnDt.year, returnDt.month, returnDt.day);
        _vehicleReturnTime = TimeOfDay(hour: returnDt.hour, minute: returnDt.minute);
      });
    } catch (e) {
      debugPrint('Error calculating return date: $e');
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _searchVehicle() async {
    final vehicleNo = _vehicleEntryNoController.text.trim();
    if (vehicleNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a vehicle number.')),
      );
      return;
    }

    setState(() {
      _isSearchingVehicle = true;
      _clearVehicleEntryFields(clearNumber: false);
    });

    try {
      final vehicleDoc = await RentalService.findVehicleByNumber(vehicleNo);

      if (mounted) {
        if (vehicleDoc != null && vehicleDoc.exists) {
          _populateVehicleEntryFields(vehicleDoc);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle details loaded successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle not found.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingVehicle = false;
        });
      }
    }
  }

  void _populateVehicleEntryFields(DocumentSnapshot<Map<String, dynamic>> vehicleDoc) {
    final data = vehicleDoc.data();
    if (data == null) return;

    _vehicleEntryNameController.text = data['name'] ?? data['vehicleName'] ?? '';
    _vehicleEntryCategoriesController.text = data['category'] ?? data['type'] ?? '';
    _vehicleEntryDescriptionController.text = data['description'] ?? '';
    _vehicleChasisNoController.text = data['chasisNo'] ?? data['chassisNo'] ?? '';
    _vehicleEngNoController.text = data['engNo'] ?? data['engineNo'] ?? '';
    _rateController.text = data['dailyRate']?.toString() ?? '';

    if (_vehicleNumberController.text.isEmpty) {
      _vehicleNumberController.text = data['number'] ?? _vehicleEntryNoController.text;
    }
    if (_vehicleController.text.isEmpty) {
      _vehicleController.text = _vehicleEntryNameController.text;
    }
  }

  void _clearVehicleEntryFields({bool clearNumber = true}) {
    if (clearNumber) _vehicleEntryNoController.clear();
    _vehicleEntryNameController.clear();
    _vehicleEntryCategoriesController.clear();
    _vehicleEntryDescriptionController.clear();
    _vehicleChasisNoController.clear();
    _vehicleEngNoController.clear();
  }

  Future<void> _generateCustomerCode(String fyear) async {
    if (_isEditMode) return;

    try {
      final code = await ChallanService.generateCustomerCodeForFinancialYear(fyear);
      if (!mounted) return;
      _custCodeController.text = code;
      setState(() {});
    } catch (e) {
      debugPrint('Error generating customer code: $e');
    }
  }

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

  void _registerFocusNode(TextEditingController controller, int step) {
    if (!_focusNodes.containsKey(controller)) {
      _focusNodes[controller] = _FieldFocus(step, FocusNode());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    final initialFyear = ChallanService.getCurrentFinancialYear();
    _dateController.text = _formatDateTime(DateTime.now());
    _fyearController.text = initialFyear;

    _daysController.addListener(_calculateBillAmount);
    _rateController.addListener(_calculateBillAmount);
    // Auto-calculate expected return whenever days change
    _daysController.addListener(_calculateReturnDate);

    if (widget.custCode != null) {
      _custCodeController.text = widget.custCode ?? '';
      _isEditMode = true;
      _loadExistingData();
    } else {
      _custCodeController.text = 'Generating...';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateCustomerCode(initialFyear);
      });
    }

    _registerFocusNode(_partyNameController, 0);
    _registerFocusNode(_phoneController, 0);
    _registerFocusNode(_daysController, 2);
    _registerFocusNode(_rateController, 2);
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return null;
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (e) {
      debugPrint("Error parsing date: $dateStr, $e");
      return null;
    }
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      debugPrint("Error parsing time: $timeStr, $e");
      return null;
    }
  }

  Future<void> _loadExistingData() async {
    if (widget.custCode == null) return;
    final doc = await _customersCollection.doc(widget.custCode).get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      final customer = Customer.fromFirestore(doc);

      _partyNameController.text = customer.name;
      _phoneController.text = customer.smsPhone;
      _alternatePhoneController.text = data['alternatePhone'] ?? '';
      _customerCityController.text = data['city'] ?? '';
      _aadharController.text = customer.aadharNo;
      _licenseController.text = customer.licenceNo;
      _vehicleController.text = customer.vehicleName;
      _daysController.text = customer.days;
      _rateController.text = customer.rate;
      _billAmountController.text = customer.billAmount;
      _depositController.text = data['deposit']?.toString() ?? data['depositAmount']?.toString() ?? '';
      _selectedPaymentMode = data['paymentMode'] ?? 'Cash';
      _hasExtraHelmet = data['hasExtraHelmet'] ?? false;
      _hasMobileHolder = data['hasMobileHolder'] ?? false;
      _calculateBillAmount();

      _dateController.text = data['sDate'] ?? _dateController.text;
      _fyearController.text = data['fyear'] ?? _fyearController.text;

      if (data['vehicleEntry'] != null) {
        final ve = data['vehicleEntry'];
        _vehicleEntryNoController.text = ve['no'] ?? '';
        _vehicleEntryNameController.text = ve['name'] ?? '';
        _vehicleEntryCategoriesController.text = ve['categories'] ?? '';
        _vehicleEntryDescriptionController.text = ve['description'] ?? '';
        _vehicleChasisNoController.text = ve['chasisNo'] ?? '';
        _vehicleEngNoController.text = ve['engNo'] ?? '';
      }

      if (data['customerDocuments'] != null) {
        _customerDocuments = CustomerDocuments.fromMap(
          Map<String, dynamic>.from(data['customerDocuments']),
        );
      }
      if (data['vehicleHandover'] != null) {
        _vehicleHandover = VehicleHandover.fromMap(
          Map<String, dynamic>.from(data['vehicleHandover']),
        );
        _vehicleNumberController.text = _vehicleHandover!.vehicleNumber;
        _pickupLocationController.text = _vehicleHandover!.vehiclePickupLocation;
        _returnLocationController.text = _vehicleHandover!.vehicleReturnLocation;
        if (_vehicleHandover!.vehicleGivenDate.isNotEmpty) {
          _vehicleGivenDate = _parseDate(_vehicleHandover!.vehicleGivenDate);
        }
        if (_vehicleHandover!.vehicleGivenTime.isNotEmpty) {
          _vehicleGivenTime = _parseTime(_vehicleHandover!.vehicleGivenTime);
        }
        if (_vehicleHandover!.vehicleReturnDate.isNotEmpty) {
          _vehicleReturnDate = _parseDate(_vehicleHandover!.vehicleReturnDate);
        }
        if (_vehicleHandover!.vehicleReturnTime.isNotEmpty) {
          _vehicleReturnTime = _parseTime(_vehicleHandover!.vehicleReturnTime);
        }
      }
      if (data['travelDetails'] != null) {
        _travelDetails = TravelDetails.fromMap(
          Map<String, dynamic>.from(data['travelDetails']),
        );
        _customerCameFromController.text = _travelDetails!.customerCameFrom;
        _stayingAtController.text = _travelDetails!.stayingAt;
        _hotelNameController.text = _travelDetails!.hotelName;
        _landmarkController.text = _travelDetails!.landmark;
        _cityController.text = _travelDetails!.city;
        _stateController.text = _travelDetails!.state;
        _pinCodeController.text = _travelDetails!.pinCode;
      }
      if (data['transportation'] != null) {
        _transportation = Transportation.fromMap(
          Map<String, dynamic>.from(data['transportation']),
        );
      }
      _selectedQRCodeId = data['qrCodeId'];
      if (_selectedQRCodeId != null && _selectedQRCodeId!.isNotEmpty) {
        final qrDoc = await _paymentSettingsCollection.doc(_selectedQRCodeId).get();
        if (qrDoc.exists) {
          final qrData = qrDoc.data() as Map<String, dynamic>;
          _selectedQRCodeImageUrl = qrData['imageUrl'];
        }
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _daysController.removeListener(_calculateBillAmount);
    _daysController.removeListener(_calculateReturnDate);
    _rateController.removeListener(_calculateBillAmount);

    _custCodeController.dispose();
    _dateController.dispose();
    _fyearController.dispose();
    _partyNameController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _customerCityController.dispose();
    _aadharController.dispose();
    _licenseController.dispose();
    _vehicleEntryNoController.dispose();
    _vehicleEntryNameController.dispose();
    _vehicleEntryCategoriesController.dispose();
    _vehicleEntryDescriptionController.dispose();
    _vehicleChasisNoController.dispose();
    _vehicleEngNoController.dispose();
    _vehicleController.dispose();
    _vehicleNumberController.dispose();
    _daysController.dispose();
    _rateController.dispose();
    _billAmountController.dispose();
    _depositController.dispose();
    _pickupLocationController.dispose();
    _returnLocationController.dispose();
    _customerCameFromController.dispose();
    _stayingAtController.dispose();
    _hotelNameController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _dropLocationController.dispose();
    _dropDateController.dispose();
    _dropTimeController.dispose();
    _additionalInfoController.dispose();
    for (var fieldFocus in _focusNodes.values) {
      fieldFocus.focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Challan' : 'New Challan', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.ember,
        foregroundColor: Colors.white, 
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: _buildStepIndicator(),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: IndexedStack(
          index: _currentStep,
          children: [
            _buildCustomerStep(),
            _buildVehicleStep(),
            _buildRentalStep(),
            _buildDocumentsStep(),
            _buildReviewStep(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStepIndicatorItem(icon: Icons.person, label: 'Customer', step: 0),
        _buildStepIndicatorItem(icon: Icons.directions_car, label: 'Vehicle', step: 1),
        _buildStepIndicatorItem(icon: Icons.calendar_today, label: 'Rental', step: 2),
        _buildStepIndicatorItem(icon: Icons.folder, label: 'Documents', step: 3),
        _buildStepIndicatorItem(icon: Icons.rate_review, label: 'Review', step: 4),
      ],
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

  Widget _buildStepIndicatorItem({required IconData icon, required String label, required int step}) {
    final bool isActive = _currentStep == step;
    final bool isCompleted = _currentStep > step;
    final color = isCompleted ? Colors.white : (isActive ? Colors.white : Colors.white.withOpacity(0.5));
    final fontWeight = isActive ? FontWeight.bold : FontWeight.normal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontWeight: fontWeight, fontSize: 12)),
      ],
    );
  }

  Widget _buildCustomerStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('Customer Details'),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 2,
                    child: FormImagePicker(
                        label: 'Customer Photo',
                        imageUrl: _customerDocuments?.customerPhoto,
                        folder: 'documents/${_custCodeController.text}/customer',
                        onImageSelected: (url) {
                          setState(() {
                            _customerDocuments = (_customerDocuments ?? CustomerDocuments()).copyWith(customerPhoto: url);
                          });
                        }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildTextField(_partyNameController, 'Customer Name'),
                        _buildTextField(_phoneController, 'Mobile Number', keyboardType: TextInputType.phone),
                        _buildTextField(_alternatePhoneController, 'WhatsApp Number', keyboardType: TextInputType.phone),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildTextField(_aadharController, 'ID/Aadhaar Number'),
          _buildTextField(_licenseController, 'Driver License Number'),
          _buildTextField(_customerCityController, 'City'),
        ],
      ),
    );
  }

  Widget _buildVehicleStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildVehicleEntrySection(),
        ],
      ),
    );
  }

  Widget _buildRentalStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('Rental & Booking'),
          _buildVehicleHandoverSection(),
          const SizedBox(height: 24),
          _buildBookingSection(),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('Upload Documents'),
          _buildDocumentSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Transportation (Optional)'),
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
                  ? 'Edit Transportation Details'
                  : 'Add Transportation Details',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('Entry Info'),
          _buildReadOnlyField('Customer Code', _custCodeController),
          _buildReadOnlyField('Date', _dateController),
          _buildReadOnlyField('Financial Year', _fyearController),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Deposit & Payment Options'),
          
          _buildTextField(_depositController, 'Deposit Amount (₹)', keyboardType: TextInputType.number),
          
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              value: _selectedPaymentMode,
              decoration: InputDecoration(
                labelText: 'Payment Mode',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _paymentModes
                  .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPaymentMode = value;
                  });
                }
              },
            ),
          ),

          if (_selectedPaymentMode == 'UPI / QR') ...[
            const SizedBox(height: 8),
            _buildPaymentMethodDropdown(),
            const SizedBox(height: 12),
            _buildQRCodeImagePreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    _registerFocusNode(controller, _currentStep);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller, 
        maxLines: maxLines,
        keyboardType: keyboardType,
        focusNode: _focusNodes[controller]?.focusNode,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
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

  Widget _buildVehicleEntrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Vehicle Entry'),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vehicleEntryNoController,
                    decoration: InputDecoration(
                      labelText: 'No',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (_) => _searchVehicle(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSearchingVehicle ? null : _searchVehicle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ember,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSearchingVehicle
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enter'),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildTextField(_vehicleEntryNameController, 'Vehicle Name'),
        _buildTextField(_vehicleEntryCategoriesController, 'Categories'),
        _buildTextField(_vehicleEntryDescriptionController, 'Description', maxLines: 3),
        _buildTextField(_vehicleChasisNoController, 'Chasis No.'),
        _buildTextField(_vehicleEngNoController, 'Eng No.'),
      ],
    );
  }

  Widget _buildDocumentSection() {
    final code = _custCodeController.text.isNotEmpty && _custCodeController.text != 'Generating...'
        ? _custCodeController.text 
        : (widget.custCode ?? 'temp');

    return Column( 
      children: [
        FormImagePicker(
          label: 'Aadhaar / License - Front',
          imageUrl: _customerDocuments?.idFront,
          folder: 'documents/$code/documents',
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
          folder: 'documents/$code/documents',
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
          folder: 'documents/$code/customer',
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
          folder: 'documents/$code/travel',
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

  Widget _buildVehicleDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: _vehiclesCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Error loading vehicles: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final vehicleItems = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['name']?.toString() ?? '',
            'dailyRate': data['dailyRate']?.toString() ?? '0',
            'number': data['number']?.toString() ?? '',
          };
        }).where((v) => v['name']!.isNotEmpty).toList();

        String? selectedValue;
        if (_vehicleController.text.isNotEmpty) {
          final exists = vehicleItems.any((v) => v['name'] == _vehicleController.text);
          if (exists) {
            selectedValue = _vehicleController.text;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: selectedValue,
            decoration: InputDecoration(
              labelText: 'Vehicle Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: vehicleItems.map((vehicle) {
              return DropdownMenuItem<String>(
                value: vehicle['name']!,
                child: Text(vehicle['name']!),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _vehicleController.text = value;

                  final selectedVehicleData = vehicleItems.firstWhere(
                    (v) => v['name'] == value,
                    orElse: () => {'dailyRate': '', 'number': ''},
                  );

                  if (selectedVehicleData['dailyRate']!.isNotEmpty) {
                    _rateController.text = selectedVehicleData['dailyRate']!;
                  }
                  if (selectedVehicleData['number']!.isNotEmpty) {
                    _vehicleNumberController.text = selectedVehicleData['number']!;
                  }
                });
              }
            },
            validator: (value) => (value == null || value.isEmpty)
                ? 'Please select a vehicle'
                : null,
          ),
        );
      },
    );
  }

  Widget _buildVehicleHandoverSection() {
    return Column(
      children: [
        // Handover section
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    TextEditingController controller,
    List<String> options,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
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

  Widget _buildBookingSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(_daysController, 'Days', keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(_rateController, 'Rate/Day', keyboardType: TextInputType.number),
            ),
          ],
        ),
        _buildReadOnlyField('Bill Amount', _billAmountController),
        if (_vehicleReturnDate != null) ...[
          const SizedBox(height: 12),
          Card(
            color: Colors.grey[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Expected Return', style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_vehicleReturnDate!.day.toString().padLeft(2, '0')}-${_vehicleReturnDate!.month.toString().padLeft(2, '0')}-${_vehicleReturnDate!.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _vehicleReturnTime != null
                            ? '${_vehicleReturnTime!.hour.toString().padLeft(2, '0')}:${_vehicleReturnTime!.minute.toString().padLeft(2, '0')}'
                            : '--:--',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Add-ons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.muted)),
              ),
              CheckboxListTile(
                title: const Text('Free Helmet (Included)'),
                value: true,
                onChanged: null,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                activeColor: AppColors.ember,
              ),
              CheckboxListTile(
                title: const Text('Extra Helmet'),
                subtitle: const Text('+ ₹50.0'),
                value: _hasExtraHelmet,
                onChanged: (bool? value) {
                  setState(() {
                    _hasExtraHelmet = value ?? false;
                    _calculateBillAmount();
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                activeColor: AppColors.ember,
              ),
              CheckboxListTile(
                title: const Text('Mobile Holder'),
                subtitle: const Text('+ ₹30.0'),
                value: _hasMobileHolder,
                onChanged: (bool? value) {
                  setState(() {
                    _hasMobileHolder = value ?? false;
                    _calculateBillAmount();
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                activeColor: AppColors.ember,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeImagePreview() {
    if (_selectedQRCodeImageUrl == null || _selectedQRCodeImageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Column(
        children: [
          const Text('Scan to Pay', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _selectedQRCodeImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.error, color: Colors.red),
                loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: _paymentSettingsCollection.where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error loading payment methods: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final qrDocs = snapshot.data?.docs ?? [];
        if (qrDocs.isEmpty) {
          return const Text('No active payment methods found.');
        }

        final selectedValueExists = qrDocs.any((doc) => doc.id == _selectedQRCodeId);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: selectedValueExists ? _selectedQRCodeId : null,
            decoration: InputDecoration(
              labelText: 'Select QR Code',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: qrDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text(data['name'] ?? 'Unnamed QR'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedQRCodeId = value;
                if (value == null) {
                  _selectedQRCodeImageUrl = null;
                } else {
                  final selectedDoc = qrDocs.firstWhere((doc) => doc.id == value);
                  final data = selectedDoc.data() as Map<String, dynamic>;
                  _selectedQRCodeImageUrl = data['imageUrl'];
                }
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: const Text('<- Back', style: TextStyle(color: AppColors.muted)),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : (_currentStep == _totalSteps - 1 ? _saveCustomer : _nextStep),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ember,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _currentStep == _totalSteps - 1 ? (_isEditMode ? 'Update Challan' : 'Save Challan') : 'Next ->',
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCustomer() async {
    _formKey.currentState?.save();
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

      final vehicleHandover = VehicleHandover(
        vehicleName: _vehicleController.text.trim(),
        vehicleNumber: _vehicleNumberController.text.trim(),
        vehiclePickupLocation: _pickupLocationController.text.trim(),
        vehicleReturnLocation: _returnLocationController.text.trim(),
        vehicleGivenDate: _vehicleGivenDate != null
            ? '${_vehicleGivenDate!.day}-${_vehicleGivenDate!.month}-${_vehicleGivenDate!.year}'
            : '',
        vehicleGivenTime: _vehicleGivenTime != null
            ? '${_vehicleGivenTime!.hour}:${_vehicleGivenTime!.minute}'
            : '',
        vehicleReturnDate: _vehicleReturnDate != null
            ? '${_vehicleReturnDate!.day}-${_vehicleReturnDate!.month}-${_vehicleReturnDate!.year}'
            : '',
        vehicleReturnTime: _vehicleReturnTime != null
            ? '${_vehicleReturnTime!.hour}:${_vehicleReturnTime!.minute}'
            : '',
        returnStatus: _vehicleHandover?.returnStatus ?? 'Pending',
        vehicleCameFrom: '',
        vehicleReturnedTo: '',
      );

      final travelDetails = TravelDetails(
        customerCameFrom: _customerCameFromController.text.trim(),
        stayingAt: _stayingAtController.text.trim(),
        hotelName: _hotelNameController.text.trim(),
        stayAddress: '', // Kept for model compatibility, but not collected from UI
        landmark: _landmarkController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pinCode: _pinCodeController.text.trim(),
      );

      final customer = Customer(
        custCode: customerCode,
        name: _partyNameController.text.trim(),
        vehicleName: _vehicleController.text.trim(),
        sDate: _dateController.text,
        returnDate: vehicleHandover.vehicleReturnDate,
        days: _daysController.text.trim(),
        rate: _rateController.text.trim(),
        billAmount: _billAmountController.text.trim(),
        smsPhone: _phoneController.text.trim(),
        aadharNo: _aadharController.text.trim(),
        licenceNo: _licenseController.text.trim(),
        fyear: _fyearController.text.trim(),
        vehicleHandover: vehicleHandover.toMap(),
        travelDetails: travelDetails.toMap(),
        customerDocuments: _customerDocuments?.toMap(),
        transportation: _transportation?.toMap(),
        hasExtraHelmet: _hasExtraHelmet,
        hasMobileHolder: _hasMobileHolder,
        extraHelmetCharge: _hasExtraHelmet ? _extraHelmetCharge : 0.0,
        mobileHolderCharge: _hasMobileHolder ? _mobileHolderCharge : 0.0,
      );

      final customerData = customer.toMap();

      customerData['vehicleEntry'] = {
        'no': _vehicleEntryNoController.text.trim(),
        'name': _vehicleEntryNameController.text.trim(),
        'categories': _vehicleEntryCategoriesController.text.trim(),
        'description': _vehicleEntryDescriptionController.text.trim(),
        'chasisNo': _vehicleChasisNoController.text.trim(),
        'engNo': _vehicleEngNoController.text.trim(),
      };

      customerData['deposit'] = _depositController.text.trim();
      customerData['depositAmount'] = _depositController.text.trim();
      customerData['paymentMode'] = _selectedPaymentMode;

      if (_selectedQRCodeId != null) {
        customerData['qrCodeId'] = _selectedQRCodeId;
      }
      if (_alternatePhoneController.text.trim().isNotEmpty) {
        customerData['alternatePhone'] = _alternatePhoneController.text.trim();
      }
      if (_customerCityController.text.trim().isNotEmpty) {
        customerData['city'] = _customerCityController.text.trim();
      }

      await _customersCollection.doc(customerCode).set(customerData, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challan saved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }
}