/// Stub implementation for non-web platforms
/// This file is used when dart:html is not available

import 'dart:typed_data';

void downloadExcelWeb(Uint8List bytes, String fileName) {
  // This is a stub - should never be called on non-web platforms
  throw UnsupportedError('downloadExcelWeb is only supported on web platform');
}
