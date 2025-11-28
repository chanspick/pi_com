// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/payment/presentation/providers/payment_provider.dart';

/// 토스페이먼츠 웹 결제 화면 (Flutter Web 전용)
class TossPaymentWebScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String userId;
  final String orderName;
  final int amount;
  final int productAmount;
  final int shippingFee;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String successUrl;
  final String failUrl;

  const TossPaymentWebScreen({
    super.key,
    required this.orderId,
    required this.userId,
    required this.orderName,
    required this.amount,
    required this.productAmount,
    required this.shippingFee,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.successUrl,
    required this.failUrl,
  });

  @override
  ConsumerState<TossPaymentWebScreen> createState() =>
      _TossPaymentWebScreenState();
}

class _TossPaymentWebScreenState extends ConsumerState<TossPaymentWebScreen> {
  late final String _viewId;
  bool _isLoading = true;
  bool _isNavigating = false;
  bool _isViewRegistered = false;
  bool _configSent = false;
  html.EventListener? _messageListener;
  html.IFrameElement? _iframe;

  static const String _testClientKey = 'test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm';
  static final Set<String> _registeredViewIds = {};

  @override
  void initState() {
    super.initState();
    _logPaymentInfo();
    _viewId = 'toss-payment-${DateTime.now().millisecondsSinceEpoch}';
    _setupMessageListener();
    _registerWebView();
  }

  void _logPaymentInfo() {
    print('');
    print('========================================');
    print('🔵 [TossPaymentWeb] 결제 정보');
    print('========================================');
    print('  orderId: ${widget.orderId}');
    print('  userId: ${widget.userId}');
    print('  orderName: ${widget.orderName}');
    print('  amount (총액): ${widget.amount}');
    print('  productAmount (상품금액): ${widget.productAmount}');
    print('  shippingFee (배송비): ${widget.shippingFee}');
    print('========================================');
  }

  @override
  void dispose() {
    if (_messageListener != null) {
      html.window.removeEventListener('message', _messageListener);
      _messageListener = null;
    }
    super.dispose();
  }

  void _registerWebView() {
    if (_registeredViewIds.contains(_viewId)) {
      if (mounted) setState(() => _isViewRegistered = true);
      return;
    }

    final baseUrl = Uri.base.origin;
    final paymentUrl = '$baseUrl/toss_payment.html';
    print('🔗 [TossPaymentWeb] Payment URL: $paymentUrl');

    try {
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) {
          print('🏗️ [TossPaymentWeb] Creating iframe');

          _iframe = html.IFrameElement()
            ..id = 'toss-payment-iframe-$viewId'
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..allow = 'payment'
            ..src = paymentUrl;

          _iframe!.onLoad.listen((_) {
            print('✅ [TossPaymentWeb] iframe loaded');
            // iframe 로드 완료 후 config 전송
            Future.delayed(const Duration(milliseconds: 100), () {
              _sendConfigToIframe();
            });
          });

          return _iframe!;
        },
      );

      _registeredViewIds.add(_viewId);
      print('✅ [TossPaymentWeb] ViewFactory registered');

