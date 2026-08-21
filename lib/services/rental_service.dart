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
    required String no,
    required String name,
    required String number,
    required String type,
    required int hourlyRate,
    required int dailyRate,
    required String fuelType,
    String? category,
    String? chasisNo,
    String? engNo,
  }) async {
    await _db.collection('vehicles').add({
      'no': no,
      'name': name,
      'number': number,
      'type': type,
      'hourlyRate': hourlyRate,
      'dailyRate': dailyRate,
      'fuelType': fuelType,
      'category': category,
      'chasisNo': chasisNo,
      'engNo': engNo,
      'available': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateVehicle({
    required String vehicleId,
    required String no,
    required String name,
    required String number,
    required String type,
    required int hourlyRate,
    required int dailyRate,
    required String fuelType,
    String? category,
    String? chasisNo,
    String? engNo,
  }) async {
    await _db.collection('vehicles').doc(vehicleId).update({
      'no': no,
      'name': name,
      'number': number,
      'type': type,
      'hourlyRate': hourlyRate,
      'dailyRate': dailyRate,
      'fuelType': fuelType,
      'category': category,
      'chasisNo': chasisNo,
      'engNo': engNo,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteVehicle(String vehicleId) async {
    await _db.collection('vehicles').doc(vehicleId).delete();
  }

  /// Finds a single vehicle by its internal 'no' field.
  static Future<DocumentSnapshot<Map<String, dynamic>>?> findVehicleByInternalNo(
      String no) async {
    if (no.trim().isEmpty) return null;

    var querySnapshot = await _db
        .collection('vehicles')
        .where('no', isEqualTo: no.trim())
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      final intValue = int.tryParse(no.trim());
      if (intValue != null) {
        querySnapshot = await _db
            .collection('vehicles')
            .where('no', isEqualTo: intValue)
            .limit(1)
            .get();
      }
    }

    return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>?> findVehicleByName(
      String name) async {
    if (name.trim().isEmpty) return null;

    final querySnapshot = await _db
        .collection('vehicles')
        .where('name', isEqualTo: name.trim())
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
  }

  /// Finds a single vehicle by its registration number.
  ///
  /// The search is case-insensitive by querying an uppercase version of the number.
  /// It's recommended to store a normalized (e.g., uppercase, no spaces) version
  /// of the vehicle number in Firestore to make queries reliable.
 static Future<DocumentSnapshot<Map<String, dynamic>>?> findVehicleByNumber(
  String inputNumber,
) async {
  final query = inputNumber.trim();
  if (query.isEmpty) return null;

  final collection = FirebaseFirestore.instance.collection('vehicles');

  // ૧. માત્ર 'No.' (no) ફીલ્ડ સાથે જ String મેચ કરશે
  var snapshot = await collection
      .where('no', isEqualTo: query)
      .limit(1)
      .get();

  if (snapshot.docs.isNotEmpty) {
    return snapshot.docs.first;
  }

  // ૨. જો ડેટાબેઝમાં 'no' Integer તરીકે સ્ટોર થયેલ હોય
  final intValue = int.tryParse(query);
  if (intValue != null) {
    snapshot = await collection
        .where('no', isEqualTo: intValue)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first;
    }
  }

  return null;
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
    String? startTime,
    String? endTime,
    String? timeSlot,
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
      'startTime': startTime,
      'endTime': endTime,
      'timeSlot': timeSlot,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if a time slot is available for a vehicle - improved validation
  /// Returns null if available, or error message if not available
  static Future<String?> checkTimeSlotAvailable({
    required String vehicleId,
    required String timeSlot,
    required DateTime bookingDate,
    String? excludeBookingId,
  }) async {
    final bookings = await _db.collection('bookings')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('timeSlot', isEqualTo: timeSlot)
        .get();

    for (final doc in bookings.docs) {
      // Skip the booking being edited
      if (excludeBookingId != null && doc.id == excludeBookingId) {
        continue;
      }

      final startAt = doc.data()['startAt'];
      if (startAt is Timestamp) {
        final docDate = startAt.toDate();
        if (docDate.year == bookingDate.year &&
            docDate.month == bookingDate.month &&
            docDate.day == bookingDate.day) {
          final existingStartTime = doc.data()['startTime'] as String? ?? '';
          final existingEndTime = doc.data()['endTime'] as String? ?? '';
          return 'Vehicle already booked for $timeSlot ($existingStartTime - $existingEndTime)';
        }
      }
    }
    return null; // Available
  }

  /// Simplified availability check
  static Future<bool> isTimeSlotAvailable({
    required String vehicleId,
    required String timeSlot,
    required DateTime bookingDate,
    String? excludeBookingId,
  }) async {
    final result = await checkTimeSlotAvailable(
      vehicleId: vehicleId,
      timeSlot: timeSlot,
      bookingDate: bookingDate,
      excludeBookingId: excludeBookingId,
    );
    return result == null;
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
