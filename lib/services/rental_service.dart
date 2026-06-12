import 'package:cloud_firestore/cloud_firestore.dart';

class RentalService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<QuerySnapshot<Map<String, dynamic>>> vehiclesStream({
    bool availableOnly = false,
  }) {
    var query = _db.collection('vehicles').orderBy('name');
    if (availableOnly) {
      query = query.where('available', isEqualTo: true).orderBy('name');
    }
    return query.snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> customersStream() {
    return _db.collection('customers').orderBy('name').snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> bookingsStream({
    String? customerUid,
  }) {
    var query = _db
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .limit(50);
    if (customerUid != null) {
      query = query.where('customerUid', isEqualTo: customerUid);
    }
    return query.snapshots();
  }

  static Future<void> saveCustomer({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String licenseNo,
  }) async {
    await _db.collection('customers').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'licenseNo': licenseNo,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> addVehicle({
    required String name,
    required String number,
    required String type,
    required int hourlyRate,
    required int dailyRate,
    required String fuelType,
  }) async {
    await _db.collection('vehicles').add({
      'name': name,
      'number': number,
      'type': type,
      'hourlyRate': hourlyRate,
      'dailyRate': dailyRate,
      'fuelType': fuelType,
      'available': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateVehicleAvailability({
    required String vehicleId,
    required bool available,
  }) async {
    await _db.collection('vehicles').doc(vehicleId).update({
      'available': available,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> createBooking({
    required String customerUid,
    required String customerName,
    required String customerPhone,
    required String vehicleId,
    required String vehicleName,
    required DateTime startAt,
    required DateTime endAt,
    required String rentType,
    required int rate,
    required int totalAmount,
    String status = 'Pending',
  }) async {
    await _db.collection('bookings').add({
      'customerUid': customerUid,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'rentType': rentType,
      'rate': rate,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final booking = await _db.collection('bookings').doc(bookingId).get();
    final vehicleId = booking.data()?['vehicleId'] as String?;

    await _db.collection('bookings').doc(bookingId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (vehicleId != null && status == 'Checked In') {
      await updateVehicleAvailability(vehicleId: vehicleId, available: false);
    }
    if (vehicleId != null && status == 'Completed') {
      await updateVehicleAvailability(vehicleId: vehicleId, available: true);
    }
  }

  static int calculateTotal({
    required DateTime startAt,
    required DateTime endAt,
    required String rentType,
    required int hourlyRate,
    required int dailyRate,
  }) {
    final minutes = endAt.difference(startAt).inMinutes;
    if (minutes <= 0) return 0;

    if (rentType == 'Day') {
      final days = (minutes / 1440).ceil().clamp(1, 365);
      return days * dailyRate;
    }

    final hours = (minutes / 60).ceil().clamp(1, 8760);
    return hours * hourlyRate;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> countStream(String collection) {
    return _db.collection(collection).snapshots();
  }
}
