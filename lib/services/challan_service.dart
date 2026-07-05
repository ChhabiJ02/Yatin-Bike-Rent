import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for managing Challan counters and transactional operations
class ChallanService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Calculate the financial year for a given date.
  /// FY starts on April 1 and ends on March 31.
  static String getFinancialYearForDate(DateTime date) {
    final currentYear = date.year;
    final fiscalYearStart = DateTime(currentYear, 4, 1);
    if (date.isBefore(fiscalYearStart)) {
      return '${currentYear - 1}-$currentYear';
    }
    return '$currentYear-${currentYear + 1}';
  }

  /// Calculate the current financial year based on today's date.
  static String getCurrentFinancialYear() => getFinancialYearForDate(DateTime.now());

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

  /// Build a customer code for a given financial year and counter value.
  static String buildCustomerCode(String financialYear, int currentNumber) {
    final prefix = getFinancialYearPrefix(financialYear);
    final numberStr = currentNumber.toString().padLeft(4, '0');
    return '$prefix$numberStr';
  }

  /// Derive the next customer code from the highest existing code in the same financial year.
  static String getNextCustomerCodeFromHighest(String financialYear, String? highestCustCode) {
    final prefix = getFinancialYearPrefix(financialYear);
    debugPrint('Current Financial Year: $financialYear');
    debugPrint('Current Prefix: $prefix');

    if (highestCustCode == null || highestCustCode.trim().isEmpty) {
      final generatedCode = buildCustomerCode(financialYear, 1);
      debugPrint('Last Customer Code found: none');
      debugPrint('Newly Generated Customer Code: $generatedCode');
      return generatedCode;
    }

    final normalizedCode = highestCustCode.trim();
    final match = RegExp('^$prefix(\\d{4})').firstMatch(normalizedCode);

    if (match == null) {
      final generatedCode = buildCustomerCode(financialYear, 1);
      debugPrint('Last Customer Code found: $normalizedCode');
      debugPrint('Newly Generated Customer Code: $generatedCode');
      return generatedCode;
    }

    final currentNumber = int.parse(match.group(1)!);
    final generatedCode = buildCustomerCode(financialYear, currentNumber + 1);
    debugPrint('Last Customer Code found: $normalizedCode');
    debugPrint('Newly Generated Customer Code: $generatedCode');
    return generatedCode;
  }

  /// Generate the next unique Customer Code by reading the existing customers collection.
  /// Format: [Prefix][4-digit-running-number] e.g., 26270001
  static Future<String> generateCustomerCode() async {
    return generateCustomerCodeForFinancialYear(getCurrentFinancialYear());
  }

  /// Generate the next unique Customer Code for a specific financial year.
  static Future<String> generateCustomerCodeForFinancialYear(String fyear) async {
    final highestCustCode = await _findHighestCustomerCodeForFinancialYear(fyear);
    return getNextCustomerCodeFromHighest(fyear, highestCustCode);
  }

  static Future<String?> _findHighestCustomerCodeForFinancialYear(String fyear) async {
    final snapshot = await _db
        .collection('customers')
        .where('fyear', isEqualTo: fyear)
        .get();

    String? highestCustCode;
    for (final doc in snapshot.docs) {
      final custCode = doc.data()['custCode']?.toString();
      if (custCode == null || custCode.trim().isEmpty) {
        continue;
      }
      if (highestCustCode == null || custCode.compareTo(highestCustCode) > 0) {
        highestCustCode = custCode;
      }
    }
    return highestCustCode;
  }

  /// Atomically generate the next unique Customer Code for a specific financial year
  /// using a counter document to avoid race conditions when multiple clients
  /// create customers simultaneously.
  /// Counter doc path: `counters/customerCounter_<fyear>` with `currentNumber` int.
  static Future<String> generateCustomerCodeWithTransaction(String fyear) async {
    final counterRef = _db.collection('counters').doc('customerCounter_$fyear');

    final highestCustCode = await _findHighestCustomerCodeForFinancialYear(fyear);
    int highestNumber = 0;
    if (highestCustCode != null && highestCustCode.isNotEmpty) {
      final prefix = getFinancialYearPrefix(fyear);
      final match = RegExp('^${RegExp.escape(prefix)}(\\d{4})').firstMatch(highestCustCode.trim());
      if (match != null) {
        highestNumber = int.parse(match.group(1)!);
      }
    }

    return _db.runTransaction<String>((transaction) async {
      final counterDoc = await transaction.get(counterRef);

      int currentNumber = 0;
      if (counterDoc.exists) {
        currentNumber = (counterDoc.data()?['currentNumber'] as int?) ?? 0;
      }

      if (currentNumber < highestNumber) {
        currentNumber = highestNumber;
      }

      currentNumber++;

      transaction.set(counterRef, {'currentNumber': currentNumber, 'fyear': fyear}, SetOptions(merge: true));

      return buildCustomerCode(fyear, currentNumber);
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