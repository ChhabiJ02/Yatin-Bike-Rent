class KilometerDetails {
  final int startKM;
  final int endKM;

  KilometerDetails({
    this.startKM = 0,
    this.endKM = 0,
  });

  int get totalKM => endKM > startKM ? endKM - startKM : 0;

  KilometerDetails copyWith({
    int? startKM,
    int? endKM,
  }) {
    return KilometerDetails(
      startKM: startKM ?? this.startKM,
      endKM: endKM ?? this.endKM,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startKM': startKM,
      'endKM': endKM,
      'totalKM': totalKM,
    };
  }

  factory KilometerDetails.fromMap(Map<String, dynamic> map) {
    return KilometerDetails(
      startKM: (map['startKM'] is int) ? map['startKM'] : 0,
      endKM: (map['endKM'] is int) ? map['endKM'] : 0,
    );
  }

  bool get isEmpty => startKM == 0 && endKM == 0;

  bool get isValid => startKM > 0 && endKM > 0 && endKM >= startKM;
}