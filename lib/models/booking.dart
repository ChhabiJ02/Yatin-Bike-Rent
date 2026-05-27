class Booking {
  final String id;
  final String customerName;
  final String vehicleName;
  final String rentalPeriod;
  final String status;
  final int totalAmount;

  const Booking({
    required this.id,
    required this.customerName,
    required this.vehicleName,
    required this.rentalPeriod,
    required this.status,
    required this.totalAmount,
  });
}
