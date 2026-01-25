/// Web implementation for Excel download
/// This file is used when dart:html is available

import 'dart:html' as html;
import 'dart:typed_data';

void downloadExcelWeb(Uint8List bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
