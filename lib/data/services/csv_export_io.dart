import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

// Mobile/Desktop implementation using path_provider
Future<String> saveFile(Uint8List data, String fileName, String mimeType) async {
  final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(data);
  return 'Exported to ${file.path}';
}
