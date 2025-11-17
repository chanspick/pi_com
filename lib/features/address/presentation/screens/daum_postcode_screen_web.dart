// lib/features/address/presentation/screens/daum_postcode_screen_web.dart

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

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

/// 웹용 다음 우편번호 검색 화면
class DaumPostcodeScreen extends StatefulWidget {
  const DaumPostcodeScreen({super.key});

  @override
  State<DaumPostcodeScreen> createState() => _DaumPostcodeScreenState();
}

class _DaumPostcodeScreenState extends State<DaumPostcodeScreen> {
  final String _viewId = 'daum-postcode-${DateTime.now().millisecondsSinceEpoch}';
  StreamSubscription<html.MessageEvent>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _initializePostcode();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _initializePostcode() {
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = 'daum_postcode.html'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none';

      return iframe;
    });

    // 메시지 리스너 등록
    _messageSubscription = html.window.onMessage.listen((event) {
      final data = event.data;

      if (data is Map) {
        if (data['type'] == 'DAUM_POSTCODE_COMPLETE') {
          final addressData = Map<String, dynamic>.from(data['data'] as Map);
          final result = DaumPostcodeResult.fromJson(addressData);
          if (mounted) {
            Navigator.pop(context, result);
          }
        } else if (data['type'] == 'DAUM_POSTCODE_CANCEL') {
          if (mounted) {
            Navigator.pop(context);
          }
        }
      }
    });
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
      body: HtmlElementView(viewType: _viewId),
    );
  }
}
