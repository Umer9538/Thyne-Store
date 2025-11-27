import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

// Web implementation - triggers browser download
Future<String> savePdfToFile(Uint8List pdfData, String fileName) async {
  // Create blob from PDF data
  final blob = html.Blob([pdfData], 'application/pdf');

  // Create download URL
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Create anchor element and trigger download
  final anchor = html.AnchorElement()
    ..href = url
    ..style.display = 'none'
    ..download = fileName;

  html.document.body?.children.add(anchor);
  anchor.click();

  // Cleanup
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);

  return 'Downloaded: $fileName';
}
