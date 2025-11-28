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
  bool _isViewRegistered = false; // viewFactory 등록 완료 플래그
  html.EventListener? _messageListener;

  // 토스페이먼츠 결제위젯 연동 클라이언트 키
  static const String _testClientKey = 'test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm';

  // 이미 등록된 viewId 추적 (중복 등록 방지)
  static final Set<String> _registeredViewIds = {};

  @override
  void initState() {
    super.initState();
    print('🔍 [TossPaymentWeb] === Widget 값 확인 ===');
    print('🔍 [TossPaymentWeb] orderId: ${widget.orderId}');
    print('🔍 [TossPaymentWeb] userId: ${widget.userId}');
    print('🔍 [TossPaymentWeb] orderName: ${widget.orderName}');
    print('🔍 [TossPaymentWeb] amount (총액): ${widget.amount}');
    print('🔍 [TossPaymentWeb] productAmount (상품금액): ${widget.productAmount}');
    print('🔍 [TossPaymentWeb] shippingFee (배송비): ${widget.shippingFee}');

    _viewId = 'toss-payment-${widget.orderId.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    _registerWebView();
    _setupMessageListener();
  }

  @override
  void dispose() {
    // 메시지 리스너 정리
    if (_messageListener != null) {
      html.window.removeEventListener('message', _messageListener);
    }
    super.dispose();
  }

  /// 결제 페이지 URL 생성 (URL 파라미터로 결제 정보 전달)
  String _buildPaymentUrl() {
    final cleanPhone = widget.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final baseUrl = Uri.base.origin;

    final params = {
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
    };

    final uri = Uri.parse('$baseUrl/toss_payment.html').replace(queryParameters: params);
    print('🔍 [TossPaymentWeb] Payment URL: $uri');
    return uri.toString();
  }

  void _registerWebView() {
    // 이미 등록된 viewId인지 확인
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
          final iframe = html.IFrameElement()
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..src = paymentUrl;

          iframe.onLoad.listen((_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
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
      // 이미 등록된 경우에도 진행
      if (mounted) {
        setState(() => _isViewRegistered = true);
      }
    }
  }

  void _setupMessageListener() {
    _messageListener = (html.Event event) {
      if (_isNavigating || !mounted) return;

      final messageEvent = event as html.MessageEvent;
      print('📩 [TossPaymentWeb] Message received: ${messageEvent.data}');

      final data = messageEvent.data;
      if (data is Map) {
        final type = data['type'];
        print('📩 [TossPaymentWeb] Message type: $type');

        if (type == 'TOSS_PAYMENT_SUCCESS') {
          _isNavigating = true;
          print('✅ [TossPaymentWeb] Payment success - paymentKey: ${data['paymentKey']}');
          _handleSuccess(
            data['paymentKey'] as String? ?? '',
            data['orderId'] as String? ?? widget.orderId,
            _parseAmount(data['amount']),
          );
        } else if (type == 'TOSS_PAYMENT_FAIL') {
          _isNavigating = true;
          final code = data['code'] as String? ?? 'UNKNOWN';
          final message = data['message'] as String? ?? '알 수 없는 오류';
          print('❌ [TossPaymentWeb] Payment failed - code: $code, message: $message');
          _handleFail(code, message);
        } else if (type == 'TOSS_PAYMENT_CANCEL') {
          _isNavigating = true;
          print('🚫 [TossPaymentWeb] Payment cancelled');
          _handleCancel();
        }
      }
    };

    html.window.addEventListener('message', _messageListener);
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
          onPressed: () {
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
          },
        ),
      ),
      body: Stack(
        children: [
          // viewFactory가 등록된 후에만 HtmlElementView 표시
          if (_isViewRegistered)
            HtmlElementView(viewType: _viewId)
          else
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0064FF)),
              ),
            ),
          if (_isLoading || isApproving)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0064FF)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isApproving ? '결제 승인 중...' : '로딩 중...',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
