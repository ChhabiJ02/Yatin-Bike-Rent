class CustomerDocuments {
  final String? aadhaarFront;
  final String? aadhaarBack;
  final String? licenseFront;
  final String? licenseBack;
  final String? customerVehiclePhoto;
  final String? travelTicketPhoto;

  CustomerDocuments({
    this.aadhaarFront,
    this.aadhaarBack,
    this.licenseFront,
    this.licenseBack,
    this.customerVehiclePhoto,
    this.travelTicketPhoto,
  });

  CustomerDocuments copyWith({
    String? aadhaarFront,
    String? aadhaarBack,
    String? licenseFront,
    String? licenseBack,
    String? customerVehiclePhoto,
    String? travelTicketPhoto,
  }) {
    return CustomerDocuments(
      aadhaarFront: aadhaarFront ?? this.aadhaarFront,
      aadhaarBack: aadhaarBack ?? this.aadhaarBack,
      licenseFront: licenseFront ?? this.licenseFront,
      licenseBack: licenseBack ?? this.licenseBack,
      customerVehiclePhoto: customerVehiclePhoto ?? this.customerVehiclePhoto,
      travelTicketPhoto: travelTicketPhoto ?? this.travelTicketPhoto,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (aadhaarFront != null) 'aadhaarFront': aadhaarFront,
      if (aadhaarBack != null) 'aadhaarBack': aadhaarBack,
      if (licenseFront != null) 'licenseFront': licenseFront,
      if (licenseBack != null) 'licenseBack': licenseBack,
      if (customerVehiclePhoto != null) 'customerVehiclePhoto': customerVehiclePhoto,
      if (travelTicketPhoto != null) 'travelTicketPhoto': travelTicketPhoto,
    };
  }

  factory CustomerDocuments.fromMap(Map<String, dynamic> map) {
    return CustomerDocuments(
      aadhaarFront: map['aadhaarFront'],
      aadhaarBack: map['aadhaarBack'],
      licenseFront: map['licenseFront'],
      licenseBack: map['licenseBack'],
      customerVehiclePhoto: map['customerVehiclePhoto'],
      travelTicketPhoto: map['travelTicketPhoto'],
    );
  }

  bool get isEmpty {
    return aadhaarFront == null &&
        aadhaarBack == null &&
        licenseFront == null &&
        licenseBack == null &&
        customerVehiclePhoto == null &&
        travelTicketPhoto == null;
  }

  bool get isComplete {
    return aadhaarFront != null &&
        aadhaarBack != null &&
        licenseFront != null &&
        licenseBack != null &&
        customerVehiclePhoto != null;
  }
}