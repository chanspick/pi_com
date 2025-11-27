import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 토스페이먼츠 웹 결제 화면 스텁 (모바일용)
/// 모바일에서는 사용되지 않음 - WebView 화면을 사용
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
  @override
  Widget build(BuildContext context) {
    // 이 화면은 모바일에서 호출되면 안 됨
    return Scaffold(
      appBar: AppBar(title: const Text('오류')),
      body: const Center(
        child: Text('이 화면은 웹에서만 사용 가능합니다.'),
      ),
    );
  }
}
