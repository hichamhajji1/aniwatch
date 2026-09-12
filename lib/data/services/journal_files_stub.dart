import 'dart:typed_data';

import 'package:flutter/painting.dart';

ImageProvider? journalImageProvider(String path) {
  if (path.startsWith('http') || path.startsWith('blob') || path.startsWith('data:')) {
    return NetworkImage(path);
  }
  return null;
}

Future<String?> persistJournalBytes(Uint8List bytes, String id) async => null;

Future<String?> persistJournalImage(String sourcePath, String id) async => sourcePath;

Future<void> deleteJournalImage(String? path) async {}
