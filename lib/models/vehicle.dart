class Vehicle {
  final String id;
  final String name;
  final String type;
  final int pricePerHour;
  final int pricePerDay;
  final bool available;
  final String description;

  const Vehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.pricePerHour,
    required this.pricePerDay,
    required this.available,
    required this.description,
  });
}
