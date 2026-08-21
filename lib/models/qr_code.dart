import 'package:cloud_firestore/cloud_firestore.dart';

class QRCodePayment {
  final String id;
  final String name;
  final String imageUrl;
  final String upiId;
  final String description;
  final bool isActive;

  const QRCodePayment({
    required this.id,
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
      // The document ID is used as the 'id', so we don't need to store it in the document fields.
      'name': name,
      'imageUrl': imageUrl,
      'upiId': upiId,
      'description': description,
      'isActive': isActive,
    };
  }

  factory QRCodePayment.fromMap(Map<String, dynamic> map) {
    return QRCodePayment(
      id: _stringValue(map['id']),
      name: _stringValue(map['name']),
      imageUrl: _stringValue(map['imageUrl']),
      upiId: _stringValue(map['upiId']),
      description: _stringValue(map['description']),
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
    );
  }

  factory QRCodePayment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return QRCodePayment(
      id: doc.id,
      name: _stringValue(data['name']),
      imageUrl: _stringValue(data['imageUrl']),
      upiId: _stringValue(data['upiId']),
      description: _stringValue(data['description']),
      isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
    );
  }

  bool get requiresQr => imageUrl.isNotEmpty || upiId.isNotEmpty;

  bool get isEmpty => id.isEmpty && name.isEmpty && imageUrl.isEmpty;
}

String _stringValue(Object? value) => value?.toString() ?? '';
