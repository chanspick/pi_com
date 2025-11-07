import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pi_com/features/payment/presentation/providers/payment_provider.dart';

/// 카카오페이 WebView 결제 화면
class PaymentWebViewScreen extends ConsumerStatefulWidget {
  final String paymentUrl; // 카카오페이 결제 페이지 URL
  final String tid; // 결제 고유 번호
  final String orderId; // 주문 번호
  final String userId; // 사용자 ID
  final String approvalUrlPattern; // 승인 URL 패턴
  final String cancelUrlPattern; // 취소 URL 패턴
  final String failUrlPattern; // 실패 URL 패턴

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.tid,
    required this.orderId,
    required this.userId,
    this.approvalUrlPattern = '/payment/approve',
    this.cancelUrlPattern = '/payment/cancel',
    this.failUrlPattern = '/payment/fail',
  });

  @override
  ConsumerState<PaymentWebViewScreen> createState() =>
      _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends ConsumerState<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
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

            // 결제 승인 URL 감지
            if (url.contains(widget.approvalUrlPattern)) {
              _handleApproval(url);
              return NavigationDecision.prevent;
            }

            // 결제 취소 URL 감지
            if (url.contains(widget.cancelUrlPattern)) {
              _handleCancel();
              return NavigationDecision.prevent;
            }

            // 결제 실패 URL 감지
            if (url.contains(widget.failUrlPattern)) {
              _handleFail(url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  /// 결제 승인 처리
  void _handleApproval(String url) async {
    try {
      // URL에서 pg_token 추출
      final uri = Uri.parse(url);
      final pgToken = uri.queryParameters['pg_token'];

      if (pgToken == null || pgToken.isEmpty) {
        _showError('결제 승인 토큰을 찾을 수 없습니다');
        return;
      }

      // 승인 중 상태 설정
      ref.read(isApprovingPaymentProvider.notifier).state = true;

      // 결제 승인 API 호출
      final approvedPayment = await ref
          .read(approvePaymentUseCaseProvider)
          .call(
            tid: widget.tid,
            orderId: widget.orderId,
            userId: widget.userId,
            pgToken: pgToken,
          );

      // 승인 완료 상태 해제
      ref.read(isApprovingPaymentProvider.notifier).state = false;

      // 현재 결제 정보 업데이트
      ref.read(currentPaymentProvider.notifier).state = approvedPayment;

      // 결제 성공으로 화면 닫기
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ref.read(isApprovingPaymentProvider.notifier).state = false;
      _showError('결제 승인 실패: $e');
    }
  }

  /// 결제 취소 처리
  void _handleCancel() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제가 취소되었습니다')),
      );
      Navigator.pop(context, false);
    }
  }

  /// 결제 실패 처리
  void _handleFail(String url) {
    final uri = Uri.parse(url);
    final errorMsg = uri.queryParameters['error_msg'] ?? '알 수 없는 오류';

    _showError('결제 실패: $errorMsg');
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
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApproving = ref.watch(isApprovingPaymentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('카카오페이 결제'),
        backgroundColor: const Color(0xFFFFE812), // 카카오 노란색
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
                      Navigator.pop(context, false); // WebView 닫기
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
                        Color(0xFFFFE812),
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
