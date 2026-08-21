import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/qr_code.dart';

class QRPaymentService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _defaultPaymentMethods = [
    QRCodePayment(id: 'cash', name: 'Cash'),
    QRCodePayment(id: 'sbi', name: 'SBI'),
    QRCodePayment(id: 'bob', name: 'BOB'),
    QRCodePayment(id: 'pnb', name: 'PNB'),
    QRCodePayment(id: 'gpay', name: 'GPay'),
  ];

  static const _allowedNames = {
    'cash',
    'sbi',
    'bob',
    'pnb',
    'gpay',
  };

  static Future<List<QRCodePayment>> getActiveQRCodes() async {
    try {
      debugPrint("Fetching active QR codes from 'paymentSettings'...");
      final snapshot = await _db
          .collection('paymentSettings')
          .where('isActive', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 15));
      debugPrint("Successfully fetched ${snapshot.docs.length} QR codes.");
      final methods = snapshot.docs
          .map((doc) => QRCodePayment.fromFirestore(doc))
            .where((method) => _allowedNames.contains(method.name.trim().toLowerCase()))
          .toList();
      return methods.isEmpty ? _defaultPaymentMethods : methods;
    } catch (e) {
      debugPrint('Error fetching active QR codes: $e');
      return _defaultPaymentMethods;
    }
  }
}
