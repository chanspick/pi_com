// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pi_com/features/payment/presentation/providers/payment_provider.dart';
import 'package:pi_com/core/utils/app_logger.dart';

/// 토스페이먼츠 v2 웹 결제 화면 (Flutter Web 전용)
///
/// 새 창(popup) 방식으로 결제 진행
/// iframe에서 cross-origin navigation 제한 문제를 우회
/// 결제 흐름: 새 창 열기 → 결제 완료 → Firestore 리스닝으로 결과 감지
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
  bool _isWaitingForPayment = false;
  bool _isNavigating = false;
  html.WindowBase? _paymentWindow;
  html.EventListener? _messageListener;
  StreamSubscription<QuerySnapshot>? _paymentListener;
  Timer? _windowCheckTimer;

  static const String _testClientKey = 'test_gck_yL0qZ4G1VO54GNy9Wnjo8oWb2MQY';

  @override
  void initState() {
    super.initState();
    _logPaymentInfo();
    _setupMessageListener();
    _setupFirestoreListener();
  }

  void _logPaymentInfo() {
    AppLogger.i('결제 정보 (새 창 방식) - orderId: ${widget.orderId}, userId: ${widget.userId}, orderName: ${widget.orderName}, amount: ${widget.amount}, productAmount: ${widget.productAmount}, shippingFee: ${widget.shippingFee}', tag: 'TossPaymentWeb');
  }

  @override
  void dispose() {
    _windowCheckTimer?.cancel();
    _paymentListener?.cancel();
    _paymentListener = null;
    if (_messageListener != null) {
      html.window.removeEventListener('message', _messageListener);
      _messageListener = null;
    }
    // 결제 창이 열려있으면 닫기
    try {
      _paymentWindow?.close();
    } catch (_) {}
    super.dispose();
  }

  /// Firestore에서 결제 상태를 실시간으로 감시
  /// 서버에서 결제 승인 완료 시 toss_payments 컬렉션에 저장됨
  void _setupFirestoreListener() {
    AppLogger.d('Setting up Firestore listener for orderId: ${widget.orderId}', tag: 'TossPaymentWeb');

    _paymentListener = FirebaseFirestore.instance
        .collection('toss_payments')
        .where('orderId', isEqualTo: widget.orderId)
        .snapshots()
        .listen(
      (snapshot) {
        if (_isNavigating || !mounted) return;

        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added ||
              change.type == DocumentChangeType.modified) {
            final data = change.doc.data();
            if (data == null) continue;

            final status = data['status'] as String?;
            AppLogger.d('Payment status from Firestore: $status', tag: 'TossPaymentWeb');

            if (status == 'DONE' || status == 'approved' || status == 'COMPLETED') {
              _isNavigating = true;
              final paymentKey = data['paymentKey'] as String? ?? '';
              final amount = data['totalAmount'] as int? ?? widget.amount;

              AppLogger.i('Payment DONE via Firestore', tag: 'TossPaymentWeb');

              // 결제 창 닫기
              _closePaymentWindow();
              _handleSuccessFromFirestore(paymentKey, widget.orderId, amount, data);
            } else if (status == 'FAILED' || status == 'failed' || status == 'ABORTED') {
              _isNavigating = true;
              final code = data['errorCode'] as String? ?? 'PAYMENT_FAILED';
              final message = data['errorMessage'] as String? ?? '결제가 실패했습니다';

              AppLogger.e('Payment FAILED via Firestore', tag: 'TossPaymentWeb');
              _closePaymentWindow();
              _handleFail(code, message);
            } else if (status == 'CANCELED' || status == 'canceled') {
              _isNavigating = true;
              AppLogger.w('Payment CANCELED via Firestore', tag: 'TossPaymentWeb');
              _closePaymentWindow();
              _handleCancel();
            }
          }
        }
      },
      onError: (error) {
        AppLogger.e('Firestore listener error: $error', tag: 'TossPaymentWeb');
      },
    );
  }

  void _setupMessageListener() {
    _messageListener = (html.Event event) {
      if (_isNavigating || !mounted) return;

      final messageEvent = event as html.MessageEvent;
      dynamic rawData = messageEvent.data;

      Map<String, dynamic> data;

      try {
        if (rawData is String) {
          try {
            final decoded = jsonDecode(rawData);
            if (decoded is Map) {
              data = Map<String, dynamic>.from(decoded);
            } else {
              return;
            }
          } catch (e) {
            return;
          }
        } else if (rawData is Map) {
          try {
            final jsonStr = jsonEncode(rawData);
            data = Map<String, dynamic>.from(jsonDecode(jsonStr));
          } catch (e) {
            return;
          }
        } else {
          return;
        }
      } catch (e) {
        return;
      }

      final type = data['type'];
      AppLogger.d('Message Type: $type', tag: 'TossPaymentWeb');

      switch (type) {
        case 'TOSS_PAYMENT_SUCCESS':
          _isNavigating = true;
          final paymentKey = data['paymentKey'] as String? ?? '';
          final orderId = data['orderId'] as String? ?? widget.orderId;
          final amount = _parseAmount(data['amount']);
          AppLogger.i('Payment SUCCESS via postMessage', tag: 'TossPaymentWeb');
          _closePaymentWindow();
          _handleSuccess(paymentKey, orderId, amount);
          break;

        case 'TOSS_PAYMENT_FAIL':
          _isNavigating = true;
          final code = data['code'] as String? ?? 'UNKNOWN';
          final message = data['message'] as String? ?? '알 수 없는 오류';
          AppLogger.e('Payment FAIL: $code - $message', tag: 'TossPaymentWeb');
          _closePaymentWindow();
          _handleFail(code, message);
          break;

        case 'TOSS_PAYMENT_CANCEL':
          _isNavigating = true;
          AppLogger.w('Payment CANCEL', tag: 'TossPaymentWeb');
          _closePaymentWindow();
          _handleCancel();
          break;
      }
    };

    html.window.addEventListener('message', _messageListener);
    AppLogger.d('Message listener attached', tag: 'TossPaymentWeb');
  }

  /// 새 창에서 결제 페이지 열기
  void _openPaymentWindow() {
    if (_isWaitingForPayment) return;

    final baseUrl = Uri.base.origin;
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPhone = widget.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');

    final paymentUrl = Uri.parse('$cleanBaseUrl/toss_payment.html').replace(
      queryParameters: {
        'clientKey': _testClientKey,
        'customerKey': widget.userId,
        'orderId': widget.orderId,
        'orderName': widget.orderName,
        'amount': widget.amount.toString(),
        'productAmount': widget.productAmount.toString(),
        'shippingFee': widget.shippingFee.toString(),
        'customerEmail': widget.customerEmail,
        'customerName': widget.customerName,
        'customerPhone': cleanPhone,
      },
    ).toString();

    AppLogger.d('Opening payment window: $paymentUrl', tag: 'TossPaymentWeb');

    // 새 창 열기 (popup)
    _paymentWindow = html.window.open(
      paymentUrl,
      'toss_payment_popup',
      'width=500,height=700,scrollbars=yes,resizable=yes',
    );

    if (_paymentWindow != null) {
      setState(() => _isWaitingForPayment = true);

      // 창이 닫혔는지 주기적으로 확인
      _windowCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (_paymentWindow?.closed == true) {
          timer.cancel();
          if (!_isNavigating && mounted) {
            // 창이 닫혔는데 결과가 없으면 사용자가 수동으로 닫은 것
            AppLogger.w('Payment window closed by user', tag: 'TossPaymentWeb');
            setState(() => _isWaitingForPayment = false);
          }
        }
      });
    } else {
      // 팝업 차단됨
      _showError('팝업이 차단되었습니다. 팝업 차단을 해제해주세요.');
    }
  }

  void _closePaymentWindow() {
    _windowCheckTimer?.cancel();
    try {
      _paymentWindow?.close();
    } catch (_) {}
    _paymentWindow = null;
    if (mounted) {
      setState(() => _isWaitingForPayment = false);
    }
  }

  int _parseAmount(dynamic value) {
    if (value == null) return widget.amount;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? widget.amount;
    return widget.amount;
  }

  void _handleSuccessFromFirestore(
    String paymentKey,
    String orderId,
    int amount,
    Map<String, dynamic> paymentData,
  ) {
    AppLogger.i('Payment already approved, returning result', tag: 'TossPaymentWeb');

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context, {
            'success': true,
            'paymentKey': paymentKey,
            'orderId': orderId,
            'amount': amount,
            'payment': paymentData,
          });
        }
      });
    }
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
      AppLogger.e('Approval error: $e', tag: 'TossPaymentWeb');
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
    if (_isWaitingForPayment) {
      // 결제 진행 중이면 창 닫기
      _closePaymentWindow();
    }

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

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
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
      body: Container(
        color: const Color(0xFFF9FAFB),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 주문 정보 카드
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '주문 정보',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow('상품명', widget.orderName),
                      _buildInfoRow('상품 금액', '${_formatPrice(widget.productAmount)}원'),
                      _buildInfoRow(
                        '배송비',
                        widget.shippingFee > 0
                            ? '${_formatPrice(widget.shippingFee)}원'
                            : '무료',
                      ),
                      const Divider(height: 32),
                      _buildInfoRow(
                        '총 결제 금액',
                        '${_formatPrice(widget.amount)}원',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 결제 버튼 또는 상태 표시
                if (isApproving)
                  const Column(
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
                  )
                else if (_isWaitingForPayment)
                  Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0064FF)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '결제 창에서 결제를 진행해주세요',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: _openPaymentWindow,
                        child: const Text('결제 창 다시 열기'),
                      ),
                    ],
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openPaymentWindow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0064FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          '${_formatPrice(widget.amount)}원 결제하기',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              color: isTotal ? const Color(0xFF111827) : const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? const Color(0xFF0064FF) : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}