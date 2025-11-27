import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

// Mobile/Desktop implementation using path_provider
Future<String> savePdfToFile(Uint8List pdfData, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(pdfData);
  return file.path;
}
