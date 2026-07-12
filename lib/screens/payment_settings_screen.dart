import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/qr_code.dart';
import '../theme/app_theme.dart';
import '../widgets/form_image_picker.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _qrCollection = FirebaseFirestore.instance
      .collection('paymentSettings')
      .doc('qrCodes')
      .collection('codes')
      .withConverter<QRCodePayment>(
        fromFirestore: (snapshot, _) => QRCodePayment.fromFirestore(snapshot),
        toFirestore: (qr, _) => qr.toMap(),
      );
  // ignore: unused_field
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Settings'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddQRDialog),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<QRCodePayment>>(
        stream: _qrCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint("PaymentSettings Error: ${snapshot.error}");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code, size: 64, color: AppColors.muted),
                  const SizedBox(height: 16),
                  const Text(
                    'No Payment Methods Added',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try again later.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddQRDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add QR Code'),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final qrCodes = docs.map((doc) => doc.data()).toList();

          if (qrCodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code, size: 64, color: AppColors.muted),
                  const SizedBox(height: 16),
                  const Text(
                    'No Payment Methods Added',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add QR codes for customers to scan and pay',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddQRDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add QR Code'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: qrCodes.length,
            itemBuilder: (context, index) {
              return _QRCodeManageCard(
                qrCode: qrCodes[index],
                onEdit: () => _showEditQRDialog(qrCodes[index]),
                onDelete: () => _deleteQRCode(qrCodes[index]),
                onToggle: (active) => _toggleQRCode(qrCodes[index], active),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddQRDialog([QRCodePayment? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _QRCodeEditSheet(
        existing: existing,
        onSave: (qrCode) async {
          if (existing != null) {
            await _qrCollection.doc(existing.id).update(qrCode.toMap());
          } else {
            await _qrCollection.doc(qrCode.id).set(qrCode);
          }
          // ignore: use_build_context_synchronously
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditQRDialog(QRCodePayment qrCode) => _showAddQRDialog(qrCode);

  Future<void> _deleteQRCode(QRCodePayment qrCode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete QR Code'),
        content: Text('Delete "${qrCode.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _qrCollection.doc(qrCode.id).delete();
    }
  }

  Future<void> _toggleQRCode(QRCodePayment qrCode, bool active) async {
    await _qrCollection.doc(qrCode.id).update({'isActive': active});
  }
}

class _QRCodeManageCard extends StatelessWidget {
  final QRCodePayment qrCode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _QRCodeManageCard({
    required this.qrCode,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  qrCode.imageUrl.isNotEmpty
                      ? Image.network(
                          qrCode.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.qr_code, size: 48),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.qr_code, size: 48),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: qrCode.isActive ? AppColors.mint : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        qrCode.isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  qrCode.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (qrCode.upiId.isNotEmpty)
                  Text(
                    qrCode.upiId,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Switch(
                        value: qrCode.isActive,
                        onChanged: onToggle,
                        activeThumbColor: AppColors.ember,
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QRCodeEditSheet extends StatefulWidget {
  final QRCodePayment? existing;
  final Future<void> Function(QRCodePayment) onSave;

  const _QRCodeEditSheet({this.existing, required this.onSave});

  @override
  State<_QRCodeEditSheet> createState() => _QRCodeEditSheetState();
}

class _QRCodeEditSheetState extends State<_QRCodeEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _upiController = TextEditingController();
  final _descController = TextEditingController();
  final _uuid = const Uuid();
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _upiController.text = widget.existing!.upiId;
      _descController.text = widget.existing!.description;
      _imageUrl = widget.existing!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _upiController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.existing != null ? 'Edit QR Code' : 'Add QR Code',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                FormImagePicker(
                  label: 'QR Code Image',
                  imageUrl: _imageUrl,
                  folder: 'payment/qr',
                  onImageSelected: (url) {
                    setState(() => _imageUrl = url);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Name',
                    hintText: 'e.g., Google Pay, PhonePe',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _upiController,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID',
                    hintText: 'e.g., mobilenumber@upi',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.existing != null ? 'Update' : 'Add'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final qrCode = QRCodePayment(
      id: widget.existing?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      imageUrl: _imageUrl ?? '',
      upiId: _upiController.text.trim(),
      description: _descController.text.trim(),
      isActive: widget.existing?.isActive ?? true,
    );

    await widget.onSave(qrCode);
  }
}
