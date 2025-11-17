// lib/features/auth/presentation/screens/auth_screen_html_mobile.dart
// Mobile stub - not used at runtime (kIsWeb guards prevent execution)

class HtmlStorage {
  String? operator [](String key) {
    throw UnsupportedError('HTML localStorage is only available on web');
  }

  void remove(String key) {
    throw UnsupportedError('HTML localStorage is only available on web');
  }
}

final htmlStorage = HtmlStorage();
