// lib/features/web_public/presentation/screens/refund_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../widgets/web_navbar_v2.dart';

class RefundPage extends StatefulWidget {
  const RefundPage({super.key});

  @override
  State<RefundPage> createState() => _RefundPageState();
}

class _RefundPageState extends State<RefundPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadFlutterAsset('assets/html/refund.html');
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
        title: const Text('환불정책'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
