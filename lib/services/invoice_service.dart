import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/challan_data.dart';

class InvoiceService {
  static final _dateFormat = DateFormat('dd-MM-yyyy');
  static final _dateTimeFormat = DateFormat('dd-MM-yyyy HH:mm');

  static Future<String> generateInvoicePdf({
    required Invoice invoice,
    String? companyName,
    String? companyAddress,
    String? gstNumber,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#E86F25'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          companyName ?? 'StreetBike Rental',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          companyAddress ?? 'Bike Rental Service',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                        ),
                        if (gstNumber != null && gstNumber.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'GST: $gstNumber',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Invoice No: ${invoice.invoiceNumber}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Date: ${invoice.invoiceDate}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Customer Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Customer Details',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#E86F25'),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Name: ${invoice.customerName}',
                                style: const pw.TextStyle(fontSize: 11)),
                            pw.SizedBox(height: 4),
                            pw.Text('Phone: ${invoice.phoneNumber}',
                                style: const pw.TextStyle(fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Vehicle Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Vehicle Details',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#E86F25'),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDetailColumn('Vehicle', invoice.vehicleName),
                        _buildDetailColumn('Vehicle No.', invoice.vehicleNumber),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Rental Period
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Rental Period',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#E86F25'),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDetailColumn(
                            'Start', '${invoice.rentalStartDate} ${invoice.rentalStartTime}'),
                        _buildDetailColumn(
                            'End', '${invoice.rentalEndDate} ${invoice.rentalEndTime}'),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Duration: ${invoice.totalRentalDuration}',
                        style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Kilometer Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Kilometer Details',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#E86F25'),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDetailColumn('Start KM', '${invoice.startKM}'),
                        _buildDetailColumn('End KM', '${invoice.endKM}'),
                        _buildDetailColumn(
                            'Total KM', '${invoice.totalKM}'),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Bill Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _buildBillRow('Rent Per Day', invoice.rentPerDay),
                    if (invoice.extraKMCharges.isNotEmpty)
                      _buildBillRow('Extra KM Charges', invoice.extraKMCharges),
                    if (invoice.securityDeposit.isNotEmpty)
                      _buildBillRow('Security Deposit', invoice.securityDeposit),
                    if (invoice.otherCharges.isNotEmpty)
                      _buildBillRow('Other Charges', invoice.otherCharges),
                    if (invoice.discount.isNotEmpty)
                      _buildBillRow('Discount', '-${invoice.discount}'),
                    if (invoice.gst.isNotEmpty)
                      _buildBillRow('GST', invoice.gst),
                    pw.Divider(),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 8),
                      color: PdfColor.fromHex('#E86F25'),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Grand Total',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Text(
                            'Rs. ${invoice.grandTotal}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Payment Status
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: invoice.paymentStatus == 'Paid'
                      ? PdfColors.green100
                      : PdfColors.red100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Payment Status: ${invoice.paymentStatus}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: invoice.paymentStatus == 'Paid'
                            ? PdfColors.green800
                            : PdfColors.red800,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Customer Signature',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 24),
                      pw.Container(
                        width: 100,
                        height: 1,
                        color: PdfColors.grey400,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Company Signature',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 24),
                      pw.Container(
                        width: 100,
                        height: 1,
                        color: PdfColors.grey400,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Staff Name
              pw.Center(
                child: pw.Text(
                  'Staff: ${invoice.staffName}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Widget _buildDetailColumn(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  static pw.Widget _buildBillRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text('Rs. $value', style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static Future<void> printInvoice(Invoice invoice) async {
    final pdfPath = await generateInvoicePdf(invoice: invoice);
    await Printing.layoutPdf(onLayout: (format) async {
      final file = File(pdfPath);
      return file.readAsBytes();
    });
  }

  static Future<String> generateChallanInvoice({
    required ChallanData challanData,
    String? companyName,
    String? companyAddress,
    String? gstNumber,
    String? staffName,
  }) async {
    if (challanData.invoice == null) {
      throw Exception('No invoice data found');
    }

    final invoice = challanData.invoice!.copyWith(staffName: staffName ?? '');
    return generateInvoicePdf(
      invoice: invoice,
      companyName: companyName,
      companyAddress: companyAddress,
      gstNumber: gstNumber,
    );
  }
}