import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';
import '../models/qr_code.dart';
import '../services/qr_payment_service.dart';
import '../theme/app_theme.dart';

class PaymentRecordScreen extends StatefulWidget {
  final String custCode;

  const PaymentRecordScreen({super.key, required this.custCode});

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
  String _paymentMode = 'Cash';
  QRCodePayment? _selectedQR;
  List<QRCodePayment> _qrCodes = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _qrLoadError = false;

  final _paymentModes = ['Cash', 'UPI', 'Bank Transfer', 'Card'];

  @override
  void initState() {
    super.initState();
    _loadQRCodes();
  }

  Future<void> _loadQRCodes() async {
    // Ensure the loading state is always reset, even if an error occurs.
    try {
      final codes = await QRPaymentService.getActiveQRCodes().timeout(
        const Duration(seconds: 15),
      );
      if (mounted) {
        setState(() {
          _qrCodes = codes;
        });
      }
    } on Exception catch (_) {
      if (mounted) {
        setState(() {
          _qrCodes = [];
          _qrLoadError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionController.dispose();
    _notesController.dispose();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _qrCodes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2, size: 64, color: AppColors.muted),
                        const SizedBox(height: 12),
                        Text(
                          _qrLoadError
                              ? 'Failed to load QR/payment data.'
                              : 'No QR codes available. Add in Payment Settings.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.settings),
                          label: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPaymentModes(),
                  const SizedBox(height: 16),
                  _buildQRSelection(),
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

  Widget _buildPaymentModes() {
    return Wrap(
      spacing: 8,
      children: _paymentModes.map((mode) {
        final isSelected = mode == _paymentMode;
        return ChoiceChip(
          label: Text(mode),
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

  Widget _buildQRSelection() {
    if (_qrCodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select QR Code to Pay',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _qrCodes.length,
          itemBuilder: (context, index) {
            final qr = _qrCodes[index];
            final isSelected = _selectedQR?.id == qr.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedQR = qr),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? AppColors.ember : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: qr.imageUrl.isNotEmpty
                          ? Image.network(qr.imageUrl, fit: BoxFit.contain)
                          : const Icon(Icons.qr_code, size: 48),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        qr.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Payment Amount',
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
      final payment = PaymentDetails(
        paymentAmount: _amountController.text.trim(),
        paymentDate: '${now.day}-${now.month}-${now.year}',
        paymentTime: '${now.hour}:${now.minute}',
        paymentMode: _paymentMode,
        transactionId: _transactionController.text.trim(),
        paymentNotes: _notesController.text.trim(),
        selectedQRName: _selectedQR?.name ?? '',
      );

      await _customersCollection.doc(widget.custCode).update({
        'payment': payment.toMap(),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment recorded')));
        Navigator.pop(context, true);
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
