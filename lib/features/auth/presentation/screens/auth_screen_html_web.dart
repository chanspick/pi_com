// lib/features/auth/presentation/screens/auth_screen_html_web.dart
// Web implementation - uses dart:html

import 'dart:html' as html;

class HtmlStorage {
  String? operator [](String key) {
    return html.window.localStorage[key];
  }

  void remove(String key) {
    html.window.localStorage.remove(key);
  }
}

final htmlStorage = HtmlStorage();
