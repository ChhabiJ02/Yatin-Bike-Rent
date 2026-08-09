class CustomerDocuments {
  final String? idFront;
  final String? idBack;
  final String? customerPhoto;
  final String? travelTicketPhoto;
  final String? vehiclePhoto;

  CustomerDocuments({
    this.idFront,
    this.idBack,
    this.customerPhoto,
    this.travelTicketPhoto,
    this.vehiclePhoto,
  });

  CustomerDocuments copyWith({
    String? idFront,
    String? idBack,
    String? customerPhoto,
    String? travelTicketPhoto,
    String? vehiclePhoto,
  }) {
    return CustomerDocuments(
      idFront: idFront ?? this.idFront,
      idBack: idBack ?? this.idBack,
      customerPhoto: customerPhoto ?? this.customerPhoto,
      travelTicketPhoto: travelTicketPhoto ?? this.travelTicketPhoto,
      vehiclePhoto: vehiclePhoto ?? this.vehiclePhoto,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (idFront != null) 'idFront': idFront,
      if (idBack != null) 'idBack': idBack,
      if (customerPhoto != null) 'customerPhoto': customerPhoto,
      if (travelTicketPhoto != null) 'travelTicketPhoto': travelTicketPhoto,
      if (vehiclePhoto != null) 'vehiclePhoto': vehiclePhoto,
    };
  }

  factory CustomerDocuments.fromMap(Map<String, dynamic> map) {
    return CustomerDocuments(
      idFront: map['idFront'] ?? map['aadhaarFront'] ?? map['licenseFront'],
      idBack: map['idBack'] ?? map['aadhaarBack'] ?? map['licenseBack'],
      customerPhoto: map['customerPhoto'] ?? map['customerVehiclePhoto'],
      travelTicketPhoto: map['travelTicketPhoto'],
      vehiclePhoto: map['vehiclePhoto'],
    );
  }

  bool get isEmpty {
    return idFront == null &&
        idBack == null &&
        customerPhoto == null &&
        travelTicketPhoto == null &&
        vehiclePhoto == null;
  }

  bool get isComplete {
    return idFront != null && idBack != null && customerPhoto != null;
  }
}