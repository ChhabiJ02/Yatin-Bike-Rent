class Invoice {
  final String invoiceNumber;
  final String invoiceDate;
  final String customerName;
  final String phoneNumber;
  final String vehicleName;
  final String vehicleNumber;
  final String rentalStartDate;
  final String rentalStartTime;
  final String rentalEndDate;
  final String rentalEndTime;
  final String totalRentalDuration;
  final int startKM;
  final int endKM;
  final int totalKM;
  final String rentPerDay;
  final String extraKMCharges;
  final String securityDeposit;
  final String otherCharges;
  final String discount;
  final String gst;
  final String grandTotal;
  final String paymentStatus;
  final String staffName;
  final String? pdfPath;

  Invoice({
    this.invoiceNumber = '',
    this.invoiceDate = '',
    this.customerName = '',
    this.phoneNumber = '',
    this.vehicleName = '',
    this.vehicleNumber = '',
    this.rentalStartDate = '',
    this.rentalStartTime = '',
    this.rentalEndDate = '',
    this.rentalEndTime = '',
    this.totalRentalDuration = '',
    this.startKM = 0,
    this.endKM = 0,
    this.totalKM = 0,
    this.rentPerDay = '',
    this.extraKMCharges = '',
    this.securityDeposit = '',
    this.otherCharges = '',
    this.discount = '',
    this.gst = '',
    this.grandTotal = '',
    this.paymentStatus = 'Pending',
    this.staffName = '',
    this.pdfPath,
  });

  Invoice copyWith({
    String? invoiceNumber,
    String? invoiceDate,
    String? customerName,
    String? phoneNumber,
    String? vehicleName,
    String? vehicleNumber,
    String? rentalStartDate,
    String? rentalStartTime,
    String? rentalEndDate,
    String? rentalEndTime,
    String? totalRentalDuration,
    int? startKM,
    int? endKM,
    int? totalKM,
    String? rentPerDay,
    String? extraKMCharges,
    String? securityDeposit,
    String? otherCharges,
    String? discount,
    String? gst,
    String? grandTotal,
    String? paymentStatus,
    String? staffName,
    String? pdfPath,
  }) {
    return Invoice(
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      rentalStartDate: rentalStartDate ?? this.rentalStartDate,
      rentalStartTime: rentalStartTime ?? this.rentalStartTime,
      rentalEndDate: rentalEndDate ?? this.rentalEndDate,
      rentalEndTime: rentalEndTime ?? this.rentalEndTime,
      totalRentalDuration: totalRentalDuration ?? this.totalRentalDuration,
      startKM: startKM ?? this.startKM,
      endKM: endKM ?? this.endKM,
      totalKM: totalKM ?? this.totalKM,
      rentPerDay: rentPerDay ?? this.rentPerDay,
      extraKMCharges: extraKMCharges ?? this.extraKMCharges,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      otherCharges: otherCharges ?? this.otherCharges,
      discount: discount ?? this.discount,
      gst: gst ?? this.gst,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      staffName: staffName ?? this.staffName,
      pdfPath: pdfPath ?? this.pdfPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'vehicleName': vehicleName,
      'vehicleNumber': vehicleNumber,
      'rentalStartDate': rentalStartDate,
      'rentalStartTime': rentalStartTime,
      'rentalEndDate': rentalEndDate,
      'rentalEndTime': rentalEndTime,
      'totalRentalDuration': totalRentalDuration,
      'startKM': startKM,
      'endKM': endKM,
      'totalKM': totalKM,
      'rentPerDay': rentPerDay,
      'extraKMCharges': extraKMCharges,
      'securityDeposit': securityDeposit,
      'otherCharges': otherCharges,
      'discount': discount,
      'gst': gst,
      'grandTotal': grandTotal,
      'paymentStatus': paymentStatus,
      'staffName': staffName,
      if (pdfPath != null) 'pdfPath': pdfPath,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      invoiceNumber: map['invoiceNumber'] ?? '',
      invoiceDate: map['invoiceDate'] ?? '',
      customerName: map['customerName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      vehicleName: map['vehicleName'] ?? '',
      vehicleNumber: map['vehicleNumber'] ?? '',
      rentalStartDate: map['rentalStartDate'] ?? '',
      rentalStartTime: map['rentalStartTime'] ?? '',
      rentalEndDate: map['rentalEndDate'] ?? '',
      rentalEndTime: map['rentalEndTime'] ?? '',
      totalRentalDuration: map['totalRentalDuration'] ?? '',
      startKM: (map['startKM'] is int) ? map['startKM'] : 0,
      endKM: (map['endKM'] is int) ? map['endKM'] : 0,
      totalKM: (map['totalKM'] is int) ? map['totalKM'] : 0,
      rentPerDay: map['rentPerDay'] ?? '',
      extraKMCharges: map['extraKMCharges'] ?? '',
      securityDeposit: map['securityDeposit'] ?? '',
      otherCharges: map['otherCharges'] ?? '',
      discount: map['discount'] ?? '',
      gst: map['gst'] ?? '',
      grandTotal: map['grandTotal'] ?? '',
      paymentStatus: map['paymentStatus'] ?? 'Pending',
      staffName: map['staffName'] ?? '',
      pdfPath: map['pdfPath'],
    );
  }

  bool get isEmpty => invoiceNumber.isEmpty;
  bool get isComplete => invoiceNumber.isNotEmpty && customerName.isNotEmpty;
}