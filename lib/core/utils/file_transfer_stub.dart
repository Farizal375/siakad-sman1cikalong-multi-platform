import 'dart:typed_data';

class PickedFileData {
  final String name;
  final Uint8List bytes;

  const PickedFileData({required this.name, required this.bytes});
}

Future<PickedFileData?> pickDataFile({String accept = ''}) async {
  throw UnsupportedError('Import file hanya tersedia pada platform web.');
}

void downloadBytesFile(
  String filename,
  List<int> bytes, {
  String mimeType = 'application/octet-stream',
}) {
  throw UnsupportedError('Export file hanya tersedia pada platform web.');
}
