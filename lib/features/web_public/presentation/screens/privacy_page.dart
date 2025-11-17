// lib/features/web_public/presentation/screens/privacy_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../widgets/web_navbar_v2.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadFlutterAsset('assets/html/privacy_policy.html');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 웹에서는 웹 네비게이션 바와 함께 표시
    if (kIsWeb) {
      return Scaffold(
        appBar: const WebNavBarV2(),
        body: ResponsiveHelper.centeredMaxWidthContainer(
          context: context,
          child: WebViewWidget(controller: _controller),
        ),
      );
    }

    // 모바일에서는 WebView로 HTML 표시
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보처리방침'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
