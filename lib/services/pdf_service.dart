import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order.dart';
import '../models/user.dart';

// Conditional imports for platform-specific code
import 'pdf_service_stub.dart'
    if (dart.library.io) 'pdf_service_io.dart'
    if (dart.library.html) 'pdf_service_web.dart' as platform;

class PdfService {
  static pw.Font? _font;
  static pw.Font? _fontBold;

  // Load Google Fonts that support Unicode (including Rs symbol)
  static Future<void> _loadFonts() async {
    if (_font == null) {
      _font = await PdfGoogleFonts.notoSansRegular();
      _fontBold = await PdfGoogleFonts.notoSansBold();
    }
  }

  static Future<Uint8List> generateInvoice(Order order, User user) async {
    // Load Unicode-compatible fonts
    await _loadFonts();

    final pdf = pw.Document();

    // Create text styles with Unicode font
    final normalStyle = pw.TextStyle(font: _font, fontSize: 10);
    final boldStyle = pw.TextStyle(font: _fontBold, fontSize: 10, fontWeight: pw.FontWeight.bold);
    final titleStyle = pw.TextStyle(font: _fontBold, fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900);
    final subtitleStyle = pw.TextStyle(font: _font, fontSize: 12, color: PdfColors.grey700);
    final invoiceStyle = pw.TextStyle(font: _fontBold, fontSize: 20, fontWeight: pw.FontWeight.bold);

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
                        pw.Text('THYNE JEWELS', style: titleStyle),
                        pw.Text('Demi-Fine Jewelry', style: subtitleStyle),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE', style: invoiceStyle),
                        pw.SizedBox(height: 4),
                        pw.Text('#${order.id}', style: normalStyle),
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
                        pw.Text('Bill To:', style: boldStyle),
                        pw.SizedBox(height: 4),
                        pw.Text(user.name, style: normalStyle),
                        pw.Text(user.email, style: normalStyle),
                        pw.Text(user.phone, style: normalStyle),
                        pw.SizedBox(height: 8),
                        pw.Text('Ship To:', style: boldStyle),
                        pw.SizedBox(height: 4),
                        pw.Text(order.shippingAddress.street, style: normalStyle),
                        pw.Text('${order.shippingAddress.city}, ${order.shippingAddress.state}', style: normalStyle),
                        pw.Text('${order.shippingAddress.zipCode}, ${order.shippingAddress.country}', style: normalStyle),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Date: ${_formatDate(order.createdAt)}', style: normalStyle),
                        pw.Text('Status: ${order.status.displayName}', style: normalStyle),
                        if (order.trackingNumber != null)
                          pw.Text('Tracking: ${order.trackingNumber}', style: normalStyle),
                        pw.Text('Payment: ${order.paymentMethod}', style: normalStyle),
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
                      _buildTableCell('Item', font: _fontBold, isHeader: true),
                      _buildTableCell('Qty', font: _fontBold, isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('Price', font: _fontBold, isHeader: true, align: pw.TextAlign.right),
                      _buildTableCell('Total', font: _fontBold, isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  // Item Rows
                  ...order.items.map((item) => pw.TableRow(
                    children: [
                      _buildTableCell(item.product.name, font: _font),
                      _buildTableCell(item.quantity.toString(), font: _font, align: pw.TextAlign.center),
                      _buildTableCell('Rs.${item.product.price.toStringAsFixed(0)}', font: _font, align: pw.TextAlign.right),
                      _buildTableCell('Rs.${(item.product.price * item.quantity).toStringAsFixed(0)}', font: _font, align: pw.TextAlign.right),
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
                      _buildTotalRow('Subtotal', order.subtotal, font: _font),
                      _buildTotalRow('Tax (GST)', order.tax, font: _font),
                      _buildTotalRow('Shipping', order.shipping, font: _font),
                      if (order.discount > 0)
                        _buildTotalRow('Discount', -order.discount, font: _font),
                      pw.Divider(),
                      _buildTotalRow('Total', order.total, font: _fontBold, isTotal: true),
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
                      style: pw.TextStyle(font: _fontBold, fontWeight: pw.FontWeight.bold, fontSize: 14),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'For questions about this invoice, please contact:',
                      style: pw.TextStyle(font: _font, fontSize: 10),
                    ),
                    pw.Text(
                      'Email: support@thynejewels.com | Phone: +91 9876543210',
                      style: pw.TextStyle(font: _font, fontSize: 10),
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

  static pw.Widget _buildTableCell(String text, {pw.Font? font, bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 11 : 10,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, {pw.Font? font, bool isTotal = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 12 : 10,
            ),
          ),
          pw.Text(
            'Rs.${amount.toStringAsFixed(0)}',
            style: pw.TextStyle(
              font: font,
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

  // Save PDF - platform aware
  static Future<String> savePdfToFile(Uint8List pdfData, String fileName) async {
    return platform.savePdfToFile(pdfData, fileName);
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
