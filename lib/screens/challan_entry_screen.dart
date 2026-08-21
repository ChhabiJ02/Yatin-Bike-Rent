import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_documents.dart';
import '../models/customer.dart';
import '../models/qr_code.dart';
import '../models/vehicle_handover.dart';
import '../models/travel_details.dart';
import '../models/transportation_model.dart';
import '../theme/app_theme.dart';
import '../widgets/form_image_picker.dart';
import '../services/challan_service.dart';
import '../services/qr_payment_service.dart';
import '../services/rental_service.dart';
import '../admin/customer_bookings_screen.dart';
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

  // Customer Mobile Verification Flow States
  int _customerVerificationStage = 0; // 0: Mobile Input, 1: Choice, 2: Scanner, 3: Full Form
  bool _isCheckingCustomer = false;
  DocumentSnapshot<Map<String, dynamic>>? _returningCustomer;
  String _lastSearchedPhone = '';
  int _searchRequestId = 0;
  bool _isScanningFront = false;
  
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
  List<QRCodePayment> _paymentMethods = const [];

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
  bool _isDeleting = false;

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

  // Calculate days & bill amount when Expected Return Date/Time changes
  void _calculateDaysFromReturnDate() {
    if (_vehicleReturnDate == null) return;

    DateTime pickupDt = DateTime.now();
    if (_vehicleGivenDate != null) {
      pickupDt = DateTime(
        _vehicleGivenDate!.year,
        _vehicleGivenDate!.month,
        _vehicleGivenDate!.day,
        _vehicleGivenTime?.hour ?? 0,
        _vehicleGivenTime?.minute ?? 0,
      );
    } else {
      final parsed = _parseDate(_dateController.text.split(' ').first);
      if (parsed != null) pickupDt = parsed;
    }

    final returnDt = DateTime(
      _vehicleReturnDate!.year,
      _vehicleReturnDate!.month,
      _vehicleReturnDate!.day,
      _vehicleReturnTime?.hour ?? 0,
      _vehicleReturnTime?.minute ?? 0,
    );

    final difference = returnDt.difference(pickupDt);
    double calculatedDays = difference.inHours / 24.0;
    if (calculatedDays <= 0) {
      calculatedDays = 1;
    } else {
      calculatedDays = (calculatedDays * 10).ceil() / 10;
    }

    _daysController.text = calculatedDays % 1 == 0
        ? calculatedDays.toInt().toString()
        : calculatedDays.toStringAsFixed(1);

    _calculateBillAmount();
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

  // --- Phone Auto Fetch Logic ---
  void _onPhoneChanged() {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      _lastSearchedPhone = '';
      if (_returningCustomer != null || _customerVerificationStage != 0) {
        setState(() {
          _returningCustomer = null;
          _customerVerificationStage = 0;
        });
      }
      return;
    }

    if (!_isEditMode && !_isCheckingCustomer && phone != _lastSearchedPhone) {
      _lastSearchedPhone = phone;
      _checkExistingCustomer(phone);
    }
  }

  Future<void> _checkExistingCustomer(String phone) async {
    final requestId = ++_searchRequestId;
    setState(() {
      _isCheckingCustomer = true;
      _returningCustomer = null;
    });

    final phoneFormats = [phone, '+91$phone'];
    DocumentSnapshot<Map<String, dynamic>>? match;

    try {
      for (final field in ['smsPhone', 'phone', 'mobile']) {
        for (final value in phoneFormats) {
          final result = await _customersCollection
              .where(field, isEqualTo: value)
              .limit(1)
              .get();
          if (result.docs.isNotEmpty) {
            match = result.docs.first;
            break;
          }
        }
        if (match != null) break;
      }

      if (!mounted || requestId != _searchRequestId) return;
      if (match != null) {
        _prefillReturningCustomer(match);
        setState(() {
          _returningCustomer = match;
          _isCheckingCustomer = false;
        });
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        if (mounted && requestId == _searchRequestId && _returningCustomer == match) {
          setState(() => _customerVerificationStage = 3);
        }
      } else {
        setState(() {
          _isCheckingCustomer = false;
          _customerVerificationStage = 1;
        });
      }
    } catch (_) {
      if (mounted && requestId == _searchRequestId) {
        setState(() => _isCheckingCustomer = false);
      }
    }
  }

  void _prefillReturningCustomer(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    _partyNameController.text = (data['name'] ?? data['partyName'] ?? '').toString();
    _alternatePhoneController.text = (data['alternatePhone'] ?? '').toString();
    _aadharController.text = (data['aadharNo'] ?? '').toString();
    _licenseController.text = (data['licenceNo'] ?? data['licenseNo'] ?? '').toString();
    _customerCityController.text = (data['city'] ?? '').toString();

    if (data['customerDocuments'] != null) {
      _customerDocuments = CustomerDocuments.fromMap(
        Map<String, dynamic>.from(data['customerDocuments']),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final initialFyear = ChallanService.getCurrentFinancialYear();
    _dateController.text = _formatDateTime(DateTime.now());
    _fyearController.text = initialFyear;

    _daysController.addListener(_calculateBillAmount);
    _rateController.addListener(_calculateBillAmount);
    _phoneController.addListener(_onPhoneChanged);
    _loadPaymentMethods();

    if (widget.custCode != null) {
      _custCodeController.text = widget.custCode ?? '';
      _isEditMode = true;
      _customerVerificationStage = 3;
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

  Future<void> _loadPaymentMethods() async {
    final methods = await QRPaymentService.getActiveQRCodes();
    if (!mounted) return;

    setState(() {
      _paymentMethods = methods;
      final selectedMethod = methods.where((method) => method.name == _selectedPaymentMode).firstOrNull;
      if (selectedMethod == null && methods.isNotEmpty) {
        _selectedPaymentMode = methods.first.name;
      }
      _selectedQRCodeId = selectedMethod?.id;
      _selectedQRCodeImageUrl = selectedMethod?.imageUrl;
    });
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

  Future<void> _deleteChallan() async {
    final customerCode = (widget.custCode ?? _custCodeController.text).trim();
    if (customerCode.isEmpty || _isDeleting) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Challan?'),
        content: const Text(
          'This challan and its customer details will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final customerRef = _customersCollection.doc(customerCode);
      await customerRef.delete();
      final deletedDocument = await customerRef.get();
      if (deletedDocument.exists) {
        throw Exception('Firebase did not remove the challan document.');
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const CustomerBookingsScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete challan: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _daysController.removeListener(_calculateBillAmount);
    _rateController.removeListener(_calculateBillAmount);
    _phoneController.removeListener(_onPhoneChanged);

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
        actions: [
          if (_isEditMode)
            IconButton(
              tooltip: 'Delete challan',
              onPressed: _isDeleting ? null : _deleteChallan,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_outline),
            ),
        ],
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

  // Updated Customer Step with Auto Fetching UI Flow
  Widget _buildCustomerStep() {
    if (!_isEditMode && _customerVerificationStage == 0) {
      return _buildMobileVerificationStep();
    }
    if (!_isEditMode && _customerVerificationStage == 1) {
      return _buildIdChoiceStep();
    }
    if (!_isEditMode && _customerVerificationStage == 2) {
      return _buildIdScannerStep();
    }

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
          _buildTextField(
            _aadharController, 
            'ID/Aadhaar Number',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
          ),
          _buildTextField(_licenseController, 'Driver License Number'),
          _buildTextField(_customerCityController, 'City'),
        ],
      ),
    );
  }

  Widget _buildMobileVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Who's renting?",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8),
          const Text(
            "Enter the customer's 10-digit mobile number",
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: const Text(
                  '+91  |',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              hintText: 'Enter mobile no',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 18),
              suffixIcon: _isCheckingCustomer
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : (_returningCustomer != null
                      ? const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 24)
                      : null),
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
            ),
          ),
          if (_returningCustomer != null) ...[
            const SizedBox(height: 20),
            _buildReturningCustomerCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildReturningCustomerCard() {
    final data = _returningCustomer?.data() ?? <String, dynamic>{};
    final name = (data['name'] ?? data['partyName'] ?? 'Customer').toString();
    final docs = data['customerDocuments'];
    final photo = docs is Map ? (docs['customerPhoto'] ?? '').toString() : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C853).withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8, spreadRadius: 2)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(Icons.check_circle, color: Color(0xFF00C853), size: 16),
                    SizedBox(width: 4),
                    Text('Returning customer', style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdChoiceStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildChoiceCard(
            icon: Icons.qr_code_scanner,
            title: 'Scan ID card',
            subtitle: 'Auto-fills name, ID number & address',
            isDark: true,
            onTap: () => setState(() {
              _isScanningFront = true;
              _customerVerificationStage = 2;
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 16),
          _buildChoiceCard(
            icon: Icons.edit_note,
            title: 'Fill in manually',
            subtitle: 'Type name, ID type & number yourself',
            isDark: false,
            onTap: () => setState(() => _customerVerificationStage = 3),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: isDark ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isDark ? Colors.white12 : Colors.white,
              child: Icon(icon, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? Colors.white : Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildIdScannerStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_isScanningFront ? 'Scanning ID Front...' : 'Scanning ID Back...'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _customerVerificationStage = 3;
              });
            },
            child: const Text('Complete Scan & Fill Form'),
          ),
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
          
          _buildPaymentModeDropdown(),
          if (_selectedQRCodeImageUrl?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _buildQRCodeImagePreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentModeDropdown() {
    if (_paymentMethods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: _paymentMethods.any((method) => method.name == _selectedPaymentMode)
            ? _selectedPaymentMode
            : null,
        decoration: InputDecoration(
          labelText: 'Payment Mode',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: _paymentMethods
            .map((method) => DropdownMenuItem(value: method.name, child: Text(method.name)))
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          final method = _paymentMethods.firstWhere((item) => item.name == value);
          setState(() {
            _selectedPaymentMode = method.name;
            _selectedQRCodeId = method.requiresQr ? method.id : null;
            _selectedQRCodeImageUrl = method.requiresQr ? method.imageUrl : null;
          });
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool required = false,
  }) {
    _registerFocusNode(controller, _currentStep);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller, 
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
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
      ],
    );
  }

  Widget _buildDocumentSection() {
    final code = _custCodeController.text.isNotEmpty && _custCodeController.text != 'Generating...'
        ? _custCodeController.text 
        : (widget.custCode ?? 'temp');

    return Column( 
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormImagePicker(
                label: 'ID - Front',
                imageUrl: _customerDocuments?.idFront,
                folder: 'documents/$code/documents',
                onImageSelected: (url) {
                  setState(() {
                    _customerDocuments =
                        (_customerDocuments ?? CustomerDocuments()).copyWith(idFront: url);
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FormImagePicker(
                label: 'ID - Back',
                imageUrl: _customerDocuments?.idBack,
                folder: 'documents/$code/documents',
                onImageSelected: (url) {
                  setState(() {
                    _customerDocuments =
                        (_customerDocuments ?? CustomerDocuments()).copyWith(idBack: url);
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormImagePicker(
                label: 'Customer Photo',
                imageUrl: _customerDocuments?.customerPhoto,
                folder: 'documents/$code/customer',
                onImageSelected: (url) {
                  setState(() {
                    _customerDocuments = (_customerDocuments ?? CustomerDocuments())
                        .copyWith(customerPhoto: url);
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FormImagePicker(
                label: 'Travel Ticket',
                imageUrl: _customerDocuments?.travelTicketPhoto,
                folder: 'documents/$code/travel',
                onImageSelected: (url) {
                  setState(() {
                    _customerDocuments = (_customerDocuments ?? CustomerDocuments())
                        .copyWith(travelTicketPhoto: url);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleHandoverSection() {
    return Column(
      children: [
        // Handover section
      ],
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
              ? '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}${time != null ? ' ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}' : ''}'
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
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDateTimePicker(
            'Expected Return',
            _vehicleReturnDate,
            _vehicleReturnTime,
            (pickedDate, pickedTime) {
              setState(() {
                _vehicleReturnDate = pickedDate;
                _vehicleReturnTime = pickedTime;
                _calculateDaysFromReturnDate();
              });
            },
          ),
        ),
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
        stayAddress: '',
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