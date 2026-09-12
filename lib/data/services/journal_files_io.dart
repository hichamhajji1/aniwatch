import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

ImageProvider? journalImageProvider(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  return FileImage(file);
}

Future<String?> persistJournalBytes(Uint8List bytes, String id) async {
  if (bytes.isEmpty) return null;
  final dir = await getApplicationDocumentsDirectory();
  final dest = File('${dir.path}/journal_$id.jpg');
  await dest.writeAsBytes(bytes, flush: true);
  await FileImage(dest).evict();
  return dest.path;
}

Future<String?> persistJournalImage(String sourcePath, String id) async {
  try {
    final source = File(sourcePath);
    if (await source.exists()) {
      final bytes = await source.readAsBytes();
      return persistJournalBytes(bytes, id);
    }
  } catch (_) {}
  return sourcePath;
}

Future<void> deleteJournalImage(String? path) async {
  if (path == null || path.isEmpty) return;
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {}
}