      if (mounted) setState(() => _isViewRegistered = true);
    } catch (e) {
      print('❌ [TossPaymentWeb] Register error: $e');
      if (mounted) setState(() => _isViewRegistered = true);
    }
  }

  void _sendConfigToIframe() {
    if (_configSent || _iframe == null) return;

    final cleanPhone = widget.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final baseUrl = Uri.base.origin;

    // JSON 문자열로 전송 (structured clone 에러 방지)
    final configJson = jsonEncode({
      'type': 'TOSS_PAYMENT_CONFIG',
      'config': {
        'clientKey': _testClientKey,
        'customerKey': widget.userId,
        'orderId': widget.orderId,
        'orderName': widget.orderName,
        'amount': widget.amount,
        'productAmount': widget.productAmount,
        'shippingFee': widget.shippingFee,
        'customerName': widget.customerName,
        'customerEmail': widget.customerEmail,
        'customerPhone': cleanPhone,
        'baseUrl': baseUrl, // 콜백 URL 생성용
      }
    });

    try {
      _iframe!.contentWindow?.postMessage(configJson, '*');
      _configSent = true;
      print('📤 [TossPaymentWeb] Config sent to iframe (baseUrl: $baseUrl)');
    } catch (e) {
      print('❌ [TossPaymentWeb] Failed to send config: $e');
    }
  }

  void _setupMessageListener() {
    _messageListener = (html.Event event) {
      if (_isNavigating || !mounted) return;

      final messageEvent = event as html.MessageEvent;
      dynamic data = messageEvent.data;

      // JSON 문자열인 경우 파싱
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (e) {
          print('📩 [TossPaymentWeb] Non-JSON message: $data');
          return;
        }
      }

      if (data is! Map) return;

      final type = data['type'];
      print('📩 [TossPaymentWeb] Message: $type');

      switch (type) {
        case 'TOSS_PAYMENT_READY':
          print('🔔 [TossPaymentWeb] iframe ready, sending config...');
          _sendConfigToIframe();
          break;

        case 'TOSS_PAYMENT_SUCCESS':
          _isNavigating = true;
          final paymentKey = data['paymentKey'] as String? ?? '';
          final orderId = data['orderId'] as String? ?? widget.orderId;
          final amount = _parseAmount(data['amount']);
          print('✅ [TossPaymentWeb] Payment SUCCESS');
          _handleSuccess(paymentKey, orderId, amount);
          break;

        case 'TOSS_PAYMENT_FAIL':
          _isNavigating = true;
          final code = data['code'] as String? ?? 'UNKNOWN';
          final message = data['message'] as String? ?? '알 수 없는 오류';
          print('❌ [TossPaymentWeb] Payment FAIL: $code - $message');
          _handleFail(code, message);
          break;

        case 'TOSS_PAYMENT_CANCEL':
          _isNavigating = true;
          print('🚫 [TossPaymentWeb] Payment CANCEL');
          _handleCancel();
          break;
      }

      // 로딩 완료
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    };

    html.window.addEventListener('message', _messageListener);
    print('👂 [TossPaymentWeb] Message listener attached');
  }

  int _parseAmount(dynamic value) {
    if (value == null) return widget.amount;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? widget.amount;
    return widget.amount;
  }

  Future<void> _handleSuccess(String paymentKey, String orderId, int amount) async {
    try {
      ref.read(isApprovingPaymentProvider.notifier).state = true;

      final approvedPayment = await ref
          .read(approveTossPaymentUseCaseProvider)
          .call(paymentKey: paymentKey, orderId: orderId, amount: amount);

      ref.read(isApprovingPaymentProvider.notifier).state = false;

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pop(context, {
              'success': true,
              'paymentKey': paymentKey,
              'orderId': orderId,
              'amount': amount,
              'payment': approvedPayment,
            });
          }
        });
      }
    } catch (e) {
      ref.read(isApprovingPaymentProvider.notifier).state = false;
      print('❌ [TossPaymentWeb] Approval error: $e');
      _showError('결제 승인 실패: $e');
    }
  }

  void _handleFail(String code, String message) {
    ref.read(paymentErrorProvider.notifier).state = message;
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context, {
            'success': false,
            'errorCode': code,
            'errorMessage': message,
          });
        }
      });
    }
  }

  void _handleCancel() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context, {
            'success': false,
            'errorCode': 'USER_CANCEL',
            'errorMessage': '사용자가 결제를 취소했습니다',
          });
        }
      });
    }
  }

  void _showError(String message) {
    ref.read(paymentErrorProvider.notifier).state = message;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context, {'success': false, 'errorMessage': message});
        }
      });
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('결제 취소'),
        content: const Text('결제를 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('계속 진행'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context, {
                'success': false,
                'errorCode': 'USER_CANCEL',
                'errorMessage': '사용자가 결제를 취소했습니다',
              });
            },
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isApproving = ref.watch(isApprovingPaymentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('토스페이먼츠 결제'),
        backgroundColor: const Color(0xFF0064FF),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _showCancelDialog,
        ),
      ),
      body: Stack(
        children: [
          if (_isViewRegistered)
            HtmlElementView(viewType: _viewId)
          else
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0064FF)),
              ),
            ),

          if (isApproving)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0064FF)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '결제 승인 중...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
