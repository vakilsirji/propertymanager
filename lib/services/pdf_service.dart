import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/admin_models.dart';

class PdfService {
  static String safeStr(String? input) {
    if (input == null) return '';
    // Strip all non-ASCII characters to prevent font encoding crashes in pdf package
    return input.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
  }

  static Future<Uint8List> generateDraftPdf(Agreement agreement, {bool isFinal = false}) async {
    final pdf = pw.Document();
    final details = agreement.details;
    if (details == null) return Uint8List(0);

    final ByteData imageBytes = await rootBundle.load('assets/logo.png');
    final Uint8List logoUint8List = imageBytes.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoUint8List);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logoImage, width: 80, height: 80),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Vakil Sirji LegalTech Services',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'www.vakilsirji.in',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                isFinal ? 'RENTAL AGREEMENT' : 'DRAFT RENTAL AGREEMENT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Agreement No: ${safeStr(agreement.agreementNumber)}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'Date: ${agreement.startDate.toLocal().toString().split(' ')[0]}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 20),

            // Property & Financial Details Table
            pw.Text(
              '1. Property & Financial Details',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(),
              headers: ['Field', 'Details'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(2),
              },
              data: <List<String>>[
                ['Property ID', safeStr(agreement.propertyId)],
                ['Property Address', safeStr(details.propertyAddress)],
                [
                  'Start Date',
                  safeStr(
                    agreement.startDate.toLocal().toString().split(' ')[0],
                  ),
                ],
                [
                  'End Date',
                  safeStr(
                    agreement.expiryDate.toLocal().toString().split(' ')[0],
                  ),
                ],
                ['Period (Months)', safeStr(details.periodMonths.toString())],
                ['Monthly Rent', 'Rs. ${safeStr(details.monthlyRent)}'],
                ['Security Deposit', 'Rs. ${safeStr(details.depositAmount)}'],
              ],
            ),
            pw.SizedBox(height: 20),

            // Owner Details Table
            pw.Text(
              '2. Owner Details (First Party)',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(),
              headers: ['Field', 'Details'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(2),
              },
              data: <List<String>>[
                ['Name', safeStr(details.owner.name)],
                ['Age', safeStr(details.owner.age)],
                ['Address', safeStr(details.owner.address)],
                ['Pincode', safeStr(details.owner.pincode)],
                ['PAN', safeStr(details.owner.pan)],
                ['Aadhaar', safeStr(details.owner.aadhaar)],
              ],
            ),
            pw.SizedBox(height: 20),

            // Tenant Details Table
            pw.Text(
              '3. Tenant Details (Second Party)',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(),
              headers: ['Field', 'Details'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(2),
              },
              data: <List<String>>[
                ['Name', safeStr(details.tenant.name)],
                ['Age', safeStr(details.tenant.age)],
                ['Address', safeStr(details.tenant.address)],
                ['Pincode', safeStr(details.tenant.pincode)],
                ['PAN', safeStr(details.tenant.pan)],
                ['Aadhaar', safeStr(details.tenant.aadhaar)],
              ],
            ),
            pw.SizedBox(height: 20),

            // Witnesses
            pw.Text(
              '4. Witnesses',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(),
              headers: ['Role', 'Name', 'Age', 'Address', 'Aadhaar'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(3),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(4),
                4: pw.FlexColumnWidth(3),
              },
              data: <List<String>>[
                [
                  'Witness 1',
                  safeStr(details.witness1.name),
                  safeStr(details.witness1.age),
                  safeStr(details.witness1.address),
                  safeStr(details.witness1.aadhaar),
                ],
                [
                  'Witness 2',
                  safeStr(details.witness2.name),
                  safeStr(details.witness2.age),
                  safeStr(details.witness2.address),
                  safeStr(details.witness2.aadhaar),
                ],
              ],
            ),
            if (!isFinal) ...[
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text(
                  '--- THIS IS A DRAFT FOR REVIEW ONLY ---',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.red),
                ),
              ),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }
}
