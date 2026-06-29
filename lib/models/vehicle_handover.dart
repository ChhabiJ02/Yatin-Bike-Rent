class VehicleHandover {
  final String vehicleName;
  final String vehicleNumber;
  final String vehicleModel;
  final String vehicleBrand;
  final String vehicleGivenDate;
  final String vehicleGivenTime;
  final String vehicleReturnDate;
  final String vehicleReturnTime;
  final String vehiclePickupLocation;
  final String vehicleReturnLocation;
  final String vehicleCameFrom;
  final String vehicleReturnedTo;
  final String returnStatus;

  VehicleHandover({
    this.vehicleName = '',
    this.vehicleNumber = '',
    this.vehicleModel = '',
    this.vehicleBrand = '',
    this.vehicleGivenDate = '',
    this.vehicleGivenTime = '',
    this.vehicleReturnDate = '',
    this.vehicleReturnTime = '',
    this.vehiclePickupLocation = '',
    this.vehicleReturnLocation = '',
    this.vehicleCameFrom = '',
    this.vehicleReturnedTo = '',
    this.returnStatus = 'Pending',
  });

  VehicleHandover copyWith({
    String? vehicleName,
    String? vehicleNumber,
    String? vehicleModel,
    String? vehicleBrand,
    String? vehicleGivenDate,
    String? vehicleGivenTime,
    String? vehicleReturnDate,
    String? vehicleReturnTime,
    String? vehiclePickupLocation,
    String? vehicleReturnLocation,
    String? vehicleCameFrom,
    String? vehicleReturnedTo,
    String? returnStatus,
  }) {
    return VehicleHandover(
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleGivenDate: vehicleGivenDate ?? this.vehicleGivenDate,
      vehicleGivenTime: vehicleGivenTime ?? this.vehicleGivenTime,
      vehicleReturnDate: vehicleReturnDate ?? this.vehicleReturnDate,
      vehicleReturnTime: vehicleReturnTime ?? this.vehicleReturnTime,
      vehiclePickupLocation: vehiclePickupLocation ?? this.vehiclePickupLocation,
      vehicleReturnLocation: vehicleReturnLocation ?? this.vehicleReturnLocation,
      vehicleCameFrom: vehicleCameFrom ?? this.vehicleCameFrom,
      vehicleReturnedTo: vehicleReturnedTo ?? this.vehicleReturnedTo,
      returnStatus: returnStatus ?? this.returnStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleName': vehicleName,
      'vehicleNumber': vehicleNumber,
      'vehicleModel': vehicleModel,
      'vehicleBrand': vehicleBrand,
      'vehicleGivenDate': vehicleGivenDate,
      'vehicleGivenTime': vehicleGivenTime,
      'vehicleReturnDate': vehicleReturnDate,
      'vehicleReturnTime': vehicleReturnTime,
      'vehiclePickupLocation': vehiclePickupLocation,
      'vehicleReturnLocation': vehicleReturnLocation,
      'vehicleCameFrom': vehicleCameFrom,
      'vehicleReturnedTo': vehicleReturnedTo,
      'returnStatus': returnStatus,
    };
  }

  factory VehicleHandover.fromMap(Map<String, dynamic> map) {
    return VehicleHandover(
      vehicleName: map['vehicleName'] ?? '',
      vehicleNumber: map['vehicleNumber'] ?? '',
      vehicleModel: map['vehicleModel'] ?? '',
      vehicleBrand: map['vehicleBrand'] ?? '',
      vehicleGivenDate: map['vehicleGivenDate'] ?? '',
      vehicleGivenTime: map['vehicleGivenTime'] ?? '',
      vehicleReturnDate: map['vehicleReturnDate'] ?? '',
      vehicleReturnTime: map['vehicleReturnTime'] ?? '',
      vehiclePickupLocation: map['vehiclePickupLocation'] ?? '',
      vehicleReturnLocation: map['vehicleReturnLocation'] ?? '',
      vehicleCameFrom: map['vehicleCameFrom'] ?? '',
      vehicleReturnedTo: map['vehicleReturnedTo'] ?? '',
      returnStatus: map['returnStatus'] ?? 'Pending',
    );
  }

  bool get isEmpty {
    return vehicleName.isEmpty &&
        vehicleNumber.isEmpty &&
        vehicleModel.isEmpty &&
        vehicleBrand.isEmpty;
  }

  bool get isComplete {
    return vehicleName.isNotEmpty && vehicleNumber.isNotEmpty;
  }
}