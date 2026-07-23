import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/invoice.dart';
import '../models/kilometer_details.dart';
import '../models/vehicle_handover.dart';
import '../models/payment.dart';
import '../services/invoice_service.dart';
import '../theme/app_theme.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final String custCode;

  const InvoicePreviewScreen({super.key, required this.custCode});

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  final _customersCollection = FirebaseFirestore.instance.collection('customers');
  Map<String, dynamic>? _challanData;
  VehicleHandover? _vehicleHandover;
  KilometerDetails? _kilometerDetails;
  PaymentDetails? _payment;
  Uint8List? _pdfBytes;
  String? _pdfPath;
  bool _isGenerating = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await _customersCollection.doc(widget.custCode).get();
    if (doc.exists) {
      _challanData = doc.data();
      if (_challanData!['vehicleHandover'] != null) {
        _vehicleHandover = VehicleHandover.fromMap(Map<String, dynamic>.from(_challanData!['vehicleHandover']));
      }
      if (_challanData!['kilometerDetails'] != null) {
        _kilometerDetails = KilometerDetails.fromMap(Map<String, dynamic>.from(_challanData!['kilometerDetails']));
      }
      if (_challanData!['payment'] != null) {
        _payment = PaymentDetails.fromMap(Map<String, dynamic>.from(_challanData!['payment']));
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        backgroundColor: AppColors.ember,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInvoiceCard(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildInvoiceCard() {
    final data = _challanData ?? {};
    final km = _kilometerDetails;
    final vh = _vehicleHandover;
    final pay = _payment;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'StreetBike Rental',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ember),
            ),
            const SizedBox(height: 16),
            _buildRow('Invoice No.', widget.custCode),
            const Divider(),
            _buildRow('Customer', data['partyName'] ?? ''),
            _buildRow('Phone', data['smsPhone'] ?? ''),
            const Divider(),
            _buildRow('Vehicle', data['vehicleName'] ?? ''),
            _buildRow('Vehicle No.', data['vehicleNumber'] ?? ''),
            _buildRow('Pickup Location', vh?.vehiclePickupLocation ?? ''),
            _buildRow('Return Location', vh?.vehicleReturnLocation ?? ''),
            const Divider(),
            _buildRow('Rental From', '${vh?.vehicleGivenDate ?? ''} ${vh?.vehicleGivenTime ?? ''}'),
            _buildRow('Rental To', '${vh?.vehicleReturnDate ?? ''} ${vh?.vehicleReturnTime ?? ''}'),
            const Divider(),
            _buildRow('Start KM', km?.startKM.toString() ?? '0'),
            _buildRow('End KM', km?.endKM.toString() ?? '0'),
            _buildRow('Total KM', km?.totalKM.toString() ?? '0'),
            const Divider(),
            _buildRow('Days', data['days'] ?? ''),
            _buildRow('Rate/Day', '₹ ${data['rate'] ?? 0}'),
            _buildRow('Total', '₹ ${data['billAmount'] ?? 0}'),
            if (pay != null && pay.paymentAmount.isNotEmpty) ...[
              const Divider(),
              _buildRow('Amount Paid', '₹ ${pay.paymentAmount}'),
              _buildRow('Payment Mode', pay.paymentMode),
              _buildRow('Transaction ID', pay.transactionId),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Due:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '₹ ${data['billAmount'] ?? 0}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ember),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : _generateInvoice,
          icon: _isGenerating
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.picture_as_pdf),
          label: Text(_isGenerating ? 'Generating...' : 'Generate Invoice PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ember,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pdfBytes != null ? _previewPdf : null,
                icon: const Icon(Icons.visibility),
                label: const Text('Preview'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ember,
                  side: const BorderSide(color: AppColors.ember),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pdfBytes != null ? _downloadPdf : null,
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ember,
                  side: const BorderSide(color: AppColors.ember),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pdfBytes != null ? _shareOnWhatsApp : null,
          //onPressed: _pdfBytes != null ? _sharePdf : null,
          icon: const Icon(Icons.share),
          label: const Text('Share PDF'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ember,
            side: const BorderSide(color: AppColors.ember),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pdfBytes != null ? _sharePdf : null,          
          //onPressed: _pdfBytes != null ? _shareOnWhatsApp : null,
          icon: const Icon(Icons.chat),
          label: const Text('Send via WhatsApp'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green,
            side: const BorderSide(color: Colors.green),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _previewPdf() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(onLayout: (format) async => _pdfBytes!);
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;

    if (kIsWeb) {
      await Printing.sharePdf(bytes: _pdfBytes!, filename: 'invoice_${widget.custCode}.pdf');
    } else {
      _pdfPath = await InvoiceService.saveInvoicePdfToFile(
        _pdfBytes!,
        invoiceNumber: widget.custCode,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_pdfPath != null ? 'PDF saved at: $_pdfPath' : 'PDF saved')),
        );
      }
    }
  }

  Future<void> _generateInvoice() async {
    setState(() => _isGenerating = true);
    try {
      final invoice = Invoice(
        invoiceNumber: widget.custCode,
        invoiceDate: DateTime.now().toString().split(' ')[0],
        customerName: _challanData?['partyName'] ?? '',
        phoneNumber: _challanData?['smsPhone'] ?? '',
        vehicleName: _challanData?['vehicleName'] ?? '',
        vehicleNumber: _challanData?['vehicleNumber'] ?? '',
        rentalStartDate: _vehicleHandover?.vehicleGivenDate ?? '',
        rentalStartTime: _vehicleHandover?.vehicleGivenTime ?? '',
        rentalEndDate: _vehicleHandover?.vehicleReturnDate ?? '',
        rentalEndTime: _vehicleHandover?.vehicleReturnTime ?? '',
        startKM: _kilometerDetails?.startKM ?? 0,
        endKM: _kilometerDetails?.endKM ?? 0,
        totalKM: _kilometerDetails?.totalKM ?? 0,
        rentPerDay: _challanData?['rate'] ?? '',
        grandTotal: _challanData?['billAmount'] ?? '',
        paymentStatus: _payment != null && _payment!.paymentAmount.isNotEmpty ? 'Paid' : 'Pending',
      );

      _pdfBytes = await InvoiceService.generateInvoicePdfBytes(invoice: invoice);
      if (!kIsWeb) {
        _pdfPath = await InvoiceService.saveInvoicePdfToFile(
          _pdfBytes!,
          invoiceNumber: widget.custCode,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice PDF generated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    if (mounted) setState(() => _isGenerating = false);
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;

    if (kIsWeb) {
      await Printing.sharePdf(bytes: _pdfBytes!, filename: 'invoice_${widget.custCode}.pdf');
      return;
    }

    _pdfPath ??= await InvoiceService.saveInvoicePdfToFile(
      _pdfBytes!,
      invoiceNumber: widget.custCode,
    );

    if (_pdfPath != null) {
      await Share.shareXFiles([XFile(_pdfPath!)], text: 'Invoice ${widget.custCode}');
    }
  }

  Future<void> _shareOnWhatsApp() async {
    final phone = _challanData?['smsPhone'] ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }
    final text = 'Invoice for ${widget.custCode} - ${_challanData?['partyName']}';
    final uri = Uri.parse('whatsapp://send?phone=$phone&text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}