import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedFileData {
  final String name;
  final Uint8List bytes;

  const PickedFileData({required this.name, required this.bytes});
}

Future<PickedFileData?> pickDataFile({String accept = ''}) async {
  final input = html.FileUploadInputElement()
    ..accept = accept
    ..multiple = false;

  input.click();
  await input.onChange.first;

  final file = input.files?.isNotEmpty == true ? input.files!.first : null;
  if (file == null) return null;

  final completer = Completer<PickedFileData>();
  final reader = html.FileReader();

  reader.onLoad.first.then((_) {
    final result = reader.result;
    if (result is ByteBuffer) {
      completer.complete(
        PickedFileData(name: file.name, bytes: Uint8List.view(result)),
      );
    } else if (result is Uint8List) {
      completer.complete(PickedFileData(name: file.name, bytes: result));
    } else {
      completer.completeError(StateError('Gagal membaca file import.'));
    }
  });

  reader.onError.first.then((_) {
    completer.completeError(StateError('Gagal membaca file import.'));
  });

  reader.readAsArrayBuffer(file);
  return completer.future;
}

void downloadBytesFile(
  String filename,
  List<int> bytes, {
  String mimeType = 'application/octet-stream',
}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
