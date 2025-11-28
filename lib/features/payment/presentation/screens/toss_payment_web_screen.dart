// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/payment/presentation/providers/payment_provider.dart';

/// 토스페이먼츠 웹 결제 화면 (Flutter Web 전용)
/// iframe을 사용하여 결제 위젯을 로드
class TossPaymentWebScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String userId;
  final String orderName;
  final int amount; // 총 결제 금액 (상품 + 배송비)
  final int productAmount; // 상품 금액
  final int shippingFee; // 배송비
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
  html.EventListener? _messageListener;

  // 토스페이먼츠 결제위젯 연동 클라이언트 키 (테스트)
  static const String _testClientKey = 'test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm';

  // 이미 등록된 viewId 추적
  static final Set<String> _registeredViewIds = {};

  @override
  void initState() {
    super.initState();
    _logPaymentInfo();
    _viewId = 'toss-payment-${DateTime.now().millisecondsSinceEpoch}';
    _registerWebView();
    _setupMessageListener();
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
    print('  customerName: ${widget.customerName}');
    print('  customerEmail: ${widget.customerEmail}');
    print('  customerPhone: ${widget.customerPhone}');
    print('========================================');
    print('');
  }

  @override
  void dispose() {
    if (_messageListener != null) {
      html.window.removeEventListener('message', _messageListener);
      _messageListener = null;
    }
    super.dispose();
  }

  /// 결제 페이지 URL 생성
  String _buildPaymentUrl() {
    final cleanPhone = widget.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final baseUrl = Uri.base.origin;

    // URL 파라미터 구성
    final uri = Uri.parse('$baseUrl/toss_payment.html').replace(
      queryParameters: {
        'clientKey': _testClientKey,
        'customerKey': widget.userId,
        'orderId': widget.orderId,
        'orderName': widget.orderName,
        'amount': widget.amount.toString(),
        'productAmount': widget.productAmount.toString(),
        'shippingFee': widget.shippingFee.toString(),
        'customerName': widget.customerName,
        'customerEmail': widget.customerEmail,
        'customerPhone': cleanPhone,
      },
    );

    final urlString = uri.toString();
    print('🔗 [TossPaymentWeb] Payment URL: $urlString');
    return urlString;
  }

  void _registerWebView() {
    if (_registeredViewIds.contains(_viewId)) {
      print('⚠️ [TossPaymentWeb] ViewId already registered: $_viewId');
      if (mounted) {
        setState(() => _isViewRegistered = true);
      }
      return;
    }

    final paymentUrl = _buildPaymentUrl();

    try {
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) {
          print('🏗️ [TossPaymentWeb] Creating iframe for viewId: $viewId');

          final iframe = html.IFrameElement()
            ..id = 'toss-payment-iframe-$viewId'
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..allow = 'payment'
            ..setAttribute('allowfullscreen', 'true')
            ..src = paymentUrl;

          // iframe 로드 완료 이벤트
          iframe.onLoad.listen((_) {
            print('✅ [TossPaymentWeb] iframe loaded successfully');
            if (mounted) {
              setState(() => _isLoading = false);
            }
          });

          // iframe 에러 이벤트
          iframe.onError.listen((event) {
            print('❌ [TossPaymentWeb] iframe error: $event');
          });

          return iframe;
        },
      );

      _registeredViewIds.add(_viewId);
      print('✅ [TossPaymentWeb] ViewFactory registered: $_viewId');

      if (mounted) {
        setState(() => _isViewRegistered = true);
      }
    } catch (e) {
      print('❌ [TossPaymentWeb] Failed to register viewFactory: $e');
      if (mounted) {
        setState(() => _isViewRegistered = true);
      }
    }
  }

  void _setupMessageListener() {
    _messageListener = (html.Event event) {
      if (_isNavigating || !mounted) return;

      final messageEvent = event as html.MessageEvent;
      final data = messageEvent.data;

      if (data is! Map) return;

      final type = data['type'];
      print('📩 [TossPaymentWeb] Message received - type: $type');

      switch (type) {
        case 'TOSS_PAYMENT_SUCCESS':
          _isNavigating = true;
          final paymentKey = data['paymentKey'] as String? ?? '';
          final orderId = data['orderId'] as String? ?? widget.orderId;
          final amount = _parseAmount(data['amount']);
          print('✅ [TossPaymentWeb] Payment SUCCESS');
          print('   paymentKey: $paymentKey');
          print('   orderId: $orderId');
          print('   amount: $amount');
          _handleSuccess(paymentKey, orderId, amount);
          break;

        case 'TOSS_PAYMENT_FAIL':
          _isNavigating = true;
          final code = data['code'] as String? ?? 'UNKNOWN';
          final message = data['message'] as String? ?? '알 수 없는 오류';
          print('❌ [TossPaymentWeb] Payment FAIL');
          print('   code: $code');
          print('   message: $message');
          _handleFail(code, message);
          break;

        case 'TOSS_PAYMENT_CANCEL':
          _isNavigating = true;
          print('🚫 [TossPaymentWeb] Payment CANCEL');
          _handleCancel();
          break;
      }
    };

    html.window.addEventListener('message', _messageListener);
    print('👂 [TossPaymentWeb] Message listener attached');
  }

  /// amount 값을 안전하게 int로 변환
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
          .call(
            paymentKey: paymentKey,
            orderId: orderId,
            amount: amount,
          );

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
          // iframe 표시 (viewFactory 등록 후에만)
          if (_isViewRegistered)
            HtmlElementView(viewType: _viewId)
          else
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0064FF)),
              ),
            ),

          // 로딩 오버레이
          if (_isLoading || isApproving)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0064FF)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isApproving ? '결제 승인 중...' : '결제 위젯 로딩 중...',
                      style: const TextStyle(
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
