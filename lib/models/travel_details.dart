class TravelDetails {
  final String customerCameFrom;
  final String stayingAt;
  final String hotelName;
  final String stayAddress;
  final String landmark;
  final String city;
  final String state;
  final String pinCode;

  TravelDetails({
    this.customerCameFrom = '',
    this.stayingAt = '',
    this.hotelName = '',
    this.stayAddress = '',
    this.landmark = '',
    this.city = '',
    this.state = '',
    this.pinCode = '',
  });

  TravelDetails copyWith({
    String? customerCameFrom,
    String? stayingAt,
    String? hotelName,
    String? stayAddress,
    String? landmark,
    String? city,
    String? state,
    String? pinCode,
  }) {
    return TravelDetails(
      customerCameFrom: customerCameFrom ?? this.customerCameFrom,
      stayingAt: stayingAt ?? this.stayingAt,
      hotelName: hotelName ?? this.hotelName,
      stayAddress: stayAddress ?? this.stayAddress,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerCameFrom': customerCameFrom,
      'stayingAt': stayingAt,
      'hotelName': hotelName,
      'stayAddress': stayAddress,
      'landmark': landmark,
      'city': city,
      'state': state,
      'pinCode': pinCode,
    };
  }

  factory TravelDetails.fromMap(Map<String, dynamic> map) {
    return TravelDetails(
      customerCameFrom: map['customerCameFrom'] ?? '',
      stayingAt: map['stayingAt'] ?? '',
      hotelName: map['hotelName'] ?? '',
      stayAddress: map['stayAddress'] ?? '',
      landmark: map['landmark'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pinCode: map['pinCode'] ?? '',
    );
  }

  bool get isEmpty {
    return customerCameFrom.isEmpty &&
        stayingAt.isEmpty &&
        hotelName.isEmpty &&
        stayAddress.isEmpty;
  }

  bool get isComplete {
    return customerCameFrom.isNotEmpty && stayingAt.isNotEmpty;
  }
}