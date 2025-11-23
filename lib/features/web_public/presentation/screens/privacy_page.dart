// lib/features/web_public/presentation/screens/privacy_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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

    // 웹에서는 HTML 파일로 직접 리다이렉트
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectToHtmlPage();
      });
    } else {
      // 모바일에서만 WebView 초기화
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadFlutterAsset('assets/html/privacy_policy.html');
    }
  }

  Future<void> _redirectToHtmlPage() async {
    final currentUrl = Uri.base;
    final targetUrl = currentUrl.replace(path: '/privacy_policy.html');

    await launchUrl(
      targetUrl,
      webOnlyWindowName: '_self', // 현재 탭에서 열기
    );
  }

  @override
  Widget build(BuildContext context) {
    // 웹에서는 리다이렉트 중 표시
    if (kIsWeb) {
      return Scaffold(
        appBar: const WebNavBarV2(),
        body: const Center(
          child: CircularProgressIndicator(),
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
