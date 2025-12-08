import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> downloadCsv({
  required String csvContent,
  required String fileName,
}) async {
  try {
    // Get the downloads directory or app documents directory
    Directory? directory;

    if (Platform.isAndroid) {
      // Try to get external storage directory first
      directory = await getExternalStorageDirectory();
      directory ??= await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      directory = await getDownloadsDirectory();
      directory ??= await getApplicationDocumentsDirectory();
    }

    final file = File('${directory.path}/$fileName');

    // Add BOM for Excel UTF-8 compatibility
    await file.writeAsString('\uFEFF$csvContent');

    // Share the file so user can save/share it
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Custom Orders CSV Export',
    );

    return true;
  } catch (e) {
    print('Error downloading CSV: $e');
    return false;
  }
}
