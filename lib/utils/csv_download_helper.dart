import 'package:flutter/foundation.dart' show kIsWeb;
import 'csv_download_helper_stub.dart'
    if (dart.library.html) 'csv_download_helper_web.dart'
    if (dart.library.io) 'csv_download_helper_mobile.dart' as platform;

class CsvDownloadHelper {
  static Future<bool> downloadCsv({
    required String csvContent,
    required String fileName,
  }) async {
    return platform.downloadCsv(csvContent: csvContent, fileName: fileName);
  }
}
