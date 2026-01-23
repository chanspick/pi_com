// lib/features/address/presentation/screens/daum_postcode_screen_mobile.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/utils/app_logger.dart';

/// 다음 우편번호 검색 결과
class DaumPostcodeResult {
  final String zonecode;
  final String roadAddress;
  final String jibunAddress;
  final String buildingName;
  final String userSelectedType;

  DaumPostcodeResult({
    required this.zonecode,
    required this.roadAddress,
    required this.jibunAddress,
    required this.buildingName,
    required this.userSelectedType,
  });

  factory DaumPostcodeResult.fromJson(Map<String, dynamic> json) {
    return DaumPostcodeResult(
      zonecode: json['zonecode'] ?? '',
      roadAddress: json['roadAddress'] ?? '',
      jibunAddress: json['jibunAddress'] ?? '',
      buildingName: json['buildingName'] ?? '',
      userSelectedType: json['userSelectedType'] ?? 'R',
    );
  }
}

/// 다음 우편번호 검색 화면
class DaumPostcodeScreen extends StatefulWidget {
  const DaumPostcodeScreen({super.key});

  @override
  State<DaumPostcodeScreen> createState() => _DaumPostcodeScreenState();
}

class _DaumPostcodeScreenState extends State<DaumPostcodeScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            AppLogger.e('WebView 오류: ${error.description}', tag: 'DaumPostcode');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handlePostcodeResult(message.message);
        },
      );

    // HTML 파일 로드
    final String htmlContent = await rootBundle.loadString('assets/html/daum_postcode.html');
    await _controller.loadHtmlString(
      htmlContent,
      baseUrl: 'https://postcode.map.daum.net',
    );
  }

  void _handlePostcodeResult(String message) {
    if (message == 'CANCELLED') {
      // 사용자가 취소한 경우
      Navigator.pop(context);
      return;
    }

    try {
      final Map<String, dynamic> data = jsonDecode(message);
      final result = DaumPostcodeResult.fromJson(data);

      // 결과를 반환하고 화면 닫기
      Navigator.pop(context, result);
    } catch (e) {
      AppLogger.e('우편번호 결과 파싱 오류: $e', tag: 'DaumPostcode');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('주소 정보를 처리하는 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주소 검색'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
