// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';

/// Dispara o download de [bytes] como um arquivo no navegador (implementação
/// web do helper). Usa `dart:html` — só é compilado em builds web.
void downloadBytes(
  Uint8List bytes, {
  required String filename,
  required String mimeType,
}) {
  final blob = html.Blob(<dynamic>[bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
