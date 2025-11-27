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
  final int amount;
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
  bool _isNavigating = false; // 중복 네비게이션 방지 플래그

  // 토스페이먼츠 결제위젯 연동 클라이언트 키
  static const String _testClientKey = 'test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm';

  @override
  void initState() {
    super.initState();
    _viewId = 'toss-payment-${DateTime.now().millisecondsSinceEpoch}';
    _registerWebView();
    _setupMessageListener();
  }

  void _registerWebView() {
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..srcdoc = _buildPaymentHtml();

        iframe.onLoad.listen((_) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        });

        return iframe;
      },
    );
  }

  void _setupMessageListener() {
    html.window.onMessage.listen((event) {
      // 이미 네비게이션 중이면 무시
      if (_isNavigating || !mounted) return;

      print('📩 [TossPaymentWeb] Message received: ${event.data}');

      final data = event.data;
      if (data is Map) {
        final type = data['type'];
        print('📩 [TossPaymentWeb] Message type: $type');

        if (type == 'TOSS_PAYMENT_SUCCESS') {
          _isNavigating = true;
          print('✅ [TossPaymentWeb] Payment success - paymentKey: ${data['paymentKey']}');
          _handleSuccess(
            data['paymentKey'] as String? ?? '',
            data['orderId'] as String? ?? widget.orderId,
            data['amount'] as int? ?? widget.amount,
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
    });
  }

  String _buildPaymentHtml() {
    // 웹 전용 redirect URL (postMessage로 결과 전달)
    const webSuccessUrl = 'https://asia-northeast3-picom-team.cloudfunctions.net/api/toss-payment-redirect/web-success';
    const webFailUrl = 'https://asia-northeast3-picom-team.cloudfunctions.net/api/toss-payment-redirect/web-fail';

    // 전화번호에서 특수문자 제거
    final cleanPhone = widget.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>토스페이먼츠 결제</title>
  <script src="https://js.tosspayments.com/v2/standard"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #f5f5f5;
      min-height: 100vh;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
    }
    .order-info {
      background: white;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 20px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .order-info h3 {
      font-size: 18px;
      margin-bottom: 16px;
      color: #333;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 12px 0;
      border-bottom: 1px solid #eee;
    }
    .info-row:last-child { border-bottom: none; }
    .info-label { color: #666; }
    .info-value { font-weight: 600; color: #333; }
    .total-amount { font-size: 24px; color: #0064FF; }
    #payment-method, #agreement {
      background: white;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 20px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .pay-button {
      width: 100%;
      padding: 18px;
      background: #0064FF;
      color: white;
      border: none;
      border-radius: 12px;
      font-size: 18px;
      font-weight: 600;
      cursor: pointer;
    }
    .pay-button:disabled { background: #ccc; cursor: not-allowed; }
    .loading {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 40px;
    }
    .spinner {
      width: 40px;
      height: 40px;
      border: 4px solid #f3f3f3;
      border-top: 4px solid #0064FF;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }
    @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
    .error-message {
      background: #fff3f3;
      border: 1px solid #ffcccc;
      border-radius: 8px;
      padding: 16px;
      color: #cc0000;
      margin-bottom: 20px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="order-info">
      <h3>주문 정보</h3>
      <div class="info-row">
        <span class="info-label">상품명</span>
        <span class="info-value">${widget.orderName}</span>
      </div>
      <div class="info-row">
        <span class="info-label">주문번호</span>
        <span class="info-value">${widget.orderId}</span>
      </div>
      <div class="info-row">
        <span class="info-label">결제금액</span>
        <span class="info-value total-amount">${_formatPrice(widget.amount)}원</span>
      </div>
    </div>

    <div id="loading" class="loading">
      <div class="spinner"></div>
      <p style="margin-top: 16px; color: #666;">결제 수단을 불러오는 중...</p>
    </div>

    <div id="error-container" style="display: none;"></div>
    <div id="payment-method" style="display: none;"></div>
    <div id="agreement" style="display: none;"></div>

    <button id="pay-button" class="pay-button" style="display: none;" onclick="requestPayment()">
      ${_formatPrice(widget.amount)}원 결제하기
    </button>
  </div>

  <script>
    const clientKey = "$_testClientKey";
    const customerKey = "${widget.userId}";
    let widgets = null;

    // 결제 정보 (Dart에서 전달)
    const orderId = "${widget.orderId}";
    const orderName = "${widget.orderName}";
    const amount = ${widget.amount};
    const customerName = "${widget.customerName}";
    const customerEmail = "${widget.customerEmail}";
    const customerPhone = "$cleanPhone";
    const successUrl = "$webSuccessUrl";
    const failUrl = "$webFailUrl";

    console.log('=== 결제 정보 초기화 ===');
    console.log('orderId:', orderId);
    console.log('orderName:', orderName);
    console.log('amount:', amount);
    console.log('customerPhone:', customerPhone);
    console.log('successUrl:', successUrl);

    async function initializePayment() {
      try {
        console.log('TossPayments 초기화 중...');
        const tossPayments = TossPayments(clientKey);
        widgets = tossPayments.widgets({ customerKey: customerKey });

        console.log('금액 설정:', amount);
        await widgets.setAmount({ currency: "KRW", value: amount });

        console.log('결제 수단 렌더링...');
        await widgets.renderPaymentMethods({ selector: "#payment-method", variantKey: "DEFAULT" });
        await widgets.renderAgreement({ selector: "#agreement", variantKey: "AGREEMENT" });

        document.getElementById('loading').style.display = 'none';
        document.getElementById('payment-method').style.display = 'block';
        document.getElementById('agreement').style.display = 'block';
        document.getElementById('pay-button').style.display = 'block';
        console.log('결제 위젯 초기화 완료!');
      } catch (error) {
        console.error('초기화 오류:', error);
        showError('결제 수단을 불러오는 중 오류가 발생했습니다: ' + (error.message || '알 수 없는 오류'));
      }
    }

    function showError(message) {
      document.getElementById('loading').style.display = 'none';
      document.getElementById('error-container').innerHTML = '<div class="error-message">' + message + '</div>';
      document.getElementById('error-container').style.display = 'block';
    }

    async function requestPayment() {
      const button = document.getElementById('pay-button');
      button.disabled = true;
      button.textContent = '결제 처리 중...';

      console.log('=== requestPayment 시작 ===');
      console.log('widgets:', widgets ? 'OK' : 'NULL');

      if (!widgets) {
        console.error('widgets 객체가 없습니다!');
        window.parent.postMessage({
          type: 'TOSS_PAYMENT_FAIL',
          code: 'WIDGETS_NOT_INITIALIZED',
          message: '결제 위젯이 초기화되지 않았습니다.'
        }, '*');
        return;
      }

      try {
        // 결제 요청 파라미터
        const paymentParams = {
          orderId: orderId,
          orderName: orderName,
          // ✅ Redirect 방식: successUrl/failUrl 설정
          // iframe 내에서 이 URL로 리다이렉트되고, 해당 페이지에서 postMessage 전송
          successUrl: successUrl,
          failUrl: failUrl
        };

        // 선택적 파라미터 추가
        if (customerName && customerName.trim()) {
          paymentParams.customerName = customerName;
        }
        if (customerEmail && customerEmail.trim()) {
          paymentParams.customerEmail = customerEmail;
        }
        if (customerPhone && customerPhone.length >= 10) {
          paymentParams.customerMobilePhone = customerPhone;
        }

        console.log('Payment params:', JSON.stringify(paymentParams, null, 2));
        console.log('widgets.requestPayment 호출...');

        // ✅ Redirect 방식으로 결제 요청
        // 성공 시: successUrl로 리다이렉트 → 해당 페이지에서 postMessage 전송
        // 실패/취소 시: catch 블록에서 처리
        await widgets.requestPayment(paymentParams);

        // 이 코드는 실행되지 않음 (성공 시 리다이렉트됨)
        console.log('requestPayment 완료 (이 로그가 보이면 문제 있음)');

      } catch (error) {
        console.error('=== Payment error ===');
        console.error('error:', error);
        console.error('error.code:', error?.code);
        console.error('error.message:', error?.message);

        const errorCode = error?.code || 'UNKNOWN_ERROR';
        const errorMessage = error?.message || String(error) || '결제 처리 중 오류가 발생했습니다.';

        if (errorCode === 'USER_CANCEL' || errorCode === 'PAY_PROCESS_CANCELED') {
          window.parent.postMessage({ type: 'TOSS_PAYMENT_CANCEL' }, '*');
        } else {
          window.parent.postMessage({
            type: 'TOSS_PAYMENT_FAIL',
            code: errorCode,
            message: errorMessage
          }, '*');
        }
        button.disabled = false;
        button.textContent = '${_formatPrice(widget.amount)}원 결제하기';
      }
    }

    initializePayment();
  </script>
</body>
</html>
''';
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
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
        // 안전한 네비게이션: 현재 프레임 완료 후 실행
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
              builder: (context) => AlertDialog(
                title: const Text('결제 취소'),
                content: const Text('결제를 취소하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('계속 진행'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
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
          HtmlElementView(viewType: _viewId),
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
