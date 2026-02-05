import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class WarrantyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const WarrantyDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final d = data['data'] as Map<String, dynamic>? ?? {};
    final id = (data['id'] ?? '') as String;
    final modelName = (d['modelName'] ?? 'Unknown').toString();
    final modelNumber = (d['modelNumber'] ?? '').toString();
    final company = (d['company'] ?? '').toString();
    final email = (d['email'] ?? '').toString();
    final phone = (d['phone'] ?? '').toString();
    final receiptUrl = d['receiptUrl'] as String?;
    final purchaseDate = (d['purchaseDate'] as Timestamp?)?.toDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warranty Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download PDF',
            onPressed: () => _downloadPdf(
              id: id,
              modelName: modelName,
              modelNumber: modelNumber,
              company: company,
              email: email,
              phone: phone,
              purchaseDate:
                  purchaseDate?.toLocal().toString().split(' ').first ?? '-',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Model Name', modelName),
                  _row('Model Number', modelNumber.isEmpty ? '-' : modelNumber),
                  _row('Company', company.isEmpty ? '-' : company),
                  _row(
                    'Purchase Date',
                    purchaseDate?.toLocal().toString().split(' ').first ?? '-',
                  ),
                  _row('Email', email.isEmpty ? '-' : email),
                  _row('Phone', phone.isEmpty ? '-' : phone),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (receiptUrl != null && receiptUrl.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('View attached receipt'),
              onTap: () => Printing.layoutPdf(
                onLayout: (_) async {
                  final doc = pw.Document();
                  doc.addPage(
                    pw.Page(
                      build: (_) => pw.Center(
                        child: pw.Text('Open receipt in browser: $receiptUrl'),
                      ),
                    ),
                  );
                  return doc.save();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(k, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(
          child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  Future<void> _downloadPdf({
    required String id,
    required String modelName,
    required String modelNumber,
    required String company,
    required String email,
    required String phone,
    required String purchaseDate,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Warranty Certificate',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text('ID: $id'),
            pw.SizedBox(height: 8),
            pw.Text('Model Name: $modelName'),
            pw.Text('Model Number: ${modelNumber.isEmpty ? '-' : modelNumber}'),
            pw.Text('Company: ${company.isEmpty ? '-' : company}'),
            pw.Text('Purchase Date: $purchaseDate'),
            pw.Text('Email: ${email.isEmpty ? '-' : email}'),
            pw.Text('Phone: ${phone.isEmpty ? '-' : phone}'),
          ],
        ),
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'warranty_$id.pdf',
    );
  }
}
