import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/qr_code.dart';

class QRPaymentService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<List<QRCodePayment>> getActiveQRCodes() async {
    try {
      debugPrint("Fetching active QR codes from 'paymentSettings'...");
      final snapshot = await _db
          .collection('paymentSettings')
          .get()
          .timeout(const Duration(seconds: 15));
      debugPrint("Successfully fetched ${snapshot.docs.length} QR codes.");
      return snapshot.docs
          .map((doc) => QRCodePayment.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching active QR codes: $e');
      // Return an empty list to ensure the Future always completes,
      // allowing the UI to stop loading and show a message.
      return [];
    }
  }
}
