import 'package:cloud_firestore/cloud_firestore.dart';

class QRCodePayment {
  final String? id;
  final String name;
  final String imageUrl;
  final String upiId;
  final String description;
  final bool isActive;

  QRCodePayment({
    this.id,
    this.name = '',
    this.imageUrl = '',
    this.upiId = '',
    this.description = '',
    this.isActive = true,
  });

  QRCodePayment copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? upiId,
    String? description,
    bool? isActive,
  }) {
    return QRCodePayment(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      upiId: upiId ?? this.upiId,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'upiId': upiId,
      'description': description,
      'isActive': isActive,
    };
  }

  factory QRCodePayment.fromMap(Map<String, dynamic> map) {
    return QRCodePayment(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      upiId: map['upiId'] ?? '',
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  factory QRCodePayment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return QRCodePayment(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      upiId: data['upiId'] ?? '',
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  bool get isEmpty => (id?.isEmpty ?? true) && name.isEmpty && imageUrl.isEmpty;
}
