import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';
import '../models/user.dart';

class PdfService {
  static Future<Uint8List> generateInvoice(Order order, User user) async {
    final pdf = pw.Document();

    // Load custom font if needed
    final fontData = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'THYNE JEWELS',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.amber900,
                          ),
                        ),
                        pw.Text(
                          'Demi-Fine Jewelry',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
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
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('#${order.id}'),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Customer & Order Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Bill To:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(user.name),
                        pw.Text(user.email),
                        pw.Text(user.phone),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Ship To:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(order.shippingAddress.street),
                        pw.Text('${order.shippingAddress.city}, ${order.shippingAddress.state}'),
                        pw.Text('${order.shippingAddress.zipCode}, ${order.shippingAddress.country}'),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Date: ${_formatDate(order.createdAt)}'),
                        pw.Text('Status: ${order.status.displayName}'),
                        if (order.trackingNumber != null)
                          pw.Text('Tracking: ${order.trackingNumber}'),
                        pw.Text('Payment: ${order.paymentMethod}'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _buildTableCell('Item', isHeader: true),
                      _buildTableCell('Qty', isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('Price', isHeader: true, align: pw.TextAlign.right),
                      _buildTableCell('Total', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  // Item Rows
                  ...order.items.map((item) => pw.TableRow(
                    children: [
                      _buildTableCell(item.product.name),
                      _buildTableCell(item.quantity.toString(), align: pw.TextAlign.center),
                      _buildTableCell('\$${item.product.price.toStringAsFixed(2)}', align: pw.TextAlign.right),
                      _buildTableCell('\$${(item.product.price * item.quantity).toStringAsFixed(2)}', align: pw.TextAlign.right),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 20),

              // Totals
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 250,
                  child: pw.Column(
                    children: [
                      _buildTotalRow('Subtotal', order.subtotal),
                      _buildTotalRow('Tax', order.tax),
                      _buildTotalRow('Shipping', order.shipping),
                      if (order.discount > 0)
                        _buildTotalRow('Discount', -order.discount),
                      pw.Divider(),
                      _buildTotalRow('Total', order.total, isTotal: true),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 40),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Thank you for your purchase!',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'For questions about this invoice, please contact:',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Email: support@thynejewels.com | Phone: 1-800-THYNE',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 11 : 10,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 12 : 10,
            ),
          ),
          pw.Text(
            '\$${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 12 : 10,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Save PDF to device
  static Future<File> savePdfToFile(Uint8List pdfData, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfData);
    return file;
  }

  // Print PDF
  static Future<void> printPdf(Uint8List pdfData) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
    );
  }

  // Share PDF
  static Future<void> sharePdf(Uint8List pdfData, String fileName) async {
    await Printing.sharePdf(
      bytes: pdfData,
      filename: fileName,
    );
  }
}