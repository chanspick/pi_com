import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pi_com/features/payment/presentation/providers/payment_provider.dart';

/// 토스페이먼츠 WebView 결제 화면
/// 결제위젯을 WebView로 로드하여 다양한 결제수단 제공
class TossPaymentWebViewScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String userId;
  final String orderName;
  final int amount;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String successUrl;
  final String failUrl;

  const TossPaymentWebViewScreen({
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
  ConsumerState<TossPaymentWebViewScreen> createState() =>
      _TossPaymentWebViewScreenState();
}

class _TossPaymentWebViewScreenState
    extends ConsumerState<TossPaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  // 토스페이먼츠 테스트용 클라이언트 키 (실제 배포시 환경변수로 관리)
  static const String _testClientKey = 'test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  String _buildPaymentHtml() {
    // 토스페이먼츠 결제위젯 HTML 페이지 생성
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
    .total-amount {
      font-size: 24px;
      color: #0064FF;
    }
    #payment-method {
      background: white;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 20px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    #agreement {
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
      transition: background 0.2s;
    }
    .pay-button:hover { background: #0052CC; }
    .pay-button:disabled {
      background: #ccc;
      cursor: not-allowed;
    }
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
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
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
    let selectedPaymentMethod = null;

    async function initializePayment() {
      try {
        // 토스페이먼츠 SDK 초기화
        const tossPayments = TossPayments(clientKey);
        widgets = tossPayments.widgets({ customerKey });

        // 결제 금액 설정
        await widgets.setAmount({
          currency: "KRW",
          value: ${widget.amount}
        });

        // 결제 수단 위젯 렌더링
        await widgets.renderPaymentMethods({
          selector: "#payment-method",
          variantKey: "DEFAULT"
        });

        // 약관 동의 위젯 렌더링
        await widgets.renderAgreement({
          selector: "#agreement",
          variantKey: "AGREEMENT"
        });

        // 로딩 숨기고 위젯 표시
        document.getElementById('loading').style.display = 'none';
        document.getElementById('payment-method').style.display = 'block';
        document.getElementById('agreement').style.display = 'block';
        document.getElementById('pay-button').style.display = 'block';

      } catch (error) {
        console.error('Payment initialization error:', error);
        showError('결제 수단을 불러오는 중 오류가 발생했습니다: ' + error.message);
      }
    }

    function showError(message) {
      document.getElementById('loading').style.display = 'none';
      const errorContainer = document.getElementById('error-container');
      errorContainer.innerHTML = '<div class="error-message">' + message + '</div>';
      errorContainer.style.display = 'block';
    }

    async function requestPayment() {
      const button = document.getElementById('pay-button');
      button.disabled = true;
      button.textContent = '결제 처리 중...';

      try {
        await widgets.requestPayment({
          orderId: "${widget.orderId}",
          orderName: "${widget.orderName}",
          customerName: "${widget.customerName}",
          customerEmail: "${widget.customerEmail}",
          customerMobilePhone: "${widget.customerPhone}",
          successUrl: "${widget.successUrl}",
          failUrl: "${widget.failUrl}"
        });
      } catch (error) {
        console.error('Payment request error:', error);
        if (error.code === 'USER_CANCEL') {
          // 사용자가 결제를 취소한 경우
          window.location.href = '${widget.failUrl}?code=USER_CANCEL&message=사용자가 결제를 취소했습니다';
        } else {
          showError('결제 요청 중 오류가 발생했습니다: ' + error.message);
        }
        button.disabled = false;
        button.textContent = '${_formatPrice(widget.amount)}원 결제하기';
      }
    }

    // 페이지 로드 시 초기화
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

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF5F5F5))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            _showError('페이지 로드 오류: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            // 결제 성공 URL 감지
            if (url.contains('/toss-payment/success') ||
                url.contains('payment_key=')) {
              _handleSuccess(url);
              return NavigationDecision.prevent;
            }

            // 결제 실패 URL 감지
            if (url.contains('/toss-payment/fail') ||
                url.contains('code=') && url.contains('message=')) {
              _handleFail(url);
              return NavigationDecision.prevent;
            }

            // 딥링크 처리 (카드사 앱, 은행 앱 등)
            if (_isDeepLink(url)) {
              _handleDeepLink(url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_buildPaymentHtml());
  }

  bool _isDeepLink(String url) {
    final deepLinkSchemes = [
      'intent://',
      'ispmobile://',
      'hdcardappcardansimclick://',
      'smhyundaiansimclick://',
      'shinhan-sr-ansimclick://',
      'kb-acp://',
      'mpocket.online.ansimclick://',
      'ansimclickscard://',
      'ansimclickipcollect://',
      'vguardstart://',
      'samsungpay://',
      'kakaotalk://',
      'supertoss://',
      'lpayapp://',
      'payco://',
      'kbbank://',
      'hanabank://',
      'nhbank://',
      'wooribank://',
      'shinhan-sr://',
      'kb-bankpay://',
    ];

    return deepLinkSchemes.any((scheme) => url.startsWith(scheme));
  }

  Future<void> _handleDeepLink(String url) async {
    try {
      // 앱 딥링크 처리
      // intent:// 스킴의 경우 Android에서 앱 실행
      if (url.startsWith('intent://')) {
        // intent 스킴에서 package 추출하여 마켓으로 이동
        final packageMatch = RegExp(r'package=([^;]+)').firstMatch(url);
        if (packageMatch != null) {
          final package = packageMatch.group(1);
          // 플레이 스토어로 이동
          final marketUrl = 'market://details?id=$package';
          // URL Launcher로 열기
        }
      }
    } catch (e) {
      print('딥링크 처리 오류: $e');
    }
  }

  /// 결제 성공 처리
  void _handleSuccess(String url) async {
    try {
      final uri = Uri.parse(url);
      final paymentKey = uri.queryParameters['paymentKey'];
      final orderId = uri.queryParameters['orderId'];
      final amount = uri.queryParameters['amount'];

      if (paymentKey == null || orderId == null || amount == null) {
        _showError('결제 정보가 올바르지 않습니다');
        return;
      }

      // 승인 중 상태 설정
      ref.read(isApprovingPaymentProvider.notifier).state = true;

      // 서버에서 결제 승인 API 호출
      final approvedPayment = await ref
          .read(approveTossPaymentUseCaseProvider)
          .call(
            paymentKey: paymentKey,
            orderId: orderId,
            amount: int.parse(amount),
          );

      ref.read(isApprovingPaymentProvider.notifier).state = false;

      // 결제 성공으로 화면 닫기
      if (mounted) {
        Navigator.pop(context, {
          'success': true,
          'paymentKey': paymentKey,
          'orderId': orderId,
          'amount': amount,
          'payment': approvedPayment,
        });
      }
    } catch (e) {
      ref.read(isApprovingPaymentProvider.notifier).state = false;
      _showError('결제 승인 실패: $e');
    }
  }

  /// 결제 실패 처리
  void _handleFail(String url) {
    final uri = Uri.parse(url);
    final errorCode = uri.queryParameters['code'] ?? 'UNKNOWN';
    final errorMsg = uri.queryParameters['message'] ?? '알 수 없는 오류';

    ref.read(paymentErrorProvider.notifier).state = errorMsg;

    if (mounted) {
      Navigator.pop(context, {
        'success': false,
        'errorCode': errorCode,
        'errorMessage': errorMsg,
      });
    }
  }

  /// 에러 메시지 표시
  void _showError(String message) {
    ref.read(paymentErrorProvider.notifier).state = message;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, {
        'success': false,
        'errorMessage': message,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApproving = ref.watch(isApprovingPaymentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('토스페이먼츠 결제'),
        backgroundColor: const Color(0xFF0064FF), // 토스페이먼츠 파란색
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
                      Navigator.pop(context); // 다이얼로그 닫기
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
          WebViewWidget(controller: _controller),
          if (_isLoading || isApproving)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0064FF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isApproving ? '결제 승인 중...' : '로딩 중...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
