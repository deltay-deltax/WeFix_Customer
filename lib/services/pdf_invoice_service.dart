import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/service_model.dart';
import 'package:intl/intl.dart';

class PdfInvoiceService {
  static Future<void> generateAndShowInvoice(ServiceRequestModel req) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final dateStr = dateFormat.format(DateTime.now());
    
    // Parse Costs
    final deliveryCost = double.tryParse(req.borzoDeliveryCost ?? '0') ?? 0;
    final double laborCost = (req.serviceDetails?.laborCost ?? 0).toDouble();
    final double partsCost = (req.serviceDetails?.partsCost ?? 0).toDouble();
    final double subTotal = laborCost + partsCost;
    final double grandTotal = subTotal + deliveryCost;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('WeFix Service Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      pw.SizedBox(height: 4),
                      pw.Text('Date: $dateStr'),
                      pw.Text('Invoice ID: ${req.id.toUpperCase().substring(0, 8)}'),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Text('COMPLETED', style: pw.TextStyle(color: PdfColors.green800, fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
              pw.SizedBox(height: 32),

              // Shop and Customer Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Service Center:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(req.shopName, style: const pw.TextStyle(fontSize: 14)),
                      ]
                    )
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Customer:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(req.yourName, style: const pw.TextStyle(fontSize: 14)),
                        pw.Text(req.phone),
                      ]
                    )
                  ),
                ],
              ),
              pw.SizedBox(height: 32),

              // Device details
              pw.Text('Device Information', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('Device: ${req.deviceType} (${req.brand} ${req.modelName})'),
              pw.Text('Issue Reported: ${req.problem}'),
              if (req.serviceDetails?.description != null && req.serviceDetails!.description.isNotEmpty)
                pw.Text('Shop Notes: ${req.serviceDetails!.description}'),
              pw.SizedBox(height: 24),

              // Cost Breakdown
              pw.Text('Cost Breakdown', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              
              _buildRow('Labor Charges', '\u20B9 $laborCost'),
              _buildRow('Parts Replaced (${req.serviceDetails?.partsReplaced ?? "None"})', '\u20B9 $partsCost'),
              
              if (deliveryCost > 0) ...[
                pw.SizedBox(height: 8),
                _buildRow('Courier Delivery (Borzo)', '\u20B9 $deliveryCost'),
              ],
              
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL AMOUNT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('\u20B9 $grandTotal', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                ]
              ),
              
              pw.Spacer(),
              pw.Center(
                child: pw.Text('Thank you for choosing WeFix!', style: const pw.TextStyle(color: PdfColors.grey600)),
              )
            ],
          );
        },
      ),
    );

    // Call printing plugin to layout and show native sharing sheet
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'WeFix_Invoice_${req.id}.pdf',
    );
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value),
        ],
      ),
    );
  }
}
