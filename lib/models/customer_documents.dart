class CustomerDocuments {
  static const _unset = Object();

  final String? idFront;
  final String? idBack;
  final String? licenseFront;
  final String? licenseBack;
  final String? customerPhoto;
  final String? travelTicketPhoto;
  final String? vehiclePhoto;

  CustomerDocuments({
    this.idFront,
    this.idBack,
    this.licenseFront,
    this.licenseBack,
    this.customerPhoto,
    this.travelTicketPhoto,
    this.vehiclePhoto,
  });

  CustomerDocuments copyWith({
    Object? idFront = _unset,
    Object? idBack = _unset,
    Object? licenseFront = _unset,
    Object? licenseBack = _unset,
    Object? customerPhoto = _unset,
    Object? travelTicketPhoto = _unset,
    Object? vehiclePhoto = _unset,
  }) {
    return CustomerDocuments(
      idFront: identical(idFront, _unset) ? this.idFront : idFront as String?,
      idBack: identical(idBack, _unset) ? this.idBack : idBack as String?,
      licenseFront: identical(licenseFront, _unset)
          ? this.licenseFront
          : licenseFront as String?,
      licenseBack: identical(licenseBack, _unset)
          ? this.licenseBack
          : licenseBack as String?,
      customerPhoto: identical(customerPhoto, _unset)
          ? this.customerPhoto
          : customerPhoto as String?,
      travelTicketPhoto: identical(travelTicketPhoto, _unset)
          ? this.travelTicketPhoto
          : travelTicketPhoto as String?,
      vehiclePhoto: identical(vehiclePhoto, _unset)
          ? this.vehiclePhoto
          : vehiclePhoto as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (idFront != null) 'idFront': idFront,
      if (idBack != null) 'idBack': idBack,
      if (licenseFront != null) 'licenseFront': licenseFront,
      if (licenseBack != null) 'licenseBack': licenseBack,
      if (customerPhoto != null) 'customerPhoto': customerPhoto,
      if (travelTicketPhoto != null) 'travelTicketPhoto': travelTicketPhoto,
      if (vehiclePhoto != null) 'vehiclePhoto': vehiclePhoto,
    };
  }

  factory CustomerDocuments.fromMap(Map<String, dynamic> map) {
    return CustomerDocuments(
      idFront: map['idFront'] ?? map['aadhaarFront'],
      idBack: map['idBack'] ?? map['aadhaarBack'],
      licenseFront: map['licenseFront'],
      licenseBack: map['licenseBack'],
      customerPhoto: map['customerPhoto'] ?? map['customerVehiclePhoto'],
      travelTicketPhoto: map['travelTicketPhoto'],
      vehiclePhoto: map['vehiclePhoto'],
    );
  }

  bool get isEmpty {
    return idFront == null &&
        idBack == null &&
        licenseFront == null &&
        licenseBack == null &&
        customerPhoto == null &&
        travelTicketPhoto == null &&
        vehiclePhoto == null;
  }

  bool get isComplete {
    return idFront != null &&
        idBack != null &&
        licenseFront != null &&
        licenseBack != null;
  }
}
