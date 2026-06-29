import 'customer_documents.dart';
import 'vehicle_handover.dart';
import 'travel_details.dart';
import 'kilometer_details.dart';
import 'invoice.dart';
import 'payment.dart';

class ChallanData {
  final CustomerDocuments? customerDocuments;
  final VehicleHandover? vehicleHandover;
  final TravelDetails? travelDetails;
  final KilometerDetails? kilometerDetails;
  final Invoice? invoice;
  final PaymentDetails? payment;

  ChallanData({
    this.customerDocuments,
    this.vehicleHandover,
    this.travelDetails,
    this.kilometerDetails,
    this.invoice,
    this.payment,
  });

  ChallanData copyWith({
    CustomerDocuments? customerDocuments,
    VehicleHandover? vehicleHandover,
    TravelDetails? travelDetails,
    KilometerDetails? kilometerDetails,
    Invoice? invoice,
    PaymentDetails? payment,
  }) {
    return ChallanData(
      customerDocuments: customerDocuments ?? this.customerDocuments,
      vehicleHandover: vehicleHandover ?? this.vehicleHandover,
      travelDetails: travelDetails ?? this.travelDetails,
      kilometerDetails: kilometerDetails ?? this.kilometerDetails,
      invoice: invoice ?? this.invoice,
      payment: payment ?? this.payment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (customerDocuments != null && !customerDocuments!.isEmpty)
        'customerDocuments': customerDocuments!.toMap(),
      if (vehicleHandover != null && !vehicleHandover!.isEmpty)
        'vehicleHandover': vehicleHandover!.toMap(),
      if (travelDetails != null && !travelDetails!.isEmpty)
        'travelDetails': travelDetails!.toMap(),
      if (kilometerDetails != null && !kilometerDetails!.isEmpty)
        'kilometerDetails': kilometerDetails!.toMap(),
      if (invoice != null && !invoice!.isEmpty)
        'invoice': invoice!.toMap(),
      if (payment != null && !payment!.isEmpty)
        'payment': payment!.toMap(),
    };
  }

  factory ChallanData.fromMap(Map<String, dynamic> map) {
    return ChallanData(
      customerDocuments: map['customerDocuments'] != null
          ? CustomerDocuments.fromMap(
              Map<String, dynamic>.from(map['customerDocuments']))
          : null,
      vehicleHandover: map['vehicleHandover'] != null
          ? VehicleHandover.fromMap(Map<String, dynamic>.from(map['vehicleHandover']))
          : null,
      travelDetails: map['travelDetails'] != null
          ? TravelDetails.fromMap(Map<String, dynamic>.from(map['travelDetails']))
          : null,
      kilometerDetails: map['kilometerDetails'] != null
          ? KilometerDetails.fromMap(
              Map<String, dynamic>.from(map['kilometerDetails']))
          : null,
      invoice: map['invoice'] != null
          ? Invoice.fromMap(Map<String, dynamic>.from(map['invoice']))
          : null,
      payment: map['payment'] != null
          ? PaymentDetails.fromMap(Map<String, dynamic>.from(map['payment']))
          : null,
    );
  }

  bool get isEmpty {
    return (customerDocuments == null || customerDocuments!.isEmpty) &&
        (vehicleHandover == null || vehicleHandover!.isEmpty) &&
        (travelDetails == null || travelDetails!.isEmpty) &&
        (kilometerDetails == null || kilometerDetails!.isEmpty) &&
        (invoice == null || invoice!.isEmpty) &&
        (payment == null || payment!.isEmpty);
  }
}