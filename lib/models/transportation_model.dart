class Transportation {
  final String dispPaper;
  final String documentPending;
  final String dlrMail;
  final String pickupDate;
  final String pickupTime;
  final String pickupLocation;
  final String dropDate;
  final String dropTime;
  final String dropLocation;
  final String stay;
  final int kms;

  Transportation({
    this.dispPaper = '',
    this.documentPending = '',
    this.dlrMail = '',
    this.pickupDate = '',
    this.pickupTime = '',
    this.pickupLocation = '',
    this.dropDate = '',
    this.dropTime = '',
    this.dropLocation = '',
    this.stay = '',
    this.kms = 0,
  });

  Transportation copyWith({
    String? dispPaper,
    String? documentPending,
    String? dlrMail,
    String? pickupDate,
    String? pickupTime,
    String? pickupLocation,
    String? dropDate,
    String? dropTime,
    String? dropLocation,
    String? stay,
    int? kms,
  }) {
    return Transportation(
      dispPaper: dispPaper ?? this.dispPaper,
      documentPending: documentPending ?? this.documentPending,
      dlrMail: dlrMail ?? this.dlrMail,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupTime: pickupTime ?? this.pickupTime,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropDate: dropDate ?? this.dropDate,
      dropTime: dropTime ?? this.dropTime,
      dropLocation: dropLocation ?? this.dropLocation,
      stay: stay ?? this.stay,
      kms: kms ?? this.kms,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dispPaper': dispPaper,
      'documentPending': documentPending,
      'dlrMail': dlrMail,
      'pickupDate': pickupDate,
      'pickupTime': pickupTime,
      'pickupLocation': pickupLocation,
      'dropDate': dropDate,
      'dropTime': dropTime,
      'dropLocation': dropLocation,
      'stay': stay,
      'kms': kms,
    };
  }

  factory Transportation.fromMap(Map<String, dynamic> map) {
    return Transportation(
      dispPaper: map['dispPaper'] ?? '',
      documentPending: map['documentPending'] ?? '',
      dlrMail: map['dlrMail'] ?? '',
      pickupDate: map['pickupDate'] ?? '',
      pickupTime: map['pickupTime'] ?? '',
      pickupLocation: map['pickupLocation'] ?? '',
      dropDate: map['dropDate'] ?? '',
      dropTime: map['dropTime'] ?? '',
      dropLocation: map['dropLocation'] ?? '',
      stay: map['stay'] ?? '',
      kms: map['kms'] ?? 0,
    );
  }

  bool get isEmpty {
    return dispPaper.isEmpty &&
        documentPending.isEmpty &&
        dlrMail.isEmpty &&
        pickupDate.isEmpty &&
        pickupTime.isEmpty &&
        pickupLocation.isEmpty &&
        dropDate.isEmpty &&
        dropTime.isEmpty &&
        dropLocation.isEmpty &&
        stay.isEmpty &&
        kms == 0;
  }
}