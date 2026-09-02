import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import '../models/customer_documents.dart';
import '../models/customer.dart';
import '../models/qr_code.dart';
import '../models/vehicle_handover.dart';
import '../models/travel_details.dart';
import '../models/transportation_model.dart';
import '../theme/app_theme.dart';
import '../widgets/form_image_picker.dart';
import '../services/challan_service.dart';
import '../services/document_scan_validator.dart';
import '../services/qr_payment_service.dart';
import '../services/rental_service.dart';
import '../admin/customer_bookings_screen.dart';

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
  final _customersCollection = FirebaseFirestore.instance.collection(
    'customers',
  );
  final _vehiclesCollection = FirebaseFirestore.instance.collection('vehicles');
  final _paymentSettingsCollection = FirebaseFirestore.instance.collection(
    'paymentSettings',
  );

  // Controllers
  final _custCodeController = TextEditingController();
  final _customerNameSearchController = TextEditingController();
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
  final _referenceIdController = TextEditingController();
  final _paidAmountController = TextEditingController();
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
  final _transportDocumentPendingController = TextEditingController();
  final _transportDlrMailController = TextEditingController();
  final _transportPickupLocationController = TextEditingController();
  final _transportStartingKmController = TextEditingController();

  // Customer Mobile Verification Flow States
  int _customerVerificationStage =
      0; // 0: Mobile Input, 1: Choice, 2: Scanner, 3: Full Form
  bool _isCheckingCustomer = false;
  DocumentSnapshot<Map<String, dynamic>>? _returningCustomer;
  String _lastSearchedPhone = '';
  int _searchRequestId = 0;
  Timer? _customerNameSearchDebounce;
  List<DocumentSnapshot<Map<String, dynamic>>> _customerNameMatches = [];
  bool _isSearchingCustomerName = false;
  String? _customerNameSearchError;
  CameraController? _cameraController;
  bool _isCapturingId = false;
  String _scanDocument = 'Aadhaar';
  int _scanSide = 0;

  // Wizard Step State
  int _currentStep = 0;
  final int _totalSteps = 3;

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
  DateTime? _transportPickupDateTime;

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

    _billAmountController.text = total % 1 == 0
        ? total.toInt().toString()
        : total.toStringAsFixed(2);
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

  void _populateVehicleEntryFields(
    DocumentSnapshot<Map<String, dynamic>> vehicleDoc,
  ) {
    final data = vehicleDoc.data();
    if (data == null) return;

    _vehicleEntryNameController.text =
        data['name'] ?? data['vehicleName'] ?? '';
    _rateController.text = data['dailyRate']?.toString() ?? '';

    if (_vehicleNumberController.text.isEmpty) {
      _vehicleNumberController.text =
          data['number'] ?? _vehicleEntryNoController.text;
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
      final code = await ChallanService.generateCustomerCodeForFinancialYear(
        fyear,
      );
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
      final code = await ChallanService.generateCustomerCodeWithTransaction(
        fyear,
      );
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
        await _loadExistingData(customer: match);
        setState(() {
          _returningCustomer = match;
          _isCheckingCustomer = false;
        });
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        if (mounted &&
            requestId == _searchRequestId &&
            _returningCustomer == match) {
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

  void _onCustomerNameSearchChanged(String value) {
    _customerNameSearchDebounce?.cancel();
    final query = value.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _customerNameMatches = [];
        _isSearchingCustomerName = false;
        _customerNameSearchError = null;
      });
      return;
    }

    setState(() => _isSearchingCustomerName = true);
    _customerNameSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchCustomersByName(query);
    });
  }

  Future<void> _searchCustomersByName(String query) async {
    try {
      final result = await _customersCollection.get();
      if (!mounted ||
          query != _customerNameSearchController.text.trim().toLowerCase())
        return;

      final matches = result.docs.where((doc) {
        final data = doc.data();
        final name =
            (data['partyName'] ?? data['name'] ?? data['displayName'] ?? '')
                .toString()
                .toLowerCase();
        return name.contains(query);
      }).toList();

      setState(() {
        _customerNameMatches = matches;
        _isSearchingCustomerName = false;
        _customerNameSearchError = matches.isEmpty
            ? 'User not found by this name. Please enter phone number.'
            : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSearchingCustomerName = false;
          _customerNameSearchError =
              'Unable to search customers. Please enter phone number.';
        });
      }
    }
  }

  Future<void> _selectCustomerName(
    DocumentSnapshot<Map<String, dynamic>> customer,
  ) async {
    await _loadExistingData(customer: customer);
    _customerNameSearchController.clear();
    setState(() {
      _customerNameMatches = [];
      _customerNameSearchError = null;
      _returningCustomer = customer;
      _customerVerificationStage = 3;
    });
  }

  Future<void> _startIdScanner() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No camera found');
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await _cameraController?.dispose();
      setState(() => _cameraController = controller);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to open camera: $e')));
      }
    }
  }

  Future<void> _captureIdCard() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isCapturingId)
      return;
    setState(() => _isCapturingId = true);
    try {
      final image = await controller.takePicture();
      await controller.dispose();
      if (identical(_cameraController, controller) && mounted) {
        setState(() => _cameraController = null);
      }

      final croppedImage = await _cropDocument(image.path);
      if (croppedImage == null) return;

      final text = await _readIdText(croppedImage.path);
      final validationMessage = _validateScannedDocument(text);
      if (validationMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      final code = _custCodeController.text == 'Generating...'
          ? 'temp'
          : _custCodeController.text;
      final fileName =
          '${_scanDocument.toLowerCase()}_${_scanSide == 0 ? 'front' : 'back'}.jpg';
      final ref = FirebaseStorage.instance.ref().child(
        'documents/$code/identity/$fileName',
      );
      final imageBytes = await croppedImage.readAsBytes();
      final snapshot = await ref.putData(imageBytes);
      final url = await snapshot.ref.getDownloadURL();
      String? faceUrl;
      if (_scanDocument == 'Aadhaar' && _scanSide == 0) {
        final faceBytes = await _cropFaceFromImage(croppedImage.path);
        if (faceBytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Face not detected. Please scan Aadhaar front again.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        final faceRef = FirebaseStorage.instance.ref().child(
          'documents/$code/customer/aadhaar_face.jpg',
        );
        final faceSnapshot = await faceRef.putData(faceBytes);
        faceUrl = await faceSnapshot.ref.getDownloadURL();
      }
      final documents = _customerDocuments ?? CustomerDocuments();
      setState(() {
        _customerDocuments = _scanDocument == 'Aadhaar'
            ? (_scanSide == 0
                  ? documents.copyWith(idFront: url, customerPhoto: faceUrl)
                  : documents.copyWith(idBack: url))
            : (_scanSide == 0
                  ? documents.copyWith(licenseFront: url)
                  : documents.copyWith(licenseBack: url));
        _applyRecognizedIdText(text);
        if (_scanDocument == 'Aadhaar') {
          _scanDocument = 'License';
          _scanSide = 0;
        } else {
          _customerVerificationStage = 3;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _scanDocument == 'License'
                  ? 'Aadhaar front scanned successfully. Now scan the driving license front.'
                  : 'Driving license front scanned successfully.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (_customerVerificationStage == 3) {
        await _cameraController?.dispose();
        if (mounted) setState(() => _cameraController = null);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
    } finally {
      if (mounted) setState(() => _isCapturingId = false);
      if (mounted &&
          _customerVerificationStage == 2 &&
          _cameraController == null) {
        await _startIdScanner();
      }
    }
  }

  Future<CroppedFile?> _cropDocument(String path) {
    return ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop document',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop document'),
        WebUiSettings(context: context),
      ],
    );
  }

  Future<Uint8List?> _cropFaceFromImage(String path) async {
    if (kIsWeb) return null;

    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableTracking: false,
      ),
    );
    try {
      final faces = await detector.processImage(InputImage.fromFilePath(path));
      if (faces.isEmpty) return null;

      final source = img.decodeImage(await XFile(path).readAsBytes());
      if (source == null) return null;

      final face = faces.first.boundingBox;
      final horizontalMargin = face.width * 0.75;
      final topMargin = face.height * 0.65;
      final bottomMargin = face.height * 0.95;
      final left = (face.left - horizontalMargin).floor().clamp(
        0,
        source.width - 1,
      );
      final top = (face.top - topMargin).floor().clamp(0, source.height - 1);
      final right = (face.right + horizontalMargin).ceil().clamp(
        left + 1,
        source.width,
      );
      final bottom = (face.bottom + bottomMargin).ceil().clamp(
        top + 1,
        source.height,
      );
      final cropped = img.copyCrop(
        source,
        x: left,
        y: top,
        width: right - left,
        height: bottom - top,
      );
      return Uint8List.fromList(img.encodeJpg(cropped, quality: 92));
    } finally {
      try {
        await detector.close();
      } on MissingPluginException {}
    }
  }

  Future<String> _readIdText(String path) async {
    if (kIsWeb) return '';
    try {
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      await recognizer.close();
      return result.text;
    } catch (_) {
      return '';
    }
  }

  String? _validateScannedDocument(String text) {
    if (_scanSide == 0 && _scanDocument == 'Aadhaar') {
      if (!isAadhaarFrontText(text)) {
        return 'Wrong document. Please scan the front of the Aadhaar card.';
      }
    }
    if (_scanSide == 0 && _scanDocument == 'License') {
      if (!isDrivingLicenseFrontText(text)) {
        return 'Wrong document. Please scan the front of the driving license.';
      }
    }
    return null;
  }

  void _applyRecognizedIdText(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ');
    final aadhaar = RegExp(
      r'\b\d{4}\s?\d{4}\s?\d{4}\b',
    ).firstMatch(compact)?.group(0);
    final phone = RegExp(r'\b[6-9]\d{9}\b').firstMatch(compact)?.group(0);
    final license =
        drivingLicenseNumberPattern.firstMatch(compact)?.group(0) ??
        extractDrivingLicenseNumber(text);
    if (aadhaar != null) _aadharController.text = aadhaar.replaceAll(' ', '');
    if (phone != null && _phoneController.text.length != 10)
      _phoneController.text = phone;
    if (license != null)
      _licenseController.text = license.replaceAll(' ', '').toUpperCase();

    final name = _scanDocument == 'Aadhaar'
        ? extractAadhaarName(text)
        : extractDrivingLicenseName(text);
    if (name != null && _partyNameController.text.isEmpty) {
      _partyNameController.text = name;
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
      final selectedMethod = methods
          .where((method) => method.name == _selectedPaymentMode)
          .firstOrNull;
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
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
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

  Future<void> _loadExistingData({
    DocumentSnapshot<Map<String, dynamic>>? customer,
  }) async {
    if (customer == null && widget.custCode == null) return;
    final doc =
        customer ?? await _customersCollection.doc(widget.custCode).get();
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
      _depositController.text =
          data['deposit']?.toString() ??
          data['depositAmount']?.toString() ??
          '';
      _referenceIdController.text = data['referenceId']?.toString() ?? '';
      _paidAmountController.text = data['paidAmount']?.toString() ?? '';
      _selectedPaymentMode = data['paymentMode'] ?? 'Cash';
      _hasExtraHelmet = data['hasExtraHelmet'] ?? false;
      _hasMobileHolder = data['hasMobileHolder'] ?? false;
      _calculateBillAmount();

      _dateController.text = data['sDate'] ?? _dateController.text;
      _fyearController.text = data['fyear'] ?? _fyearController.text;

      if (data['vehicleEntry'] is Map) {
        final ve = Map<String, dynamic>.from(data['vehicleEntry'] as Map);
        _vehicleEntryNoController.text = (ve['no'] ?? ve['number'] ?? '')
            .toString();
        _vehicleEntryNameController.text =
            (ve['name'] ?? ve['vehicleName'] ?? '').toString();
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
        if (_vehicleEntryNoController.text.isEmpty) {
          _vehicleEntryNoController.text = _vehicleHandover!.vehicleNumber;
        }
        if (_vehicleEntryNameController.text.isEmpty) {
          _vehicleEntryNameController.text = _vehicleHandover!.vehicleName;
        }
        _pickupLocationController.text =
            _vehicleHandover!.vehiclePickupLocation;
        _returnLocationController.text =
            _vehicleHandover!.vehicleReturnLocation;
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
      if (_vehicleEntryNoController.text.isEmpty) {
        _vehicleEntryNoController.text =
            (data['vehicleNumber'] ?? data['vehicleNo'] ?? '').toString();
      }
      if (_vehicleController.text.isEmpty) {
        _vehicleController.text = (data['vehicleName'] ?? '').toString();
      }
      if (_vehicleEntryNoController.text.isNotEmpty) {
        final vehicleDoc = await RentalService.findVehicleByNumber(
          _vehicleEntryNoController.text.trim(),
        );
        if (vehicleDoc != null && vehicleDoc.exists) {
          _populateVehicleEntryFields(vehicleDoc);
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
        _transportDocumentPendingController.text =
            _transportation!.documentPending;
        _transportDlrMailController.text = _transportation!.dlrMail;
        _transportPickupLocationController.text =
            _transportation!.pickupLocation;
        _transportStartingKmController.text = _transportation!.startingKm;
        final pickupDate = _parseDate(_transportation!.pickupDate);
        final pickupTime = _parseTime(_transportation!.pickupTime);
        if (pickupDate != null) {
          _transportPickupDateTime = DateTime(
            pickupDate.year,
            pickupDate.month,
            pickupDate.day,
            pickupTime?.hour ?? 0,
            pickupTime?.minute ?? 0,
          );
        }
      }
      _selectedQRCodeId = data['qrCodeId'];
      if ((_selectedQRCodeId ?? '').isNotEmpty) {
        final qrDoc = await _paymentSettingsCollection
            .doc(_selectedQRCodeId)
            .get();
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
        MaterialPageRoute(builder: (_) => const CustomerBookingsScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to delete challan: $e')));
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _customerNameSearchDebounce?.cancel();
    _daysController.removeListener(_calculateBillAmount);
    _rateController.removeListener(_calculateBillAmount);
    _phoneController.removeListener(_onPhoneChanged);

    _custCodeController.dispose();
    _customerNameSearchController.dispose();
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
    _referenceIdController.dispose();
    _paidAmountController.dispose();
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
    _transportDocumentPendingController.dispose();
    _transportDlrMailController.dispose();
    _transportPickupLocationController.dispose();
    _transportStartingKmController.dispose();
    for (var fieldFocus in _focusNodes.values) {
      fieldFocus.focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showStepIndicator = _isEditMode || _customerVerificationStage == 3;
    final showBottomNavigation = _isEditMode || _customerVerificationStage == 3;
    final isScanner = _customerVerificationStage == 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isScanner
              ? 'Scan ${_scanDocument.toLowerCase()} front'
              : (_isEditMode ? 'Edit Booking' : 'New Booking'),
          style: TextStyle(
            color: isScanner ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: isScanner ? AppColors.ember : Colors.white,
        foregroundColor: isScanner ? Colors.white : AppColors.ink,
        centerTitle: true,
        leading: isScanner
            ? null
            : IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back),
              ),
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
          if (!_isEditMode && !isScanner)
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Cancel'),
            ),
        ],
        bottom: !showStepIndicator
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(80.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 12.0,
                  ),
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
            _buildBookingDetailsStep(),
            _buildReviewStep(),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNavigation
          ? _buildBottomNavigationBar()
          : null,
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(_totalSteps, (step) {
        return Expanded(
          child: Row(
            children: [
              Expanded(child: _buildStepIndicatorItem(step: step)),
              if (step < _totalSteps - 1)
                Expanded(
                  child: Container(height: 1, color: const Color(0xFFD0D0D0)),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepIndicatorItem({required int step}) {
    final bool isActive = _currentStep == step;
    final bool isCompleted = _currentStep > step;
    const labels = ['Customer Details', 'Booking Details', 'Payment'];
    final color = isCompleted || isActive ? Colors.black : AppColors.muted;
    final fontWeight = isActive ? FontWeight.bold : FontWeight.normal;

    return InkWell(
      onTap: step <= _currentStep
          ? () => setState(() => _currentStep = step)
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive || isCompleted ? Colors.black : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26),
              ),
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive || isCompleted ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[step],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: fontWeight,
                fontSize: 12,
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyField(
                  'Customer Code',
                  _custCodeController,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _buildReadOnlyField('Date', _dateController)),
            ],
          ),
          _buildCustomerSectionTitle('Customer Details'),
          LayoutBuilder(
            builder: (context, constraints) {
              final details = Column(
                children: [
                  _buildCustomerInfoCard(
                    Icons.person_outline,
                    'Name',
                    _partyNameController,
                  ),
                  _buildCustomerInfoCard(
                    Icons.phone_outlined,
                    'Mobile Number',
                    _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildCustomerInfoCard(
                    Icons.chat_outlined,
                    'WhatsApp Number',
                    _alternatePhoneController,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              );
              final photo = _buildCustomerPhotoCard();

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: constraints.maxWidth < 430 ? 108 : 132,
                    child: photo,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          _buildCustomerSectionTitle('Identity Details'),
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
          _buildCustomerSectionTitle('Identity Proof (Select 4 Photos)'),
          _buildDocumentSection(),
        ],
      ),
    );
  }

  Widget _buildCustomerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard(
    IconData icon,
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E2E2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: keyboardType == TextInputType.phone
                      ? [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ]
                      : null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerPhotoCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E2E2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: FormImagePicker(
        label: 'Face Photo',
        imageUrl: _customerDocuments?.customerPhoto,
        folder: 'documents/${_custCodeController.text}/customer',
        onImageSelected: (url) {
          setState(() {
            _customerDocuments = (_customerDocuments ?? CustomerDocuments())
                .copyWith(customerPhoto: url);
          });
        },
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
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: const Text(
                  '+91  |',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              hintText: 'Enter mobile no',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 18),
              suffixIcon: _isCheckingCustomer
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (_returningCustomer != null
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF00C853),
                            size: 24,
                          )
                        : null),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _customerNameSearchController,
            onChanged: _onCustomerNameSearchChanged,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Search by customer name',
              hintText: 'Type customer name',
              prefixIcon: const Icon(Icons.person_search),
              suffixIcon: _isSearchingCustomerName
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (_customerNameMatches.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _customerNameMatches.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final customer = _customerNameMatches[index];
                  final data = customer.data() ?? <String, dynamic>{};
                  final name =
                      (data['partyName'] ??
                              data['name'] ??
                              data['displayName'] ??
                              '')
                          .toString();
                  return InkWell(
                    onTap: () => _selectCustomerName(customer),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline),
                          const SizedBox(width: 16),
                          Expanded(child: Text(name)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (_customerNameSearchError != null) ...[
            const SizedBox(height: 8),
            Text(
              _customerNameSearchError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF00C853),
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Returning customer',
                      style: TextStyle(
                        color: Color(0xFF00C853),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
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
            onTap: () {
              setState(() {
                _customerVerificationStage = 2;
                _scanDocument = 'Aadhaar';
                _scanSide = 0;
              });
              _startIdScanner();
            },
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
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white : Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdScannerStep() {
    final camera = _cameraController;
    final title = 'Scan ${_scanDocument.toLowerCase()} front';
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Place card flat and keep all corners in frame',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: camera?.value.isInitialized == true
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final frameWidth = (constraints.maxWidth - 32).clamp(
                          0.0,
                          620.0,
                        );
                        final frameHeight = frameWidth / 1.586;
                        return SizedBox(
                          width: frameWidth,
                          height: frameHeight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width:
                                        camera!.value.previewSize?.height ??
                                        frameWidth,
                                    height:
                                        camera.value.previewSize?.width ??
                                        frameHeight,
                                    child: CameraPreview(camera),
                                  ),
                                ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white70,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: GestureDetector(
              onTap: _isCapturingId ? null : _captureIdCard,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade500, width: 5),
                ),
                child: _isCapturingId
                    ? const Padding(
                        padding: EdgeInsets.all(22),
                        child: CircularProgressIndicator(),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('From City'),
          _buildTextField(_cityController, 'City'),
          _buildSectionHeader('Select Vehicle'),
          _buildVehicleEntrySection(),
          _buildSectionHeader('Date & Time'),
          Row(
            children: [
              Expanded(
                child: _buildDateTimePicker(
                  'Pickup Date & Time',
                  _vehicleGivenDate,
                  _vehicleGivenTime,
                  (date, time) {
                    setState(() {
                      _vehicleGivenDate = date;
                      _vehicleGivenTime = time;
                    });
                  },
                  icon: Icons.calendar_month_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDateTimePicker(
                  'Return Date & Time',
                  _vehicleReturnDate,
                  _vehicleReturnTime,
                  (date, time) {
                    setState(() {
                      _vehicleReturnDate = date;
                      _vehicleReturnTime = time;
                      _calculateDaysFromReturnDate();
                    });
                  },
                  icon: Icons.calendar_month_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _pickupLocationController,
                  'Pick up location',
                  icon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  _transportStartingKmController,
                  'Start kilometer',
                  keyboardType: TextInputType.number,
                  icon: Icons.speed_outlined,
                ),
              ),
            ],
          ),
          _buildSectionHeader('Helmet & Add-ons'),
          _buildBookingSection(),
        ],
      ),
    );
  }

  Widget _buildTransportationPickupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Pickup Details'),
        _buildDateTimePicker(
          'Pickup Date and Time',
          _transportPickupDateTime,
          _transportPickupDateTime == null
              ? null
              : TimeOfDay.fromDateTime(_transportPickupDateTime!),
          (date, time) {
            if (date == null) return;
            setState(() {
              _transportPickupDateTime = DateTime(
                date.year,
                date.month,
                date.day,
                time?.hour ?? 0,
                time?.minute ?? 0,
              );
            });
          },
        ),
        _buildTextField(_transportPickupLocationController, 'Pickup Location'),
        _buildTextField(
          _transportStartingKmController,
          'Starting KM',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('Payment'),
          _buildTextField(_referenceIdController, 'Reference ID'),
          _buildTextField(
            _paidAmountController,
            'Paid Amount (₹)',
            keyboardType: TextInputType.number,
          ),
          _buildReadOnlyField('Bill Amount', _billAmountController),
          _buildPaymentModeDropdown(),
          if ((_selectedQRCodeImageUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildQRCodeImagePreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentModeDropdown() {
    const methods = ['Cash', 'BOB', 'SBI', 'GPay', 'PNB'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Payment Method',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        Row(
          children: methods.map((method) {
            final isSelected =
                _selectedPaymentMode.toLowerCase() == method.toLowerCase();
            final configured = _paymentMethods
                .where(
                  (item) => item.name.toLowerCase() == method.toLowerCase(),
                )
                .firstOrNull;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: method == methods.last ? 0 : 8),
                child: _buildPaymentMethodCard(method, isSelected, configured),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
    String method,
    bool isSelected,
    QRCodePayment? configured,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMode = method;
          _selectedQRCodeId = configured?.requiresQr == true
              ? configured!.id
              : null;
          _selectedQRCodeImageUrl = configured?.requiresQr == true
              ? configured!.imageUrl
              : null;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 86,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.black : const Color(0xFFE5E5E5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPaymentLogo(method, configured),
            const SizedBox(height: 5),
            Text(
              method,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentLogo(String method, QRCodePayment? configured) {
    if ((configured?.imageUrl ?? '').isNotEmpty) {
      return SizedBox(
        width: 30,
        height: 30,
        child: Image.network(
          configured!.imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _buildFallbackPaymentLogo(method),
        ),
      );
    }
    return _buildFallbackPaymentLogo(method);
  }

  Widget _buildFallbackPaymentLogo(String method) {
    final colors = <String, Color>{
      'Cash': Colors.black,
      'BOB': const Color(0xFFE85D04),
      'SBI': const Color(0xFF1769AA),
      'GPay': const Color(0xFF34A853),
      'PNB': const Color(0xFF9E1B32),
    };
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (colors[method] ?? Colors.black).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: method == 'Cash'
          ? Icon(Icons.payments_outlined, size: 24, color: colors[method])
          : Text(
              method == 'GPay' ? 'G' : method[0],
              style: TextStyle(
                color: colors[method] ?? Colors.black,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
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
    IconData? icon,
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
          prefixIcon: icon == null ? null : Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: required
            ? (v) =>
                  (v == null || v.trim().isEmpty) ? '$label is required' : null
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
    final vehicleNumber = _vehicleEntryNoController.text.trim();
    final fetchedVehicleNumber = _vehicleNumberController.text.trim();
    final vehicleName = _vehicleEntryNameController.text.trim();
    final rate = _rateController.text.trim();
    final hasVehicle = vehicleNumber.isNotEmpty || vehicleName.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _showVehicleEntryDialog,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4E4E4)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.ember.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.two_wheeler_outlined,
                        color: AppColors.ember,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasVehicle
                                ? (vehicleName.isEmpty
                                      ? 'Vehicle'
                                      : vehicleName)
                                : 'Select Vehicle',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            fetchedVehicleNumber.isNotEmpty
                                ? 'Number plate: $fetchedVehicleNumber'
                                : vehicleNumber.isEmpty
                                ? 'Tap to add vehicle number'
                                : vehicleNumber,
                            style: TextStyle(
                              fontSize: 13,
                              color: hasVehicle ? Colors.black54 : Colors.grey,
                            ),
                          ),
                          if (rate.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '₹$rate / day',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_outlined, size: 21),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  _rateController,
                  'Rate/Day',
                  keyboardType: TextInputType.number,
                  icon: Icons.currency_rupee,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showVehicleEntryDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Vehicle Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 TextFormField(
                   controller: _vehicleEntryNoController,
                   autofocus: true,
                   decoration: InputDecoration(
                     labelText: 'No',
                     border: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(12),
                     ),
                   ),
                   textInputAction: TextInputAction.search,
                   onFieldSubmitted: (_) async {
                     setDialogState(() {});
                     await _searchVehicle();
                     if (dialogContext.mounted) setDialogState(() {});
                   },
                 ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSearchingVehicle
                    ? null
                    : () async {
                        setDialogState(() {});
                        await _searchVehicle();
                        final navigator = Navigator.of(dialogContext);
                        if (mounted) setState(() {});
                        if (navigator.canPop()) navigator.pop();
                      },
                child: _isSearchingVehicle
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _buildDocumentSection() {
    final code =
        _custCodeController.text.isNotEmpty &&
            _custCodeController.text != 'Generating...'
        ? _custCodeController.text
        : (widget.custCode ?? 'temp');

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormImagePicker(
                label: 'Aadhar Card\nFront',
                compact: true,
                cropDocument: true,
                imageUrl: _customerDocuments?.idFront,
                folder: 'documents/$code/documents',
                onImageSelected: (url) {
                  setState(() {
                    _customerDocuments =
                        (_customerDocuments ?? CustomerDocuments()).copyWith(
                          idFront: url,
                        );
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FormImagePicker(
                label: 'Aadhar Card\nBack',
                compact: true,
                cropDocument: true,
                imageUrl: _customerDocuments?.idBack,
                folder: 'documents/$code/documents',
                onImageSelected: (url) {
                  setState(() {
                    _customerDocuments =
                        (_customerDocuments ?? CustomerDocuments()).copyWith(
                          idBack: url,
                        );
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
                label: 'Driving License\nFront',
                compact: true,
                cropDocument: true,
                imageUrl: _customerDocuments?.licenseFront,
                folder: 'documents/$code/identity',
                onImageSelected: (url) {
                  setState(() {
                    _customerDocuments =
                        (_customerDocuments ?? CustomerDocuments()).copyWith(
                          licenseFront: url,
                        );
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FormImagePicker(
                label: 'Driving License\nBack',
                compact: true,
                cropDocument: true,
                imageUrl: _customerDocuments?.licenseBack,
                folder: 'documents/$code/identity',
                onImageSelected: (url) {
                  setState(() {
                    _customerDocuments =
                        (_customerDocuments ?? CustomerDocuments()).copyWith(
                          licenseBack: url,
                        );
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
    Function(DateTime?, TimeOfDay?) onChanged, {
    IconData? icon,
  }) {
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
          prefixIcon: icon == null ? null : Icon(icon),
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
        _buildReadOnlyField('Bill Amount', _billAmountController),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAddOnCard(
                icon: Icons.sports_motorsports_outlined,
                label: '1 Helmet',
                selected: !_hasExtraHelmet,
                onTap: () {
                  setState(() {
                    _hasExtraHelmet = false;
                    _calculateBillAmount();
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAddOnCard(
                icon: Icons.sports_motorsports_outlined,
                label: '2 Helmets',
                charge: '+ ₹50',
                selected: _hasExtraHelmet,
                onTap: () {
                  setState(() {
                    _hasExtraHelmet = true;
                    _calculateBillAmount();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildAddOnCard(
          icon: Icons.phone_android_outlined,
          label: 'Mobile Holder',
          charge: '+ ₹30',
          selected: _hasMobileHolder,
          onTap: () {
            setState(() {
              _hasMobileHolder = !_hasMobileHolder;
              _calculateBillAmount();
            });
          },
        ),
      ],
    );
  }

  Widget _buildAddOnCard({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? charge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selected ? Colors.black : const Color(0xFFE2E2E2),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 22,
              color: selected ? Colors.black : AppColors.ink,
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 25, color: AppColors.ink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                charge == null ? label : '$label\n$charge',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeImagePreview() {
    final imageUrl = _selectedQRCodeImageUrl ?? '';
    if (imageUrl.isEmpty) {
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
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.error, color: Colors.red),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                TextButton(
                  onPressed: _previousStep,
                  child: const Text(
                    '<- Back',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : (_currentStep == _totalSteps - 1
                          ? _saveCustomer
                          : _nextStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ember,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _currentStep == _totalSteps - 1
                            ? (_isEditMode ? 'Update Booking' : 'Save Booking')
                            : 'Next ->',
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 13, color: AppColors.muted),
              SizedBox(width: 5),
              Text(
                'Your data is secure and will not be shared.',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
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

      _transportation = Transportation(
        documentPending: _transportDocumentPendingController.text.trim(),
        dlrMail: _transportDlrMailController.text.trim(),
        pickupDate: _transportPickupDateTime == null
            ? ''
            : '${_transportPickupDateTime!.day.toString().padLeft(2, '0')}-${_transportPickupDateTime!.month.toString().padLeft(2, '0')}-${_transportPickupDateTime!.year}',
        pickupTime: _transportPickupDateTime == null
            ? ''
            : '${_transportPickupDateTime!.hour.toString().padLeft(2, '0')}:${_transportPickupDateTime!.minute.toString().padLeft(2, '0')}',
        pickupLocation: _transportPickupLocationController.text.trim(),
        startingKm: _transportStartingKmController.text.trim(),
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
      customerData['referenceId'] = _referenceIdController.text.trim();
      customerData['paidAmount'] = _paidAmountController.text.trim();
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

      await _customersCollection
          .doc(customerCode)
          .set(customerData, SetOptions(merge: true));
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
