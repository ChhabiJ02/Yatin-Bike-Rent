import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String custCode;
  final String name;
  final String vehicleName;
  final String sDate;
  final String returnDate;
  final String days;
  final String rate;
  final String billAmount;
  final String address;
  final String smsPhone;
  final String aadharNo;
  final String licenceNo;
  final String fyear;
  final Map<String, dynamic>? vehicleHandover;
  final Map<String, dynamic>? travelDetails;
  final Map<String, dynamic>? kilometerDetails;
  final Map<String, dynamic>? customerDocuments;
  final Map<String, dynamic>? transportation;
  final Map<String, dynamic>? payment;
  final bool hasExtraHelmet;
  final bool hasMobileHolder;
  final double extraHelmetCharge;
  final double mobileHolderCharge;
  final Timestamp? createdAt;

  Customer({
    required this.custCode,
    required this.name,
    required this.vehicleName,
    required this.sDate,
    required this.returnDate,
    required this.days,
    required this.rate,
    required this.billAmount,
    this.address = '',
    this.smsPhone = '',
    this.aadharNo = '',
    this.licenceNo = '',
    this.fyear = '',
    this.vehicleHandover,
    this.travelDetails,
    this.kilometerDetails,
    this.customerDocuments,
    this.transportation,
    this.payment,
    this.hasExtraHelmet = false,
    this.hasMobileHolder = false,
    this.extraHelmetCharge = 0.0,
    this.mobileHolderCharge = 0.0,
    this.createdAt,
  });

  Customer copyWith({
    String? custCode,
    String? name,
    String? vehicleName,
    String? sDate,
    String? returnDate,
    String? days,
    String? rate,
    String? billAmount,
    String? address,
    String? smsPhone,
    String? aadharNo,
    String? licenceNo,
    String? fyear,
    Map<String, dynamic>? vehicleHandover,
    Map<String, dynamic>? travelDetails,
    Map<String, dynamic>? kilometerDetails,
    Map<String, dynamic>? customerDocuments,
    Map<String, dynamic>? transportation,
    Map<String, dynamic>? payment,
    bool? hasExtraHelmet,
    bool? hasMobileHolder,
    double? extraHelmetCharge,
    double? mobileHolderCharge,
    Timestamp? createdAt,
  }) {
    return Customer(
      custCode: custCode ?? this.custCode,
      name: name ?? this.name,
      vehicleName: vehicleName ?? this.vehicleName,
      sDate: sDate ?? this.sDate,
      returnDate: returnDate ?? this.returnDate,
      days: days ?? this.days,
      rate: rate ?? this.rate,
      billAmount: billAmount ?? this.billAmount,
      address: address ?? this.address,
      smsPhone: smsPhone ?? this.smsPhone,
      aadharNo: aadharNo ?? this.aadharNo,
      licenceNo: licenceNo ?? this.licenceNo,
      fyear: fyear ?? this.fyear,
      vehicleHandover: vehicleHandover ?? this.vehicleHandover,
      travelDetails: travelDetails ?? this.travelDetails,
      kilometerDetails: kilometerDetails ?? this.kilometerDetails,
      customerDocuments: customerDocuments ?? this.customerDocuments,
      transportation: transportation ?? this.transportation,
      payment: payment ?? this.payment,
      hasExtraHelmet: hasExtraHelmet ?? this.hasExtraHelmet,
      hasMobileHolder: hasMobileHolder ?? this.hasMobileHolder,
      extraHelmetCharge: extraHelmetCharge ?? this.extraHelmetCharge,
      mobileHolderCharge: mobileHolderCharge ?? this.mobileHolderCharge,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Customer.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return Customer(
      custCode: data['custCode'] ?? snapshot.id,
      name: data['partyName'] ?? '',
      vehicleName: data['vehicleName'] ?? '',
      sDate: data['sDate'] ?? '',
      returnDate: data['returnDate'] ?? '',
      days: data['days'] ?? '',
      rate: data['rate'] ?? '',
      billAmount: data['billAmount'] ?? '',
      address: data['address'] ?? '',
      smsPhone: data['smsPhone'] ?? '',
      aadharNo: data['aadharNo'] ?? '',
      licenceNo: data['licenceNo'] ?? '',
      fyear: data['fyear'] ?? '',
      vehicleHandover: data['vehicleHandover'] is Map
          ? Map<String, dynamic>.from(data['vehicleHandover'])
          : null,
      travelDetails: data['travelDetails'] is Map
          ? Map<String, dynamic>.from(data['travelDetails'])
          : null,
      kilometerDetails: data['kilometerDetails'] is Map
          ? Map<String, dynamic>.from(data['kilometerDetails'])
          : null,
      customerDocuments: data['customerDocuments'] is Map
          ? Map<String, dynamic>.from(data['customerDocuments'])
          : null,
      transportation: data['transportation'] is Map
          ? Map<String, dynamic>.from(data['transportation'])
          : null,
      hasExtraHelmet: data['hasExtraHelmet'] ?? false,
      hasMobileHolder: data['hasMobileHolder'] ?? false,
      extraHelmetCharge: (data['extraHelmetCharge'] as num?)?.toDouble() ?? 0.0,
      mobileHolderCharge: (data['mobileHolderCharge'] as num?)?.toDouble() ?? 0.0,
      payment: data['payment'] is Map
          ? Map<String, dynamic>.from(data['payment'])
          : null,
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'custCode': custCode,
      'partyName': name,
      'vehicleName': vehicleName,
      'sDate': sDate,
      'returnDate': returnDate,
      'days': days,
      'rate': rate,
      'billAmount': billAmount,
      'address': address,
      'smsPhone': smsPhone,
      'aadharNo': aadharNo,
      'licenceNo': licenceNo,
      'fyear': fyear,
      'vehicleHandover': vehicleHandover,
      'travelDetails': travelDetails,
      'kilometerDetails': kilometerDetails,
      'customerDocuments': customerDocuments,
      'transportation': transportation,
      'payment': payment,
      'hasExtraHelmet': hasExtraHelmet,
      'hasMobileHolder': hasMobileHolder,
      'extraHelmetCharge': extraHelmetCharge,
      'mobileHolderCharge': mobileHolderCharge,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
