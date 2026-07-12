class PaymentDetails {
  final String paymentAmount;
  final String paymentDate;
  final String paymentTime;
  final String paymentMode;
  final String transactionId;
  final String paymentNotes;
  final String selectedQRName;

  PaymentDetails({
    this.paymentAmount = '',
    this.paymentDate = '',
    this.paymentTime = '',
    this.paymentMode = '',
    this.transactionId = '',
    this.paymentNotes = '',
    this.selectedQRName = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentAmount': paymentAmount,
      'paymentDate': paymentDate,
      'paymentTime': paymentTime,
      'paymentMode': paymentMode,
      'transactionId': transactionId,
      'paymentNotes': paymentNotes,
      'selectedQRName': selectedQRName,
    };
  }

  factory PaymentDetails.fromMap(Map<String, dynamic> map) {
    return PaymentDetails(
      paymentAmount: map['paymentAmount'] ?? '',
      paymentDate: map['paymentDate'] ?? '',
      paymentTime: map['paymentTime'] ?? '',
      paymentMode: map['paymentMode'] ?? '',
      transactionId: map['transactionId'] ?? '',
      paymentNotes: map['paymentNotes'] ?? '',
      selectedQRName: map['selectedQRName'] ?? '',
    );
  }

  PaymentDetails copyWith({
    String? paymentAmount,
    String? paymentDate,
    String? paymentTime,
    String? paymentMode,
    String? transactionId,
    String? paymentNotes,
    String? selectedQRName,
  }) {
    return PaymentDetails(
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentTime: paymentTime ?? this.paymentTime,
      paymentMode: paymentMode ?? this.paymentMode,
      transactionId: transactionId ?? this.transactionId,
      paymentNotes: paymentNotes ?? this.paymentNotes,
      selectedQRName: selectedQRName ?? this.selectedQRName,
    );
  }

  bool get isEmpty {
    return paymentAmount.isEmpty &&
        paymentDate.isEmpty &&
        paymentTime.isEmpty &&
        paymentMode.isEmpty &&
        transactionId.isEmpty &&
        paymentNotes.isEmpty &&
        selectedQRName.isEmpty;
  }
}
