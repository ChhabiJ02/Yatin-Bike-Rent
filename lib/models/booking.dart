class Booking {
  final String id;
  final String customerName;
  final String vehicleName;
  final String rentalPeriod;
  final String status;
  final int totalAmount;
  final String? startTime;
  final String? endTime;
  final String? timeSlot;

  const Booking({
    required this.id,
    required this.customerName,
    required this.vehicleName,
    required this.rentalPeriod,
    required this.status,
    required this.totalAmount,
    this.startTime,
    this.endTime,
    this.timeSlot,
  });

  static const timeSlots = [
    'Morning (6AM - 12PM)',
    'Afternoon (12PM - 6PM)',
    'Evening (6PM - 12AM)',
    'Night (12AM - 6AM)',
    'Full Day (24 Hours)',
  ];

  bool overlaps(Booking other) {
    if (vehicleName != other.vehicleName) return false;
    if (startTime == null || other.startTime == null) return false;
    return startTime == other.startTime;
  }
}
