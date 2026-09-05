import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';
import '../theme/app_theme.dart';

class PaymentRecordScreen extends StatefulWidget {
  final String custCode;
  final String? initialAmount;

  const PaymentRecordScreen({
    super.key,
    required this.custCode,
    this.initialAmount,
  });

  @override
  State<PaymentRecordScreen> createState() => _PaymentRecordScreenState();
}

class _PaymentRecordScreenState extends State<PaymentRecordScreen> {
  final _customersCollection = FirebaseFirestore.instance.collection(
    'customers',
  );
  final _amountController = TextEditingController();
  final _transactionController = TextEditingController();
  final _notesController = TextEditingController();
  final _refIdController = TextEditingController();
  String _paymentMode = 'Cash';
  bool _isSaving = false;

  final List<String> _paymentModes = ['Cash', 'SBI', 'BOB', 'GPay', 'PNB'];

  @override
  void initState() {
    super.initState();
    if ((widget.initialAmount ?? '').isNotEmpty) {
      _amountController.text = widget.initialAmount!;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionController.dispose();
    _notesController.dispose();
    _refIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppColors.ember,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRefIdField(),
            const SizedBox(height: 16),
            _buildPaymentModes(),
            const SizedBox(height: 16),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildTransactionField(),
            const SizedBox(height: 16),
            _buildNotesField(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _savePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ember,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefIdField() {
    return TextFormField(
      controller: _refIdController,
      decoration: const InputDecoration(
        labelText: 'Ref ID (Optional)',
        labelStyle: TextStyle(color: Colors.black),
        hintStyle: TextStyle(color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }

  Widget _buildPaymentModes() {
    return Wrap(
      spacing: 10,
      children: _paymentModes.map((mode) {
        final isSelected = mode == _paymentMode;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _paymentModeIcon(mode),
                size: 18,
                color: isSelected ? Colors.white : AppColors.ember,
              ),
              const SizedBox(width: 6),
              Text(mode),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => setState(() => _paymentMode = mode),
          selectedColor: AppColors.ember,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.ink,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  IconData _paymentModeIcon(String mode) {
    switch (mode) {
      case 'Cash':
        return Icons.money;
      case 'SBI':
        return Icons.account_balance;
      case 'BOB':
        return Icons.account_balance_wallet;
      case 'GPay':
        return Icons.payment;
      case 'PNB':
        return Icons.account_balance;
      default:
        return Icons.payments;
    }
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Payment Amount',
        labelStyle: const TextStyle(color: Colors.black),
        hintStyle: const TextStyle(color: Colors.black),
        prefixText: '₹ ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTransactionField() {
    return TextFormField(
      controller: _transactionController,
      decoration: InputDecoration(
        labelText: 'Transaction ID (Optional)',
        labelStyle: const TextStyle(color: Colors.black),
        hintStyle: const TextStyle(color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Notes (Optional)',
        labelStyle: const TextStyle(color: Colors.black),
        hintStyle: const TextStyle(color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _savePayment() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Amount is required')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0;
      final doc = await _customersCollection.doc(widget.custCode).get();
      final data = doc.data() ?? {};
      final currentPaid =
          double.tryParse((data['paidAmount'] ?? '0').toString()) ?? 0;
      final totalAmount =
          double.tryParse((data['billAmount'] ?? '0').toString()) ?? 0;
      final newPaidAmount = currentPaid + enteredAmount;
      final dueAmount =
          newPaidAmount < totalAmount ? totalAmount - newPaidAmount : 0;
      final overpaidAmount =
          newPaidAmount >= totalAmount ? newPaidAmount - totalAmount : 0;

      final payment = PaymentDetails(
        paymentAmount: _amountController.text.trim(),
        paymentDate: '${now.day}-${now.month}-${now.year}',
        paymentTime: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        paymentMode: _paymentMode,
        transactionId: _transactionController.text.trim(),
        paymentNotes: _notesController.text.trim(),
        selectedQRName: '',
      );

      final historyEntry = {
        'type': 'Paid',
        'amount': enteredAmount.toStringAsFixed(2),
        'date': '${now.day}-${now.month}-${now.year}',
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'timestamp': DateTime.now().toIso8601String(),
        'refId': _refIdController.text.trim(),
        'paymentMethod': _paymentMode,
        'bankName': _paymentMode,
        'transactionId': _transactionController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      await _customersCollection.doc(widget.custCode).update({
        'payment': payment.toMap(),
        'paidAmount': newPaidAmount.toStringAsFixed(0),
        'dueAmount': dueAmount.toStringAsFixed(0),
        'overpaidAmount': overpaidAmount.toStringAsFixed(0),
        'paymentHistory': FieldValue.arrayUnion([historyEntry]),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment recorded')));
        Navigator.pop(context, newPaidAmount.toStringAsFixed(0));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }
}
