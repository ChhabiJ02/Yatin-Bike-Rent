import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// theme not required here

class TransportationForm extends StatefulWidget {
  const TransportationForm({super.key});

  @override
  State<TransportationForm> createState() => _TransportationFormState();
}

class _TransportationFormState extends State<TransportationForm> {
  final pendingController = TextEditingController();
  final narrationController = TextEditingController();
  final pickupDateController = TextEditingController();
  final pickupTimeController = TextEditingController();
  final pickupLocationController = TextEditingController();
  final dropDateController = TextEditingController();
  final dropTimeController = TextEditingController();
  final dropLocationController = TextEditingController();
  final stayController = TextEditingController();
  final kmsController = TextEditingController();

  @override
  void dispose() {
    pendingController.dispose();
    narrationController.dispose();
    pickupDateController.dispose();
    pickupTimeController.dispose();
    pickupLocationController.dispose();
    dropDateController.dispose();
    dropTimeController.dispose();
    dropLocationController.dispose();
    stayController.dispose();
    kmsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final data = {
      'pendingPaperList': pendingController.text.trim(),
      'narration': narrationController.text.trim(),
      'pickupDate': pickupDateController.text.trim(),
      'pickupTime': pickupTimeController.text.trim(),
      'pickupLocation': pickupLocationController.text.trim(),
      'dropDate': dropDateController.text.trim(),
      'dropTime': dropTimeController.text.trim(),
      'dropLocation': dropLocationController.text.trim(),
      'stay': stayController.text.trim(),
      'kms': kmsController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('transportation').add(data);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transportation saved.')));
    Navigator.of(context).pop();
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transportation Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field('Pending Paper List', pendingController, maxLines: 3),
            _field('Narration', narrationController, maxLines: 3),
            _field('Pickup Date', pickupDateController),
            _field('Pickup Time', pickupTimeController),
            _field('Pickup Location', pickupLocationController),
            _field('Drop Date', dropDateController),
            _field('Drop Time', dropTimeController),
            _field('Drop Location', dropLocationController),
            _field('Stay', stayController),
            _field('KMS', kmsController),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Save Transportation Details'),
            ),
          ],
        ),
      ),
    );
  }
}
