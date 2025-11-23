// lib/features/web_public/presentation/screens/storage_service_terms_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/web_navbar_v2.dart';

class StorageServiceTermsPage extends StatefulWidget {
  const StorageServiceTermsPage({super.key});

  @override
  State<StorageServiceTermsPage> createState() => _StorageServiceTermsPageState();
}

class _StorageServiceTermsPageState extends State<StorageServiceTermsPage> {
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
        ..loadFlutterAsset('assets/html/storage_service_terms.html');
    }
  }

  Future<void> _redirectToHtmlPage() async {
    final currentUrl = Uri.base;
    final targetUrl = currentUrl.replace(path: '/storage_service_terms.html');

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
        title: const Text('보관 서비스 약관'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
