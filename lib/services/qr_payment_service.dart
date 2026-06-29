import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/qr_code.dart';

class QRPaymentService {
  static final CollectionReference<Map<String, dynamic>> _qrCollection =
      FirebaseFirestore.instance.collection('paymentSettings');

  static Stream<List<QRCodePayment>> qrCodesStream() {
    return _qrCollection
        .doc('qrCodes')
        .collection('codes')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QRCodePayment.fromMap(doc.data()))
            .toList());
  }

  static Future<List<QRCodePayment>> getActiveQRCodes() async {
    final snapshot = await _qrCollection
        .doc('qrCodes')
        .collection('codes')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => QRCodePayment.fromMap(doc.data()))
        .toList();
  }

  static Future<void> addQRCode(QRCodePayment qrCode) async {
    await _qrCollection
        .doc('qrCodes')
        .collection('codes')
        .doc(qrCode.id)
        .set(qrCode.toMap());
  }

  static Future<void> updateQRCode(QRCodePayment qrCode) async {
    await _qrCollection
        .doc('qrCodes')
        .collection('codes')
        .doc(qrCode.id)
        .update(qrCode.toMap());
  }

  static Future<void> deleteQRCode(String id) async {
    await _qrCollection
        .doc('qrCodes')
        .collection('codes')
        .doc(id)
        .delete();
  }

  static Future<void> toggleQRCodeStatus(String id, bool isActive) async {
    await _qrCollection
        .doc('qrCodes')
        .collection('codes')
        .doc(id)
        .update({'isActive': isActive});
  }
}