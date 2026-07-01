import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing Challan counters and transactional operations
class ChallanService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Calculate the current financial year based on today's date
  /// FY starts on April 1 and ends on March 31
  static String getCurrentFinancialYear() {
    final now = DateTime.now();
    final currentYear = now.year;
    final fiscalYearStart = DateTime(currentYear, 4, 1);
    if (now.isBefore(fiscalYearStart)) {
      return '${currentYear - 1}-$currentYear';
    }
    return '$currentYear-${currentYear + 1}';
  }

  /// Generate the financial year prefix (e.g., "2627" for FY 2026-2027)
  static String getFinancialYearPrefix(String fyear) {
    final parts = fyear.split('-');
    if (parts.length >= 2) {
      final start = parts[0].substring(2);
      final end = parts[1].substring(2);
      return '$start$end';
    }
    return '';
  }

  /// Generate the next unique Customer Code using a counter with transaction
  /// Format: [Prefix][4-digit-running-number] e.g., 26270001
  static Future<String> generateCustomerCode() async {
    final fyear = getCurrentFinancialYear();
    final prefix = getFinancialYearPrefix(fyear);
    final counterRef = _db.collection('counters').doc('customerCode');

    return _db.runTransaction<String>((transaction) async {
      final counterDoc = await transaction.get(counterRef);

      int currentNumber = 1;
      String storedFyear = fyear;

      if (counterDoc.exists) {
        storedFyear = counterDoc.data()?['financialYear'] as String? ?? fyear;
        // If financial year changed, reset counter to 1
        if (storedFyear != fyear) {
          currentNumber = 1;
          storedFyear = fyear;
        } else {
          currentNumber = (counterDoc.data()?['currentNumber'] as int?) ?? 0;
          currentNumber++;
        }
      }

      // Update the counter with new values
      transaction.set(
        counterRef,
        {
          'currentNumber': currentNumber,
          'financialYear': storedFyear,
          'prefix': prefix,
        },
        SetOptions(merge: true),
      );

      // Format: [Prefix][4-digit-number] e.g., 26270001
      final numberStr = currentNumber.toString().padLeft(4, '0');
      return '$prefix$numberStr';
    });
  }

  /// Generate the next unique Challan number using a counter
  /// Uses Firestore transactions to ensure atomicity
  static Future<String> generateChallanNumber() async {
    final counterRef = _db.collection('counters').doc('challanCounter');

    return _db.runTransaction<String>((transaction) async {
      final counterDoc = await transaction.get(counterRef);

      int currentNumber = 1;
      if (counterDoc.exists) {
        currentNumber = (counterDoc.data()?['currentNumber'] as int?) ?? 0;
        currentNumber++;
      }

      // Update the counter
      transaction.set(counterRef, {'currentNumber': currentNumber}, SetOptions(merge: true));

      // Format: CH-{year}-{5-digit-number}
      final year = DateTime.now().year;
      final formattedNumber = currentNumber.toString().padLeft(5, '0');
      return 'CH-$year-$formattedNumber';
    });
  }

  /// Save a complete Challan with all related data in a single transaction
  static Future<void> saveChallanWithTransaction({
    required String custCode,
    required Map<String, dynamic> customerData,
    Map<String, dynamic>? transportation,
    Map<String, dynamic>? vehicleHandover,
    Map<String, dynamic>? travelDetails,
    Map<String, dynamic>? kilometerDetails,
    Map<String, dynamic>? payment,
    Map<String, dynamic>? documents,
  }) async {
    await _db.runTransaction((transaction) async {
      final custDocRef = _db.collection('customers').doc(custCode);
      final counterRef = _db.collection('counters').doc('challanCounter');

      // Get and increment counter
      final counterDoc = await transaction.get(counterRef);
      int currentNumber = 1;
      if (counterDoc.exists) {
        currentNumber = (counterDoc.data()?['currentNumber'] as int?) ?? 0;
        currentNumber++;
      }

      // Format: CH-{year}-{5-digit-number}
      final year = DateTime.now().year;
      final formattedNumber = currentNumber.toString().padLeft(5, '0');
      final challanNumber = 'CH-$year-$formattedNumber';

      // Update counter
      transaction.set(counterRef, {'currentNumber': currentNumber}, SetOptions(merge: true));

      // Build the complete data map
      final data = Map<String, dynamic>.from(customerData);
      data['challanNumber'] = challanNumber;
      data['updatedAt'] = FieldValue.serverTimestamp();

      // Add transportation data inside the Challan document
      if (transportation != null && transportation.isNotEmpty) {
        data['transportation'] = transportation;
      }

      // Add vehicle handover
      if (vehicleHandover != null && vehicleHandover.isNotEmpty) {
        data['vehicleHandover'] = vehicleHandover;
      }

      // Add travel details
      if (travelDetails != null && travelDetails.isNotEmpty) {
        data['travelDetails'] = travelDetails;
      }

      // Add kilometer details
      if (kilometerDetails != null && kilometerDetails.isNotEmpty) {
        data['kilometerDetails'] = kilometerDetails;
      }

      // Add payment details
      if (payment != null && payment.isNotEmpty) {
        data['payment'] = payment;
      }

      // Add documents
      if (documents != null && documents.isNotEmpty) {
        data['customerDocuments'] = documents;
      }

      // Save to Firestore
      transaction.set(custDocRef, data, SetOptions(merge: true));
    });
  }

  /// Update vehicle return status with transaction
  static Future<void> updateVehicleReturnStatus({
    required String custCode,
    required String returnStatus,
  }) async {
    await _db.runTransaction((transaction) async {
      final custDocRef = _db.collection('customers').doc(custCode);
      final custDoc = await transaction.get(custDocRef);

      if (!custDoc.exists) {
        throw Exception('Customer document not found');
      }

      final data = custDoc.data()!;
      final handover = Map<String, dynamic>.from(data['vehicleHandover'] ?? {});
      handover['returnStatus'] = returnStatus;
      handover['returnUpdatedAt'] = FieldValue.serverTimestamp();

      transaction.update(custDocRef, {'vehicleHandover': handover});
    });
  }

  /// Update booking status with transaction
  static Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    String? vehicleId,
    bool? vehicleAvailable,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _db.collection('bookings').doc(bookingId);

      // Update booking status
      transaction.update(bookingRef, {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update vehicle availability if provided
      if (vehicleId != null && vehicleAvailable != null) {
        final vehicleRef = _db.collection('vehicles').doc(vehicleId);
        transaction.update(vehicleRef, {
          'available': vehicleAvailable,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Check if a time slot is available for a vehicle
  static Future<bool> isTimeSlotAvailable({
    required String vehicleId,
    required String date,
    required String timeSlot,
    String? excludeBookingId,
  }) async {
    final bookings = await _db
        .collection('bookings')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('date', isEqualTo: date)
        .where('timeSlot', isEqualTo: timeSlot)
        .get();

    for (final doc in bookings.docs) {
      if (excludeBookingId != null && doc.id == excludeBookingId) {
        continue;
      }
      return false;
    }
    return true;
  }

  /// Get vehicle status summary for dashboard
  static Future<Map<String, int>> getVehicleStatusSummary() async {
    final vehicles = await _db.collection('vehicles').get();
    final customers = await _db.collection('customers').get();

    int available = 0;
    int booked = 0;
    int returnPending = 0;
    int returned = 0;

    for (final vehicle in vehicles.docs) {
      final available_ = vehicle.data()['available'] as bool? ?? false;
      if (available_) {
        available++;
      } else {
        booked++;
      }
    }

    for (final customer in customers.docs) {
      final handover = customer.data()['vehicleHandover'] as Map<String, dynamic>?;
      final status = handover?['returnStatus'] as String? ?? 'Pending';
      if (status == 'Returned') {
        returned++;
      } else {
        returnPending++;
      }
    }

    return {
      'available': available,
      'booked': booked,
      'returnPending': returnPending,
      'returned': returned,
    };
  }
}