import 'dart:html' as html;
import 'dart:convert';

Future<bool> downloadCsv({
  required String csvContent,
  required String fileName,
}) async {
  try {
    // Add BOM for Excel UTF-8 compatibility
    final bytes = utf8.encode('\uFEFF$csvContent');
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    html.Url.revokeObjectUrl(url);
    return true;
  } catch (e) {
    print('Error downloading CSV: $e');
    return false;
  }
}
